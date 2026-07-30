package funkin.data;

import flixel.util.FlxSave;

class ModPrefs
{
	public static var saveInstance:FlxSave;
	
	public static function init()
	{
		saveInstance = new FlxSave();
	}
	
	public static function load()
	{
		saveInstance.bind(Mods.currentModDirectory, CoolUtil.getSavePath(), (str, e) -> {
			trace('Mod ' + Mods.currentModDirectory + ' custom save is corrupted\nException:' + e);
			return {};
		});
	}
	
	public static function flush()
	{
		saveInstance.flush();
	}
	
	public static function getPref(key:String):Any
	{
		return Reflect.field(saveInstance, key);
	}
	
	public static function savePref(key:String, data:Any):Void
	{
		Reflect.setField(saveInstance, key, data);
	}
}
