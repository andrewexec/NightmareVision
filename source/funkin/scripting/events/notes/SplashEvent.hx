package funkin.scripting.events.notes;

import funkin.objects.note.Note;
import funkin.objects.note.NoteSplash;
import funkin.objects.note.SustainSplash;

class SplashEvent extends BasicEvent
{
	public var splash:flixel.util.typeLimit.OneOfTwo<NoteSplash, SustainSplash>;
	public var note:Note;
}
