-- saving to disk functions

function buildSave(name)
  print("saving song to " .. name)
  pd.file.mkdir("songs/" .. name)
  -- format
  --
  -- 1 = tracks
  -- |- 1 = name
  -- |- 2 = notes
  -- |- 3 = adsr
  -- |- 4 = legato
  -- |- 5 = params
  -- |- 6 = transpose
  -- |- 7 = volume
  -- |- 8 = swing
  -- -- 9 = user track name
  -- 2 = other
  -- |- 1 = tempo
  -- -- 2 = steps
  -- 3 = metadata
  -- |- 1 = author
  -- -- 2 = time and date

  local tmp = { { {}, {}, {}, {}, {}, {}, {}, {}, {} }, {}, {} }

  for i, v in ipairs(tracks) do
    tmp[1][1][i] = trackNames[i]
    tmp[1][2][i] = v:getNotes()
    tmp[1][3][i] = instrumentADSRtable[i]
    tmp[1][4][i] = instrumentLegatoTable[i]
    tmp[1][5][i] = instrumentParamTable[i]
    tmp[1][6][i] = instrumentTransposeTable[i]
    tmp[1][7][i] = instrumentTable[i]:getVolume()
    tmp[1][8][i] = tracksSwingTable[i]
    tmp[1][9][i] = userTrackNames[i]
  end

  for i, v in ipairs(pd.file.listFiles("temp/")) do
    if string.sub(v, #v - 2) == "pda" or string.sub(v, #v - 2) == "wav" then
      local smp, err = snd.sample.new("temp/" .. v)
      if err ~= nil then
        print(err)
      end
      smp:save("songs/" .. name .. "/" .. v)
    elseif string.sub(v, #v - 2) == "pdi" then
      pd.datastore.writeImage(pd.datastore.readImage("temp/" .. v), "songs/" .. name .. "/" .. v)
    end
  end

  tmp[2][1] = seq:getTempo() / 8
  tmp[2][2] = stepCount / 8

  tmp[3][1] = settings["author"]
  tmp[3][2] = pd.getTime()

  pd.datastore.write(tmp, "songs/" .. name .. "/song", false)
  print("success!")
  return tmp
end

function loadSave(name)
  local log = logScreen
  log.init()

  log.append("cs-16 v" .. pd.metadata.version .. " ptfs loader")
  log.append("")
  log.append("stopping sequencer...")

  seq:stop()

  log.append("stopping active voices...")

  seq:allNotesOff()
  seq:goToStep(1)

  log.append("clearing temp dir...")

  pd.file.delete("temp/", true)
  pd.file.mkdir("temp/")

  log.append("loading from " .. name .. "...")

  print("loading song from " .. name)
  local tmp = pd.datastore.read(name .. "song")

  log.append("applying track data...")

  for i, v in ipairs(tracks) do
    log.append("applying data for track " .. i .. "...")

    trackNames[i] = tmp[1][1][i]

    if tmp[1][8] == nil then
      for k, noteVal in pairs(tmp[1][2][i]) do
        tmp[1][2][i][k]["step"] = noteVal["step"] * 8
        tmp[1][2][i][k]["length"] = noteVal["length"] * 8
      end
    end

    v:setNotes(tmp[1][2][i])

    instrumentADSRtable[i] = tmp[1][3][i]
    local adsr = instrumentADSRtable[i]
    instrumentTable[i]:setADSR(adsr[1], adsr[2], adsr[3], adsr[4])

    if trackNames[i] ~= "smp" then
      log.append("loading waveform " .. trackNames[i] .. "...")

      instrumentTable[i]:setWaveform(waveTable[table.indexOfElement(waveNames, trackNames[i])])
    else
      log.append("loading sample...")

      local smp = snd.sample.new(name .. i .. ".pda")
      instrumentTable[i]:setWaveform(WAVE_SIN)
      instrumentTable[i]:setWaveform(smp)
      smp:save("temp/" .. i .. ".pda")

      local sampleImage = pd.datastore.readImage(name .. i .. ".pdi")
      if sampleImage ~= nil then
        log.append("duplicating sample image...")
        pd.datastore.writeImage(sampleImage, "temp/" .. i .. ".pdi")
      end

      if settings["savewavs"] == true then
        smp:save("temp/" .. i .. ".wav")
      end
    end

    log.append("applying modifiers...")

    instrumentLegatoTable[i] = tmp[1][4][i]
    instrumentTable[i]:setLegato(instrumentLegatoTable[i])
    instrumentParamTable[i] = tmp[1][5][i]
    instrumentTable[i]:setParameter(1, instrumentParamTable[i][1])
    instrumentTable[i]:setParameter(2, instrumentParamTable[i][2])
    instrumentTransposeTable[i] = tmp[1][6][i]
    tracks[i]:getInstrument():setTranspose(instrumentTransposeTable[i])
    if tmp[1][7] then
      instrumentTable[i]:setVolume(tmp[1][7][i])
    end
    tracksMutedTable[i] = false
    tracks[i]:setMuted(false)
    instrument.allMuted = false

    if tmp[1][8] then
      log.append("found swing, applying...")

      tracksSwingTable[i] = tmp[1][8][i]
      applySwing(tracksSwingTable[i], tracks[i], true)
    end

    if tmp[1][9] then
      if tmp[1][9][i] ~= "" then
        log.append("found custom track name, applying...")
      end
      userTrackNames[i] = tmp[1][9][i]
    else
      userTrackNames[i] = ""
    end

    for i = 1, 16 do
      instrumentTable[i]:stop()
    end

    local finalListViewContents = {}

    for i = 1, #trackNames, 1 do
      table.insert(finalListViewContents, tostring(i) .. " - " .. trackNames[i])
    end

    listview:set(finalListViewContents)
  end

  log.append("setting tempo to " .. tmp[2][1] .. "...")

  seq:setTempo(tmp[2][1] * 8)
  sinetimer.duration = 400 - (getTempoFromSPS(seq:getTempo()) / 8)

  log.append("setting stepcount...")

  stepCount = tmp[2][2] * 8
  seq:setLoops(1, stepCount)

  songAuthor = tmp[3][1]

  log.append("finalizing...")

  updateStepsImage()
  updateInstsImage()
  instrument.updateList()

  cursor = { 0, 0 }
  crankMode = "screen"
  print("success!")

  log.append("success!")
end

function saveSettings()
  pd.datastore.write(settings, "settings")
end

function loadSettings()
  local data = pd.datastore.read("settings")
  if data ~= nil then
    for k, v in pairs(settings) do
      if data[k] == nil or type(data[k]) ~= type(v) then
        data[k] = v
      end
    end

    if data["50fps"] == true then
      pd.display.setRefreshRate(50)
    else
      pd.display.setRefreshRate(30)
    end

    if data["useSystemFont"] == true then
      fnt = rains2x
      fnt8x8 = rains1x
    else
      fnt = gfx.font.new("fnt/modified-tron")
      fnt8x8 = gfx.font.new("fnt/modified-tron-8x8")
    end

    gfx.setFont(fnt)

    return data
  end
  return settings
end
