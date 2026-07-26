package funkin.backend;

import flixel.FlxSubState;
import flixel.util.FlxDestroyUtil;
import flixel.group.FlxGroup.FlxTypedGroup;

import funkin.input.Controls;
import funkin.data.*;
import funkin.scripts.*;

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
	}
	
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;
	
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;
	
	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	
	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;
	
	inline function get_controls():Controls return Controls.instance;
	
	public var scriptName:String = '';
	public var scriptPrefix:String = 'substates';
	public var stateScripts:ScriptGroup = new ScriptGroup();
	
	public function initStateScript(?scriptName:String, callOnLoad:Bool = true):Void
	{
		if (scriptName == null)
		{
			final stateName = Type.getClassName(Type.getClass(this)).split('.').pop();
			scriptName = stateName ?? '???';
		}
		
		this.scriptName = scriptName;
		
		final scriptFile = FunkinScript.getPath('scripts/$scriptPrefix/$scriptName');
		
		if (FunkinAssets.exists(scriptFile))
		{
			var newScript = FunkinScript.fromFile(scriptFile, null, false);
			stateScripts.addScript(newScript);
			newScript.execute();
			if (newScript.parsingFailed())
			{
				stateScripts.removeScript(newScript);
				newScript = FlxDestroyUtil.destroy(newScript);
				return;
			}
			
			Logger.log('script [$scriptName] initialized', NOTICE);
			
			stateScripts.addScript(newScript);
		}
		
		if (callOnLoad) stateScripts.call('onLoad');
	}
	
	public function refreshZ(?group:FlxTypedGroup<FlxBasic>)
	{
		group ??= FlxG.state;
		group.sort(SortUtil.sortByZ, flixel.util.FlxSort.ASCENDING);
	}
	
	override function update(elapsed:Float)
	{
		var oldStep:Int = curStep;
		
		updateCurStep();
		updateBeat();
		
		if (oldStep != curStep) // fix this later
		{
			if (curStep > 0)
			{
				stepHit();
				if (curStep % 4 == 0) beatHit();
			}
			
			if (PlayState.SONG != null)
			{
				if (oldStep < curStep) updateSection();
				else rollbackSection();
			}
		}
		
		dispatchEvent('onUpdate', EventCache.get(UpdateEvent).recycle(elapsed), true);
		
		super.update(elapsed);
	}
	
	private function updateSection():Void
	{
		if (stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}
	
	private function rollbackSection():Void
	{
		if (curStep < 0) return;
		
		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep) break;
				
				curSection++;
			}
		}
		
		if (curSection > lastSection) sectionHit();
	}
	
	function getBeatsOnSection():Float
	{
		return PlayState.SONG?.notes[curSection]?.sectionBeats ?? 4.0;
	}
	
	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}
	
	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);
		
		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrotchet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}
	
	public function stepHit():Void
	{
		dispatchEvent('onStepHit', EventCache.get(IntEvent).recycle(curStep), true);
	}
	
	public function beatHit():Void
	{
		dispatchEvent('onBeatHit', EventCache.get(IntEvent).recycle(curBeat), true);
	}
	
	public function sectionHit()
	{
		dispatchEvent('onSectionHit', EventCache.get(IntEvent).recycle(curSection), true);
	}
	
	override function destroy()
	{
		stateScripts.call('onDestroy');
		
		stateScripts = FlxDestroyUtil.destroy(stateScripts);
		
		super.destroy();
	}
	
	/**
	 * Dispatches a event onto all scriptGroups
	 * 
	 * Whatever groups this will be called onto changes per state implementation
	 */
	public function dispatchEvent<T:BasicEvent>(func:String, event:T, immutablePropogation:Bool = false):T
	{
		stateScripts.event(func, event, immutablePropogation);
		
		return event;
	}
}
