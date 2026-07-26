package funkin.scripting;

import funkin.backend.FallbackState;

@:nullSafety
class ScriptedState extends MusicBeatState
{
	public function new(scriptName:String)
	{
		super();
		
		initStateScript(scriptName);
	}
	
	override function create()
	{
		super.create();
		
		if (stateScripts.length == 0)
		{
			FlxG.switchState(() -> new FallbackState('failed to load ($scriptName)!\nDoes it exist?', () -> FlxG.switchState(MainMenuState.new)));
			return;
		}
		
		stateScripts.call('onCreate');
	}
}
