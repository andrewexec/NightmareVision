package funkin.states.transitions;

import funkin.backend.BaseTransitionState;

class ScriptedTransition extends BaseTransitionState
{
	public static var scriptKey:String = '';
	
	override function create()
	{
		scriptPrefix = 'transitions';
		initStateScript(scriptKey, false);
		super.create();
		
		stateScripts.call('onLoad'); // on load ?
	}
}
