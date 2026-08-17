package backend;

enum CueKind {
    Tap;
    Hold;
    Prompt;
}

enum Judgement {
    PERFECT;
    GOOD;
    MISS;
}

/**
 * Simply a scheduled interaction which the player has to respond to, where either the player has to
 * tap or hold on it.
 */
class Cue
{
    public var time:Float = 0;
    public var action:String;
    public var kind:CueKind;
    public var holdLength:Float;
    
    //!!!! DO NOT MESS WITH THESE VARIABLES, THEY'RE HANDLED BY THE CUE MANAGER!
    public var resolved:Bool = false;
    public var holding:Bool = false;
    public var judgement:Null<Judgement> = null;

    public function new(time:Float, action:String, kind:CueKind = Tap, holdLength:Float = 0)
    {
        this.time = time;
        this.action = action;
        this.kind = kind;
        this.holdLength = holdLength;
    }

    public inline function releaseTime():Float
        return time + holdLength;
}