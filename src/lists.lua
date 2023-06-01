listviewContents = {}

listview = pd.ui.gridview.new(0, 10)
listview.backgroundImage = gfx.image.new(10,10,gfx.kColorWhite)
listview:setNumberOfRows(16)
listview:setCellPadding(0, 0, 5, 10)
listview:setContentInset(24, 24, 13, 11)

function listview:drawCell(section, row, column, selected, x, y, width, height)

  if selected then
    gfx.fillRoundRect(x, y, width, 20, 4)
    gfx.setImageDrawMode(gfx.kDrawModeNXOR)
  else
    gfx.setImageDrawMode(gfx.kDrawModeNXOR)
  end
  gfx.drawText(listviewContents[row], x+4, y+2, width, height, nil, "...", align.center)
end

function listview:set(t)
  listviewContents = t
  listview:setNumberOfRows(#t)
end

filePickListContents = {}

filePickList = pd.ui.gridview.new(0, 10)
filePickList.backgroundImage = gfx.image.new(10,10,gfx.kColorWhite)
filePickList:setNumberOfRows(1)
filePickList:setCellPadding(0, 0, 5, 10)
filePickList:setContentInset(24, 24, 13, 11)

function filePickList:drawCell(section, row, column, selected, x, y, width, height)
  if filePickListContents[row] == ".." then
    filePickListContents[row] = "Ā"
  end

  if selected then
    gfx.fillRoundRect(x, y, width, 20, 4)
    gfx.setImageDrawMode(gfx.kDrawModeNXOR)
  else
    gfx.setImageDrawMode(gfx.kDrawModeNXOR)
  end
  gfx.drawText(filePickListContents[row], x+4, y+2, width, height, nil, "...", align.center)
end

function filePickList:set(t)
  filePickListContents = t
  filePickList:setNumberOfRows(#t)
end


fxListContents = {}

fxList = pd.ui.gridview.new(0, 10)
fxList.backgroundImage = gfx.image.new(10,10,gfx.kColorWhite)
fxList:setNumberOfRows(1)
fxList:setCellPadding(0, 0, 5, 10)
fxList:setContentInset(24, 24, 13, 11)

function fxList:drawCell(section, row, column, selected, x, y, width, height)
  if fxListContents[row] == ".." then
    fxListContents[row] = "Ā"
  end

  if selected then
    gfx.fillRoundRect(x, y, width, 20, 4)
    gfx.setImageDrawMode(gfx.kDrawModeNXOR)
  else
    gfx.setImageDrawMode(gfx.kDrawModeNXOR)
  end
  gfx.drawText(fxListContents[row], x+4, y+2, width, height, nil, "...", align.center)
end

function fxList:set(t)
  fxListContents = t
  fxList:setNumberOfRows(#t)
end


settingsListContents = {}

settingsList = pd.ui.gridview.new(0, 10)
settingsList.backgroundImage = gfx.image.new(10,10,gfx.kColorWhite)
settingsList:setNumberOfRows(1)
settingsList:setCellPadding(0, 0, 5, 10)
settingsList:setContentInset(24, 24, 13, 11)

function settingsList:drawCell(section, row, column, selected, x, y, width, height)
  if selected then
    gfx.fillRoundRect(x, y, width, 20, 4)
    gfx.setImageDrawMode(gfx.kDrawModeNXOR)
  else
    gfx.setImageDrawMode(gfx.kDrawModeNXOR)
  end
  gfx.drawText(settingsListContents[row], x+4, y+2, width, height, nil, "...", align.center)
end

function settingsList:set(t)
  settingsListContents = t
  settingsList:setNumberOfRows(#t)
end
