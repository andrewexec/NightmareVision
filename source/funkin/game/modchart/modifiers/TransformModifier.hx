package funkin.game.modchart.modifiers;

typedef TransformKeyNames =
{
	xName:String,
	xAName:String,
	yName:String,
	yAName:String,
	zName:String,
	zAName:String
}

class TransformModifier extends NoteModifier
{ // this'll be transformX in ModManager
	inline function lerp(a:Float, b:Float, c:Float)
	{
		return a + (b - a) * c;
	}
	
	override function getName() return 'transformX';
	
	override function getOrder() return Modifier.ModifierOrder.LAST;
	
	var _keyNamesCache:Map<Int, TransformKeyNames> = new Map();
	
	function getKeyNames(data:Int):TransformKeyNames
	{
		var names = _keyNamesCache.get(data);
		if (names == null)
		{
			names =
				{
					xName: 'transform${data}X',
					xAName: 'transform${data}X-a',
					yName: 'transform${data}Y',
					yAName: 'transform${data}Y-a',
					zName: 'transform${data}Z',
					zAName: 'transform${data}Z-a'
				};
			_keyNamesCache.set(data, names);
		}
		return names;
	}
	
	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite)
	{
		pos.x += getValue(player) + getSubmodValue("transformX-a", player);
		pos.y += getSubmodValue("transformY", player) + getSubmodValue("transformY-a", player);
		pos.z += getSubmodValue('transformZ', player) + getSubmodValue("transformZ-a", player);
		
		final names = getKeyNames(data);
		pos.x += getSubmodValue(names.xName, player) + getSubmodValue(names.xAName, player);
		pos.y += getSubmodValue(names.yName, player) + getSubmodValue(names.yAName, player);
		pos.z += getSubmodValue(names.zName, player) + getSubmodValue(names.zAName, player);
		
		return pos;
	}
	
	override function getSubmods()
	{
		var subMods:Array<String> = ["transformY", "transformZ", "transformX-a", "transformY-a", "transformZ-a"];
		
		var receptors = modMgr.receptors[0];
		for (i in 0...PlayState.SONG.keys)
		{
			subMods.push('transform${i}X');
			subMods.push('transform${i}Y');
			subMods.push('transform${i}Z');
			subMods.push('transform${i}X-a');
			subMods.push('transform${i}Y-a');
			subMods.push('transform${i}Z-a');
		}
		return subMods;
	}
}
