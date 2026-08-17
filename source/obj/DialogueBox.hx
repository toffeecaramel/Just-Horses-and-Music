package obj;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
import flixel.util.FlxSpriteUtil;

typedef DialogueLine =
{
	var ?speaker:String;
	var text:String;
	var ?speed:Float;
}

class DialogueBox extends FlxSpriteGroup
{
	public final onLineStart:FlxTypedSignal<DialogueLine->Void> = new FlxTypedSignal();
	public final onLineComplete:FlxTypedSignal<DialogueLine->Void> = new FlxTypedSignal();
	public final onDialogueComplete:FlxSignal = new FlxSignal();

	public var speed:Float = 40;
	public var isTyping(default, null):Bool = false;

	var bg:FlxSprite;
	var nameBg:FlxSprite;
	var nameText:FlxText;
	var bodyText:FlxText;

	var lines:Array<DialogueLine> = [];
	var lineIndex:Int = -1;

	var fullText:String = "";
	var charTimer:Float = 0;
	var visibleChars:Int = 0;

	static inline var PADDING:Float = 16;

	public function new(?x:Float, ?y:Float, ?width:Float, ?height:Float)
	{
		final w = width != null ? width : FlxG.width - 40;
		final h = height != null ? height : 120;

		super(x != null ? x : 20, y != null ? y : FlxG.height - h - 20);

		bg = new FlxSprite();
		bg.makeGraphic(Std.int(w), Std.int(h), FlxColor.TRANSPARENT, true);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, w, h, 20, 20, FlxColor.fromRGB(20, 20, 30, 230));
		add(bg);

		bodyText = new FlxText(PADDING, PADDING, w - PADDING * 2, "", 20);
		bodyText.color = FlxColor.WHITE;
		add(bodyText);
		
		nameBg = new FlxSprite(0, -32);
		nameBg.makeGraphic(140, 32, FlxColor.TRANSPARENT, true);
		FlxSpriteUtil.drawRoundRect(nameBg, 0, 0, 140, 32, 12, 12, FlxColor.fromRGB(20, 20, 30, 230));
		add(nameBg);

		nameText = new FlxText(0, -28, 140, "", 18);
		nameText.alignment = CENTER;
		nameText.color = FlxColor.WHITE;
        nameText.antialiasing = false;
		add(nameText);

		visible = false;
	}

	public function startDialogue(newLines:Array<DialogueLine>):Void
	{
		lines = newLines;
		lineIndex = -1;
		visible = true;
		next();
	}

	public function next():Void
	{
		if (isTyping)
		{
			visibleChars = fullText.length;
			bodyText.text = fullText;
			isTyping = false;
			onLineComplete.dispatch(lines[lineIndex]);
			return;
		}

		lineIndex++;
		if (lineIndex >= lines.length)
		{
			visible = false;
			onDialogueComplete.dispatch();
			return;
		}

		var line = lines[lineIndex];
		fullText = line.text;
		visibleChars = 0;
		charTimer = 0;
		isTyping = true;
		bodyText.text = "";

		var speaker = line.speaker != null ? line.speaker : "";
		nameText.text = speaker;
		nameBg.visible = speaker != "";
		nameText.visible = speaker != "";

		onLineStart.dispatch(line);
	}

	public function skipAll():Void
	{
		isTyping = false;
		visible = false;
		onDialogueComplete.dispatch();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!isTyping) return;

		final interval = 1 / (lines[lineIndex].speed != null ? lines[lineIndex].speed : speed);

		charTimer += elapsed;
		while (charTimer >= interval && visibleChars < fullText.length)
		{
			charTimer -= interval;
			visibleChars++;
			bodyText.text = fullText.substr(0, visibleChars);
		}

		if (visibleChars >= fullText.length)
		{
			isTyping = false;
			onLineComplete.dispatch(lines[lineIndex]);
		}
	}
}
