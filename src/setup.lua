knobRotations = {0}
crankSensList = {1,2,3,4,5,6,7,8}

settings = {["dark"]=true,["playonload"]=true,["cranksens"]=4,["author"]="anonymous",["output"]=3,["stoponsample"]=true,["stopontempo"]=true,["savewavs"]=false,["pmode"]=false}
settings = loadSettings()
saveSettings()

i1 = synth.new(WAVE_SIN)
i2 = synth.new(WAVE_SQU)
i3 = synth.new(WAVE_SAW)
i4 = synth.new(WAVE_TRI)
i5 = synth.new(WAVE_NSE)
i6 = synth.new(WAVE_POP)
i7 = synth.new(WAVE_POD)
i8 = synth.new(WAVE_POV)
i9 = synth.new(WAVE_SIN)
i10 = synth.new(WAVE_SQU)
i11 = synth.new(WAVE_SAW)
i12 = synth.new(WAVE_TRI)
i13 = synth.new(WAVE_NSE)
i14 = synth.new(WAVE_POP)
i15 = synth.new(WAVE_POD)
i16 = synth.new(WAVE_POV)

instrumentTable = {i1,i2,i3,i4,i5,i6,i7,i8,i9,i10,i11,i12,i13,i14,i15,i16}
tracksMutedTable = {}
instrumentADSRtable = {}
instrumentLegatoTable = {}
instrumentParamTable = {}
instrumentTransposeTable = {}
channelTable = {}
tracks = {}

for i=1, 16 do
  table.insert(instrumentADSRtable,{0,0,0.3,0.4})
  local adsr = instrumentADSRtable[i]
  instrumentTable[i]:setADSR(adsr[1],adsr[2],adsr[3],adsr[4])
  instrumentTable[i]:setEnvelopeCurvature(0.5) -- probably should add a setting to change this...
  instrumentLegatoTable[i] = false
  instrumentTransposeTable[i] = 0

  if i == 2 or i == 10 then
    instrumentParamTable[i] = {0.5,0.0}
  else
    instrumentParamTable[i] = {0.0,0.0}
  end

  table.insert(tracks, snd.track.new())
  tracks[i]:setInstrument(instrumentTable[i])

  tracksMutedTable[i] = false
end

waveTable = {WAVE_SIN,WAVE_SQU,WAVE_SAW,WAVE_TRI,WAVE_NSE,WAVE_POP,WAVE_POD,WAVE_POV} -- haha funni joke wavetable
waveNames = {"sin","squ","saw","tri","nse","poP","poD","poV"}

seq = snd.sequence.new()
seq:setLoops(1,stepCount)
for i=1, #tracks do
  seq:addTrack(tracks[i])
end
seq:play()

pd.setMenuImage(gfx.image.new("img/menu"))
pd.setCrankSoundsDisabled(true)

gfx.setImageDrawMode(gfx.kDrawModeNXOR)
