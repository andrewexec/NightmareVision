package funkin.backend.plugins;

import flixel.group.FlxGroup.FlxTypedGroup;

import funkin.scripts.FunkinScript;
import funkin.scripts.ScriptGroup;

/**
 * A FlxPlugin that handles scripted plugins
 */
@:nullSafety
class ModPlugin extends FlxTypedGroup<FlxBasic>
{
	@:nullSafety(Off)
	public static var instance:ModPlugin;
	
	public static function init()
	{
		if (instance == null)
		{
			FlxG.plugins.addPlugin(instance = new ModPlugin());
			#if debug
			FlxG.console.registerClass(ModPlugin);
			#end
		}
	}
	
	public final scripts:ScriptGroup;
	
	public function new()
	{
		super();
		scripts = new ScriptGroup(this);
		
		if (!FlxG.signals.postStateSwitch.has(onStateSwitchPost)) FlxG.signals.postStateSwitch.add(onStateSwitchPost);
		if (!FlxG.signals.preStateSwitch.has(onStateSwitch)) FlxG.signals.preStateSwitch.add(onStateSwitch);
	}
	
	override function destroy()
	{
		clearScripts();
		super.destroy();
	}
	
	/**
	 * Destroys all currently loaded scripts
	 * @param callDestroy whether to dispatch `onDestroy` to the scripts before deletion
	 */
	public function clearScripts(callDestroy:Bool = true)
	{
		scripts.clear(callDestroy);
		
		forEach(member -> FlxDestroyUtil.destroy(member));
		clear();
	}
	
	/**
	 * Gets a script plugin by name.
	 * 
	 * @return The `FunkinScript` instance or `null` if it could not be found.
	 */
	public function getPlugin(key:String):Null<FunkinScript>
	{
		return scripts.getScript(key);
	}
	
	/**
	 * Calls a function directly to a plugin script.
	 * @param name 
	 * @param func 
	 * @param args 
	 * @return Null<Dynamic>
	 */
	public function callOnPlugin(name:String, func:String, ?args:Array<Dynamic>):Null<Dynamic>
	{
		final script = getPlugin(name);
		
		if (script == null) return null;
		return script.call(func, args)?.returnValue;
	}
	
	/**
	 * Calls a event directly to a plugin script.
	 * @param func 
	 * @param event 
	 * @param immutablePropogation 
	 * @return T
	 */
	public function eventOnPlugin<T:BasicEvent>(name:String, func:String, event:T):T
	{
		final script = getPlugin(name);
		
		if (script == null) return event;
		
		script.event(func, event);
		return event;
	}
	
	public function call(func:String, ?args:Array<Dynamic>):Void
	{
		scripts.call(func, args);
	}
	
	public function event<T:BasicEvent>(func:String, event:T, immutablePropogation:Bool = false):T
	{
		return scripts.event(func, event, immutablePropogation);
	}
	
	/**
	 * Claers all scripts and loads all script within `scripts/plugins/` directory.
	 * 
	 * All found scripts will have `onLoad` called and `onInit`.
	 * 
	 * The `name` of a plugin by default is the name of the file however a custom name can be defined via the `onInit` event.
	 */
	public function populate()
	{
		clearScripts();
		
		for (file in Paths.listAllFilesInDirectory('scripts/plugins/'))
		{
			if (FunkinScript.isHxFile(file))
			{
				final scriptName = file.withoutDirectory().withoutExtension();
				
				var script = FunkinScript.fromFile(file, scriptName, false);
				
				scripts.addScript(script, true);
				script.execute();
				
				if (script.parsingFailed())
				{
					scripts.removeScript(script);
					script = FlxDestroyUtil.destroy(script);
					continue;
				}
				
				if (script.exists('onLoad')) script.call('onLoad');
				if (script.exists('init'))
				{
					var ev = script.event('init', new PluginInitEvent());
					
					if (ev.name != null && ev.name.length > 0)
					{
						script.config.name = ev.name;
					}
					ev = null;
				}
			}
		}
	}
	
	public function onStateSwitchPost():Void
	{
		event('onStateSwitchPost', EventCache.get(StateEvent).recycle(FlxG.state));
	}
	
	public function onStateSwitch():Void
	{
		event('onStateSwitch', EventCache.get(StateEvent).recycle(FlxG.state));
	}
}
