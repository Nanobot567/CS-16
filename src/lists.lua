-- every listview

listviewContents = {}

listview = pd.ui.gridview.new(0, 10)
listview:setNumberOfRows(16)
listview:setCellPadding(0, 0, 5, 10)
listview:setContentInset(20, 20, 10, 10)

function listview:drawCell(section, row, column, selected, x, y, width, height)
  if selected then
    gfx.fillRoundRect(x, y, width, 20, 4)
    gfx.setImageDrawMode(gfx.kDrawModeNXOR)
  else
    gfx.setImageDrawMode(gfx.kDrawModeNXOR)
  end
  gfx.drawText(listviewContents[row], x + 4, y + 2)
end

function listview:set(t)
  listviewContents = t
  listview:setNumberOfRows(#t)
end

filePickListContents = {}

filePickList = pd.ui.gridview.new(0, 10)
filePickList:setNumberOfRows(1)
filePickList:setCellPadding(0, 0, 5, 10)
filePickList:setContentInset(20, 20, 15, 10)

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
  gfx.drawText(filePickListContents[row], x + 4, y + 2)
end

function filePickList:set(t)
  filePickListContents = t
  filePickList:setNumberOfRows(#t)
end

function filePickList:get()
  return filePickListContents
end

settingsListContents = {}

settingsList = pd.ui.gridview.new(0, 10)
settingsList:setNumberOfRows(1)
settingsList:setCellPadding(0, 0, 5, 10)
settingsList:setContentInset(20, 20, 15, 13)

function settingsList:drawCell(section, row, column, selected, x, y, width, height)
  if selected then
    gfx.fillRoundRect(x, y, width, 20, 4)
    gfx.setImageDrawMode(gfx.kDrawModeNXOR)
  else
    gfx.setImageDrawMode(gfx.kDrawModeNXOR)
  end
  gfx.drawText(settingsListContents[row], x + 4, y + 2)
end

function settingsList:set(t)
  settingsListContents = t
  settingsList:setNumberOfRows(#t)
end

function settingsList:get()
  return settingsListContents
end
