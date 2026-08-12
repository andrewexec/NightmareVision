package funkin.scripting.events.play;

import funkin.objects.note.Note;
import funkin.game.Rating;

import flixel.group.FlxGroup.FlxTypedGroup;

class ScoreEvent extends BasicEvent
{
	public var note:Note;
	public var rating:Rating;
	
	public var graphic:FlxSprite;
	public var numGrp:FlxTypedGroup<FlxSprite>;
	
	public var combo:Int;
}
