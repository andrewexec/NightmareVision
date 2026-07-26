package funkin;

class FunkinConstants // use this later and when used add docs to every var
{
	public static inline final HEALTH_MAX:Float = 2.0;
	
	public static inline final HEALTH_MIN:Float = 0.0; // a little redundant but sure
	
	public static final STATE_REDIRECT_BLACKLIST:Array<String> = [
		"ScriptedSubstate",
		"ScriptedState"
	];
}
