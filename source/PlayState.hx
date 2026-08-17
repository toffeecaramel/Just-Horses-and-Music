package;

import backend.*;
import flixel.*;
import flixel.FlxState;

class PlayState extends FlxState
{
	var mgr:CueManager;
	override public function create()
	{
		super.create();
		Conductor.reset(119);
		FlxG.sound.playMusic(AssetPaths.tutorial_race__ogg);

		mgr = new CueManager();
		mgr.onHit.add((cue, judgment) -> trace('${cue.action} at ${cue.time} with $judgment'));
		mgr.onMiss.add((cue) -> trace('missed cue at ${cue.time}'));
		mgr.onHoldBroken.add((cue) -> trace('let go too early!'));
		mgr.onPrompt.add((cue) -> {
			FlxG.sound.play('assets/sounds/hitsound-p1.wav');
			trace(cue);
		});

		mgr.loadChart(ChartTest.build());

		Conductor.onBeatHit.add(onBeat);
	}

	override public function update(elapsed:Float)
	{
		Conductor.update(elapsed);

		mgr.update();

		if (FlxG.keys.justPressed.Z) mgr.press("A");
		if (FlxG.keys.justReleased.Z) mgr.release("A");

		super.update(elapsed);
	}
	function onBeat(bitch:Int)
	{
		trace(bitch);

		FlxG.sound.play('assets/sounds/tick.ogg');
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
