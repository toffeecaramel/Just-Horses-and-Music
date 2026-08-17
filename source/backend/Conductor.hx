package backend;

import flixel.FlxG;
import flixel.util.FlxSignal.FlxTypedSignal;

@:publicFields
/**
 * Cool conductor (conductor I love conducting my conductor <3)
 */
class Conductor
{
    static var bpm(default, set):Float = 100;
    static var crotchet(default, null):Float = 600;
    static var stepCrotchet(default, null):Float = 150;

    static var stepsPerBeat:Int = 4;
    static var beatsPerMeasure:Int = 4;

    static var songPosition:Float = 0;
    static var rawSongPosition:Float = 0;

    static var offset:Float = 0;

    static var curStep(default, null):Int = 0;
    static var curBeat(default, null):Int = 0;
    static var curMeasure(default, null):Int = 0;

    static var stepFraction(default, null):Float = 0;
    static var beatFraction(default, null):Float = 0;

    static final onStepHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
    static final onBeatHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
    static final onMeasureHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal();

    // justtt in case we ever need to not be based off FlxG.sound.music.time
    static var watchingMusic:Bool = true;

    static var lastStep:Int = -1;
	static var lastBeat:Int = -1;
	static var lastMeasure:Int = -1;

    // How strongly we correct toward the real audio position each frame when the difference is small
	static inline var SYNC_STRENGTH:Float = 0.10;

	// If we're off from the real audio position by more than this many ms, snap instantly
	static inline var SNAP_THRESHOLD:Float = 40;

    public static function set_bpm(v:Float):Float
	{
		bpm = v;
		crotchet = 60000 / bpm;
		stepCrotchet = crotchet / stepsPerBeat;
		return bpm;
	}

    public static function reset(startBpm:Float, ?startOffset:Float = 0):Void
	{
		bpm = startBpm;
		offset = startOffset;
		songPosition = 0;
		rawSongPosition = 0;
		curStep = curBeat = curMeasure = 0;
		lastStep = lastBeat = lastMeasure = -1;
	}

    public static function update(elapsed:Float):Void
	{
		songPosition += elapsed * 1000;
		if (watchingMusic && FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			rawSongPosition = FlxG.sound.music.time;
			var diff:Float = rawSongPosition - (songPosition - offset);

			if (Math.abs(diff) > SNAP_THRESHOLD) songPosition = rawSongPosition + offset;
			else songPosition += diff * SYNC_STRENGTH;
		}

		updateStepAndBeat();
	}

    static function updateStepAndBeat():Void
	{
		curStep = Math.floor(songPosition / stepCrotchet);
		curBeat = Math.floor(songPosition / crotchet);
		curMeasure = Math.floor(curBeat / beatsPerMeasure);

		stepFraction = (songPosition % stepCrotchet) / stepCrotchet;
		beatFraction = (songPosition % crotchet) / crotchet;
		if (stepFraction < 0) stepFraction += 1;
		if (beatFraction < 0) beatFraction += 1;

		if (curStep != lastStep)
		{
			lastStep = curStep;
			onStepHit.dispatch(curStep);
		}
		if (curBeat != lastBeat)
		{
			lastBeat = curBeat;
			onBeatHit.dispatch(curBeat);
		}
		if (curMeasure != lastMeasure)
		{
			lastMeasure = curMeasure;
			onMeasureHit.dispatch(curMeasure);
		}
	}
}