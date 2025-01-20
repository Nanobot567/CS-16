-- this is CS-16, a synthesizer for playdate.
-- dedicated to my dog, Bella, who passed on 7/1/23. we'll miss you!

import "CoreLibs/graphics"
import "CoreLibs/ui"
import "CoreLibs/nineslice"
import "CoreLibs/object"
import "CoreLibs/crank"
import "CoreLibs/timer"
import "CoreLibs/keyboard"
import "CoreLibs/animator"

stepCount = 32 * 8

local firstTime = false

if not playdate.file.exists("settings.json") then
  firstTime = true
end

import "draw"
import "funcs"
import "save"
import "fx"
import "buttons"
import "consts"
import "setup"
import "lists"
import "ui"

sinetimer = pd.timer.new(400 - (getTempoFromSPS(seq:getTempo()) / 8))
sinetimer.repeats = true

songdir = "temp/"

pd.file.mkdir("samples")
pd.file.mkdir("songs")
pd.file.mkdir("temp")

marker = { 0, 0 }
cursor = { 0, 0 }
trackNames = { "sin", "squ", "saw", "tri", "nse", "poP", "poD", "poV", "sin", "squ", "saw", "tri", "nse", "poP", "poD", "poV" }
userTrackNames = {"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""}
crankModes = crankModesList[1]
crankMode = "note status"
tempo = 120.0
selectedTrack = tracks[1]
textTimer = nil
textTimerText = ""
screenModes = { "pattern", "track", "fx", "song" }
screenMode = "pattern"
currentElem = 1
autonote = "none"
songAuthor = settings["author"]
elementAnimator = gfx.animator.new(0, 0, 0)
inScreen = false

pd.display.setInverted(settings["dark"])

pd.inputHandlers.push(pattern, true)

local finalListViewContents = {}

for i = 1, #trackNames, 1 do
  table.insert(finalListViewContents, tostring(i) .. " - " .. trackNames[i])
end
listview:set(finalListViewContents)

finalListViewContents = nil

pdmenu = pd.getSystemMenu()

applyMenuItems("pattern")

knobs = { Knob(55, 65, 8, true), Knob(150, 65, 21), Knob(180, 65, 21), Knob(210, 65, 21), Knob(240, 65, 21), Knob(215,
  135, 11), Knob(255, 135, 11), Knob(336, 135, 25, true), Knob(55, 205, 11) }
buttons = { Button(5, 5, nil, nil, "back", true), Button(333 - (fnt8x8:getTextWidth("toggle") / 2), 53, nil, nil,
  "toggle", true), Button(53 - (fnt8x8:getTextWidth("select") / 2), 125, nil, nil, "select", true), Button(
143 - (fnt8x8:getTextWidth("play") / 2), 125, nil, nil, "play", true) }

allElems = { buttons[1], knobs[1], knobs[2], knobs[3], knobs[4], knobs[5], buttons[2], buttons[3], buttons[4], knobs[6],
  knobs[7], knobs[8], knobs[9] }

function pd.update()
  pd.timer.updateTimers()

  local crank = 0
  if crankMode == "tempo" then
    crank = pd.getCrankTicks(10)
  elseif crankMode == "turn knob" then
    crank = pd.getCrankTicks(8)
  else
    crank = pd.getCrankTicks(settings["cranksens"])
  end

  if pd.isCrankDocked() then
    crank = 0
  end

  if crank ~= 0 and pattern.recording == false then -- if cranked, then do action selected.
    local b = nil
    if crank == -1 then
      b = true
    end

    if crankMode == "note status" then -- no "displayInfo" here because i thought it would get in the way
      local thisTrack = table.indexOfElement(tracks, selectedTrack)

      if autonote == "none" then
        local step = getStepFromCursor(cursor)
        local swingVal = tracksSwingTable[thisTrack]

        if step % 16 == 0 then
          toggleNote(step + swingVal)
        else
          toggleNote(step)
        end
      else
        local mod = 0

        if cursor[2] % 2 == 1 and autonote == "32" then
          mod = 128
        end

        for i = 1, stepCount / 8 do
          if (i - cursor[1]) % tonumber(autonote) - 1 == 0 then
            toggleNote((i * 8) + mod)
          elseif autonote == "1" then
            toggleNote(i * 8)
          end
        end
      end

      applySwing(tracksSwingTable[thisTrack], selectedTrack, true)

      updateInstsImage()
    elseif crankMode == "pitch" or crankMode == "length" or crankMode == "velocity" then
      local function applyNote(step)
        local swing

        if step % 16 ~= 0 then
          swing = 0
        else
          swing = tracksSwingTable[table.indexOfElement(tracks, selectedTrack)]
        end

        local note = selectedTrack:getNotes(step + swing, step + swing)
        local concat = ""
        if note[1] ~= nil then
          modifyNote(note[1], crankMode, crank, step + swing)
          note = selectedTrack:getNotes(step + swing, step + swing)

          if crankMode == "pitch" then
            concat = "*Ă* " .. MIDInotes[math.floor(note[1]["note"]) - 20]
          elseif crankMode == "length" then
            concat = "len: " .. math.floor(note[1]["length"] / 8)
          elseif crankMode == "velocity" then
            concat = "vel: " .. note[1]["velocity"]
          end
          displayInfo(concat)
        end
      end

      if autonote == "none" then
        applyNote(getStepFromCursor(cursor))
      else
        for i = 1, stepCount / 8 do
          if (i - cursor[1]) % tonumber(autonote) - 1 == 0 then
            applyNote(i * 8)
          elseif autonote == "1" then
            applyNote(i * 8)
          end
        end
      end

      updateInstsImage()
    elseif crankMode == "swing" then
      local thisTrack = table.indexOfElement(tracks, selectedTrack)
      local thisSwing = tracksSwingTable[thisTrack]

      applySwing(thisSwing + crank, selectedTrack)

      updateInstsImage()

      displayInfo("swing: " .. tracksSwingTable[thisTrack])
    elseif crankMode == "track" then
      selectedTrack = table.cycle(tracks, selectedTrack, b)
      updateInstsImage()
    elseif crankMode == "screen" then
      gfx.clear()
      crankModes = table.cycle(crankModesList, crankModes, b)
      screenMode = table.cycle(screenModes, screenMode, b)
      pd.inputHandlers.pop()
      pdmenu:removeAllMenuItems()

      if screenMode == "pattern" then
        pd.inputHandlers.push(pattern, true)
      elseif screenMode == "track" then
        instrument.copytrack = 0
        pd.inputHandlers.push(instrument, true)
      elseif screenMode == "song" then
        pd.inputHandlers.push(song, true)
      elseif screenMode == "fx" then
        pd.inputHandlers.push(fx, true)
      end
      applyMenuItems(screenMode)

      local append = ""
      if settings["num/max"] == true then
        append = " - " .. table.indexOfElement(screenModes, screenMode) .. "/" .. #screenModes
      end

      displayInfo("screen: " .. screenMode .. append, 750)

      screenAnim(b)
    elseif crankMode == "tempo" then
      local tm = getTempoFromSPS(seq:getTempo()) -- this is some goofy math but it works lol

      if settings["smallerTempoIncrements"] then
        tm = getSPSfromTempo(tm + (crank / 1.25))
      else
        tm = getSPSfromTempo(tm + (crank * 8))
      end

      seq:setTempo(math.max(16, math.min(512, tm)))
      sinetimer.duration = 400 - (getTempoFromSPS(seq:getTempo()) / 8)
      if seq:isPlaying() and settings["stopontempo"] then
        seq:stop()
        seq:goToStep(1)
        sinetimer:pause()
      end
    elseif crankMode == "pattern length" then
      local newThing = stepCount + ((crank * 16) * 8)
      if newThing <= 128 * 8 and newThing >= 16 * 8 then
        stepCount = newThing

        while (cursor[2] + 1) * 16 > stepCount do
          cursor[2] -= 1
        end
      end
      seq:setLoops(1, stepCount)

      if not seq:isPlaying() then
        sinetimer:pause()
      end

      updateStepsImage()
    elseif crankMode == "turn knob" and listviewContents[#listviewContents] == "*Ā*" then
      if allElems[currentElem]:isa(Knob) then
        local selRow = listview:getSelectedRow()

        local curKnob = allElems[currentElem]
        curKnob:click(1, crank)
        if currentElem == 2 then
          if trackNames[selRow] == "smp" then
            knobs[1]:setClicks(1)
          end
          instrument.selectedInst:setWaveform(waveTable[(knobs[1]:getCurrentClick()) + 1])
          trackNames[selRow] = waveNames[(knobs[1]:getCurrentClick() + 1)]

          displayInfo("wave: " .. trackNames[selRow])
        elseif currentElem < 7 then
          local adsrNames = { "attack: ", "decay: ", "sustain: ", "release: " }
          local adsr = instrumentADSRtable[selRow]
          adsr[currentElem - 2] = math.round(math.normalize((0.1 * crank) + adsr[currentElem - 2], 0.0, 2.0), 1)
          instrument.selectedInst:setADSR(adsr[1], adsr[2], adsr[3], adsr[4])
          displayInfo(adsrNames[currentElem - 2] .. adsr[currentElem - 2])
        elseif currentElem < 12 then
          local paramNum
          if currentElem == 10 then
            paramNum = 1
          else
            paramNum = 2
          end

          instrumentParamTable[selRow][paramNum] = math.round(
            math.normalize((0.1 * crank) + instrumentParamTable[selRow][paramNum], 0.0, 1.0), 1)
          instrument.selectedInst:setParameter(paramNum, instrumentParamTable[selRow][paramNum])
          displayInfo("param " .. paramNum .. ": " .. instrumentParamTable[selRow][paramNum])
        elseif currentElem == 12 then -- shift
          local old = instrumentTransposeTable[selRow]

          instrumentTransposeTable[selRow] = math.normalize(instrumentTransposeTable[selRow] + 1 * crank, -24, 24)
          if old == instrumentTransposeTable[selRow] then
            curKnob:click(-1, crank)
          end
          tracks[selRow]:getInstrument():setTranspose(instrumentTransposeTable[selRow])
          displayInfo("transpose: " .. instrumentTransposeTable[selRow])
        else
          local old = instrument.selectedInst:getVolume()
          local newVol = math.round(math.normalize((0.1 * crank) + old, 0.0, 1.0), 1)
          instrument.selectedInst:setVolume(newVol)

          displayInfo("volume: " .. newVol)
        end
      end
    elseif crankMode == "lock effect" then
      for i, v in ipairs(CS16effects) do
        if v:getEnabled() then
          if v:getLocked() and crank == -1 then
            v:setLocked(false)
            v:disable()
          else
            v:setLocked(true)
          end
        end
      end
    elseif crankMode == "effect" then
      local curEffect = CS16effects[fx.selectedEffect]
      CS16effects[fx.selectedEffect]:setName(table.cycle(validEffectsNames, curEffect:getName()))
    elseif crankMode == "effect intensity" then
      if fx.selectedEffect ~= 0 then
        CS16effects[fx.selectedEffect]:notch(crank)
      end
    end
  end

  if screenMode ~= "track" then
    gfx.clear()
  end

  if screenMode == "pattern" then -- all the drawing functions
    drawSteps()
    drawInsts()
    drawNoteOn()
    drawCursor()

    if autonote ~= "none" then
      gfx.drawTextAligned("a*Ă*: " .. autonote, 400, 222, align.right)
    end

    local index = table.indexOfElement(tracks, selectedTrack)

    local name = trackNames[index]

    if userTrackNames[index] ~= "" then
      name = userTrackNames[index]
    end

    gfx.drawText(math.ceil(currentSeqStep / 8), 0, 222)
    gfx.drawTextAligned(
      table.indexOfElement(tracks, selectedTrack) .. "-" .. name, 200,
      222, align.center)
  elseif screenMode == "track" then
    local selRow = listview:getSelectedRow()
    if listviewContents[1] ~= "*Ā*" then
      if listview.needsDisplay or textTimer.timeLeft ~= 0 then
        gfx.clear()
        listview:drawInRect(0, 0, 400, 240)

        if instrument.allMuted == true then
          gfx.drawText("*ć*", 383, 223)
        end

        -- fnt8x8:drawTextAligned("tracks",200,0,align.center)
      end
    else
      local concatTable = {selRow, "-"}

      gfx.clear()
      synthset:draw(0, 0)

      gfx.setLineWidth(3)

      if trackNames[selRow] == "smp" then
        gfx.drawLine(92, 125, 103, 125)
        gfx.drawLine(101, 125, 101, 54)
        gfx.drawLine(101, 55, 120, 55)
      else
        gfx.drawLine(92, 55, 120, 55)
      end

      gfx.setLineWidth(1)

      if instrumentLegatoTable[selRow] == true then
        gfx.fillCircleAtPoint(336, 76, 2)
      end

      for i = 1, #allElems, 1 do
        local sel = nil
        local prs = nil
        if i == currentElem then
          sel = true
          if pd.buttonIsPressed("a") then
            prs = true
          end
        end

        allElems[i]:draw(sel, prs)
      end

      local name = trackNames[selRow]

      if userTrackNames[selRow] ~= "" then
        name = userTrackNames[selRow]
      end

      table.insert(concatTable, name)

      if userTrackNames[selRow] ~= "" then
        table.insert(concatTable, " (" .. trackNames[selRow] .. ")")
      end

      fnt8x8:drawTextAligned(table.concat(concatTable), 400, 231, align.right)
    end
  elseif screenMode == "song" then
    local curStep = seq:getCurrentStep() / 8
    local metronome = {"*ĉ*", "*Ċ*", "*ĉ*", "*Ĉ*"}
    local curMet = metronome[1]

    if not seq:isPlaying() then
      curMet = metronome[1]
    elseif (curStep) % 4 < 4 then
      curMet = metronome[math.ceil(curStep / 4) % 4 + 1]
    end

    local toDraw = "no name"

    if songdir ~= "temp/" then
      toDraw = string.normalize(string.split(songdir, "/")[#string.split(songdir, "/") - 1])
    end
    gfx.drawTextInRect(toDraw .. " by " .. songAuthor, 0, 0, 400, 240, nil, nil, align.center)

    gfx.drawTextAligned(curMet .. (math.round(getTempoFromSPS(seq:getTempo() / 8), 2)), 400, 222, align.right)
    gfx.drawText(math.floor(stepCount / 8) .. " steps", 0, 222)

    if settings["visualizer"]["sine"] then -- sine wave
      gfx.setLineWidth(2)
      gfx.drawSineWave(0, 120, 405, 120, (stepCount / 2) / 8, (stepCount / 2) / 8,
        math.max(10, 400 - (getTempoFromSPS(seq:getTempo()) / 8)),
        sinetimer.currentTime)
      gfx.setLineWidth(1)
    end

    if settings["visualizer"]["notes"] then -- note status display
      for i = 1, 16 do
        if instrumentTable[i]:isPlaying() then
          gfx.setColor(gfx.kColorXOR)
          gfx.fillRoundRect((i * 25) - 22, 110, 20, 20, 2)
          gfx.setColor(gfx.kColorBlack)
        end
      end
    end

    if settings["visualizer"]["stars"] then -- stars!
      for i, v in ipairs(visualizerStars) do
        v:update()
      end
    end

    if #externalVisualizers > 0 then -- all external visualizers
      local isBeat = false

      if ((math.round(curStep)) % 8 == 1) and seq:isPlaying() then
        isBeat = true
      end

      local data = { -- thankfully most of these are just pointers haha, it would suck if i had to .deepcopy() them or something
        tempo=tempo,
        step=math.round(curStep),
        rawStep=curStep,
        length=stepCount,
        playing=seq:isPlaying(),
        beat=isBeat,
        tracks=tracks,
        trackNames=trackNames,
        userTrackNames=userTrackNames,
        trackSwings=tracksSwingTable,
        mutedTracks=tracksMutedTable,
        instruments=instrumentTable,
        instrumentADSRs=instrumentADSRtable,
        instrumentLegatos=instrumentLegatoTable,
        instrumentParams=instrumentParamTable,
        instrumentTransposes=instrumentTransposeTable,
        settings=settings,
        sequencer=seq
      }

      for i, v in ipairs(externalVisualizers) do
        if settings["visualizer"][v[1]] then
          v[2](data)
        end
      end
    end
  elseif screenMode == "fx" then
    gfx.clear()

    drawFxTriangle(200, 40, "n", 30, tapeEffect:getEnabled())
    drawFxTriangle(200, 200, "s", 30, waterEffect:getEnabled())
    drawFxTriangle(280, 120, "e", 30, bitcrushEffect:getEnabled())
    drawFxTriangle(120, 120, "w", 30, overdriveEffect:getEnabled())

    if fx.enabled then
      -- gfx.getSystemFont():getGlyph("Ⓐ"):scaledImage(2):drawCentered(202, 122)
      gfx.drawTextAligned("ACTV!", 200, 112, kTextAlignment.center)
    end

    local effectIsLocked = false

    for i, v in ipairs(CS16effects) do
      if v:getLocked() == true then
        effectIsLocked = true
        break
      end
    end

    if effectIsLocked then
      gfx.drawText("*Ć*", 0, 224)
    end

    if fx.selectedEffect ~= 0 then
      local tw, th
      local spacer = " - "

      if fx.selectedEffect % 2 == 0 then
        spacer = "\n"
      end

      tw, th = gfx.getTextSize(CS16effects[fx.selectedEffect]:getName() ..
      spacer .. CS16effects[fx.selectedEffect]:getOverallValue())

      local Xs = { 200, 340, 200, 60 }
      local Ys = { 10, 103, 212, 103 }

      gfx.drawRect((Xs[fx.selectedEffect] - (tw / 2)) - 4, Ys[fx.selectedEffect] - 2, tw + 10, th + 6)
    end

    gfx.drawTextAligned(tapeEffect:getName() .. " - " .. tapeEffect:getOverallValue(), 200, 10, kTextAlignment.center)
    gfx.drawTextAligned(bitcrushEffect:getName() .. "\n" .. bitcrushEffect:getOverallValue(), 340, 103,
      kTextAlignment.center)
    gfx.drawTextAligned(waterEffect:getName() .. " - " .. waterEffect:getOverallValue(), 200, 212, kTextAlignment.center)
    gfx.drawTextAligned(overdriveEffect:getName() .. "\n" .. overdriveEffect:getOverallValue(), 60, 103,
      kTextAlignment.center)

    if settings["fxvfx"] then
      if tapeEffect:getEnabled() then
        local curImg = gfx.getWorkingImage()
        gfx.clear()
        curImg:vcrPauseFilterImage():draw(0,0)
        gfx.pushContext()
        gfx.setColor(gfx.kColorWhite)
        local w, _ = gfx.getTextSize("no signal")
        gfx.fillRect(10, 10, w + 2, 18)
        gfx.drawText("no signal", 10, 10)
        gfx.popContext()
      end

      if bitcrushEffect:getEnabled() or overdriveEffect:getEnabled() then
        local intensity = 1
        if overdriveEffect:getEnabled() then
          intensity = overdriveEffect:getOverallValue() * 5
        else
          intensity = bitcrushEffect:getOverallValue() * 3
        end
        
        intensity = math.round(intensity)

        pd.display.setOffset(math.random(-intensity, intensity), math.random(-intensity, intensity))

        if not pd.getReduceFlashing() then
          if bitcrushEffect:getEnabled() then
            gfx.drawText("reboot", math.random(-100, 400), math.random(-10, 240))
            gfx.drawText("warning", math.random(-100, 400), math.random(-10, 240))
            gfx.drawText("deprecated", math.random(-100, 400), math.random(-10, 240))
          end

          if overdriveEffect:getEnabled() then
            gfx.drawText("error", math.random(-100, 400), math.random(-10, 240))
            gfx.drawText("corefault", math.random(-100, 400), math.random(-10, 240))
            gfx.drawText("!!", math.random(-100, 400), math.random(-10, 240))
          end
        end
      else
        pd.display.setOffset(0, 0)
      end

      if waterEffect:getEnabled() then
        local curImg = gfx.getWorkingImage():copy()
        gfx.clear()
        curImg:drawBlurred(0, 0, math.round(waterEffect:getOverallValue() * 3), 1, gfx.image.kDitherTypeBayer4x4)

        local w, _ = gfx.getTextSize("unstable")
        gfx.pushContext()
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(200 - (w / 2), 112, w + 2, 18)
        gfx.drawTextAligned("unstable", 200, 112, kTextAlignment.center)
        gfx.popContext()
      end
    end
  end
 
  if elementAnimator:ended() == false then
    pd.display.setOffset(elementAnimator:currentValue(), 0)
  end

  if textTimer ~= nil and textTimer.active == true then
    local sizex, sizey = gfx.getTextSize(textTimerText)
    local offsetx, offsety = pd.display.getOffset()
    local rectx, recty, rectw, recth = (200 - (sizex / 2)) - 2 - offsetx, 109, sizex + 6, sizey + 6

    gfx.fillRect(rectx - 2, recty - 2, rectw, recth)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(rectx, recty, rectw, recth)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(rectx, recty, rectw, recth)
    gfx.drawTextAligned(textTimerText, 200 - offsetx, 111, align.center)
  end

  --pd.drawFPS(0,0)
end

function pd.gameWillPause()
  pd.display.setOffset(0, 0)
end

function pd.gameWillTerminate()
  local time = pd.getTime()

  local finalRemarks = {
    "this machine is now entering idle mode...",
    "shutdown completed at " .. time.hour .. ":" .. time.minute .. ", " .. time.month .. "/" .. time.day .. "/2634",
    "0 defective items found.",
    "sending " .. math.random(2, 15) .. " defects to incinerator...",
    "REMINDER: assembly line at DWZ331 requires attention.",
    "giving payouts to organic lifeforms...",
    "sending " .. songAuthor .. " back to timeline 28731...",
    "please report to iwp://xythia.optou/konoye."
 }

  local log = logScreen

  log.init()

  log.append("shutting down cs-16 v" .. pd.metadata.version)
  log.append("deleting temp directory...")
  pd.file.delete("temp/", true)
  log.append(finalRemarks[math.random(#finalRemarks)])
  log.append("returning to launcher. bye!")
end

function pd.crankDocked()
  if settings["crankDockedScreen"] ~= "none" and not inScreen then
    screenMode = settings["crankDockedScreen"]
    pdmenu:removeAllMenuItems()
    crankMode = "screen"
    crankModes = crankModesList[table.indexOfElement(screenModes, screenMode)]
    pd.inputHandlers.pop()

    if screenMode == "pattern" then
      pd.inputHandlers.push(pattern, true)
    elseif screenMode == "track" then
      instrument.copytrack = 0
      pd.inputHandlers.push(instrument, true)
      instrument.updateList()
    elseif screenMode == "fx" then
      pd.inputHandlers.push(fx, true)
    elseif screenMode == "song" then
      pd.inputHandlers.push(song, true)
    end

    applyMenuItems(screenMode)
  end
end

if settings["playonload"] == true then
  seq:play()
end

snd.getHeadphoneState(function(phones, mic)
  local hp, spk = false, false
  local text = "headphones plugged in"
  if settings["output"] == "auto" then
    if phones == true then
      hp = true
      spk = false
      settings["output"] = 1
    else
      hp = false
      spk = true
      settings["output"] = 0
      text = "headphones unplugged"
    end
    snd.setOutputsActive(hp, spk)
    displayInfo(text)
  end
end)

displayInfo("cs-16 v" .. pd.metadata.version, 2000)

if firstTime then -- reading the manual is pretty important, so i thought this would be helpful.
  messageBox.open(
    "welcome to cs-16! :)\n\nbefore you begin, it is highly recommended that you read the manual, as most functions are not immediately apparent and are hard to reach without aid from the documentation.\n\nscan the qr code in the system menu to view it!\n\npress a to continue.")
end
