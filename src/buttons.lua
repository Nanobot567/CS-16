-- defs for buttons on each screen mode

pattern = {}
instrument = {}
song = {}

instrument.selectedInst = 0
instrument.allMuted = false
instrument.samplePreviewElems = {playdate.sound.track.new(), playdate.sound.sequence.new()}
instrument.sample = playdate.sound.sample.new(5)

function pattern.AButtonDown()
  if seq:isPlaying() then
    seq:stop()
    seq:goToStep(1)
  else
    seq:play()
  end
end

function pattern.BButtonDown()
  crankMode = table.cycle(crankModes,crankMode)
  displayInfo(crankMode)
end

function pattern.upButtonDown()
  if cursor[2] ~= 0 then
    cursor[2] -= 1
  end
end

function pattern.downButtonDown()
  if (cursor[2]+1)*16 < stepCount then
    cursor[2] += 1
  end
end

function pattern.rightButtonDown()
  if cursor[1] ~= 15 then
    cursor[1] += 1
  end
end

function pattern.leftButtonDown()
  if cursor[1] ~= 0 then
    cursor[1] -= 1
  end
end

function instrument.AButtonDown()
  local selRow = listview:getSelectedRow()
  if listviewContents[1] ~= "Ā" then
    instrument.selectedInst = instrumentTable[selRow]
    listview:set({"Ā"})
    knobs[1]:setClicks(table.find(trackNames,trackNames[selRow])-1)

    local adsr = instrumentADSRtable[selRow]

    for i=2,5 do
      knobs[i]:setClicks((adsr[i-1]*10))
    end

    knobs[6]:setClicks(instrumentParamTable[selRow][1]*10)
    knobs[7]:setClicks(instrumentParamTable[selRow][2]*10)
    knobs[8]:setClicks(instrumentTransposeTable[selRow])
    knobs[9]:setClicks(instrument.selectedInst:getVolume()*10)
  elseif currentElem == 1 then
    local finalListViewContents = {}

    for i = 1, #trackNames, 1 do
      local append = ""
      if tracksMutedTable[i] == true then
        append = " ć"
      end
      table.insert(finalListViewContents, tostring(i).." - "..trackNames[i]..append)
    end

    listview:set(finalListViewContents)
  elseif currentElem == 7 then
    instrumentLegatoTable[selRow] = not instrumentLegatoTable[selRow]
    instrument.selectedInst:setLegato(instrumentLegatoTable[selRow])
  elseif currentElem == 8 then
    local mode = ""
    if trackNames[listview:getSelectedRow()] == "smp" then
      mode = "newsmp"
    end
    filePicker.open(function(file)
      local newSample,err
      if type(file) == "string" then
        newSample,err = snd.sample.new(file)
      elseif type(file) == "userdata" then
        newSample = file
      end
      if err == nil then
        local filename
        if type(file) == "string" then
          filename = string.split(file,"/")[#string.split(file,"/")]
        else
          filename = listview:getSelectedRow()..".pda"
        end

        instrument.selectedInst:setWaveform(WAVE_SIN)
        instrument.selectedInst:setWaveform(newSample)
        trackNames[listview:getSelectedRow()] = "smp"
        newSample:save("temp/"..listview:getSelectedRow()..".pda")
        newSample:save("temp/"..listview:getSelectedRow()..".wav")
        displayInfo("loaded "..filename)
      elseif file == "none" then
        print("ERROR INTENTIONAL! No sample selected.")
      else
        print("ugh, error... "..tostring(err))
      end
    end,mode)
  elseif currentElem == 9 then
    local trk = instrument.samplePreviewElems[1]
    local sequ = instrument.samplePreviewElems[2]
    sequ:allNotesOff()
    local inst = snd.synth.new()
    local len = 3
    if trackNames[selRow] == "smp" then
      instrument.sample:load("temp/"..selRow..".pda")
      inst:setWaveform(WAVE_SIN)
      inst:setWaveform(instrument.sample)
      len = 100
    else
      inst:setWaveform(waveTable[table.find(waveNames,trackNames[selRow])])
    end
    local adsr = instrumentADSRtable[selRow] -- once fix is pushed, remove and replace with synth:copy()
    inst:setADSR(adsr[1],adsr[2],adsr[3],adsr[4])
    inst:setLegato(instrumentLegatoTable[selRow])
    inst:setParameter(1,instrumentParamTable[selRow][1])
    inst:setParameter(2,instrumentParamTable[selRow][2])
    inst:setVolume(instrument.selectedInst:getVolume())

    sequ:setLoops(1,1,1)
    trk:setInstrument(inst)
    trk:addNote(1,60+instrumentTransposeTable[selRow],len)

    sequ:addTrack(trk)
    sequ:play(function(s)
      s:stop()
    end)
    instrument.samplePreviewElems = {trk, sequ}
  end
end

function instrument.BButtonDown()
  if listviewContents[1] == "Ā" then
    crankMode = table.cycle(crankModes,crankMode)
  else
    crankMode = "screen"
  end
  displayInfo(crankMode)
end

function instrument.upButtonDown()
  if listviewContents[1] ~= "Ā" then
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
  if listviewContents[1] ~= "Ā" then
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
  if currentElem ~= #knobs+#buttons and listviewContents[1] == "Ā" then
    currentElem += 1
  elseif listviewContents[1] ~= "Ā" then
    tracksMutedTable[selRow] = not tracksMutedTable[selRow]
    tracks[selRow]:setMuted(tracksMutedTable[selRow])
    if tracksMutedTable[selRow] == true then
      instrumentTable[selRow]:stop()
    end

    local append = ""
    if tracksMutedTable[selRow] == true then
      append = " ć"
    end

    listviewContents[selRow] = tostring(selRow).." - "..trackNames[selRow]..append
  end
end

function instrument.leftButtonDown()
  local selRow = listview:getSelectedRow()
  if currentElem ~= 1 and listviewContents[1] == "Ā"then
    currentElem -= 1
  elseif listviewContents[1] ~= "Ā" then
    instrument.allMuted = not instrument.allMuted
    local newVal = instrument.allMuted

    for i=1, #tracks do
      tracksMutedTable[i] = newVal
      tracks[i]:setMuted(newVal)
      if newVal == true then
        instrumentTable[i]:stop()
      end

      local append = ""
      if tracksMutedTable[i] == true then
        append = " ć"
      end

      listviewContents[i] = tostring(i).." - "..trackNames[i]..append
    end
  end
end


function song.AButtonDown()
  if seq:isPlaying() then
    seq:stop()
    seq:goToStep(1)
  else
    seq:play()
  end
end

function song.BButtonDown()
  textTimer = pd.timer.new(1000, nil)
  crankMode = table.cycle(crankModes,crankMode)
  textTimerText = crankMode
end

function song.upButtonDown()

end

function song.downButtonDown()

end

function song.rightButtonDown()

end

function song.leftButtonDown()

end
