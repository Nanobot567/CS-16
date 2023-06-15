function table.find(t, value) -- finds value in the provided table and returns the index of it. if the item is not found, returns -1.
  local index = -1
  for i = 1, #t, 1 do
    if value == t[i] then
      index = i
    end
  end
  return index
end

function table.cycle(t, currentVal, backwards) -- returns the next value in the table after the currentVal.
  local val

  if table.find(t,currentVal) == -1 then
    return t[1]
  end

  if backwards ~= nil then
    if currentVal == t[1] then
      val = t[#t]
    else
      val = t[table.find(t,currentVal)-1]
    end
  else
    if currentVal == t[#t] then
      val = t[1]
    else
      val = t[table.find(t,currentVal)+1]
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

function toggleNote(step)
  local notes = selectedTrack:getNotes()

  for i = 1, #notes, 1 do
    if notes[i]["step"] == step then
      selectedTrack:removeNote(step, notes[i]["note"])
      goto continue
    end
  end

  selectedTrack:addNote(step, 60, 1)
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
  --
  local tmp = {{{},{},{},{},{},{}},{},{}}

  for i, v in ipairs(tracks) do
    tmp[1][1][i] = trackNames[i]
    tmp[1][2][i] = v:getNotes()
    tmp[1][3][i] = instrumentADSRtable[i]
    tmp[1][4][i] = instrumentLegatoTable[i]
    tmp[1][5][i] = instrumentParamTable[i]
    tmp[1][6][i] = instrumentTransposeTable[i]
    --tmp[1][7][i] = instrumentTable[i]:getVolume()
  end

  for i,v in ipairs(pd.file.listFiles("temp/")) do
    if string.sub(v,#v-2) == "pda" or string.sub(v,#v-2) == "wav" then
      local smp,err = snd.sample.new("temp/"..v)
      if err ~= nil then
        print(err)
      end
      smp:save("songs/"..name.."/"..v)
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
  seq:goToStep(1)

  pd.file.delete("temp/",true)
  pd.file.mkdir("temp/")

  -- copy samples into temp/ folder
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
      smp:save("temp/"..i..".wav")
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

    seq:setTempo(tmp[2][1])
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
  print("success!")
end

function saveSettings()
  pd.datastore.write(settings,"settings")
end

function loadSettings()
  local data = pd.datastore.read("settings")
  if data ~= nil and data["stopontempo"] ~= nil then
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

function wav2pda(wavfile,pdafile)
  local fil = pd.file
  local wav = fil.open(wavfile, fil.kFileRead)
  local datalen = fil.getSize(wavfile) - 44
  local pda = fil.open(pdafile, fil.kFileWrite)
  
  wav:seek(44)
  pda:write("Playdate AUD\68\172\0\2") -- 44kHz 16 bit mono
  
  local offset = 0
  
  while offset < datalen do
      local n = math.min(datalen-offset, 1024)
      pda:write(wav:read(n))
      offset += n
  end
  
  wav:close()
  pda:close()
end

function math.normalize(n, b, t)
  return math.max(b, math.min(t, n))
end

function applyMenuItems(mode)
  pdmenu:removeAllMenuItems()
  if mode == "song" then
    local saveMenuItem, error = pdmenu:addMenuItem("save", function()
      local startname = "newsong"
      if songdir ~= "temp/" then
        startname = string.split(songdir,"/")[#string.split(songdir,"/")-1]
      end
      keyboardScreen.open("song name:",startname,20,function(name)
        if name ~= "_EXITED_KEYBOĀRD" then
          buildSave(name)
          displayInfo("saved song "..name)
          songdir = "/songs/"..name.."/ (song)"
        end
        applyMenuItems("song")
      end)
    end)
    local loadMenuItem, error = pdmenu:addMenuItem("load", function()
      filePicker.open(function (name)
        if name ~= "none" then
          pd.file.delete("temp/",true)
          pd.file.mkdir("temp/")

          loadSave(string.sub(name,1,#name-7))

          screenMode = "pattern"
          pdmenu:removeAllMenuItems()
          crankModes = crankModesList[1]
          pd.inputHandlers.pop()
          pd.inputHandlers.push(pattern, true)
          local autoNoteMenuItem, error = pdmenu:addOptionsMenuItem("autonote", {"none","1","2","4","8","16","32"}, autonote, function(arg)
            autonote = arg
          end)
          songdir = name
          displayInfo("loaded song "..string.split(name,"/")[#string.split(name,"/")-1])

          if settings["playonload"] == true then
            seq:play()
          end
        else
          print("no song picked")
        end
        applyMenuItems("pattern")
      end,"song")
    end)
    local settingsMenuItem, error = pdmenu:addMenuItem("settings", function ()
      settingsScreen.open()
    end)
  elseif mode == "pattern" then
    local autoNoteMenuItem, error = pdmenu:addOptionsMenuItem("autonote", {"none","1","2","4","8","16","32"}, autonote, function(arg)
      autonote = arg
    end)
  end
end
