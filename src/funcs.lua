-- helper functions!

function table.cycle(t, currentVal, backwards) -- returns the next value in the table after the currentVal.
  local val
  local find = table.indexOfElement(t, currentVal)

  if find == -1 then
    return t[1]
  end

  if backwards ~= nil then
    if currentVal == t[1] then
      val = t[#t]
    else
      val = t[find - 1]
    end
  else
    if currentVal == t[#t] then
      val = t[1]
    else
      val = t[find + 1]
    end
  end

  return val
end

function table.join(t, t2)
  local t1 = table.deepcopy(t)
  for i = 1, #t2 do
    t1[#t1 + 1] = t2[i]
  end
  return t1
end

function math.round(num, numDecimalPlaces)
  local mult = 10 ^ (numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function math.nearest(table, number)
  local smallestSoFar, smallestIndex
  for i, y in ipairs(table) do
    if not smallestSoFar or (math.abs(number - y) <= smallestSoFar) then
      smallestSoFar = math.abs(number - y)
      smallestIndex = i
    end
  end
  return smallestIndex, table[smallestIndex]
end

function math.normalize(n, b, t)
  return math.max(b, math.min(t, n))
end

function math.quantize(step, quant)
  step -= 8
  local swing = tracksSwingTable[table.indexOfElement(tracks, selectedTrack)]

if math.abs(swing) ~= swing then
    swing = 16 + swing
  end

  if step % 16 == swing then
    step -= swing
  end

  quant *= 8
  if step % quant ~= 1 and quant ~= 1 then
    local t = {}
    for i = 1, stepCount, 8 do
      if i % quant == 1 then
        table.insert(t, i)
      end
    end
    local index, value = math.nearest(t, step)
    return value + 7
  end
  return step + 7
end

function string.normalize(str)
  return string.gsub(string.gsub(str, "_", "__"), "%*", "%*%*")
end

function string.unnormalize(str)
  return string.gsub(string.gsub(str, "__", "_"), "%*%*", "%*")
end

function string.split(inputstr, sep)
  local t = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    table.insert(t, str)
  end

  return t
end

function getStepFromCursor(cursor)
  local step = (cursor[1] + 1)
  if cursor[2] >= 1 then
    step += (16 * cursor[2])
  end
  return step * 8
end

function applySwing(newSwing, trackToSwing, updateAnyway, dontUpdateTable)
  local trackIndex = table.indexOfElement(tracks, trackToSwing)
  local currentSwing = tracksSwingTable[trackIndex]
  local swingEd = currentSwing

  newSwing = math.normalize(newSwing, -5, 5)

  if math.abs(currentSwing) ~= currentSwing then
    swingEd = 16 + swingEd
  end

  if newSwing ~= currentSwing or updateAnyway then
    local notes = trackToSwing:getNotes()

    for i = 1, #notes do
      if notes[i]["step"] % 16 == swingEd then
        notes[i]["step"] -= currentSwing
      end
    end

    trackToSwing:setNotes(notes)

    local notes = trackToSwing:getNotes()

    for i = 1, #notes do
      if notes[i]["step"] % 16 == 0 then
        notes[i]["step"] += newSwing
      end
    end

    if not dontUpdateTable then
      tracksSwingTable[trackIndex] = newSwing
    end

    trackToSwing:setNotes(notes)
  end
end

function modifyNote(note, attrib, val, step)
  if step == nil then
    step = getStepFromCursor(cursor)
  end

  if attrib == "pitch" then
    attrib = "note"

    if (note["note"] == 21 and val == -1) or (note["note"] == #MIDInotes + 20 and val == 1) then
      goto continue
    end
  elseif attrib == "length" then
    if (note["length"] == 8 and val == -1) then
      goto continue
    else
      val *= 8 -- NOTE: possible hi-res length changes??
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
        notes[i][attrib] = math.round(notes[i][attrib], 1)
      end
    end
    selectedTrack:setNotes(notes)
  end
  ::continue::
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
  return (steps / 4) * 30
end

function getSPSfromTempo(tempo)
  local newTempo = 0.0
  newTempo = (tempo / 30) * 4
  if newTempo == 0.0 then
    newTempo = 16
  end

  return newTempo
end

function displayInfo(text, time)
  local ms = 1000
  if time ~= nil then
    ms = time
  end
  textTimer = pd.timer.new(ms, function()
    if screenMode == "track" then
      listview.needsDisplay = true
    end
  end)
  textTimerText = text
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

  trackObj:addNote(step, 60, 8)
  ::continue::
end

function applyMenuItems(mode)
  pdmenu:removeAllMenuItems()
  if mode == "song" then
    local saveMenuItem, error = pdmenu:addMenuItem("save", function()
      pdmenu:removeAllMenuItems()
      local startname = "newsong"
      if songdir ~= "temp/" then
        startname = string.split(songdir, "/")[#string.split(songdir, "/") - 1]
      end
      keyboardScreen.open("song name:", startname, 20, function(name)
        if name ~= "_EXITED_KEYBOĀRD" then -- this is such a lame solution, but it works!
          buildSave(string.unnormalize(name))
          displayInfo("saved song " .. name)
          songdir = "/songs/" .. string.unnormalize(name) .. "/ (song)"
        end
        applyMenuItems("song")
      end)
    end)
    local loadMenuItem, error = pdmenu:addMenuItem("load", function()
      pdmenu:removeAllMenuItems()
      filePicker.open(function(name)
        if name ~= "none" then
          name = string.unnormalize(name)
          pd.file.delete("temp/", true)
          pd.file.mkdir("temp/")

          loadSave(string.sub(name, 1, #name - 7))

          screenMode = "pattern"
          crankModes = crankModesList[1]
          pd.inputHandlers.pop()
          pd.inputHandlers.push(pattern, true)
          local autoNoteMenuItem, error = pdmenu:addOptionsMenuItem("autonote",
            { "none", "1", "2", "4", "8", "16", "32" },
            autonote, function(arg)
              autonote = arg
            end)
          songdir = name
          displayInfo("loaded song " .. string.normalize(string.split(name, "/")[#string.split(name, "/") - 1]))

          if settings["playonload"] == true then
            seq:play()
            sinetimer:start()
          end
          applyMenuItems("pattern")
        else
          print("no song picked")
          applyMenuItems("song")
        end
      end, "song")
    end)
    local settingsMenuItem, error = pdmenu:addMenuItem("settings", function()
      pdmenu:removeAllMenuItems()
      settingsScreen.open()
    end)
  elseif mode == "pattern" then
    local autoNoteMenuItem, error = pdmenu:addOptionsMenuItem("autonote", { "none", "1", "2", "4", "8", "16", "32" },
      autonote, function(arg)
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

        for index, track in ipairs(tracks) do -- NOTE: hacky solution inbound!!
          applySwing(0, track, true, true)
        end

        updateInstsImage()

        recordMenuItem:setTitle("stop record")
        metronomeTrack:setMuted(false)
      else
        pattern.recording = false
        recordMenuItem:setTitle("record")
        metronomeTrack:setMuted(true)

        for index, track in ipairs(tracks) do
          applySwing(tracksSwingTable[index], track, true)
        end

        updateInstsImage()
      end
    end)
  elseif mode == "track" then
    local copyMenuItem, error = pdmenu:addMenuItem("copy")
    local copyModeMenuItem, error = pdmenu:addOptionsMenuItem("cpy mode", { "all", "inst", "ptn" }, "all", function(arg)
      instrument.copymode = arg
    end)
    local renameMenuItem, error = pdmenu:addMenuItem("rename")

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
        local track = instrument.copytrack -- copy from me!
        instrument.copytrack = 0

        if row ~= track then
          if doPattern then
            tracks[row]:setNotes(tracks[track]:getNotes())

            tracksSwingTable[row] = tracksSwingTable[track]

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
              local smp = snd.sample.new("temp/" .. track .. ".pda")
              smp:save("temp/" .. row .. ".pda")
              smp = snd.sample.new("temp/" .. row .. ".pda")
              instrumentTable[row]:setWaveform(WAVE_SIN)
              instrumentTable[row]:setWaveform(smp)
            else
              local wv = waveTable[table.indexOfElement(waveNames, trackNames[row])]
              instrumentTable[row] = instrumentTable[track]:copy()
              instrumentTable[row]:setWaveform(wv)
              tracks[row]:setInstrument(instrumentTable[row])
            end

            instrumentADSRtable[row] = table.deepcopy(instrumentADSRtable[track])
            instrumentParamTable[row] = table.deepcopy(instrumentParamTable[track])
            instrumentLegatoTable[row] = instrumentLegatoTable[track]
            instrumentTransposeTable[row] = instrumentTransposeTable[track]

            local adsr = instrumentADSRtable[row]

            instrumentTable[row]:setADSR(adsr[1], adsr[2], adsr[3], adsr[4])
            instrumentTable[row]:setLegato(instrumentLegatoTable[row])
            instrumentTable[row]:setParameter(1, instrumentParamTable[track][1])
            instrumentTable[row]:setParameter(2, instrumentParamTable[track][2])
            tracks[row]:getInstrument():setTranspose(instrumentTransposeTable[row])
            instrumentTable[row]:setVolume(instrumentTable[track]:getVolume())

            seq:play()
          end

          if instrument.copymode == "all" then
            userTrackNames[row] = userTrackNames[track]
          end
        end

        instrument.updateList()

        copyMenuItem:setTitle("copy")

        displayInfo("pasted to track " .. row)

        updateInstsImage()
      else
        instrument.copytrack = listview:getSelectedRow()
        instrument.updateList()
        copyMenuItem:setTitle("paste")

        displayInfo("copied track " .. instrument.copytrack)
      end
    end)

    renameMenuItem:setCallback(function()
      pd.getSystemMenu():removeAllMenuItems()

      local currentRow = listview:getSelectedRow()
      local name = trackNames[currentRow]

      if userTrackNames[currentRow] ~= "" then
        name = userTrackNames[currentRow]
      end

      keyboardScreen.open("rename track", name, 10, function(newname)
        if name == trackNames[currentRow] then
          name = "default"
        end

        if newname ~= "_EXITED_KEYBOĀRD" then
          userTrackNames[currentRow] = newname

          if newname == "" then
            displayInfo(name .. " >> default")
          else
            displayInfo(name .. " >> " .. newname)
          end

          instrument.updateList()
        end

        applyMenuItems(screenMode)
      end)
    end)
  elseif mode == "songpicker" then
    local log = logScreen

    local deleteMenuItem, error = pdmenu:addMenuItem("delete")
    local cloneMenuItem, error = pdmenu:addMenuItem("clone")
    local renameMenuItem, error = pdmenu:addMenuItem("rename")

    deleteMenuItem:setCallback(function()
      local songName = filePickListContents[filePickList:getSelectedRow()]

      if songName ~= "*Ā*" and string.sub(songName, #songName - 5) == "(song)" then
        songName = string.sub(songName, 1, #songName - 8)

        messageBox.open(
          "are you sure you want to delete this song?\n\n\n\n" .. songName .. "\n\n\n\na = yes, b = no",
          function(ans)
            log.init()
            if ans == "yes" then
              songName = string.unnormalize(songName)

              log.append("cs-16 v" .. pd.metadata.version .. " song eradicator")
              log.append("")
              log.append("attempting to delete song " .. songName)

              for i, v in ipairs(pd.file.listFiles("songs/" .. songName)) do
                pd.file.delete("songs/" .. songName .. "/" .. v)
                log.append("deleted " .. v)
              end

              pd.file.delete("songs/" .. songName)

              log.append("!! song successfully eradicated !!")

              displayInfo("song " .. songName .. "deleted")

              filePicker.updateFiles()
            end

            filePicker.update(true)
          end)
      end
    end)

    cloneMenuItem:setCallback(function()
      local songName = filePickListContents[filePickList:getSelectedRow()]
      local update = true

      if songName ~= "*Ā*" and string.sub(songName, #songName - 5) == "(song)" then
        songName = string.sub(songName, 1, #songName - 8)

        keyboardScreen.open("what should the clone be called?", string.unnormalize(songName), 20, function(name)
          if name ~= "_EXITED_KEYBOĀRD" and name ~= "" then
            if name == songName then
              local tempNewName = string.unnormalize(songName) .. "_clone"
              name = string.sub(tempNewName, 1, 20)
            end

            if pd.file.exists("songs/" .. name) then
              update = false
              messageBox.open("song already exists!\n\na = ok", function()
                filePicker.update(true)
              end)
            else
              songName = string.unnormalize(songName)

              log.init()

              log.append("cs-16 v" .. pd.metadata.version .. " song cloner")
              log.append("")
              log.append("attempting to clone song " .. songName .. "...")

              pd.file.mkdir("songs/" .. name)
              log.append("created song directory")
              
              log.append("cloning song data...")

              for i, v in ipairs(pd.file.listFiles("songs/" .. songName)) do
                log.append("attempting to clone " .. v .. "...")
                if string.sub(v, #v - 3) == ".pda" then
                  log.append("file is a sample, using more efficient method...")
                  local sample = snd.sample.new("songs/" .. songName .. "/" .. v)
                  sample:save("songs/" .. name .. "/" .. v)
                elseif string.sub(v, #v - 4) == ".json" then
                  log.append("found song json data, cloning...")

                  pd.datastore.write(pd.datastore.read("songs/" .. songName .. "/song"), "songs/" .. name .. "/song", false)
                else
                  local oldfile = pd.file.open("songs/" .. songName .. "/" .. v)
                  local newfile = pd.file.open("songs/" .. name .. "/" .. v, pd.file.kFileWrite)

                  local data = oldfile:read(10000000) -- performance issue maybe could be??

                  newfile:write(data)

                  oldfile:close()
                  newfile:close()
                end

                log.append("cloned " .. v .. " successfully")
              end

              log.append("successfully cloned " .. songName)

              filePicker.updateFiles()

              local index = table.indexOfElement(filePickListContents, string.normalize(name) .. "/ (song)")

              filePickList:setSelectedRow(index)
              filePickList:scrollToRow(index)
            end
          end

          if update then
            filePicker.update(true)
          end
        end)
      end
    end)

    renameMenuItem:setCallback(function()
      local songName = filePickListContents[filePickList:getSelectedRow()]
      local update = true

      if songName ~= "*Ā*" and string.sub(songName, #songName - 5) == "(song)" then
        songName = string.sub(songName, 1, #songName - 8)

        keyboardScreen.open("what should the song name be?", string.unnormalize(songName), 20, function(name)
          if name ~= "_EXITED_KEYBOĀRD" and name ~= "" then
            if pd.file.exists("songs/" .. string.unnormalize(name)) then
              update = false
              messageBox.open("song already exists!\n\na = ok", function()
                filePicker.update(true)
              end)
            else
              pd.file.rename("songs/" .. string.unnormalize(songName), "songs/" .. string.unnormalize(name))

              filePicker.update(true)

              filePicker.updateFiles()

              local index = table.indexOfElement(filePickListContents, string.normalize(name) .. "/ (song)")

              filePickList:setSelectedRow(index)
              filePickList:scrollToRow(index)
            end
          end

          if update then
            filePicker.update(true)
          end
        end)
      end
    end)
  end
  instrument.copytrack = 0
end
