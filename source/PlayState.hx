package;

import backend.*;
import flixel.*;
import flixel.FlxState;
import obj.DialogueBox;
import openfl.utils.Assets;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import haxe.Json;
import StringTools;

class PlayState extends FlxState
{
	public static inline var DEFAULT_SONG:String = "tutorial_race";

	var songId:String;
	var songPath:String;
	var chartPath:String;
	var mgr:CueManager;
	var dialogueBox:DialogueBox;

	public function new(?songId:String)
	{
		super();
		this.songId = songId == null ? DEFAULT_SONG : songId;
		this.songPath = 'assets/music/${this.songId}.ogg';
		this.chartPath = 'assets/music/${this.songId}.chart.json';
	}

	override public function create()
	{
		super.create();
		Conductor.reset(119);
		playSong();

		mgr = new CueManager();
		mgr.onHit.add((cue, judgment) -> trace('${cue.action} at ${cue.time} with $judgment'));
		mgr.onMiss.add((cue) -> trace('missed cue at ${cue.time}'));
		mgr.onHoldBroken.add((cue) -> trace('let go too early!'));
		mgr.onPrompt.add((cue) -> {
			FlxG.sound.play('assets/sounds/hitsound-p1.wav');
			trace(cue);
		});

		mgr.loadChart(ChartLoader.load(chartPath));

		Conductor.onBeatHit.add(onBeat);
		dialogueBox = new DialogueBox();
		add(dialogueBox);

		dialogueBox.startDialogue([
			{speaker: "Coach", text: "Alright, watch this!"},
			{speaker: "Coach", text: "Tap right when you hear the cue."},
			{text: "shut up bitch"}
		]);
	}

	function playSong():Void
	{
		if (Assets.exists(songPath))
			FlxG.sound.playMusic(songPath);
		else
			trace('Missing song: $songPath');
	}

	override public function update(elapsed:Float)
	{
		Conductor.update(elapsed);

		mgr.update();

		if (FlxG.keys.justPressed.Z) mgr.press("A");
		if (FlxG.keys.justReleased.Z) mgr.release("A");

		if (FlxG.keys.justPressed.Z && dialogueBox.visible)
			dialogueBox.next();

		super.update(elapsed);
	}

	function onBeat(bitch:Int)
	{
		trace(bitch);

		FlxG.sound.play('assets/sounds/tick.ogg');
	}
}

typedef ChartFile = {
	@:optional var meta:ChartMeta;
	var notes:Array<ChartNote>;
}

typedef ChartMeta = {
	@:optional var song:String;
	@:optional var bpm:Float;
	@:optional var offset:Float;
	@:optional var author:String;
}

typedef ChartNote = {
	var time:Float;
}

class ChartLoader
{
	public static function load(path:String):Array<Cue>
	{
		var raw:String = read(path);
		if (raw == null || StringTools.trim(raw) == "")
			return ChartTest.build();

		var chart:ChartFile = Json.parse(raw);
		if (chart == null || chart.notes == null)
			return [];

		if (chart.meta != null && chart.meta.bpm != null)
			Conductor.reset(chart.meta.bpm, chart.meta.offset == null ? 0 : chart.meta.offset);

		var cues:Array<Cue> = [];
		for (note in chart.notes)
			cues.push(new Cue(note.time, "A"));

		return cues;
	}

	static function read(path:String):String
	{
		#if sys
		if (FileSystem.exists(path))
			return File.getContent(path);
		#end
		if (Assets.exists(path))
			return Assets.getText(path);
		return null;
	}
}

class ChartTest
{
	public static function build():Array<Cue>
	{
		var cues:Array<Cue> = [];

		cues = cues.concat(CueManager.callAndResponse(0, "call", 4, "A"));
		cues = cues.concat(CueManager.callAndResponse(8, "call", 4, "A"));

		cues = cues.concat(CueManager.callAndResponseMulti(16, "call", [1, 3], 4, "A"));
		cues = cues.concat(CueManager.callAndResponseMulti(24, "call", [1, 3], 4, "A"));

		cues = cues.concat(CueManager.callAndResponse(32, "call", 4, "A", Hold, 4));

		cues = cues.concat(CueManager.callAndResponse(48, "call", 4, "A"));

		cues = cues.concat(CueManager.callAndResponseMulti(52, "call", [1, 3], 4, "A"));
		cues = cues.concat(CueManager.callAndResponse(58, "call", 4, "A"));

		return cues;
	}
}
