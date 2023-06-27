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

function Button:draw(selected)
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

  local fontdraw = fnt
  gfx.drawRect(self.x,self.y,w,h)

  if selected ~= nil then
    gfx.drawRoundRect(self.x-3,self.y-3,w+6,h+6,2)
  end

  if self.drawSmall ~= nil then
    fontdraw = fnt8x8
  end
  fontdraw:drawText(self.text,self.x+2,self.y+2)
end


-- alternate pd.updates

filePicker = {}
filePicker.selectedFile = nil
filePicker.callback = nil
filePicker.oldUpdate = nil
filePicker.mode = nil
filePicker.sample = snd.sampleplayer.new(snd.sample.new(1))
filePicker.keyTimer = nil

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
    filePickList:drawInRect(0,0,400,240)
    fnt8x8:drawTextAligned("choose a "..ftype,200,0,align.center)
  end

  pd.timer.updateTimers()
end

function filePicker.close()
  pd.inputHandlers.pop()
  pd.update = filePicker.oldUpdate
  filePicker.callback(filePicker.selectedFile)
end

function filePicker.AButtonDown()
  if pd.file.isdir(currentPath..filePickListContents[row]) then
    table.insert(dirs, currentPath)
    table.insert(dirLocations, row)
    currentPath = currentPath..filePickListContents[row]
    filePickList:set(filePicker.modifyDirContents(pd.file.listFiles(currentPath)))
    filePickList:setSelectedRow(1)
    filePickList:scrollToRow(1)
  elseif filePickListContents[row] == "Ā" then
    currentPath = table.remove(dirs)
    filePickList:set(filePicker.modifyDirContents(pd.file.listFiles(currentPath)))
    local rmed = table.remove(dirLocations)
    filePickList:setSelectedRow(rmed)
    filePickList:scrollToRow(rmed)
  elseif filePickListContents[row] == "Ą record sample" then
    sampleScreen.open(function(sample)
      filePicker.selectedFile = sample
      filePicker.close()
    end)
  elseif filePickListContents[row] == "ċ edit sample" then
    sampleEditScreen.open(snd.sample.new("temp/"..listview:getSelectedRow()..".pda"), function(sample)
      filePicker.selectedFile = sample
      filePicker.close()
    end)
  else
    if filePicker.mode ~= "song" or string.find(filePickListContents[row],"%/ %(song%)") then
      filePicker.selectedFile = currentPath..filePickListContents[row]
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
  end
end

function filePicker.rightButtonDown()
  if not pd.file.isdir(currentPath..filePickListContents[row]) and string.find(filePickListContents[row],"%.pda") then
    filePicker.sample:stop()
    filePicker.sample:setSample(snd.sample.new(currentPath..filePickListContents[row]))
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
  end

  if currentPath ~= "/" then
    table.insert(val,1,"Ā")
  elseif filePicker.mode ~= "song" then
    table.insert(val,1,"Ą record sample")
  end

  if filePicker.mode == "newsmp" and currentPath == "/" then
    table.insert(val,1,"ċ edit sample")
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

local state = "press A to arm..."

function sampleScreen.open(callback)
  sampleScreen.sample = nil
  sampleScreen.callback = nil
  sampleScreen.recording = false
  sampleScreen.oldUpdate = nil
  sampleScreen.waiting = false
  sampleScreen.waitForButton = false
  sampleScreen.recTimer:reset()
  sampleScreen.recTimer:pause()
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
    sampleScreen.record()
  end

  gfx.drawTextAligned(state,200,0,align.center)
  gfx.drawRect(50,110,300,20)
  gfx.fillRect(50,110,snd.micinput.getLevel()*300,20)
  fnt8x8:drawTextAligned(math.round(snd.micinput.getLevel(),2),200,116,align.center)
  fnt8x8:drawTextAligned("will start recording from "..snd.micinput.getSource().." at volume "..sampleScreen.recAt,200,231,align.center)
  gfx.drawTextAligned(tostring(sampleScreen.recTimer.currentTime/1000).." / 5.0",200,20,align.center)
  pd.timer.updateTimers()
end

function sampleScreen.close()
  pd.inputHandlers.pop()
  pd.update = sampleScreen.oldUpdate
  sampleScreen.callback(sampleScreen.sample)

  if settings["stoponsample"] == true then
    seq:play()
  end
end

function sampleScreen.record()
  sampleScreen.recording = true
  sampleScreen.waiting = false
  sampleScreen.recTimer:start()
  local buffer = snd.sample.new(5, snd.kFormat16bitMono)
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
    sampleScreen.recAt += 0.05
    sampleScreen.fixRec()
  end
end

function sampleScreen.downButtonDown()
  sampleScreen.recAt -= 0.05
  sampleScreen.fixRec()
end

function sampleScreen.leftButtonDown()
  sampleScreen.recAt -= 0.05
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
  keyboardScreen.text = text
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
    keyboardScreen.text = pd.keyboard.text
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
settingsScreen.oldUpdate = nil
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

  pd.inputHandlers.push(settingsScreen,true)
  settingsScreen.oldUpdate = pd.update
  pd.update = settingsScreen.update
end

