-- this is CS-16, a synthesizer for playdate.
-- dedicated to my dog, Bella, who passed on 7/1/23. we'll miss you!

import "CoreLibs/graphics"
import "CoreLibs/ui"
import "CoreLibs/nineslice"
import "CoreLibs/object"
import "CoreLibs/crank"
import "CoreLibs/timer"
import "CoreLibs/keyboard"

stepCount = 32

local firstTime = false

if not playdate.file.exists("settings.json") then
  firstTime = true
end

import "funcs"
import "buttons"
import "consts"
import "setup"
import "lists"
import "ui"

sinetimer = pd.timer.new(400-getTempoFromSPS(seq:getTempo()))
sinetimer.repeats = true

songdir = "temp/"

pd.file.mkdir("samples")
pd.file.mkdir("songs")
pd.file.mkdir("temp")

marker = {0,0}
cursor = {0,0}
trackNames = {"sin","squ","saw","tri","nse","poP","poD","poV","sin","squ","saw","tri","nse","poP","poD","poV"}
crankModes = crankModesList[1]
crankMode = "note status"
tempo = 120.0
selectedTrack = tracks[1]
textTimer = nil
textTimerText = ""
screenModes = {"pattern","track","song"}
screenMode = "pattern"
currentElem = 1
autonote = "none"
songAuthor = settings["author"]

pd.display.setInverted(settings["dark"])

pd.inputHandlers.push(pattern, true)

local finalListViewContents = {}

for i = 1, #trackNames, 1 do
  table.insert(finalListViewContents, tostring(i).." - "..trackNames[i])
end
listview:set(finalListViewContents)

finalListViewContents = nil

pdmenu = pd.getSystemMenu()

local autoNoteMenuItem, error = pdmenu:addOptionsMenuItem("autonote", {"none","1","2","4","8","16","32"}, "none", function(arg)
  autonote = arg
end)

knobs = {Knob(55,65,8,true),Knob(150,65,21),Knob(180,65,21),Knob(210,65,21),Knob(240,65,21),Knob(215,135,11),Knob(255,135,11),Knob(336,135,25,true),Knob(55,205,11)}
buttons = {Button(5,5,nil,nil,"back",true),Button(310,55,nil,nil,"toggle",true),Button(53-(fnt8x8:getTextWidth("select")/2),125,nil,nil,"select",true),Button(127,125,nil,nil,"play",true)}

allElems = {buttons[1],knobs[1],knobs[2],knobs[3],knobs[4],knobs[5],buttons[2],buttons[3],buttons[4],knobs[6],knobs[7],knobs[8],knobs[9]}


