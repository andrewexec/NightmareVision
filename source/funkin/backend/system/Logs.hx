package funkin.backend.system;

import flixel.system.debug.log.LogStyle;
import funkin.backend.utils.NativeAPI.ConsoleColor;
import funkin.backend.utils.NativeAPI;
import haxe.Log;

using funkin.backend.system.Logs.StringToolsExt;

final class Logs {
	private static var __showing:Bool = false;
	private static var __registered:Bool = false;

	public static var nativeTrace = Log.trace;

	public static function init() {
		Log.trace = function(v:Dynamic, ?infos:Null<haxe.PosInfos>) {
			var data = [
				logText('${infos.fileName}:${infos.lineNumber}: ', CYAN),
				logText(Std.string(v))
			];

			if (infos.customParams != null) {
				for (i in infos.customParams) {
					data.push(
						logText("," + Std.string(i))
					);
				}
			}
			traceColored(data, TRACE);
		};

		if (!__registered) {
			__registered = true;
			registerStyle(LogStyle.CONSOLE, "> ", WHITE, INFO);
			registerStyle(LogStyle.ERROR, "[FLIXEL]", RED, ERROR);
			registerStyle(LogStyle.NORMAL, "[FLIXEL]", WHITE, INFO);
			registerStyle(LogStyle.NOTICE, "[FLIXEL]", GREEN, VERBOSE);
			registerStyle(LogStyle.WARNING, "[FLIXEL]", YELLOW, WARNING);
		}
	}

	// flixel doesn't expose a single global log callback here (unlike some other versions),
	// so each LogStyle's own onLog signal is hooked individually instead.
	private static function registerStyle(style:LogStyle, prefix:String, color:ConsoleColor, level:Level) {
		style.onLog.add(function(data:Any, ?pos:haxe.PosInfos) {
			var d:Dynamic = data;
			if (!(d is Array))
				d = [d];
			var a:Array<Dynamic> = d;
			var strs = [for (e in a) Std.string(e)];
			for (e in strs)
			{
				Logs.trace('$prefix $e', level, color);
			}
		});
	}

	public static function prepareColoredTrace(text:Array<LogText>, level:Level = INFO) {
		var time = Date.now();
		var superCoolText = [
			logText('[  '),
			logText('${Std.string(time.getHours()).addZeros(2)}:${Std.string(time.getMinutes()).addZeros(2)}:${Std.string(time.getSeconds()).addZeros(2)}', DARKMAGENTA),
			logText('  |'),
			switch (level)
			{
				case WARNING:	logText('   WARNING   ', DARKYELLOW);
				case ERROR:		logText('    ERROR    ', DARKRED);
				case TRACE:		logText('    TRACE    ', GRAY);
				case VERBOSE:	logText('   VERBOSE   ', DARKMAGENTA);
				case SUCCESS:	logText('   SUCCESS   ', GREEN);
				case FAILURE:	logText('   FAILURE   ', RED);
				default:		logText(' INFORMATION ', CYAN);
			},
			logText('] ')
		];
		for(k=>e in superCoolText)
			text.insert(k, e);
		return text;
	}

	public static function logText(text:String, color:ConsoleColor = LIGHTGRAY):LogText {
		return {
			text: text,
			color: color
		};
	}

	public static function __showInConsole(text:Array<LogText>) {
		#if (sys && !mobile)
		while(__showing) {
			Sys.sleep(0.05);
		}
		__showing = true;
		for(t in text) {
			NativeAPI.setConsoleColors(t.color);
			Sys.print(t.text);
		}
		NativeAPI.setConsoleColors();
		Sys.print("\r\n");
		__showing = false;
		#elseif mobile
		while(__showing) {
			Sys.sleep(0.05);
		}
		__showing = true;
		@:privateAccess
		Sys.print([for(t in text) t.text].join(""));
		__showing = false;
		#else
		@:privateAccess
		nativeTrace([for(t in text) t.text].join(""));
		#end
	}

	public inline static function traceColored(text:Array<LogText>, level:Level = INFO)
		__showInConsole(prepareColoredTrace(text, level));

	public static function trace(text:String, level:Level = INFO, color:ConsoleColor = LIGHTGRAY, ?prefix:String) {
		var text = [logText(text, color)];
		if(prefix != null) text.insert(0, getPrefix(prefix));
		traceColored(text, level);
	}

	public inline static function getPrefix(prefix:String)
		return logText('[${prefix}] ', BLUE);

	public inline static function infos(text:String, color:ConsoleColor = LIGHTGRAY, ?prefix:String)
		Logs.trace(text, INFO, color, prefix);

	public inline static function verbose(text:String, color:ConsoleColor = LIGHTGRAY, ?prefix:String)
		if (Main.verbose) Logs.trace(text, VERBOSE, color, prefix);

	public inline static function warn(text:String, color:ConsoleColor = YELLOW, ?prefix:String)
		Logs.trace(text, WARNING, color, prefix);

	public inline static function error(text:String, color:ConsoleColor = RED, ?prefix:String)
		Logs.trace(text, ERROR, color, prefix);
}

enum abstract Level(Int) {
	var INFO = 0;
	var WARNING = 1;
	var ERROR = 2;
	var TRACE = 3;
	var VERBOSE = 4;
	var SUCCESS = 5;
	var FAILURE = 6;
}

typedef LogText = {
	var text:String;
	var color:ConsoleColor;
}

class StringToolsExt {
	public static function addZeros(str:String, zeros:Int):String {
		while (str.length < zeros)
			str = "0" + str;
		return str;
	}
}
