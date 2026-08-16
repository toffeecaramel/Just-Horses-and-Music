package;

import backend.*;
import flixel.*;
import flixel.FlxState;

class PlayState extends FlxState
{
	override public function create()
	{
		super.create();
		Conductor.reset(119);
		FlxG.sound.playMusic(AssetPaths.tutorial_race__ogg);

		Conductor.onBeatHit.add(onBeat);
	}

	override public function update(elapsed:Float)
	{
		Conductor.update(elapsed);
		super.update(elapsed);
	}
	function onBeat(bitch:Int)
	{
		trace(bitch);

		FlxG.sound.play('assets/sounds/tick.ogg');
	}
}