function pd.update()
  local crank = 0
  if crankMode == "tempo" then
    crank = pd.getCrankTicks(8)
  elseif crankMode == "turn knob" then
    crank = pd.getCrankTicks(8)
  else
    crank = pd.getCrankTicks(settings["cranksens"])
  end

  if pd.isCrankDocked() then
    crank = 0
  end

  if crank ~= 0 then -- if cranked, then do action selected.
    local b = nil
    if crank == -1 then
      b = true
    end

    if crankMode == "note status" then -- no "displayInfo" here because i thought it would get in the way
      if autonote == "none" then
        toggleNote(getStepFromCursor(cursor))
      else
        for i=1,stepCount do
          if (i-cursor[1]) % tonumber(autonote)-1 == 0 then
            toggleNote(i)
          elseif autonote == "1" then
            toggleNote(i)
          end
        end
      end
    elseif crankMode == "pitch" or crankMode == "length" or crankMode == "velocity" then
      local function applyNote(step)
        local note = selectedTrack:getNotes(step,step)
        local concat = ""
        if note[1] ~= nil then
          modifyNote(note[1],crankMode,crank,step)
          note = selectedTrack:getNotes(step,step)

          if crankMode == "pitch" then
            concat = "Ă "..MIDInotes[math.floor(note[1]["note"])-20]
          elseif crankMode == "length" then
            concat = "len: "..note[1]["length"]
          elseif crankMode == "velocity" then
            concat = "vel: "..note[1]["velocity"]
          end
          displayInfo(concat)
        end
      end

      if autonote == "none" then
        applyNote(getStepFromCursor(cursor))
      else
        for i=1,stepCount do
          if (i-cursor[1]) % tonumber(autonote)-1 == 0 then
            applyNote(i)
          elseif autonote == "1" then
            applyNote(i)
          end
        end
      end
    elseif crankMode == "track" then
      selectedTrack = table.cycle(tracks,selectedTrack,b)
    elseif crankMode == "screen" then
      gfx.clear()
      crankModes = table.cycle(crankModesList,crankModes,b)
      screenMode = table.cycle(screenModes,screenMode,b)
      pd.inputHandlers.pop()
      pdmenu:removeAllMenuItems()

      if screenMode == "pattern" then
        pd.inputHandlers.push(pattern, true)
      elseif screenMode == "track" then
        pd.inputHandlers.push(instrument, true)
      elseif screenMode == "song" then
        pd.inputHandlers.push(song, true)
      end
      applyMenuItems(screenMode)

      local append = ""
      if settings["num/max"] == true then
        append = " - "..table.find(screenModes,screenMode).."/"..#screenModes
      end

      displayInfo("screen: "..screenMode..append,750)
    elseif crankMode == "tempo" then
      seq:setTempo(math.max(2,math.min(64,seq:getTempo()+crank)))
      sinetimer.duration = 400-getTempoFromSPS(seq:getTempo())
      if seq:isPlaying() and settings["stopontempo"] then
        seq:stop()
        seq:goToStep(1)
        sinetimer:pause()
      end
    elseif crankMode == "pattern length" then
      local newThing = stepCount+(crank*16)
      if newThing <= 128 and newThing >= 16 then
        stepCount = newThing

        while (cursor[2]+1)*16 > stepCount do
          cursor[2] -= 1
        end
      end
      seq:setLoops(1,stepCount)

      if not seq:isPlaying() then
        sinetimer:pause()
      end

    elseif crankMode == "turn knob" and listviewContents[#listviewContents] == "Ā" then
      if allElems[currentElem]:isa(Knob) then
        local selRow = listview:getSelectedRow()

        local curKnob = allElems[currentElem]
        curKnob:click(1,crank)
        if currentElem == 2 then
          if trackNames[selRow] == "smp" then
            knobs[1]:setClicks(1)
          end
          instrument.selectedInst:setWaveform(waveTable[(knobs[1]:getCurrentClick())+1])
          trackNames[selRow] = waveNames[(knobs[1]:getCurrentClick()+1)]
          displayInfo("wave: "..trackNames[selRow])
        elseif currentElem < 7 then
          local adsrNames = {"attack: ","decay: ","sustain: ","release: "}
          local adsr = instrumentADSRtable[selRow]
          adsr[currentElem-2] = math.round(math.normalize((0.1*crank)+adsr[currentElem-2],0.0,2.0),1)
          instrument.selectedInst:setADSR(adsr[1],adsr[2],adsr[3],adsr[4])
          displayInfo(adsrNames[currentElem-2]..adsr[currentElem-2])
        elseif currentElem < 12 then
          local paramNum
          if currentElem == 10 then
            paramNum = 1
          else
            paramNum = 2
          end

          instrumentParamTable[selRow][paramNum] = math.round(math.normalize((0.1*crank)+instrumentParamTable[selRow][paramNum],0.0,1.0),1)
          instrument.selectedInst:setParameter(paramNum, instrumentParamTable[selRow][paramNum])
          displayInfo("param "..paramNum..": "..instrumentParamTable[selRow][paramNum])
        elseif currentElem == 12 then -- shift
          local old = instrumentTransposeTable[selRow]

          instrumentTransposeTable[selRow] = math.normalize(instrumentTransposeTable[selRow]+1*crank,-24,24)
          if old == instrumentTransposeTable[selRow] then
            curKnob:click(-1, crank)
          end
          tracks[selRow]:getInstrument():setTranspose(instrumentTransposeTable[selRow])
          displayInfo("transpose: "..instrumentTransposeTable[selRow])
        else
          local old = instrument.selectedInst:getVolume()
          local newVol = math.round(math.normalize((0.1*crank)+old,0.0,1.0),1)
          instrument.selectedInst:setVolume(newVol)

          displayInfo("volume: "..newVol)
        end
      end
    end
  end

  gfx.clear()

  if screenMode == "pattern" then -- all the drawing functions
    drawInsts()
    drawSteps()
    drawCursor()

    if autonote ~= "none" then
      gfx.drawTextAligned("aĂ: "..autonote,400,222,align.right)
    end

    gfx.drawText(currentSeqStep,0,222)
    gfx.drawTextAligned(table.find(tracks,selectedTrack).."-"..trackNames[table.find(tracks,selectedTrack)],200,222,align.center)

  elseif screenMode == "track" then
    local selRow = listview:getSelectedRow()
    if listviewContents[1] ~= "Ā" then
      listview:drawInRect(0, 0, 400, 240)
      --fnt8x8:drawTextAligned("tracks",200,0,align.center)
      if instrument.allMuted == true then
        gfx.drawText("ć",383,223)
      end
    else
      synthset:draw(0,0)

      if trackNames[selRow] == "smp" then
        gfx.drawLine(92,125,101,125)
        gfx.drawLine(101,125,101,55)
        gfx.drawLine(101,55,120,55)
      else
        gfx.drawLine(92,55,120,55)
      end

      if instrumentLegatoTable[selRow] == true then
        gfx.fillCircleAtPoint(336,76,5)
      end

      for i = 1, #allElems, 1 do
        local sel = nil
        if i == currentElem then
          sel = true
        end

        allElems[i]:draw(sel)
      end

      fnt8x8:drawTextAligned(selRow.."-"..trackNames[selRow],400,231,align.right)
    end
  elseif screenMode == "song" then
    local curStep = seq:getCurrentStep()
    local metronome = {"Ĉ", "ĉ", "Ċ", "ĉ"}
    local curMet = metronome[1]

    if (curStep - 1) % 4 < 4 then
      curMet = metronome[math.ceil(curStep / 4) % 4 + 1]
    end

    local toDraw = "no name"

    if songdir ~= "temp/" then
      toDraw = string.split(songdir,"/")[#string.split(songdir,"/")-1]
    end
    gfx.drawTextInRect(toDraw.." by "..songAuthor,0,0,400,240,nil,nil,align.center)

    if settings["visualizer"] then
      gfx.drawSineWave(0,120,405,120,stepCount/2,stepCount/2,math.max(10,400-getTempoFromSPS(seq:getTempo())),sinetimer.currentTime) -- TODO: visualizer in later update!
    end
    -- vis idea: for each instrument playing, put a visual down somewhere

    gfx.drawTextAligned(curMet..getTempoFromSPS(seq:getTempo()), 400, 222, align.right)
    gfx.drawText(stepCount.." steps", 0, 222)
  end

  if textTimer ~= nil and textTimer.active == true then
    local sizex,sizey = gfx.getTextSize(textTimerText)
    local rectx,recty,rectw,recth = (200-(sizex/2))-2,109,sizex+6,sizey+6

    gfx.fillRect(rectx-2,recty-2,rectw,recth)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(rectx,recty,rectw,recth)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(rectx,recty,rectw,recth)
    gfx.drawTextAligned(textTimerText,200,111,align.center)
  end

  pd.timer.updateTimers()
  --pd.drawFPS(0,0)
end

function pd.gameWillTerminate()
  pd.file.delete("temp/",true)
end

function pd.crankDocked()
  screenMode = "pattern"
  pdmenu:removeAllMenuItems()
  crankModes = crankModesList[1]
  pd.inputHandlers.pop()
  pd.inputHandlers.push(pattern, true)
  applyMenuItems("pattern")
end

if settings["playonload"] == true then
  seq:play()
end

snd.getHeadphoneState(function(phones,mic)
  local hp,spk = false, false
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

displayInfo("cs-16 v"..pd.metadata.version,2000)

if firstTime then -- reading the manual is pretty important, so i thought this would be helpful.
  messageBox.open("welcome to cs-16! :)\n\nbefore you begin, it is highly recommended that you read the manual, as most functions are not immediately apparent and are hard to reach without aid from the documentation.\n\nyou can read it at https://is.gd/cs16m/ (all capital letters).\n\npress a to continue.")
end
