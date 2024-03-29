-- helper functions!

function drawCursor()
  gfx.setColor(gfx.kColorXOR)
  gfx.setLineWidth(3)
  gfx.drawRect(cursor[1]*25,cursor[2]*25,25,25)
  gfx.setLineWidth(1)
  gfx.setColor(gfx.kColorBlack)
end

function drawSteps()
  currentSeqStep = seq:getCurrentStep()
  local markerX, markerY
  local lasty = 0

  for i = 1, stepCount do
    markerY = math.floor((i - 1) / 16) * 25
    markerX = (((i - 1) % 16) * 25)

    noteOff:draw(markerX, markerY)
    lasty = markerY
  end

  markerY = math.floor((currentSeqStep - 1) / 16) * 25
  markerX = ((currentSeqStep - 1) % 16) * 25

  if seq:isPlaying() then
    noteOn:draw(markerX, markerY)
  end

  local activeStr = ""
  for i=1, #tracks do
    activeStr = activeStr..tostring(tracks[i]:getNotesActive())
  end

  gfx.drawTextAligned(activeStr,200,lasty+27,align.center)
end

function drawInsts()
  local notes = selectedTrack:getNotes()
  local seqSegment = math.ceil(seq:getCurrentStep()/32)
  for i = 1, #notes, 1 do
    local step = notes[i]["step"]-1
    if step >= stepCount  then
      break
    end
    local stepx, stepy
    if step > 15 then
      stepx = (step%16)*25
      stepy = (math.floor(step/16))*25
    else
      stepx = (step)*25
      stepy = 0
    end

    notePlaced:fadedImage(notes[i]["velocity"],gfx.image.kDitherTypeBayer4x4):draw(stepx,stepy)

    -- this goofy ahh solution is used instead of drawTextInRect.
    -- mainly because...
    -- a) drawTextInRect is VERY memory intensive
    -- b) it's much faster

    if settings["showNoteNames"] then
      local text = MIDInotes[notes[i]["note"]-20]
      local tagoroctave = string.sub(text, 2, 2)

      if tagoroctave == "#" then
        fnt8x8:drawText(string.sub(text, 1, 2), stepx+4, stepy+4)
        fnt8x8:drawText(string.sub(text, 3, 3), stepx+4, stepy+12)
      else
        fnt8x8:drawText(string.sub(text, 1, 1), stepx+4, stepy+4)
        fnt8x8:drawText(tagoroctave, stepx+4, stepy+12)
      end
      --gfx.drawTextInRect(MIDInotes[notes[i]["note"]-20], stepx+4, stepy+4, 16, 20, nil, nil, nil, fnt8x8)
    end
  end
end

function table.find(t, value) -- finds value in the provided table and returns the index of it. if the item is not found, returns -1.
  -- blah, realized that there was already a function for this in the sdk (which is probably faster), so this is mainly just a shorthand func now
  local found = table.indexOfElement(t, value)
  if found == nil then
    return -1
  else
    return found
  end
end

