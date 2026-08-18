package;

import backend.Cue;
import backend.Conductor;
import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import haxe.Json;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

typedef EditableChart = {
	var meta:EditableChartMeta;
	var notes:Array<EditableChartNote>;
}

typedef EditableChartMeta = {
	var song:String;
	@:optional var bpm:Float;
	@:optional var offset:Float;
	@:optional var author:String;
}

typedef EditableChartNote = {
	var time:Float;
}

class ChartEditorState extends FlxState
{
	var songId:String;
	var chartPath:String;
	var title:FlxText;
	var info:FlxText;
	var notes:Array<EditableChartNote> = [];
	var selected:Int = 0;
	var cursorTime:Float = 0;

	public function new(songId:String)
	{
		super();
		this.songId = songId;
		this.chartPath = 'assets/music/${songId}.chart.json';
	}

	override public function create()
	{
		super.create();
		Conductor.reset(119);
		notes = loadExisting();

		title = new FlxText(24, 18, 0, 'Chart Editor: $songId', 28);
		info = new FlxText(24, 60, 0, "", 18);

		add(title);
		add(info);
		refreshText();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		cursorTime += elapsed * 1000;
		Conductor.update(elapsed);

		if (FlxG.keys.justPressed.LEFT)
		{
			cursorTime = Math.max(0, cursorTime - 100);
			refreshText();
		}
		if (FlxG.keys.justPressed.RIGHT)
		{
			cursorTime += 100;
			refreshText();
		}
		if (FlxG.keys.justPressed.SPACE)
		{
			addNote(cursorTime);
			refreshText();
		}
		if (FlxG.keys.justPressed.BACKSPACE && notes.length > 0)
		{
			notes.splice(selected, 1);
			selected = Std.int(Math.max(0, Math.min(selected, notes.length - 1)));
			refreshText();
		}
		if (FlxG.keys.justPressed.UP && notes.length > 0)
		{
			selected = (selected - 1 + notes.length) % notes.length;
			refreshText();
		}
		if (FlxG.keys.justPressed.DOWN && notes.length > 0)
		{
			selected = (selected + 1) % notes.length;
			refreshText();
		}
		if (FlxG.keys.justPressed.S)
			save();
		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(new DebugSongSelectState());
	}

	function addNote(time:Float):Void
	{
		notes.push({time: Math.round(time)});
		notes.sort((a, b) -> a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
		selected = notes.length - 1;
	}

	function loadExisting():Array<EditableChartNote>
	{
		#if sys
		if (FileSystem.exists(chartPath))
		{
			var raw = File.getContent(chartPath);
			var parsed:EditableChart = Json.parse(raw);
			if (parsed != null && parsed.notes != null)
				return parsed.notes;
		}
		#end
		return [];
	}

	function save():Void
	{
		#if sys
		var chart:EditableChart = {
			meta: {song: songId, bpm: 119, offset: 0, author: "debug-editor"},
			notes: notes
		};
		File.saveContent(chartPath, Json.stringify(chart, null, "\t"));
		#end
		refreshText();
	}

	function refreshText():Void
	{
		var lines:Array<String> = [];
		lines.push("LEFT/RIGHT move time  SPACE add note  BACKSPACE delete  S save  ESC back");
		lines.push('song: $songId');
		lines.push('chart: $chartPath');
		lines.push('cursor: ${Std.int(cursorTime)} ms');
		lines.push('');

		for (i in 0...notes.length)
		{
			var marker = i == selected ? "> " : "  ";
			lines.push(marker + 'note ' + i + ' @ ' + Std.int(notes[i].time) + ' ms');
		}

		if (notes.length == 0)
			lines.push("(no notes yet)");

		info.text = lines.join("\n");
	}
}
