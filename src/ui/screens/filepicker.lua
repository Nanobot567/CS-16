-- file picker

filePicker = { cranked = function() end }
filePicker.selectedFile = nil
filePicker.callback = nil
filePicker.oldUpdate = nil
filePicker.mode = nil
filePicker.sample = snd.sampleplayer.new(snd.sample.new(1))
filePicker.keyTimer = nil
filePicker.animator = nil
filePicker.fileMetadataImage = nil

local dirs = {}
local currentPath = "/"
local row = filePickList:getSelectedRow()
local songMeta = ""
local currentText = ""
local songMetaName = ""
dirLocations = {}

function filePicker.open(callback, mode)
  inScreen = true

  row = filePickList:getSelectedRow()

  if callback ~= nil then
    filePicker.callback = callback
  end
  filePicker.mode = mode

  dirs = {}
  if mode == "song" then
    currentPath = "/songs/"
    table.insert(dirs, "/")
    table.insert(dirLocations, 2)

    applyMenuItems("songpicker")
  else
    currentPath = "/"
  end

  filePicker.anim()

  pd.inputHandlers.push(filePicker, true)
  filePicker.oldUpdate = pd.update
  pd.update = filePicker.update

  filePicker.updateFiles()
end

function filePicker.update(force)
  local ftype = "sample"
  row = filePickList:getSelectedRow()
  currentText = filePickListContents[row]

  if filePicker.mode == "song" then
    ftype = "song"
  end

  if filePickList.needsDisplay == true or (filePicker.animator ~= nil and filePicker.animator:ended() == false) or force then
    gfx.clear()
    filePickList:drawInRect(filePicker.animator:currentValue(), 0, 400, 240)
    fnt8x8:drawTextAligned("choose a " .. ftype, 200, 0, align.center)
  end

  if pd.buttonIsPressed("right") and filePicker.mode == "song" and string.sub(currentText, #currentText - 5) == "(song)" then
    if songMeta == "" or songMetaName ~= currentText then
      local songName = string.unnormalize(string.sub(currentText, 1, #currentText - 8))
      local songData = pd.datastore.read(currentPath .. songName .. "/song")
      local rect = nil

      if songData ~= nil then
        local timeStuff = songData[3][2]

        local concatTable = {
          songName,
          " by ",
          songData[3][1],
          "\n\n",
          "tempo: ",
          math.round(getTempoFromSPS(songData[2][1]), 2),
          ", ",
          songData[2][2],
          " steps",
          "\n\n",
          "last modified: ",
          timeStuff["month"],
          "/",
          timeStuff["day"],
          "/",
          timeStuff["year"],
          " ",
          timeStuff["hour"],
          ":",
          timeStuff["minute"],
          ":",
          timeStuff["second"]
        }

        songMeta = string.normalize(table.concat(concatTable))
        songMetaName = currentText

        local textw, texth = gfx.getTextSizeForMaxWidth(songMeta, 320)
        filePicker.fileMetadataImage = gfx.image.new(400, 240, gfx.kColorClear)

        gfx.pushContext(filePicker.fileMetadataImage)

        rect = pd.geometry.rect.new(40, 120 - (texth / 2), 320, texth + 4)

        gfx.fillRect(rect)
        gfx.pushContext()
        gfx.setColor(gfx.kColorXOR)
        gfx.drawRect(rect)
        gfx.popContext()

        rect.y += 1

        gfx.drawTextInRect(songMeta, rect, nil, nil, kTextAlignment.center)

        rect.y -= 1

        gfx.popContext()
      end
    end

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    filePicker.fileMetadataImage:draw(0, 0)
    gfx.setImageDrawMode(gfx.kDrawModeNXOR)
  else
    songMeta = ""
    songMetaName = ""
  end

  pd.timer.updateTimers()
end

function filePicker.close()
  pd.inputHandlers.pop()
  pd.update = filePicker.oldUpdate
  filePicker.callback(filePicker.selectedFile)
  filePicker.animator = nil
  inScreen = false
end

function filePicker.AButtonDown()
  if pd.file.isdir(currentPath .. filePickListContents[row]) then
    filePicker.anim()
    table.insert(dirs, currentPath)
    table.insert(dirLocations, row)
    currentPath = currentPath .. filePickListContents[row]
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
    sampleEditScreen.open(snd.sample.new("temp/" .. listview:getSelectedRow() .. ".pda"), function(sample)
      filePicker.selectedFile = sample
      filePicker.close()
    end, pd.datastore.readImage("temp/" .. listview:getSelectedRow() .. ".pdi"))
  else
    if filePicker.mode ~= "song" or string.find(filePickListContents[row], "%/ %(song%)") then
      filePicker.selectedFile = string.unnormalize(currentPath .. filePickListContents[row])
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
  if not pd.file.isdir(currentPath .. filePickListContents[row]) and string.find(filePickListContents[row], "%.pda") then
    filePicker.sample:stop()
    filePicker.sample:setSample(snd.sample.new(string.unnormalize(currentPath .. filePickListContents[row])))
    filePicker.sample:play()
  end
end

function filePicker.rightButtonUp()
  if filePicker.mode == "song" then
    filePicker.update(true)
  end
end

function filePicker.upButtonDown()
  filePicker.upButtonUp()

  local function callback()
    filePickList:selectPreviousRow()
  end
  filePicker.upKeyTimer = pd.timer.keyRepeatTimerWithDelay(300, 75, callback)
end

function filePicker.downButtonDown()
  filePicker.downButtonUp()

  local function callback()
    filePickList:selectNextRow()
  end
  filePicker.downKeyTimer = pd.timer.keyRepeatTimerWithDelay(300, 75, callback)
end

function filePicker.upButtonUp()
  if filePicker.upKeyTimer ~= nil then
    filePicker.upKeyTimer:remove()
  end
end

function filePicker.downButtonUp()
  if filePicker.downKeyTimer ~= nil then
    filePicker.downKeyTimer:remove()
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
    for i = #val, 1, -1 do
      if val[i] ~= "samples/" and val[i] ~= "temp/" and val[i] ~= "songs/" then
        table.remove(val, i)
      end
    end
  end

  for i = 1, #val do
    if pd.file.isdir(currentPath .. val[i]) then
      if filePicker.mode == "song" and table.indexOfElement(pd.file.listFiles(currentPath .. val[i]), "song.json") ~= nil then
        val[i] = val[i] .. " (song)"
      end
    end
    val[i] = string.normalize(val[i])
  end

  if settings["foldersPrecedeFiles"] then
    local tempVal = table.shallowcopy(val)

    for i = #tempVal, 1, -1 do
      if string.sub(tempVal[i], #tempVal[i] - 5) ~= "(song)" then
        table.insert(val, 1, table.remove(val, table.indexOfElement(val, tempVal[i])))
      end
    end
  end
 
  if currentPath ~= "/" then
    table.insert(val, 1, "*Ā*")
  elseif filePicker.mode ~= "song" then
    table.insert(val, 1, "*Ą* record sample")
  end

  if filePicker.mode == "newsmp" and currentPath == "/" then
    table.insert(val, 1, "*ċ* edit sample")
  end

  return val
end

function filePicker.updateFiles()
  filePickList:set(filePicker.modifyDirContents(pd.file.listFiles(currentPath)))
  filePickList:setSelectedRow(1)
  filePickList:scrollToRow(1)
end

