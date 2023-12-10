-- ui classes and sub-screens (keyboard screen, settings screen, etc. basically everything else that uses inputHandlers.)

class("Knob").extends()
class("Button").extends()

function Knob:init(x, y, clicks, rot)
  self.x = x
  self.y = y
  self.clicks = 360/clicks
  self.rotation = 0
  self.freeRotate = rot
end

function Knob:getCurrentClick()
  return math.round(self.rotation/self.clicks,0)
end

function Knob:getValue()
  return self.rotation
end

function Knob:setValue(value)
  if value >= 360 then
    self.rotation = value - 360
  else
    self.rotation = value
  end
end

function Knob:setClicks(click)
  self.rotation = click*self.clicks
end

function Knob:adjust(amount, backwards)
  self.rotation = (((self.rotation+(amount)*backwards) % 360) + 360) % 360
end

function Knob:click(amount, backwards)
  if self.freeRotate == nil then
    self.rotation = math.normalize(self.rotation+((amount*self.clicks)*backwards),0,360-self.clicks)
  else
    self.rotation = ((self.rotation+((amount*self.clicks)*backwards) % 360) + 360) % 360
  end
end

function Knob:draw(selected)
  if selected ~= nil and selected == true then
    gfx.drawRoundRect(self.x-12,self.y-12,24,24,2)
  end
  knob:drawRotated(self.x,self.y,self.rotation)
  gfx.drawCircleAtPoint(self.x,self.y,10)
end



function Button:init(x,y,w,h,text,smallfont)
  self.drawSmall = smallfont
  self.x = x
  self.y = y
  self.w = w
  self.h = h
  self.text = text
end

function Button:draw(selected, pressed)
  local w = self.w
  local h = self.h

  if w == nil and h == nil then
    if self.drawSmall == true then
      w = fnt8x8:getTextWidth(self.text)+5
    else
      w = fnt:getTextWidth(self.text)+5
    end
    h = 13
  end

  if pressed == true then
    gfx.setColor(gfx.kColorWhite)
  end

  local fontdraw = fnt
  gfx.drawRect(self.x,self.y,w,h)

  if pressed == true then
    gfx.setColor(gfx.kColorBlack)
  end

  if selected ~= nil then
    gfx.drawRoundRect(self.x-3,self.y-3,w+6,h+6,2)
  end

  if self.drawSmall ~= nil then
    fontdraw = fnt8x8
  end
  fontdraw:drawText(self.text,self.x+2,self.y+2)
end


-- alternate pd.updates

filePicker = {cranked = function() end}
filePicker.selectedFile = nil
filePicker.callback = nil
filePicker.oldUpdate = nil
filePicker.mode = nil
filePicker.sample = snd.sampleplayer.new(snd.sample.new(1))
filePicker.keyTimer = nil
filePicker.animator = nil

local dirs = {}
local currentPath = "/"
local row = filePickList:getSelectedRow()
dirLocations = {}

function filePicker.open(callback, mode)
  row = filePickList:getSelectedRow()

  if callback ~= nil then
    filePicker.callback = callback
  end
  filePicker.mode = mode

  dirs = {}
  if mode == "song" then
    currentPath = "/songs/"
    table.insert(dirs,"/")
    table.insert(dirLocations, 2)
  else
    currentPath = "/"
  end

  filePicker.anim()

  pd.inputHandlers.push(filePicker,true)
  filePicker.oldUpdate = pd.update
  pd.update = filePicker.update

  filePickList:set(filePicker.modifyDirContents(pd.file.listFiles(currentPath)))
  filePickList:setSelectedRow(1)
  filePickList:scrollToRow(1)
end

function filePicker.update()
  local ftype = "sample"
  row = filePickList:getSelectedRow()

  if filePicker.mode == "song" then
    ftype = "song"
  end

  if filePickList.needsDisplay == true then
    filePickList:drawInRect(filePicker.animator:currentValue(),0,400,240)
    fnt8x8:drawTextAligned("choose a "..ftype,200,0,align.center)
  end

  pd.timer.updateTimers()
end

function filePicker.close()
  pd.inputHandlers.pop()
  pd.update = filePicker.oldUpdate
  filePicker.callback(filePicker.selectedFile)
  filePicker.animator = nil
end

