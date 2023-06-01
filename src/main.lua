-- this is SeaSynth, a synthesizer for the playdate.

import "CoreLibs/graphics"
import "CoreLibs/ui"
import "CoreLibs/nineslice"
import "CoreLibs/object"
import "CoreLibs/crank"
import "CoreLibs/timer"
import "CoreLibs/keyboard"

stepCount = 32

import "funcs"
import "buttons"
import "consts"
import "synthSetup"
import "lists"
import "uiToolkit"

songdir = "temp/"

pd.file.mkdir("samples")
pd.file.mkdir("songs")
pd.file.mkdir("temp")

settings = {["dark"]=true,["playonload"]=true,["cranksens"]=4,["author"]="anonymous",["output"]=0,["stoponsample"]=true}
crankSensList = {1,2,3,4,5,6,7,8}

settings = loadSettings()

marker = {0,0}
cursor = {0,0}
trackNames = {"sin","squ","saw","tri","nse","poP","poD","poV","sin","squ","saw","tri","nse","poP","poD","poV"}
crankModes = crankModesList[1]
crankMode = "pitch"
tempo = 120.0
selectedTrack = tracks[1]
textTimer = nil
textTimerText = ""
screenModes = {"pattern","instrument","song"}
screenMode = "pattern"
currentElem = 1
autonote = "none"
songAuthor = settings["author"]

gfx.setImageDrawMode(gfx.kDrawModeNXOR)
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

knobs = {Knob(55,65,8,true),Knob(150,65,21),Knob(180,65,21),Knob(210,65,21),Knob(240,65,21),Knob(146,135,21),Knob(215,135,11),Knob(255,135,11),Knob(336,135,25,true),Knob(55,205,11)}
buttons = {Button(5,5,nil,nil,"back",true),Button(310,55,nil,nil,"toggle",true),Button(53-(fnt8x8:getTextWidth("select")/2),125,nil,nil,"select",true)}

allElems = {buttons[1],knobs[1],knobs[2],knobs[3],knobs[4],knobs[5],buttons[2],buttons[3],knobs[6],knobs[7],knobs[8],knobs[9],knobs[10]}

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
  end
end

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

  if crank ~= 0 then
    local b = nil
    if crank == -1 then
      b = true
    end

    if crankMode == "note status" then
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
        local autoNoteMenuItem, error = pdmenu:addOptionsMenuItem("autonote", {"none","1","2","4","8","16","32"}, autonote, function(arg)
          autonote = arg
        end)
      elseif screenMode == "instrument" then
        pd.inputHandlers.push(instrument, true)
      elseif screenMode == "song" then
        pd.inputHandlers.push(song, true)
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
          end,"song")
        end)
        local settingsMenuItem, error = pdmenu:addMenuItem("settings", function ()
          settingsScreen.open()
        end)
      end
    elseif crankMode == "tempo" then
      if seq:isPlaying() then
        seq:stop()
      end
      seq:setTempo(math.max(2,math.min(64,seq:getTempo()+crank)))
    elseif crankMode == "pattern length" then
      local newThing = stepCount+(crank*16)
      if newThing <= 128 and newThing >= 16 then
        stepCount = newThing

        while (cursor[2]+1)*16 > stepCount do
          cursor[2] -= 1
        end
      end
      seq:setLoops(1,stepCount)

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
        elseif currentElem == 9 then -- pan
          local pans = {{0,1},{0.1,1},{0.2,1},{0.3,1},{0.4,1},{0.5,1},{0.6,1},{0.7,1},{0.8,1},{0.9,1},{1,1},{1,0.9},{1,0.8},{1,0.7},{1,0.6},{1,0.5},{1,0.4},{1,0.3},{1,0.2},{1,0.1},{1,0}} -- fix so this changes with volume
          --local vol = instrument.selectedInst:getVolume()
          --if type(vol) ~= "table" then
            --vol = {vol,vol}
          --end
          print(curKnob:getCurrentClick())

          local vol = {}
          table.insert(vol,pans[curKnob:getCurrentClick()+1][1])
          table.insert(vol,pans[curKnob:getCurrentClick()+1][2])
          --vol[1] += crank*0.1
          --vol[2] -= crank*0.1

          printTable(vol)
          instrument.selectedInst:setVolume(vol[1],vol[2])
          --knobs[10]:setClicks(instrument.selectedInst:getVolume()*10)
          displayInfo("pan: ".."L"..vol[1]..", R"..vol[2])
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

  if screenMode == "pattern" then
    drawInsts()
    drawSteps()
    drawCursor()

    if autonote ~= "none" then
      gfx.drawTextAligned("aĂ: "..autonote,400,222,align.right)
    end

    gfx.drawText(currentSeqStep,0,222)
    gfx.drawTextAligned(table.find(tracks,selectedTrack).."-"..trackNames[table.find(tracks,selectedTrack)],200,222,align.center)

  elseif screenMode == "instrument" then -- at some point, maybe add a "+ track" thing?
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
  local autoNoteMenuItem, error = pdmenu:addOptionsMenuItem("autonote", {"none","1","2","4","8","16","32"}, autonote, function(arg)
    autonote = arg
  end)
end

if settings["playonload"] == true then
  seq:play()
end

displayInfo("cs-16 v"..pd.metadata.version,2000)
