-- defs for buttons on each screen mode

pattern = {}
instrument = {}
song = {}
fx = {}

pattern.recording = false

instrument.selectedInst = 0
instrument.allMuted = false
instrument.samplePreviewElems = { playdate.sound.track.new(), playdate.sound.sequence.new() }
instrument.sample = playdate.sound.sample.new(5)

instrument.copymode = "all"
instrument.copytrack = 0

instrument.movetrack = 0

function pattern.AButtonDown()
  if pattern.recording == true then
    toggleNote(math.quantize(currentSeqStep, settings["recordQuantization"]), settings["aRecTrack"])
    updateInstsImage()
  else
    if seq:isPlaying() then
      seq:stop()
      seq:goToStep(1)
      sinetimer:pause()
    else
      seq:play()
      sinetimer:reset()
      sinetimer:start()
    end
  end
end

function pattern.BButtonDown()
  if pattern.recording == true then
    toggleNote(math.quantize(currentSeqStep, settings["recordQuantization"]), settings["bRecTrack"])
    updateInstsImage()
  else
    crankMode = table.cycle(crankModes, crankMode)
    local append = ""
    if settings["num/max"] == true then
      append = " - " .. table.indexOfElement(crankModes, crankMode) .. "/" .. #crankModes
    end
    displayInfo(crankMode .. append)
  end
end

function pattern.upButtonDown()
  if pattern.recording == true then
    toggleNote(math.quantize(currentSeqStep, settings["recordQuantization"]), settings["upRecTrack"])
    updateInstsImage()
  else
    if cursor[2] ~= 0 then
      cursor[2] -= 1
    end
  end
end

function pattern.downButtonDown()
  if pattern.recording == true then
    toggleNote(math.quantize(currentSeqStep, settings["recordQuantization"]), settings["downRecTrack"])
    updateInstsImage()
  else
    if (cursor[2] + 1) * 16 < (stepCount / 8) then
      cursor[2] += 1
    end
  end
end

function pattern.rightButtonDown()
  if pattern.recording == true then
    toggleNote(math.quantize(currentSeqStep, settings["recordQuantization"]), settings["rightRecTrack"])
    updateInstsImage()
  else
    if cursor[1] ~= 15 then
      cursor[1] += 1
    end
  end
end

function pattern.leftButtonDown()
  if pattern.recording == true then
    toggleNote(math.quantize(currentSeqStep, settings["recordQuantization"]), settings["leftRecTrack"])
    updateInstsImage()
  else
    if cursor[1] ~= 0 then
      cursor[1] -= 1
    end
  end
end