function filePicker.AButtonDown()
  if pd.file.isdir(currentPath..filePickListContents[row]) then
    filePicker.anim()
    table.insert(dirs, currentPath)
    table.insert(dirLocations, row)
    currentPath = currentPath..filePickListContents[row]
    filePickList:set(filePicker.modifyDirContents(pd.file.listFiles(currentPath)))
    filePickList:setSelectedRow(1)
    filePickList:scrollToRow(1)
  elseif filePickListContents[row] == "*Ā*" then
    filePicker.anim(true)
    currentPath = table.remove(dirs)
    filePickList:set(filePicker.modifyDirContents(pd.file.listFiles(currentPath)))
    local rmed = table.remove(dirLocations)
    filePickList:setSelectedRow(rmed)
    filePickList:scrollToRow(rmed)
  elseif filePickListContents[row] == "*Ą* record sample" then
    sampleScreen.open(function(sample)
      filePicker.selectedFile = sample
      filePicker.close()
    end)
  elseif filePickListContents[row] == "*ċ* edit sample" then
    sampleEditScreen.open(snd.sample.new("temp/"..listview:getSelectedRow()..".pda"), function(sample)
      filePicker.selectedFile = sample
      filePicker.close()
    end, pd.datastore.readImage("temp/"..listview:getSelectedRow()..".pdi"))
  else
    if filePicker.mode ~= "song" or string.find(filePickListContents[row],"%/ %(song%)") then
      filePicker.selectedFile = string.unnormalize(currentPath..filePickListContents[row])
      filePicker.close()
    end
  end
end

function filePicker.BButtonDown()
  if currentPath == "/" then
    filePicker.selectedFile = "none"
    filePicker.close()
  else
    currentPath = table.remove(dirs)
    filePickList:set(filePicker.modifyDirContents(pd.file.listFiles(currentPath)))
    local rmed = table.remove(dirLocations)
    filePickList:setSelectedRow(rmed)
    filePickList:scrollToRow(rmed)
    filePicker.anim(true)
  end
end

function filePicker.rightButtonDown()
  if not pd.file.isdir(currentPath..filePickListContents[row]) and string.find(filePickListContents[row],"%.pda") then
    filePicker.sample:stop()
    filePicker.sample:setSample(snd.sample.new(string.unnormalize(currentPath..filePickListContents[row])))
    filePicker.sample:play()
  end
end

function filePicker.upButtonDown()
  local function callback()
    filePickList:selectPreviousRow()
  end
  filePicker.keyTimer = pd.timer.keyRepeatTimerWithDelay(300,75,callback)
end

function filePicker.downButtonDown()
  local function callback()
    filePickList:selectNextRow()
  end
  filePicker.keyTimer = pd.timer.keyRepeatTimerWithDelay(300,75,callback)
end

function filePicker.upButtonUp()
  if filePicker.keyTimer ~= nil then
    filePicker.keyTimer:remove()
  end
end

function filePicker.downButtonUp()
  if filePicker.keyTimer ~= nil then
    filePicker.keyTimer:remove()
  end
end

function filePicker.anim(back)
  gfx.clear()
  if back then
    filePicker.animator = gfx.animator.new(200, -200, 0, pd.easingFunctions.outQuart)
  else
    filePicker.animator = gfx.animator.new(200, 200, 0, pd.easingFunctions.outQuart)
  end
end

function filePicker.modifyDirContents(val)
  if currentPath == "/" then
    for i=#val, 1, -1 do
      if val[i] ~= "samples/" and val[i] ~= "temp/" and val[i] ~= "songs/" then
        table.remove(val, i)
      end
    end
  end

  for i=1, #val do
    if pd.file.isdir(currentPath..val[i]) then
      if filePicker.mode == "song" and table.find(pd.file.listFiles(currentPath..val[i]),"song.json") ~= -1 then
        val[i] = val[i].." (song)"
      end
    end
    val[i] = string.normalize(val[i])
  end

  if currentPath ~= "/" then
    table.insert(val,1,"*Ā*")
  elseif filePicker.mode ~= "song" then
    table.insert(val,1,"*Ą* record sample")
  end

  if filePicker.mode == "newsmp" and currentPath == "/" then
    table.insert(val,1,"*ċ* edit sample")
  end

  return val
end

sampleScreen = {}
sampleScreen.sample = nil
sampleScreen.callback = nil
sampleScreen.recording = false
sampleScreen.oldUpdate = nil
sampleScreen.waiting = false
sampleScreen.waitForButton = false
sampleScreen.recAt = 0.15
sampleScreen.recTimer = pd.timer.new(5000)
sampleScreen.waveformImage = nil
sampleScreen.waveformAnimator = nil
sampleScreen.waveformLastXY = {0,20}

local state = "press A to arm..."