function settingsScreen.update()
  gfx.clear()

  settingsList:drawInRect(0,0,400,240)
  fnt8x8:drawTextAligned("settings",200,0,align.center)
  fnt8x8:drawTextAligned("cs-16 version "..pd.metadata.version..", build "..pd.metadata.buildNumber,200,231,align.center)
end

function settingsScreen.close()
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
  if settingsList:getSelectedRow() == 3 then
    settings["cranksens"] = table.cycle(crankSensList, settings["cranksens"],true)
  elseif settingsList:getSelectedRow() == 5 then
    settingsScreen.updateOutputs()
  end
  settingsScreen.updateSettings()
end

function settingsScreen.rightButtonDown()
  if settingsList:getSelectedRow() == 3 then
    settings["cranksens"] = table.cycle(crankSensList, settings["cranksens"])
  elseif settingsList:getSelectedRow() == 5 then
    settingsScreen.updateOutputs()
  end
  settingsScreen.updateSettings()
end

function settingsScreen.BButtonDown()
  settingsScreen.close()
end

function settingsScreen.AButtonDown()
  local row = settingsList:getSelectedRow()
  if row == 1 then
    settings["dark"] = not settings["dark"]
    pd.display.setInverted(settings["dark"])
  elseif row == 2 then
    settings["playonload"] = not settings["playonload"]
  elseif row == 3 then
    settings["cranksens"] = table.cycle(crankSensList, settings["cranksens"])
  elseif row == 4 then
    keyboardScreen.open("enter new author name:",settings["author"],15,function(t)
      if t ~= "_EXITED_KEYBOĀRD" then
        settings["author"] = t
        if songdir == "temp/" then
          songAuthor = t
        end
        settingsScreen.updateSettings()
      end
    end)
  elseif row == 5 then
    settingsScreen.updateOutputs()
  elseif row == 6 then
    settings["stoponsample"] = not settings["stoponsample"]
  elseif row == 7 then
    settings["stopontempo"] = not settings["stopontempo"]
  elseif row == 8 then
    settings["savewavs"] = not settings["savewavs"]
  end
  settingsScreen.updateSettings()
end

function settingsScreen.updateSettings()
  local outputText = "speaker"
  if settings["output"] == 1 then
    outputText = "headset"
  elseif settings["output"] == 2 then
    outputText = "speaker, headset"
  elseif settings["output"] == 3 then
    outputText = "auto"
  end
  settingsList:set({"dark mode: "..tostring(settings["dark"]),"play on load: "..tostring(settings["playonload"]),"crank speed: "..settings["cranksens"],"author: "..settings["author"],"output: "..outputText,"stop if sampling: "..tostring(settings["stoponsample"]),"tempo edit stop: "..tostring(settings["stopontempo"]),"save .wav samples: "..tostring(settings["savewavs"])})
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

function sampleEditScreen.open(sample, callback) -- this whole thing could look better!
  sampleEditScreen.sample = sample
  sampleEditScreen.editedSample = nil
  sampleEditScreen.callback = callback
  sampleEditScreen.changeVal = 1000
  sampleEditScreen.trim = {0,0}
  sampleEditScreen.side = 1

  sampleEditScreen.sampleLen = math.round(sample:getLength()*44100,0)

  sampleEditScreen.trim[2] = sampleEditScreen.sampleLen

  pd.inputHandlers.push(sampleEditScreen,true)
  sampleEditScreen.oldUpdate = pd.update
  pd.update = sampleEditScreen.update

  gfx.clear()

  sample:play()
end

function sampleEditScreen.update()
  local sidetext = "start"
  gfx.clear()
  local crank = pd.getCrankTicks(settings["cranksens"])

  if crank ~= 0 then
    sampleEditScreen.trim[sampleEditScreen.side] += sampleEditScreen.changeVal*crank
    sampleEditScreen.trim[sampleEditScreen.side] = math.normalize(sampleEditScreen.trim[sampleEditScreen.side],0,sampleEditScreen.sampleLen)
    sampleEditScreen.editedSample = sampleEditScreen.sample:getSubsample(sampleEditScreen.trim[1],sampleEditScreen.trim[2])
    sampleEditScreen.editedSample:play()
  end

  if sampleEditScreen.side == 2 then
    sidetext = "end"
  end

  gfx.drawTextAligned("start: "..sampleEditScreen.trim[1]..", end: "..sampleEditScreen.trim[2],200,104,align.center)
  gfx.drawTextAligned("selected: "..sidetext,200,120,align.center)
  gfx.drawTextAligned("a to save, b to discard",200,210,align.center)
  fnt8x8:drawTextAligned("changing frames by "..sampleEditScreen.changeVal,200,231,align.center)
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
--messageBox.message = ""

function messageBox.open(message)
  gfx.drawTextInRect(message,0,0,400,240,nil,nil,align.center)

  pd.inputHandlers.push(messageBox,true)
  messageBox.oldUpdate = pd.update
  pd.update = messageBox.update
end

function messageBox.update()
  
end

function messageBox.AButtonDown()
  messageBox.close()
end

function messageBox.BButtonDown()
  messageBox.close()
end

function messageBox.close()
  pd.inputHandlers.pop()
  pd.update = messageBox.oldUpdate
end
