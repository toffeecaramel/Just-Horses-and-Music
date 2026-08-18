package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import StringTools;
#if sys
import sys.FileSystem;
#end

class DebugSongSelectState extends FlxState
{
	var songs:Array<String> = [];
	var index:Int = 0;
	var title:FlxText;
	var list:FlxText;
	var hint:FlxText;

	override public function create()
	{
		super.create();

		songs = SongLibrary.listSongs();

		title = new FlxText(40, 24, 0, "Debug Song Select", 32);
		list = new FlxText(40, 88, 0, "", 24);
		hint = new FlxText(40, 600, 0, "UP/DOWN select  ENTER play  E edit  R refresh", 18);

		add(title);
		add(list);
		add(hint);

		render();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.UP)
		{
			if (songs.length == 0) return;
			index = (index - 1 + songs.length) % songs.length;
			render();
		}
		if (FlxG.keys.justPressed.DOWN)
		{
			if (songs.length == 0) return;
			index = (index + 1) % songs.length;
			render();
		}
		if (FlxG.keys.justPressed.R)
		{
			songs = SongLibrary.listSongs();
			index = 0;
			render();
		}
		if (songs.length > 0 && FlxG.keys.justPressed.ENTER)
			FlxG.switchState(new PlayState(songs[index]));
		if (songs.length > 0 && FlxG.keys.justPressed.E)
			FlxG.switchState(new ChartEditorState(songs[index]));
	}

	function render():Void
	{
		if (songs.length == 0)
		{
			list.text = "No .ogg files found in assets/music";
			return;
		}

		var lines:Array<String> = [];
		for (i in 0...songs.length)
		{
			var prefix = i == index ? "> " : "  ";
			lines.push(prefix + songs[i]);
		}
		list.text = lines.join("\n");
	}
}

class SongLibrary
{
	public static function listSongs():Array<String>
	{
		#if sys
		if (!FileSystem.exists("assets/music"))
			return [];

		var songs:Array<String> = [];
		for (file in FileSystem.readDirectory("assets/music"))
		{
			if (!StringTools.endsWith(file.toLowerCase(), ".ogg"))
				continue;
			songs.push(file.substr(0, file.length - 4));
		}
		songs.sort(Reflect.compare);
		return songs;
		#else
		return [PlayState.DEFAULT_SONG];
		#end
	}
}
