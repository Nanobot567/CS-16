# develop

## building

Building CS-16 is exactly like how you'd build any other Playdate game (in this case, the command is `pdc src/ CS-16.pdx`).

However, I personally use [`just`](https://github.com/casey/just) to make things a little faster! If you install `just` or already have it installed, the default `just` recipe will build CS-16 and open it in the Playdate Simulator, presuming `PlaydateSimulator` is in `$PATH`.

> note: the `just` recipes are only compatible with Linux or MacOS. the `justfile` may need to be modified if you are on Windows.

> also, if you end up taking a look at the code, sorry in advance if it's a mess XD
 
## visualizers

### format
A CS-16 visualizer at its core is just a function that gets called every playdate.update() loop, so you can do pretty much whatever you want with it!

In order for it to be recognized by CS-16, your visualizer code must be either a standalone `.lua` file, or be in a folder by the same name as one of the `.lua` files.

CS-16 requires that a visualizer returns a table with the name of the visualizer, as well as the function that will be called every update. When it is called, CS-16 will pass in a key-value table containing many values which you may find useful when creating a visualizer.

Here's the code for one of my visualizers, called "bumper", as an example:

```lua
local function bumperUpdate(data)
  if data.beat then
    pd.display.setOffset(0, 3)
  elseif math.floor(data.step) % 8 == 2 then
    pd.display.setOffset(0, 1)
  else
    pd.display.setOffset(0, 0)
  end
end

return {"bumper", bumperUpdate}
```

### building and importing
Currently, there is no way to directly load Lua code from the Playdate's Data/ directory (most likely for security reasons), so you'll have to rebuild CS-16 with your custom visualizers in the source code.

To do this, clone this repository with `git clone https://github.com/nanobot567/CS-16`. Then, navigate to the `src/` directory, and create a new folder named `visualizers` if it doesn't already exist. Here, simply paste your .lua files (or the folder containing your .lua file) and rebuild CS-16 with `pdc src/ CS-16.pdx` (or if you have [`just`](https://github.com/casey/just) installed, `just`).

### visualizer key-value table data

| key                  | type               | note                                                                                                                        |
| -------------------- | ------------------ | --------------------------------------------------------------------------------------------------------------------------- |
| tempo                | number             | pattern tempo                                                                                                               |
| step                 | number             | pattern step                                                                                                                |
| rawStep              | number             | pattern step, not rounded                                                                                                   |
| length               | number             | pattern length                                                                                                              |
| playing              | boolean            | true if pattern is currently playing                                                                                        |
| beat                 | boolean            | true if current step is a beat                                                                                              |
| tracks               | object table       | table of `playdate.sound.track`s in the pattern                                                                             |
| trackNames           | string table       | table of the names of the tracks                                                                                            |
| userTrackNames       | string table       | table of user-defined track names. if a name has not been set, the value at that track's index will be an empty string ("") |
| trackSwings          | number table       | table of swing values for each track                                                                                        |
| mutedTracks          | boolean table      | mutedTracks[trackNumber] returns true if the track is currently muted                                                       |
| instruments          | object table       | table of `playdate.sound.instrument`s                                                                                       |
| instrumentADSRs      | number table table | nested tables contain the attack, decay, sustain and release values in that order for each track                            |
| instrumentLegatos    | boolean table      | legato status for each track                                                                                                |
| instrumentParams     | number table table | tables within contain parameter 1 and 2 values for square wave tracks and TE synth tracks (phase, digital, vosim)           |
| instrumentTransposes | number table       | contains the transposition value of each track                                                                              |
| settings             | key-value table    | contains the user's settings. refer to your own `settings.json` file if you don't know what the key to a setting may be!    |
| sequencer            | object             | CS-16's `playdate.sound.sequencer`*                                                                                         |
