-- message box

messageBox = {}
messageBox.oldUpdate = nil
messageBox.callback = nil
--messageBox.message = ""

function messageBox.open(message, callback)
  gfx.clear()
  messageBox.callback = callback
  
  local w, h = gfx.getTextSizeForMaxWidth(message, 400)

  gfx.drawTextInRect(message, 0, 120 - (h / 2), 400, h, nil, nil, align.center)

  pd.inputHandlers.push(messageBox, true)
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