function table.cycle(t, currentVal, backwards) -- returns the next value in the table after the currentVal.
  local val
  local find = table.find(t,currentVal)

  if find == -1 then
    return t[1]
  end

  if backwards ~= nil then
    if currentVal == t[1] then
      val = t[#t]
    else
      val = t[find-1]
    end
  else
    if currentVal == t[#t] then
      val = t[1]
    else
      val = t[find+1]
    end
  end

  return val
end

function table.join(t,t2)
  local t1 = table.deepcopy(t)
  for i=1,#t2 do
    t1[#t1+1] = t2[i]
  end
  return t1
end

function getStepFromCursor(cursor)
  local step = (cursor[1]+1)
  if cursor[2] >= 1 then
    step += (16*cursor[2])
  end
  return step
end

function modifyNote(note, attrib, val, step)
  if step == nil then
    step = getStepFromCursor(cursor)
  end

  if attrib == "pitch" then
    attrib = "note"

    if (note["note"] == 21 and val == -1) or (note["note"] == #MIDInotes+20 and val == 1) then
      goto continue
    end
  elseif attrib == "length" then
    if (note["length"] == 1 and val == -1) then
      goto continue
    end
  elseif attrib == "velocity" then
    if (note["velocity"] == 0 and val == -1) or (note["velocity"] == 1 and val == 1) then
      goto continue
    end

  end

  if attrib == "velocity" then
    val *= 0.1
  end

  if note ~= nil then
    local notes = selectedTrack:getNotes()
    local step = step
    for i = 1, #notes, 1 do
      if notes[i]["step"] == step then
        notes[i][attrib] += val
        notes[i][attrib] = math.round(notes[i][attrib],1)
      end
    end
    selectedTrack:setNotes(notes)
  end
  ::continue::
end

function math.nearest(table, number)
    local smallestSoFar, smallestIndex
    for i, y in ipairs(table) do
        if not smallestSoFar or (math.abs(number-y) <= smallestSoFar) then
            smallestSoFar = math.abs(number-y)
            smallestIndex = i
        end
    end
    return smallestIndex, table[smallestIndex]
end

function math.quantize(step, quant)
  if step % quant ~= 1 and quant ~= 1 then
    local t = {}
    for i = 1, stepCount do
      if i % quant == 1 then
        table.insert(t, i)
      end
    end
    local index, value = math.nearest(t, step)
    return value
  end
  return step
end

function screenAnim(back)
  if settings["screenAnimation"] then
    if back == true then
      elementAnimator = gfx.animator.new(500, -25, 0, pd.easingFunctions.outQuint)
    else
      elementAnimator = gfx.animator.new(500, 25, 0, pd.easingFunctions.outQuint)
    end
  end
end

function getTempoFromSPS(steps) -- returns tempo from steps per second
  return (steps/4)*30
end

function getSPSfromTempo(tempo)
  local newTempo = 0.0
  newTempo = (tempo/30)*4
  if newTempo == 0.0 then
    newTempo = 16
  end

  return newTempo
end

function table.merge(t,t2)
  for i=1,#t2 do
    t[#t+1] = t2[i]
  end
  return t
end

function string.normalize(str)
  return string.gsub(string.gsub(str, "_", "__"),"%*","%*%*")
end

function string.unnormalize(str)
  return string.gsub(string.gsub(str,"__","_"),"%*%*","%*")
end

function displayInfo(text, time)
  local ms = 1000
  if time ~= nil then
    ms = time
  end
  textTimer = pd.timer.new(ms,nil)
  textTimerText = text
end

function math.round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function toggleNote(step, track)
  local notes
  local trackObj
  if track == nil then
    trackObj = selectedTrack
  else
    trackObj = tracks[track]
  end
  notes = trackObj:getNotes()

  for i = 1, #notes, 1 do
    if notes[i]["step"] == step then
      trackObj:removeNote(step, notes[i]["note"])
      goto continue
    end
  end

  trackObj:addNote(step, 60, 1)
  ::continue::
end

function buildSave(name)
  print("saving song to "..name)
  pd.file.mkdir("songs/"..name)
  -- format
  --
  -- 1 = tracks
  -- |- 1 = name
  -- |- 2 = notes
  -- |- 3 = adsr
  -- |- 4 = legato
  -- |- 5 = params
  -- |- 6 = transpose
  -- -- 7 = volume/pan
  -- 2 = other
  -- |- 1 = tempo
  -- |- 2 = steps
  -- -- 3 = fx
  -- 3 = metadata
  -- |- 1 = author
  -- -- 2 = time and date

  local tmp = {{{},{},{},{},{},{}},{},{}}

  for i, v in ipairs(tracks) do
    tmp[1][1][i] = trackNames[i]
    tmp[1][2][i] = v:getNotes()
    tmp[1][3][i] = instrumentADSRtable[i]
    tmp[1][4][i] = instrumentLegatoTable[i]
    tmp[1][5][i] = instrumentParamTable[i]
    tmp[1][6][i] = instrumentTransposeTable[i]
  end

  for i,v in ipairs(pd.file.listFiles("temp/")) do
    if string.sub(v,#v-2) == "pda" or string.sub(v,#v-2) == "wav" then
      local smp,err = snd.sample.new("temp/"..v)
      if err ~= nil then
        print(err)
      end
      smp:save("songs/"..name.."/"..v)
    elseif string.sub(v, #v-2) == "pdi" then
      pd.datastore.writeImage(pd.datastore.readImage("temp/"..v), "songs/"..name.."/"..v)
    end
  end

  tmp[2][1] = seq:getTempo()
  tmp[2][2] = stepCount

  tmp[3][1] = settings["author"]
  tmp[3][2] = pd.getTime()

  pd.datastore.write(tmp,"songs/"..name.."/song",false)
  print("success!")
  return tmp
end

function loadSave(name)
  seq:stop()
  seq:allNotesOff()
  seq:goToStep(1)

  pd.file.delete("temp/",true)
  pd.file.mkdir("temp/")
 
  print("loading song from "..name)
  local tmp = pd.datastore.read(name.."song")

  for i, v in ipairs(tracks) do
    trackNames[i] = tmp[1][1][i]
    v:setNotes(tmp[1][2][i])
    instrumentADSRtable[i] = tmp[1][3][i]
    local adsr = instrumentADSRtable[i]
    instrumentTable[i]:setADSR(adsr[1],adsr[2],adsr[3],adsr[4])

    if trackNames[i] ~= "smp" then
      instrumentTable[i]:setWaveform(waveTable[table.find(waveNames,trackNames[i])])
    else
      local smp = snd.sample.new(name..i..".pda")
      instrumentTable[i]:setWaveform(WAVE_SIN)
      instrumentTable[i]:setWaveform(smp)
      smp:save("temp/"..i..".pda")

      local sampleImage = pd.datastore.readImage(name..i..".pdi")
      if sampleImage ~= nil then
        pd.datastore.writeImage(sampleImage, "temp/"..i..".pdi")
      end
      
      if settings["savewavs"] == true then
        smp:save("temp/"..i..".wav")
      end
    end
    instrumentLegatoTable[i] = tmp[1][4][i]
    instrumentTable[i]:setLegato(instrumentLegatoTable[i])
    instrumentParamTable[i] = tmp[1][5][i]
    instrumentTable[i]:setParameter(1, instrumentParamTable[i][1])
    instrumentTable[i]:setParameter(2, instrumentParamTable[i][2])
    instrumentTransposeTable[i] = tmp[1][6][i]
    tracks[i]:getInstrument():setTranspose(instrumentTransposeTable[i])
    if tmp[1][7] ~= nil then
      instrumentTable[i]:setVolume(tmp[1][7][i])
    end
    tracksMutedTable[i] = false
    tracks[i]:setMuted(false)
    instrument.allMuted = false

    seq:setTempo(tmp[2][1]) -- TODO: be sure to implement real world bpm changes once fix is pushed!
    sinetimer.duration = 400-getTempoFromSPS(seq:getTempo())
    stepCount = tmp[2][2]
    seq:setLoops(1,stepCount)

    songAuthor = tmp[3][1]

    for i=1,16 do
      instrumentTable[i]:stop()
    end

    local finalListViewContents = {}

    for i = 1, #trackNames, 1 do
      table.insert(finalListViewContents, tostring(i).." - "..trackNames[i])
    end

    listview:set(finalListViewContents)
  end
  cursor = {0,0}
  print("success!")
end

function saveSettings()
  pd.datastore.write(settings,"settings")
end

function loadSettings()
  local data = pd.datastore.read("settings")
  if data ~= nil then
    for k,v in pairs(settings) do
      if data[k] == nil then
        data[k] = v
      elseif type(data[k]) ~= type(v) then
        data[k] = v
      end
    end

    if data["pmode"] == true then
      pd.display.setRefreshRate(50)
    else
      pd.display.setRefreshRate(30)
    end

    if data["useSystemFont"] == true then
      fnt = gfx.getSystemFont()
    else
      fnt = gfx.font.new("fnt/modified-tron")
    end
    
    gfx.setFont(fnt)

    return data
  end
  return settings
end

function string.split(inputstr,sep)
  local t = {}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end

  return t
end

function math.normalize(n, b, t)
  return math.max(b, math.min(t, n))
end

function applyMenuItems(mode)
  pdmenu:removeAllMenuItems()
  if mode == "song" then
    local saveMenuItem, error = pdmenu:addMenuItem("save", function()
      pdmenu:removeAllMenuItems()
      local startname = "newsong"
      if songdir ~= "temp/" then
        startname = string.split(songdir,"/")[#string.split(songdir,"/")-1]
      end
      keyboardScreen.open("song name:",startname,20,function(name)
        if name ~= "_EXITED_KEYBOĀRD" then -- this is such a lame solution, but it works!
          buildSave(string.unnormalize(name))
          displayInfo("saved song "..name)
          songdir = "/songs/"..string.unnormalize(name).."/ (song)"
        end
        applyMenuItems("song")
      end)
    end)
    local loadMenuItem, error = pdmenu:addMenuItem("load", function()
      pdmenu:removeAllMenuItems()
      filePicker.open(function (name)
        if name ~= "none" then
          name = string.unnormalize(name)
          pd.file.delete("temp/",true)
          pd.file.mkdir("temp/")

          loadSave(string.sub(name,1,#name-7))

          screenMode = "pattern"
          crankModes = crankModesList[1]
          pd.inputHandlers.pop()
          pd.inputHandlers.push(pattern, true)
          local autoNoteMenuItem, error = pdmenu:addOptionsMenuItem("autonote", {"none","1","2","4","8","16","32"}, autonote, function(arg)
            autonote = arg
          end)
          songdir = name
          displayInfo("loaded song "..string.normalize(string.split(name,"/")[#string.split(name,"/")-1]))

          if settings["playonload"] == true then
            seq:play()
            sinetimer:start()
          end
          applyMenuItems("pattern")
        else
          print("no song picked")
          applyMenuItems("song")
        end
      end,"song")
    end)
    local settingsMenuItem, error = pdmenu:addMenuItem("settings", function ()
      pdmenu:removeAllMenuItems()
      settingsScreen.open()
    end)
  elseif mode == "pattern" then
    local autoNoteMenuItem, error = pdmenu:addOptionsMenuItem("autonote", {"none","1","2","4","8","16","32"}, autonote, function(arg)
      autonote = arg
    end)
    local recordMenuItem, error = pdmenu:addMenuItem("record")
    recordMenuItem:setCallback(function()
      if recordMenuItem:getTitle() == "record" then
        pattern.recording = true
        if not seq:isPlaying() then
          seq:play()
          sinetimer:reset()
          sinetimer:start()
        end
        recordMenuItem:setTitle("stop record")
        metronomeTrack:setMuted(false)
      else
        pattern.recording = false
        recordMenuItem:setTitle("record")
        metronomeTrack:setMuted(true)
      end
    end)
  elseif mode == "track" then
    local copyMenuItem, error = pdmenu:addMenuItem("copy")
    local copyModeMenuItem, error = pdmenu:addOptionsMenuItem("cpy mode", {"all", "inst", "ptn"}, "all", function(arg)
      instrument.copymode = arg
    end)
    copyMenuItem:setCallback(function()
      if instrument.copytrack ~= 0 then
        local doInst = false
        local doPattern = false
        
        if instrument.copymode == "all" then
          doInst = true
          doPattern = true
        elseif instrument.copymode == "inst" then
          doInst = true
        else
          doPattern = true
        end

        local row = listview:getSelectedRow()
        local track = instrument.copytrack
        instrument.copytrack = 0

        if doPattern then
          tracks[row]:setNotes(tracks[track]:getNotes())
          if seq:isPlaying() then
            seq:stop()
            seq:play()
            sinetimer:reset()
          end
        end

        if doInst then
          seq:stop()
          seq:allNotesOff()

          trackNames[row] = trackNames[track]
          if trackNames[row] == "smp" then
            local smp = snd.sample.new("temp/"..track..".pda")
            smp:save("temp/"..row..".pda")
            smp = snd.sample.new("temp/"..row..".pda")
            instrumentTable[row]:setWaveform(WAVE_SIN)
            instrumentTable[row]:setWaveform(smp)
          else
            local wv = waveTable[table.indexOfElement(waveNames, trackNames[row])]
            instrumentTable[row] = instrumentTable[track]:copy()
            instrumentTable[row]:setWaveform(wv)
          end

          tracks[row]:setInstrument(instrumentTable[row])

          instrumentADSRtable[row] = table.deepcopy(instrumentADSRtable[track])
          instrumentParamTable[row] = table.deepcopy(instrumentParamTable[track])
          instrumentLegatoTable[row] = instrumentLegatoTable[track]
          instrumentTransposeTable[row] = instrumentTransposeTable[track]

          local adsr = instrumentADSRtable[row]

          instrumentTable[row]:setADSR(adsr[1],adsr[2],adsr[3],adsr[4])
          instrumentTable[row]:setLegato(instrumentLegatoTable[row])
          instrumentTable[row]:setParameter(1, instrumentParamTable[track][1])
          instrumentTable[row]:setParameter(2, instrumentParamTable[track][2])
          tracks[row]:getInstrument():setTranspose(instrumentTransposeTable[row])
          instrumentTable[row]:setVolume(instrumentTable[track]:getVolume())

          seq:play()
        end

        instrument.updateList()

        copyMenuItem:setTitle("copy")

        displayInfo("pasted to track "..row)
      else
        instrument.copytrack = listview:getSelectedRow()
        instrument.updateList()
        copyMenuItem:setTitle("paste")

        displayInfo("copied track "..instrument.copytrack)
      end
    end)
  end
  instrument.copytrack = 0
end
