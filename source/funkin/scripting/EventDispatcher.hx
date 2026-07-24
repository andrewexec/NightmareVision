package funkin.scripting;

import flixel.FlxState;

import funkin.scripting.events.*;

final class EventDispatcher
{
	public static function init()
	{
		FlxG.signals.preStateCreate.add(onStateSwitch);
	}
	
	// map doesn't work for that
	public static var eventValues:Array<BasicEvent> = [];
	public static var eventKeys:Array<Class<BasicEvent>> = [];
	
	/**
	 * Retrieves a event from the cache. If there is no existing event of that type it will create a new one.
	 * @return The event.
	 */
	public static function get<T:BasicEvent>(cl:Class<T>):T
	{
		var c:Class<BasicEvent> = cast cl;
		
		var index = eventKeys.indexOf(c);
		if (index < 0)
		{
			eventKeys.push(c);
			var ret = Type.createInstance(c, []);
			eventValues.push(ret);
			return cast ret;
		}
		
		return cast eventValues[index];
	}
	
	/**
	 * Clears all cached events
	 */
	public static function reset()
	{
		for (v in eventValues)
			v.destroy();
		eventValues = [];
		eventKeys = [];
	}
	
	private static inline function onStateSwitch(newState:FlxState) reset();
}
