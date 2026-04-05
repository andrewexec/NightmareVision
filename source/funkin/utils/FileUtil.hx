package funkin.utils;

import lime.utils.Bytes;

import openfl.utils.ByteArray;

import lime.ui.FileDialog;

import openfl.net.FileFilter;
import openfl.filesystem.File;

typedef BrowseOptions =
{
	var ?typeFilter:Array<FileFilter>;
	var ?title:String;
	var ?defaultSearch:String;
}

class FileUtil
{
	public static function browseForFile(options:BrowseOptions, ?onSelect:String->Void, ?onCancel:Void->Void)
	{
		final title = options.title;
		final filters = options.typeFilter;
		final startPath = options.defaultSearch;
		
		FileDialog.openFile(FlxG.stage.window, title, (files, filter) -> {
			if (files != null && files.length > 0)
			{
				if (onSelect != null) onSelect(files[0]);
			}
			else
			{
				if (onCancel != null) onCancel();
			}
		}, @:privateAccess File.__getFilterTypes(filters), startPath);
	}
	
	public static function browseForMultipleFiles(options:BrowseOptions, ?onSelect:Array<String>->Void, ?onCancel:Void->Void)
	{
		final title = options.title;
		final filters = options.typeFilter;
		final startPath = options.defaultSearch;
		
		FileDialog.openFile(FlxG.stage.window, title, (files, filter) -> {
			if (files != null && files.length > 0)
			{
				if (onSelect != null) onSelect(files);
			}
			else
			{
				if (onCancel != null) onCancel();
			}
		}, @:privateAccess File.__getFilterTypes(filters), startPath, true);
	}
	
	public static function saveFile(data:Dynamic, ?fileName:String, ?onSelect:String->Void, ?onCancel:Void->Void)
	{
		if (data == null) return;
		
		var filters = null;
		if (fileName != null && fileName.extension().length > 0)
		{
			final ext:String = fileName.extension();
			filters = [new lime.ui.FileDialogFilter('*.$ext', ext)];
		}
		
		FileDialog.saveFile(FlxG.stage.window, 'Save', (file, filter) -> {
			if (file != null && file.length > 0)
			{
				final bytes:ByteArray = if (data is ByteArrayData)
				{
					data;
				}
				else
				{
					var bArray = new ByteArray();
					bArray.writeUTFBytes(Std.string(data));
					bArray;
				}
				
				Bytes.toFile(file, bytes);
				
				if (onSelect != null) onSelect(file);
			}
			else
			{
				if (onCancel != null) onCancel();
			}
		}, filters, fileName);
	}
}