function instrument.AButtonDown() -- sorry, "track" screen in manual is referred to as "instrument" in source code. silly me :P
  local selRow = listview:getSelectedRow()
  if listviewContents[1] ~= "*Ā*" then
    pd.getSystemMenu():removeAllMenuItems()

    instrument.selectedInst = instrumentTable[selRow]
    listview:set({ "*Ā*" })

    local clickIndex = table.indexOfElement(waveNames, trackNames[selRow])

    if clickIndex == nil then
      knobs[1]:setClicks(0)
    else
      knobs[1]:setClicks(clickIndex - 1)
    end

    local adsr = instrumentADSRtable[selRow]

    for i = 2, 5 do
      knobs[i]:setClicks((adsr[i - 1] * 10))
    end

    knobs[6]:setClicks(instrumentParamTable[selRow][1] * 10)
    knobs[7]:setClicks(instrumentParamTable[selRow][2] * 10)
    knobs[8]:setClicks(instrumentTransposeTable[selRow])
    knobs[9]:setClicks(instrument.selectedInst:getVolume() * 10)
  elseif currentElem == 1 then
    instrument.updateList()
    applyMenuItems("track")
  elseif currentElem == 7 then
    instrumentLegatoTable[selRow] = not instrumentLegatoTable[selRow]
    instrument.selectedInst:setLegato(instrumentLegatoTable[selRow])
  elseif currentElem == 8 then
    local mode = ""
    if trackNames[listview:getSelectedRow()] == "smp" then
      mode = "newsmp"
    end

    filePicker.open(function(data)
      local file, image = nil, nil
      if type(data) == "table" then
        file = data[1]
        image = data[2]
      else
        file = data
      end

      local newSample, err
      if type(file) == "string" then
        newSample, err = snd.sample.new(file)
      elseif type(file) == "userdata" then
        newSample = file
      end
      if err == nil then
        local filename
        if type(file) == "string" then
          filename = string.split(file, "/")[#string.split(file, "/")]
        else
          filename = listview:getSelectedRow() .. ".pda"
        end

        instrument.selectedInst:setWaveform(WAVE_SIN)
        instrument.selectedInst:setWaveform(newSample)
        trackNames[listview:getSelectedRow()] = "smp"
        newSample:save("temp/" .. listview:getSelectedRow() .. ".pda")
        if settings["savewavs"] == true then
          newSample:save("temp/" .. listview:getSelectedRow() .. ".wav")
        end

        if image ~= nil then
          pd.datastore.writeImage(image, "temp/" .. listview:getSelectedRow() .. ".pdi")
        end

        displayInfo("loaded " .. filename)
      elseif file == "none" then
        print("ERROR INTENTIONAL! No sample selected.")
      else
        print("ugh, error... " .. tostring(err))
      end
    end, mode)
  elseif currentElem == 9 then
    local trk = instrument.samplePreviewElems[1]
    local sequ = instrument.samplePreviewElems[2]
    sequ:allNotesOff()
  
    trk:setNotes({})

    local inst = snd.synth.new()
    local len = 1
    if trackNames[selRow] == "smp" then
      instrument.sample:load("temp/" .. selRow .. ".pda")
      inst:setWaveform(WAVE_SIN)
      inst:setWaveform(instrument.sample)
      len = 100
    else
      inst:setWaveform(waveTable[table.indexOfElement(waveNames, trackNames[selRow])])
    end
    local adsr = instrumentADSRtable[selRow] -- once fix is pushed, remove and replace with synth:copy()
    inst:setADSR(adsr[1], adsr[2], adsr[3], adsr[4])
    inst:setLegato(instrumentLegatoTable[selRow])
    inst:setParameter(1, instrumentParamTable[selRow][1])
    inst:setParameter(2, instrumentParamTable[selRow][2])
    inst:setVolume(instrument.selectedInst:getVolume())

    sequ:setLoops(1, 1, 1)
    trk:setInstrument(inst)
    trk:addNote(1, 60 + instrumentTransposeTable[selRow], len)

    sequ:addTrack(trk)
    sequ:play(function(s)
      s:stop()
    end)
    instrument.samplePreviewElems = { trk, sequ }
  end
end

function instrument.BButtonDown()
  local cur, max = table.indexOfElement(crankModes, crankMode), #crankModes
  if listviewContents[1] == "*Ā*" then
    crankMode = table.cycle(crankModes, crankMode)
  else
    crankMode = "screen"
    cur, max = 1, 1
  end

  local append = ""
  if settings["num/max"] == true then
    append = " - " .. cur .. "/" .. max
  end
  displayInfo(crankMode .. append)
end

function instrument.upButtonDown()
  if listviewContents[1] ~= "*Ā*" then
    listview:selectPreviousRow()
  else
    if currentElem <= 6 then
      currentElem = 1
    elseif currentElem == 12 then
      currentElem = 7
    elseif currentElem == 13 then
      currentElem = 8
    else
      currentElem -= 6
    end
  end
end

function instrument.downButtonDown()
  if listviewContents[1] ~= "*Ā*" then
    listview:selectNextRow()
  else
    if currentElem == 1 then
      currentElem = 2
    elseif currentElem == 7 then
      currentElem = 12
    elseif currentElem <= 12 then
      currentElem += 6
      currentElem = math.min(currentElem, 13)
    end
  end
end

function instrument.rightButtonDown()
  local selRow = listview:getSelectedRow()
  if currentElem ~= #knobs + #buttons and listviewContents[1] == "*Ā*" then
    currentElem += 1
  elseif listviewContents[1] ~= "*Ā*" then
    tracksMutedTable[selRow] = not tracksMutedTable[selRow]
    tracks[selRow]:setMuted(tracksMutedTable[selRow])
    if tracksMutedTable[selRow] == true then
      instrumentTable[selRow]:stop()
    end

    instrument.updateList()
  end
end

function instrument.leftButtonDown()
  local selRow = listview:getSelectedRow()
  if currentElem ~= 1 and listviewContents[1] == "*Ā*" then
    currentElem -= 1
  elseif listviewContents[1] ~= "*Ā*" then
    instrument.allMuted = not instrument.allMuted
    local newVal = instrument.allMuted

    for i = 1, #tracks do
      tracksMutedTable[i] = newVal
      tracks[i]:setMuted(newVal)
    end

    instrument.updateList()
  end
end

function instrument.updateList()
  local finalListViewContents = {}

  for i = 1, #trackNames, 1 do
    local append = ""
    if tracksMutedTable[i] == true then
      append = " *ć*"
    end

    if i == instrument.copytrack then
      if tracksMutedTable[i] == true then
        append = " *ćč*"
      else
        append = append .. " *č*"
      end
    end

    local name = trackNames[i]

    if userTrackNames[i] ~= "" then
      name = userTrackNames[i]
    end

    table.insert(finalListViewContents, tostring(i) .. " - " .. name .. append)
  end

  listview:set(finalListViewContents)
end

function song.AButtonDown()
  if seq:isPlaying() then
    seq:stop()
    seq:goToStep(1)
    sinetimer:pause()
  else
    seq:play()
    sinetimer:reset()
    sinetimer:start()
  end
end

function song.BButtonDown()
  crankMode = table.cycle(crankModes, crankMode)
  local append = ""
  if settings["num/max"] == true then
    append = " - " .. table.indexOfElement(crankModes, crankMode) .. "/" .. #crankModes
  end
  displayInfo(crankMode .. append)
end

function song.upButtonDown()

end

function song.downButtonDown()

end

function song.rightButtonDown()

end

function song.leftButtonDown()

end

fx.enabled = false
fx.selectedEffect = 0

function fx.AButtonDown()
  fx.enabled = not fx.enabled

  if fx.enabled == false then
    for i, v in ipairs(CS16effects) do
      v:disable()
    end
  end
end

function fx.BButtonDown()
  crankMode = table.cycle(crankModes, crankMode)
  local append = ""
  if settings["num/max"] == true then
    append = " - " .. table.indexOfElement(crankModes, crankMode) .. "/" .. #crankModes
  end
  displayInfo(crankMode .. append)
end

function fx.upButtonDown()
  if fx.enabled then
    tapeEffect:enable()
  else
    fx.selectedEffect = 1
  end

  if tapeEffect:getLocked() and fx.enabled then
    tapeEffect:setLocked(false)
  end
end

function fx.upButtonUp()
  tapeEffect:disable()
end

function fx.downButtonDown()
  if fx.enabled then
    waterEffect:enable()
  else
    fx.selectedEffect = 3
  end

  if waterEffect:getLocked() and fx.enabled then
    waterEffect:setLocked(false)
  end
end

function fx.downButtonUp()
  waterEffect:disable()
end

function fx.rightButtonDown()
  if fx.enabled then
    bitcrushEffect:enable()
  else
    fx.selectedEffect = 2
  end

  if bitcrushEffect:getLocked() and fx.enabled then
    bitcrushEffect:setLocked(false)
  end
end

function fx.rightButtonUp()
  bitcrushEffect:disable()
end

function fx.leftButtonDown()
  if fx.enabled then
    overdriveEffect:enable()
  else
    fx.selectedEffect = 4
  end

  if overdriveEffect:getLocked() and fx.enabled then
    overdriveEffect:setLocked(false)
  end
end

function fx.leftButtonUp()
  overdriveEffect:disable()
end

-- burmger