function sampleScreen.open(callback)
  sampleScreen.sample = nil
  sampleScreen.callback = nil
  sampleScreen.recording = false
  sampleScreen.oldUpdate = nil
  sampleScreen.waiting = false
  sampleScreen.waitForButton = false
  sampleScreen.recTimer = pd.timer.new(5000)
  sampleScreen.recTimer:reset()
  sampleScreen.recTimer:pause()
  sampleScreen.waveformImage = gfx.image.new(400, 45)
  sampleScreen.waveformLastXY = {0,20}
  state = "press A to arm..."


  if callback ~= nil then
    sampleScreen.callback = callback
  end

  if settings["stoponsample"] == true then
    seq:stop()
    seq:allNotesOff()
  end

  pd.inputHandlers.push(sampleScreen,true)
  sampleScreen.oldUpdate = pd.update
  pd.update = sampleScreen.update
  snd.micinput.startListening()
end

function sampleScreen.update()
  gfx.clear()
  if sampleScreen.waiting == true and snd.micinput.getLevel() > sampleScreen.recAt then
    state = "recording..."
    sampleScreen.waveformAnimator = gfx.animator.new(5000, 1, 400)
    sampleScreen.record()
  end

  if sampleScreen.recording == true then
    local lastxy = sampleScreen.waveformLastXY
    local x = sampleScreen.waveformAnimator:currentValue()
    local y = 40+((-snd.micinput.getLevel())*40)
    gfx.pushContext(sampleScreen.waveformImage)
    gfx.drawLine(lastxy[1], lastxy[2], x, y)
    gfx.popContext()
    sampleScreen.waveformLastXY = {x, y}
    sampleScreen.waveformImage:draw(0, 55)
  end

  gfx.drawTextAligned(state,200,0,align.center)
  gfx.drawRect(50,110,300,20)
  gfx.fillRect(50,110,snd.micinput.getLevel()*300,20)
  fnt8x8:drawTextAligned(math.round(snd.micinput.getLevel(),2),200,116,align.center)
  fnt8x8:drawTextAligned("will start recording from "..snd.micinput.getSource().." if volume = "..sampleScreen.recAt,200,231,align.center)
  gfx.drawTextAligned(tostring(sampleScreen.recTimer.currentTime/1000).." / 5.0",200,20,align.center)
  pd.timer.updateTimers()
end

function sampleScreen.close()
  pd.inputHandlers.pop()
  pd.update = sampleScreen.oldUpdate
  if settings["saveWaveforms"] == true then
    sampleScreen.callback({sampleScreen.sample, sampleScreen.waveformImage:copy()})
  else
    sampleScreen.callback(sampleScreen.sample)
  end

  if settings["stoponsample"] == true then
    seq:play()
  end
end

function sampleScreen.record()
  sampleScreen.recording = true
  sampleScreen.waiting = false
  sampleScreen.recTimer:reset()
  sampleScreen.recTimer:start()

  local format = snd.kFormat16bitMono

  if settings["sample16bit"] == false then
    format = snd.kFormat8bitMono
  end

  local buffer = snd.sample.new(5, format)
  snd.micinput.recordToSample(buffer, function(smp)
    sampleScreen.sample = smp
    snd.micinput.stopListening()
    if sampleScreen.sample == "none" then
      goto continue
    end

    sampleScreen.recording = false
    sampleScreen.waitForButton = true

    gfx.clear()
    smp:play()
    gfx.drawTextInRect("save?\n\na to save, b to redo, right to hear again",20,85,360,200,nil,nil,align.center)
    sampleScreen.waveformImage:drawCentered(400-(sampleScreen.waveformAnimator:currentValue()/2), 45)
    pd.stop()
    ::continue::
  end)
end

function sampleScreen.AButtonDown()
  if sampleScreen.waitForButton == true then
    pd.start()
    displayInfo("saved as "..listview:getSelectedRow()..".pda")
    sampleScreen.sample:save(songdir..listview:getSelectedRow()..".pda")
    if settings["savewavs"] == true then
      sampleScreen.sample:save(songdir..listview:getSelectedRow()..".wav")
    end
    sampleScreen.close()
  elseif sampleScreen.waiting == false and sampleScreen.recording == false then
    sampleScreen.waiting = true
    state = "armed, waiting..."
  else
    snd.micinput.stopRecording()
  end
end

