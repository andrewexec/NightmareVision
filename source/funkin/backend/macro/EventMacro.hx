package funkin.backend.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * Macro that generates all additional fields, making events much easier to code in.
 * It adds the `recycle` function, which allows you to "reset" an event's values.
 */
class EventMacro
{
	public static function build():Array<Field>
	{
		var fields = Context.getBuildFields();
		
		var curClassRest = Context.getLocalClass();
		if (curClassRest == null) return fields;
		
		var curClass = curClassRest.get();
		if (curClass == null) return fields;
		
		for (f in fields)
			if (f.name == "recycle") return fields;
			
		// gets all fields
		var values:Array<EventVar> = [];
		var hiddenValues:Array<EventVar> = [];
		
		for (field in fields)
		{
			if (field.access.contains(AStatic)) continue;
			
			var ignoredField = false;
			var hidden = false;
			if (field.meta != null) for (m in field.meta)
			{
				if (m.name == ":dox") hidden = true;
				if (m.name == ':ignore') ignoredField = true;
			}
			if (ignoredField) continue;
			
			if (!field.access.contains(APublic)) hidden = true;
			
			switch (field.kind)
			{
				case FVar(type, expr):
					(hidden ? hiddenValues : values).push(
						{
							name: field.name,
							type: type,
							expr: expr
						});
				default:
					continue;
			}
		}
		
		// add recycle Function
		var funcBlock:Array<Expr> = [macro basicRecycle(isCancellable)];
		
		// add a "set this" expr for each variable
		for (v in values)
		{
			var name = v.name;
			funcBlock.push(macro this.$name = $i{name});
		}
		
		// add a "set this" expr to reset each private/hidden variables
		for (v in hiddenValues)
		{
			var name = v.name;
			funcBlock.push(macro this.$name = ${v.expr});
		}
		
		funcBlock.push(macro return this);
		
		var func:Function =
			{
				args: [for (a in values)
					{
						name: a.name,
						type: a.type,
						opt: false
					}].concat([ // im gay
					{
						name: 'isCancellable',
						type: macro:Null<Bool>,
						opt: true
					}]),
				expr:
					{
						pos: Context.currentPos(),
						expr: EBlock(funcBlock)
					}
			};
		
		fields.push(
		{
			pos: Context.currentPos(),
			name: "recycle",
			kind: FFun(func),
			access: [APublic]
		});
		
		return fields;
	}
}

typedef EventVar =
{
	var name:String;
	var type:ComplexType;
	var expr:Expr;
}
#end
