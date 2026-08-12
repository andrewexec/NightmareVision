package funkin.scripting.events.play;

import funkin.objects.note.Note;
import funkin.game.Rating;

import flixel.group.FlxGroup.FlxTypedGroup;

class ScoreEvent extends BasicEvent
{
	var note:Note;
	var rating:Rating;
	
	var graphic:FlxSprite;
	var numGrp:FlxTypedGroup<FlxSprite>;
	
	var combo:Int;
}