function sampleScreen.BButtonDown()
  if sampleScreen.waitForButton == true then
    pd.start()
    sampleScreen.sample = nil
    sampleScreen.recording = false
    sampleScreen.oldUpdate = nil
    sampleScreen.waiting = false
    sampleScreen.waitForButton = false
    sampleScreen.recTimer:reset()
    sampleScreen.recTimer:pause()
    sampleScreen.waveformImage = gfx.image.new(400, 45)
    sampleScreen.waveformAnimator = nil
    sampleScreen.waveformLastXY = {0,20}

    state = "press A to arm..."

    snd.micinput.startListening()
  elseif sampleScreen.recording == false then
    sampleScreen.sample = "none"
    snd.micinput.stopListening()
    sampleScreen.close()
  end
end

function sampleScreen.upButtonDown()
  sampleScreen.recAt += 0.05
  sampleScreen.fixRec()
end

function sampleScreen.rightButtonDown()
  if sampleScreen.waitForButton == true then
    sampleScreen.sample:play()
  else
    sampleScreen.recAt += 0.01
    sampleScreen.fixRec()
  end
end

function sampleScreen.downButtonDown()
  sampleScreen.recAt -= 0.05
  sampleScreen.fixRec()
end

function sampleScreen.leftButtonDown()
  sampleScreen.recAt -= 0.01
  sampleScreen.fixRec()
end

function sampleScreen.fixRec()
  sampleScreen.recAt = math.round(sampleScreen.recAt,2)
  sampleScreen.recAt = math.max(0.0, math.min(1.0, (sampleScreen.recAt)))
end

keyboardScreen = {}
keyboardScreen.oldUpdate = nil
keyboardScreen.callback = nil
keyboardScreen.askingForOK = false
keyboardScreen.prompt = ""
keyboardScreen.text = ""
keyboardScreen.limit = nil
keyboardScreen.origtext = ""

function keyboardScreen.open(prompt,text,limit,callback)
  keyboardScreen.callback = callback
  keyboardScreen.text = string.normalize(text)
  keyboardScreen.origtext = text
  keyboardScreen.prompt = prompt
  keyboardScreen.askingForOK = false

  if limit == nil then
    limit = 100000
  end
  keyboardScreen.limit = limit


  pd.inputHandlers.push(keyboardScreen,true)
  keyboardScreen.oldUpdate = pd.update
  pd.update = keyboardScreen.update

  pd.keyboard.show(text)
end

function keyboardScreen.update()
  local rectWidth = 400-pd.keyboard.width()
  gfx.clear()

  if keyboardScreen.askingForOK == false then
    gfx.drawTextInRect(keyboardScreen.prompt,0,0,rectWidth,100,nil,nil,align.center)
    gfx.drawTextInRect(keyboardScreen.text,0,104,rectWidth,136,nil,nil,align.center)
  else
    gfx.drawTextInRect("is this good?\n\na to confirm, b to redo, left to quit",0,0,rectWidth,100,nil,nil,align.center)
    gfx.drawTextInRect(keyboardScreen.text,0,104,rectWidth,136,nil,nil,align.center)
  end
end

function keyboardScreen.close()
  pd.inputHandlers.pop()
  keyboardScreen.callback(keyboardScreen.text)
  pd.update = keyboardScreen.oldUpdate
end

function pd.keyboard.keyboardWillHideCallback()
  keyboardScreen.askingForOK = true
end

function pd.keyboard.textChangedCallback()
  if #pd.keyboard.text <= keyboardScreen.limit then
    keyboardScreen.text = string.normalize(pd.keyboard.text)
  else
    pd.keyboard.text = string.sub(pd.keyboard.text,1,keyboardScreen.limit)
  end
end

function keyboardScreen.AButtonDown()
  if keyboardScreen.askingForOK == true then
    keyboardScreen.close()
  end
end

function keyboardScreen.BButtonDown()
  if keyboardScreen.askingForOK == true then
    keyboardScreen.askingForOK = false
    pd.keyboard.show(keyboardScreen.text)
  end
end

function keyboardScreen.leftButtonDown()
  keyboardScreen.text = "_EXITED_KEYBOĀRD"
  keyboardScreen.close()
end


settingsScreen = {}
settingsScreen.subMenu = ""
settingsScreen.oldUpdate = nil
settingsScreen.animator = nil
settingsScreen.updateOutputs = (function()
  if settings["output"] < 3 then
    settings["output"] += 1
  else
    settings["output"] = 0
    snd.setOutputsActive(false, true)
  end
  if settings["output"] == 1 then
    snd.setOutputsActive(true, false)
  elseif settings["output"] == 2 then
    snd.setOutputsActive(true, true)
  elseif settings["output"] == 3 then
    local state = snd.getHeadphoneState()
    snd.setOutputsActive(state, not state)
  end
end)

