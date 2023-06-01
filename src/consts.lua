pd = playdate
gfx = pd.graphics
snd = pd.sound
synth = snd.synth

-- images

noteOff = gfx.image.new("img/note_off")
noteOn = gfx.image.new("img/note_on")
notePlaced = gfx.image.new("img/note_placed")
knob = gfx.image.new("img/knob")
synthset = gfx.image.new("img/synthset")

WAVE_SIN = snd.kWaveSine
WAVE_SQU = snd.kWaveSquare
WAVE_SAW = snd.kWaveSawtooth
WAVE_TRI = snd.kWaveTriangle
WAVE_NSE = snd.kWaveNoise
WAVE_POP = snd.kWavePOPhase
WAVE_POD = snd.kWavePODigital
WAVE_POV = snd.kWavePOVosim

crankModesList = {
  {"note status","pitch","length","velocity","track","screen"}, -- velocity?
  {"turn knob","screen"},
  {"tempo","pattern length","screen"}
}

fnt = gfx.font.new("fnt/modified-tron")
gfx.setFont(fnt)

fnt8x8 = gfx.font.new("fnt/modified-tron-8x8")

MIDInotes = {}

for i = 1, 21, 1 do
  table.insert(MIDInotes,"")
end

MIDInotes = {
  "A0", "A#0", "B0", "C1", "C#1", "D1", "D#1", "E1", "F1", "F#1", "G1", "G#1",
  "A1", "A#1", "B1", "C2", "C#2", "D2", "D#2", "E2", "F2", "F#2", "G2", "G#2",
  "A2", "A#2", "B2", "C3", "C#3", "D3", "D#3", "E3", "F3", "F#3", "G3", "G#3",
  "A3", "A#3", "B3", "C4", "C#4", "D4", "D#4", "E4", "F4", "F#4", "G4", "G#4",
  "A4", "A#4", "B4", "C5", "C#5", "D5", "D#5", "E5", "F5", "F#5", "G5", "G#5",
  "A5", "A#5", "B5", "C6", "C#6", "D6", "D#6", "E6", "F6", "F#6", "G6", "G#6",
  "A6", "A#6", "B6", "C7", "C#7", "D7", "D#7", "E7", "F7", "F#7", "G7", "G#7",
  "A7", "A#7", "B7", "C8", "C#8", "D8", "D#8", "E8", "F8", "F#8", "G8", "G#8",
  "A8"
}

align = kTextAlignment
