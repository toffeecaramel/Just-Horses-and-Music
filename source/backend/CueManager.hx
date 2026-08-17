package backend;

import backend.Cue.CueKind;
import backend.Cue.Judgement;
import flixel.util.FlxSignal;

@:publicFields

/**
 * Holds a chart of cues, ties them to the Conductor, and matches player input to
 * the nearest unresolved cue.
 */
class CueManager
{
	var cues(default, null):Array<Cue> = [];

	final PERFECT_WINDOW:Float = 50;
	final GOOD_WINDOW:Float = 120;

	// still deciding whether I'll keep this true or not.
	// basically, "ghost tapping" with no nearby active cues punishes the player.
	final PUNISH_STRAY_INPUTS:Bool = true;

	final onHit:FlxTypedSignal<Cue->Judgement->Void> = new FlxTypedSignal();
	final onMiss:FlxTypedSignal<Cue->Void> = new FlxTypedSignal();
	final onHoldBroken:FlxTypedSignal<Cue->Void> = new FlxTypedSignal();
	final onWrongInput:FlxTypedSignal<String->Void> = new FlxTypedSignal();
	final onPrompt:FlxTypedSignal<Cue->Void> = new FlxTypedSignal();

	var searchIndex:Int = 0;

	public function new() {}

	public function loadChart(newCues:Array<Cue>):Void
	{
		cues = newCues;
		cues.sort((a, b) -> a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
		searchIndex = 0;
	}

	// just for convenience lol
	public static function atStep(step:Float, action:String, kind:CueKind = Tap, stepsHoldLength:Float = 0):Cue
		return new Cue(step * Conductor.stepCrotchet, action, kind, stepsHoldLength * Conductor.stepCrotchet);

	public static function prompt(step:Float, action:String):Cue
		return new Cue(step * Conductor.stepCrotchet, action, Prompt);

	public static function callAndResponse(promptStep:Float, promptAction:String, stepDelay:Float, responseAction:String, kind:CueKind = Tap, stepsHoldLength:Float = 0):Array<Cue>
	{
		return [
			prompt(promptStep, promptAction),
			atStep(promptStep + stepDelay, responseAction, kind, stepsHoldLength)
		];
	}

	public static function callAndResponseMulti(promptStep:Float, promptAction:String, offsets:Array<Float>, stepDelay:Float, responseAction:String, kind:CueKind = Tap, stepsHoldLength:Float = 0):Array<Cue>
	{
		var result:Array<Cue> = [];
		for (o in offsets)
			result.push(prompt(promptStep + o, promptAction));

		for (o in offsets)
			result.push(atStep(promptStep + stepDelay + o, responseAction, kind, stepsHoldLength));
        
		return result;
	}

	public function update()
	{
		final pos = Conductor.songPosition;

		while (searchIndex < cues.length && cues[searchIndex].resolved)
			searchIndex++;

		for (i in searchIndex...cues.length)
		{
			final cue = cues[i];
			if (cue.resolved) continue;

			switch (cue.kind)
			{
				case Prompt:
					if (pos >= cue.time)
					{
						cue.resolved = true;
						onPrompt.dispatch(cue);
					}

				case Tap:
					if (pos > cue.time + GOOD_WINDOW)
					{
						resolve(cue, MISS);
						onMiss.dispatch(cue);
					}

				case Hold:
					if (!cue.holding && pos > cue.time + GOOD_WINDOW)
					{
						resolve(cue, MISS);
						onMiss.dispatch(cue);
					}
					else if (cue.holding && pos > cue.releaseTime() + GOOD_WINDOW)
					{
						final j = judge(pos - cue.releaseTime());
						resolve(cue, j);
						onHit.dispatch(cue, j);
					}
			}

			if (!cue.holding && cue.time > pos + GOOD_WINDOW)
				break;
		}
	}

	public function press(action:String):Void
	{
		final pos = Conductor.songPosition;
		var best:Cue = null;
		var bestDiff:Float = GOOD_WINDOW + 1;

		for (i in searchIndex...cues.length)
		{
			final cue = cues[i];
			if (cue.resolved || cue.holding || cue.kind == Prompt || cue.action != action) continue;

			final diff = Math.abs(pos - cue.time);
			if (diff <= GOOD_WINDOW && diff < bestDiff)
			{
				best = cue;
				bestDiff = diff;
			}

			if (cue.time > pos + GOOD_WINDOW) break;
		}

		if (best == null)
		{
			if (PUNISH_STRAY_INPUTS) onWrongInput.dispatch(action);
			return;
		}

		if (best.kind == Tap)
		{
			final j = judge(bestDiff);
			resolve(best, j);
			onHit.dispatch(best, j);
		}
		else best.holding = true; //AUUH
	}

	public function release(action:String):Void
	{
		final pos = Conductor.songPosition;

		for (cue in cues)
		{
			if (cue.resolved || !cue.holding || cue.action != action) continue;

			final diff = pos - cue.releaseTime();
			if (diff < -GOOD_WINDOW)
			{
				//early release (missed)
				cue.holding = false;
				resolve(cue, MISS);
				onHoldBroken.dispatch(cue);
			}
			else
			{
				final j = judge(Math.abs(diff));

				cue.holding = false;
				resolve(cue, j);
				onHit.dispatch(cue, j);
			}
			return;
		}
	}

	inline function judge(diff:Float):Judgement
		return diff <= PERFECT_WINDOW ? PERFECT : GOOD;

	inline function resolve(cue:Cue, j:Judgement)
	{
		cue.resolved = true;
		cue.judgement = j;
	}
}
