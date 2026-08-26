package funkin.backend;

import funkin.states.PlayState;

// do more wuith this
@:nullSafety
class Difficulty
{
	/**
	 * Constant list of the default Difficulties used by the game
	 */
	public static final defaultDifficulties:Array<String> = ['Easy', 'Normal', 'Hard'];
	
	/**
	 * Resets the currently loaded difficulties to `defaultDifficulties`
	 */
	public static inline function reset() return (difficulties = defaultDifficulties.copy());
	
	/**
	 * The considered default difficulty. Used to determine which difficulties chart shouldnt have a suffix
	 */
	public static var defaultDifficulty:String = 'Normal';
	
	/**
	 * Currently loaded list of difficulties 
	 */
	public static var difficulties:Array<String> = reset();
	
	/**
	 * Returns the difficulty suffix from an index in `Difficulty.difficulties`
	 */
	public static function getDifficultyFilePath(number:Int = -1):String
	{
		if (number == -1) number = PlayState.storyMeta.difficulty;
		
		var fileSuffix:Null<String> = difficulties[number];
		
		if (fileSuffix == null)
		{
			Logger.log('difficulty in index $number does not exist');
			return Paths.sanitize(defaultDifficulty);
		}
		
		return Paths.sanitize(fileSuffix);
	}
	
	/**
	 * Gets the current difficulty by string.
	 * @return String
	 */
	public static function getCurrentDifficultyString():String
	{
		return difficulties[PlayState.storyMeta.difficulty] ?? defaultDifficulty;
	}
	
	static final _nonDifficultyNames:Array<String> = ['events', 'meta', 'metadata', 'converted', 'chart'];
	
	public static function detectDifficulties(songName:String):Array<String>
	{
		var found:Array<String> = [];
		
		for (folder in ['charts', 'data'])
		{
			for (path in Paths.listAllFilesInDirectory('songs/$songName/$folder'))
			{
				if (!path.toLowerCase().endsWith('.json')) continue;
				
				final name = path.withoutDirectory().withoutExtension();
				if (_nonDifficultyNames.contains(name.toLowerCase())) continue;
				
				final display = prettify(name);
				if (display.length > 0 && !found.contains(display)) found.push(display);
			}
		}
		
		final sanitizedSong = Paths.sanitize(songName);
		
		for (path in Paths.listAllFilesInDirectory('songs/$songName'))
		{
			if (!path.toLowerCase().endsWith('.json')) continue;
			
			final name = path.withoutDirectory().withoutExtension();
			if (!name.startsWith(sanitizedSong)) continue;
			
			final remainder = name.substr(sanitizedSong.length);
			
			var display:String;
			if (remainder == '') display = defaultDifficulty;
			else if (remainder.startsWith('-'))
			{
				final suffix = remainder.substr(1);
				if (suffix.length == 0 || _nonDifficultyNames.contains(suffix.toLowerCase())) continue;
				display = prettify(suffix);
			}
			else continue;
			
			if (display.length > 0 && !found.contains(display)) found.push(display);
		}
		
		return found;
	}
	
	static function prettify(sanitized:String):String
	{
		return sanitized.split('-').map(word -> word.length > 0 ? (word.charAt(0).toUpperCase() + word.substr(1)) : word).join(' ');
	}
}
