package funkin.scripting.events;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;

@:autoBuild(funkin.backend.macro.EventMacro.build())
class BasicEvent implements IFlxDestroyable
{
	public var isCancellable:Bool = true;
	
	/**
	 * if cancelled, the function the event was used in will be cancelled.
	 */
	public var cancelled:Bool = false;
	
	/**
	 * Whether the event should be called on the next script.
	 */
	public var shouldPropogate:Bool = true;
	
	/**
	 * Additional data if used in scripts
	 */
	public var data:Dynamic = {};
	
	/**
	 * Creates a new basic event.
	 * This allows scripts to call `cancel()` to cancel the event.
	 */
	public function new() {}
	
	/**
	 * The basic event recycle method. Use this for `BasicEvent` but for any other use the `recycle` method.
	 */
	public function basicRecycle(?cancellable:Bool = true)
	{
		data = {};
		cancelled = false;
		shouldPropogate = true;
		isCancellable = cancellable;
		
		return this;
	}
	
	/**
	 * Returns a string representation of the event, in this format:
	 * `[BasicEvent]`
	 * `[BasicEvent (Cancelled)]`
	 * @return String
	 */
	public function toString():String
	{
		var claName = Type.getClassName(Type.getClass(this)).split(".");
		return '[${claName[claName.length - 1]}${cancelled ? " (Cancelled)" : ""}]';
	}
	
	public function destroy()
	{
		data = null;
	}
}
