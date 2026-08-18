# Just-Horses-and-Music
A Game for the HaxeJam 2026: Summer Jam - Horsin' Around

Hors

## Chart format

Songs can use a chart file next to the audio:

- `assets/music/tutorial_race.ogg`
- `assets/music/tutorial_race.chart.json`

The chart JSON currently supports:

```json
{
  "meta": {
    "song": "tutorial_race",
    "bpm": 119,
    "offset": 0,
    "author": "toffee"
  },
  "notes": [
    { "time": 0 }
  ]
}
```

In `debug` builds, the game starts with a song selector and a basic chart editor.