function settingsScreen.open()
  settingsScreen.updateSettings()

  pd.getSystemMenu():removeAllMenuItems()

  settingsList:setSelectedRow(1)
  settingsList:scrollToRow(1)

  settingsScreen.animator = gfx.animator.new(200, 200, 0, pd.easingFunctions.outQuart)

  pd.inputHandlers.push(settingsScreen,true)
  settingsScreen.oldUpdate = pd.update
  pd.update = settingsScreen.update
end

function settingsScreen.update()
  if settingsList.needsDisplay or settingsScreen.animator:ended() == false 
  then
    gfx.clear()
    settingsList:drawInRect(settingsScreen.animator:currentValue(),0,400,240)

    if settingsScreen.subMenu == "" then
      fnt8x8:drawTextAligned("settings",200,0,align.center)
    else
      fnt8x8:drawTextAligned("settings/"..string.sub(settingsScreen.subMenu,1,#settingsScreen.subMenu-1),200,0,align.center)
    end
    fnt8x8:drawTextAligned("cs-16 version "..pd.metadata.version..", build "..pd.metadata.buildNumber,200,231,align.center)
  end

  pd.timer.updateTimers()
end

function settingsScreen.close()
  settingsScreen.animator = nil
  pd.inputHandlers.pop()
  pd.update = settingsScreen.oldUpdate

  applyMenuItems("song")
end

function settingsScreen.downButtonDown()
  settingsList:selectNextRow()
end

function settingsScreen.upButtonDown()
  settingsList:selectPreviousRow()
end

function settingsScreen.leftButtonDown()
  if settingsList:getSelectedRow() == 3 and settingsScreen.subMenu == "general/" then
    settingsScreen.updateOutputs()
  elseif settingsList:getSelectedRow() == 4 and settingsScreen.subMenu == "general/" then
    settings["cranksens"] = table.cycle(crankSensList, settings["cranksens"],true)
  end
  settingsScreen.updateSettings()
end

function settingsScreen.rightButtonDown()
  if settingsList:getSelectedRow() == 3 and settingsScreen.subMenu == "general/" then
    settingsScreen.updateOutputs()
  elseif settingsList:getSelectedRow() == 4 and settingsScreen.subMenu == "general/" then
    settings["cranksens"] = table.cycle(crankSensList, settings["cranksens"])
  end
  settingsScreen.updateSettings()
end

function settingsScreen.BButtonDown()
  if settingsScreen.subMenu == "" then
    settingsScreen.close()
  else
    local oldmenu = settingsScreen.subMenu
    settingsScreen.subMenu = ""
    settingsScreen.updateSettings()
    settingsList:setSelectedRow(table.indexOfElement(settingsList:get(), oldmenu))
    settingsScreen.animator = gfx.animator.new(200, -200, 0, pd.easingFunctions.outQuart)
  end
end

function settingsScreen.AButtonDown()
  local row = settingsList:getSelectedRow()
  local text = settingsListContents[settingsList:getSelectedRow()]
  
  local refresh = true

  if settingsScreen.subMenu == "" then
    settingsScreen.subMenu = text
    settingsList:setSelectedRow(1)
    settingsScreen.animator = gfx.animator.new(200, 200, 0, pd.easingFunctions.outQuart)
  else
    if text == "*Ā*" then
      local oldmenu = settingsScreen.subMenu
      settingsScreen.subMenu = ""
      settingsScreen.updateSettings()
      settingsList:setSelectedRow(table.indexOfElement(settingsList:get(), oldmenu))
      settingsScreen.animator = gfx.animator.new(200, -200, 0, pd.easingFunctions.outQuart)
      refresh = false
    end

    if settingsScreen.subMenu == "ui/" then
      if row == 2 then
        settings["dark"] = not settings["dark"]
        pd.display.setInverted(settings["dark"])
      elseif row == 3 then
        if settings["visualizer"] < 3 then
          settings["visualizer"] += 1
        else
          settings["visualizer"] = 0
        end
      elseif row == 4 then
        settings["num/max"] = not settings["num/max"]
      elseif row == 5 then
        settings["showNoteNames"] = not settings["showNoteNames"]
      elseif row == 6 then
        settings["screenAnimation"] = not settings["screenAnimation"]
      elseif row == 7 then
        settings["useSystemFont"] = not settings["useSystemFont"]
        if settings["useSystemFont"] == true then
          fnt = gfx.getSystemFont()
        else
          fnt = gfx.font.new("fnt/modified-tron")
        end
        gfx.setFont(fnt)
      elseif row == 8 then
        if settings["pmode"] == false then
          messageBox.open("\n\nwarning!\n\nrunning cs-16 at 50fps will reduce your battery life, but improve performance.\n\nare you sure you want to enable this?\n\na = yes, b = no", function(ans)
            if ans == "yes" then
              settings["pmode"] = not settings["pmode"]
              if settings["pmode"] == true then
                pd.display.setRefreshRate(50)
              else
                pd.display.setRefreshRate(30)
              end
            end
            settingsScreen.updateSettings()
          end)
        else
          settings["pmode"] = not settings["pmode"]
          pd.display.setRefreshRate(30)
        end
      end
    elseif settingsScreen.subMenu == "behavior/" then
      if row == 2 then
        settings["playonload"] = not settings["playonload"]
      elseif row == 3 then
        settings["stoponsample"] = not settings["stoponsample"]
      elseif row == 4 then
        settings["stopontempo"] = not settings["stopontempo"]
      elseif row == 5 then
        settings["savewavs"] = not settings["savewavs"]
      end
    elseif settingsScreen.subMenu == "recording/" then
      if row == 8 then
        local quant = settings["recordQuantization"]
        if quant == 1 then -- every #th note
          settings["recordQuantization"] = 2
        elseif quant == 2 then
          settings["recordQuantization"] = 4
        elseif quant == 4 then
          settings["recordQuantization"] = 1
        end
      elseif row > 1 then
        keyboardScreen.open("enter a new track number for this button (1-16):","",2,function(t)
          local num = tonumber(t)
          if num ~= nil then
            if num > 0 and num < 17 then
              if row == 2 then
                settings["aRecTrack"] = num
              elseif row == 3 then
                settings["bRecTrack"] = num
              elseif row == 4 then
                settings["upRecTrack"] = num
              elseif row == 5 then
                settings["downRecTrack"] = num
              elseif row == 6 then
                settings["leftRecTrack"] = num
              elseif row == 7 then
                settings["rightRecTrack"] = num
              end
              settingsScreen.updateSettings()
            end
          end
        end)
      end
    elseif settingsScreen.subMenu == "general/" then
      if row == 2 then
        keyboardScreen.open("enter new author name:",settings["author"],15,function(t)
          if t ~= "_EXITED_KEYBOĀRD" then
            settings["author"] = t
            if songdir == "temp/" then
              songAuthor = t
            end
            settingsScreen.updateSettings()
          end
        end)
      elseif row == 3 then
        settingsScreen.updateOutputs()
      elseif row == 4 then
        settings["cranksens"] = table.cycle(crankSensList, settings["cranksens"])
      elseif row == 5 then
        creditsScreen.open()
      end
    elseif settingsScreen.subMenu == "sampling/" then
      if row == 2 then
        settings["sample16bit"] = not settings["sample16bit"]
      elseif row == 3 then
        settings["saveWaveforms"] = not settings["saveWaveforms"]
      end
    end
  end

  if refresh then
    settingsScreen.updateSettings()
  end
end

function settingsScreen.updateSettings()
  if settingsScreen.subMenu == "" then
    settingsList:set({"general/","behavior/","recording/","sampling/","ui/"})
  elseif settingsScreen.subMenu == "general/" then
    local outputText = "speaker"
    if settings["output"] == 1 then
      outputText = "headset"
    elseif settings["output"] == 2 then
      outputText = "speaker, headset"
    elseif settings["output"] == 3 then
      outputText = "auto"
    end

    settingsList:set({
      "*Ā*",
      "author: "..settings["author"],
      "output: "..outputText,
      "crank speed: "..settings["cranksens"],
      "credits..."
    })
  elseif settingsScreen.subMenu == "behavior/" then
    settingsList:set({
      "*Ā*",
      "play on load: "..tostring(settings["playonload"]),
      "stop if sampling: "..tostring(settings["stoponsample"]),
      "tempo edit stop: "..tostring(settings["stopontempo"]),
      "save .wav samples: "..tostring(settings["savewavs"])
    })
  elseif settingsScreen.subMenu == "recording/" then
    settingsList:set({
      "*Ā*",
      "_Ⓐ_ button track: "..tostring(settings["aRecTrack"]),
      "_Ⓑ_ button track: "..tostring(settings["bRecTrack"]),
      "_⬆️_ button track: "..tostring(settings["upRecTrack"]),
      "_⬇️_ button track: "..tostring(settings["downRecTrack"]),
      "_⬅️_ button track: "..tostring(settings["leftRecTrack"]),
      "_➡️_ button track: "..tostring(settings["rightRecTrack"]),
      "quantization: "..tostring(settings["recordQuantization"])
    })
  elseif settingsScreen.subMenu == "sampling/" then
    local format = "16 bit"
    if settings["sample16bit"] == false then
      format = "8 bit"
    end
    settingsList:set({
      "*Ā*",
      "sample format: "..format,
      "save waveforms: "..tostring(settings["saveWaveforms"])
    })
  elseif settingsScreen.subMenu == "ui/" then
    local vistext = "both"

    if settings["visualizer"] == 0 then
      vistext = "none"
    elseif settings["visualizer"] == 1 then
      vistext = "notes"
    elseif settings["visualizer"] == 2 then
      vistext = "sine"
    end

    settingsList:set({
      "*Ā*",
      "dark mode: "..tostring(settings["dark"]),
      "visualizer: "..vistext,
      "show number/total: "..tostring(settings["num/max"]),
      "show note names: "..tostring(settings["showNoteNames"]),
      "animate scrn move: "..tostring(settings["screenAnimation"]),
      "use system font: "..tostring(settings["useSystemFont"]),
      "50fps: "..tostring(settings["pmode"])
    })
  end
  saveSettings()
end


sampleEditScreen = {}
sampleEditScreen.oldUpdate = nil
sampleEditScreen.sample = nil
sampleEditScreen.editedSample = nil
sampleEditScreen.callback = nil
sampleEditScreen.changeVal = 1000
sampleEditScreen.sampleLen = 0
sampleEditScreen.trim = {0,0}
sampleEditScreen.side = 1 -- 1 = begin, 2 = end
sampleEditScreen.ctrPixel = 0

function sampleEditScreen.open(sample, callback, image)
  sampleEditScreen.sample = sample
  sampleEditScreen.sampleImg = image
  sampleEditScreen.editedSample = nil
  sampleEditScreen.callback = callback
  sampleEditScreen.changeVal = 1000
  sampleEditScreen.trim = {0,0}
  sampleEditScreen.side = 1

  if image ~= nil then
    local done = false
    for x = 400, 0, -1 do
      for y = 40, 0, -1 do
        if image:sample(x, y) == gfx.kColorBlack then
          sampleEditScreen.ctrPixel = 400-(x/2)
          done = true
          break
        end
      end
      if done then
        break
      end
    end
  end

  sampleEditScreen.sampleLen = math.round(sample:getLength()*44100,0)

  sampleEditScreen.trim[2] = sampleEditScreen.sampleLen

  sampleEditScreen.editedSample = sampleEditScreen.sample:getSubsample(sampleEditScreen.trim[1],sampleEditScreen.trim[2])
  sampleEditScreen.samplePlayer = snd.sampleplayer.new(sampleEditScreen.editedSample)

  pd.inputHandlers.push(sampleEditScreen,true)
  sampleEditScreen.oldUpdate = pd.update
  pd.update = sampleEditScreen.update

  gfx.clear()

  sample:play()
end

function sampleEditScreen.update() -- TODO: stop animation timer when the sample has finished playing, and figure out where the line should start from trim
  local sidetext = "start"
  gfx.clear()
  local crank = pd.getCrankTicks(settings["cranksens"])
  local side = sampleEditScreen.side

  if crank ~= 0 then
    local otherside = 1 -- IS THAT A MINECRAFT REFERENCE????? :OOOO
    sampleEditScreen.trim[side] += sampleEditScreen.changeVal*crank
    sampleEditScreen.trim[side] = math.normalize(sampleEditScreen.trim[side],0,sampleEditScreen.sampleLen)

    if side == 1 then
      otherside = 2
      if sampleEditScreen.trim[side] >= sampleEditScreen.trim[otherside] then
        sampleEditScreen.trim[side] = sampleEditScreen.trim[otherside] - 10
      end
    else
      if sampleEditScreen.trim[side] <= sampleEditScreen.trim[otherside] then
        sampleEditScreen.trim[side] = sampleEditScreen.trim[otherside] + 10
      end
    end
    sampleEditScreen.editedSample = sampleEditScreen.sample:getSubsample(sampleEditScreen.trim[1],sampleEditScreen.trim[2])
    sampleEditScreen.samplePlayer:setSample(sampleEditScreen.editedSample)
    sampleEditScreen.samplePlayer:play()
  end

  if sampleEditScreen.side == 2 then
    sidetext = "end"
  end

  gfx.drawTextAligned("start: "..sampleEditScreen.trim[1]..", end: "..sampleEditScreen.trim[2],200,104,align.center)
  gfx.drawTextAligned("selected: "..sidetext,200,120,align.center)
  gfx.drawTextAligned("a to save, b to discard",200,210,align.center)
  fnt8x8:drawTextAligned("changing frames by "..sampleEditScreen.changeVal,200,231,align.center)

  if sampleEditScreen.sampleImg ~= nil then
    sampleEditScreen.sampleImg:drawCentered(sampleEditScreen.ctrPixel, 40)
  end
end

function sampleEditScreen.rightButtonDown()
  sampleEditScreen.side = 2
end

function sampleEditScreen.leftButtonDown()
  sampleEditScreen.side = 1
end

function sampleEditScreen.upButtonDown()
  sampleEditScreen.changeVal = math.normalize(sampleEditScreen.changeVal+50,50,2000)
end

function sampleEditScreen.downButtonDown()
  sampleEditScreen.changeVal = math.normalize(sampleEditScreen.changeVal-50,50,2000)
end

function sampleEditScreen.close(sample)
  pd.inputHandlers.pop()
  pd.update = sampleEditScreen.oldUpdate
  sampleEditScreen.callback(sample)
end

function sampleEditScreen.BButtonDown()
  sampleEditScreen.close(sampleEditScreen.sample)
end

function sampleEditScreen.AButtonDown()
  sampleEditScreen.close(sampleEditScreen.editedSample)
end

messageBox = {}
messageBox.oldUpdate = nil
messageBox.callback = nil
--messageBox.message = ""

function messageBox.open(message, callback)
  gfx.clear()
  messageBox.callback = callback
  gfx.drawTextInRect(message,0,0,400,240,nil,nil,align.center)

  pd.inputHandlers.push(messageBox,true)
  messageBox.oldUpdate = pd.update
  pd.update = messageBox.update
end

function messageBox.update()
  
end

function messageBox.AButtonDown()
  messageBox.close("yes")
end

function messageBox.BButtonDown()
  messageBox.close("no")
end

function messageBox.close(ans)
  pd.inputHandlers.pop()
  pd.update = messageBox.oldUpdate
  if messageBox.callback ~= nil then
    messageBox.callback(ans)
  end
end

creditsScreen = {}
creditsScreen.oldUpdate = nil
creditsScreen.current = 1

function creditsScreen.open()
  creditsScreen.current = 1
  creditsScreen.updateText()

  pd.inputHandlers.push(creditsScreen,true)
  creditsScreen.oldUpdate = pd.update
  pd.update = creditsScreen.update
end

function creditsScreen.update()
  
end

function creditsScreen.updateText()
  local text
  gfx.clear()

  if creditsScreen.current == 1 then -- used if statements so credits could be dynamic!
    text = "\ncs-16 v"..pd.metadata.version.."\n\ndeveloped by nanobot567\n\n\n\n-- feature requesters --"
  elseif creditsScreen.current == 2 then
    text = "\nspecial thanks to...\n\n\n\n\n\n\n\n\n\n\nyou guys are awesome! :)"
  end

  gfx.drawTextInRect(text,0,0,400,240,nil,nil,align.center)

  if creditsScreen.current == 1 then
    gfx.drawTextInRect("\n\ndrhitchcockco - number/total setting\n\njustyouraveragehomie - waveform view, live record, and much more!", 0, 128, 400, 240, nil, nil, align.center, fnt8x8)
  elseif creditsScreen.current == 2 then
    gfx.drawTextInRect("my family\nlilfigurative\ntrisagion media\nthe trisagion insurgence", 0, 48, 400, 240, nil, nil, align.center, fnt8x8)
  elseif creditsScreen.current == 3 then
    gfx.drawTextInRect("nanobot567: open source, forever.\n\n\n\nthe cs-16 font is a modified version of the 'Tron' font from idleberg's playdate arcade fonts (https://github.com/idleberg/playdate-arcade-fonts).\n\nall of the source code is under the mit license, and is available at https://is.gd/cs16m (capital letters) (https://github.com/nanobot567/cs-16).", 2, 0, 396, 240, nil, nil, align.center, fnt8x8)
  end
  gfx.drawTextInRect("credits - use left / right to navigate, B to exit", 0, 232, 400, 8, nil, nil, align.center, fnt8x8)
end

function creditsScreen.BButtonDown()
  creditsScreen.close()
end

function creditsScreen.leftButtonDown()
  if creditsScreen.current > 1 then
    creditsScreen.current -= 1
    creditsScreen.updateText()
  end
end

function creditsScreen.rightButtonDown()
  if creditsScreen.current < 3 then
    creditsScreen.current += 1
    creditsScreen.updateText()
  else
    creditsScreen.close()
  end
end

function creditsScreen.close()
  pd.inputHandlers.pop()
  pd.update = creditsScreen.oldUpdate
end
