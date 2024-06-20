-- keyboard for text input

keyboardScreen = {}
keyboardScreen.oldUpdate = nil
keyboardScreen.callback = nil
keyboardScreen.askingForOK = false
keyboardScreen.prompt = ""
keyboardScreen.text = ""
keyboardScreen.limit = nil
keyboardScreen.origtext = ""

function keyboardScreen.open(prompt, text, limit, callback)
  inScreen = true

  text = string.normalize(text)

  keyboardScreen.callback = callback
  keyboardScreen.text = text
  keyboardScreen.origtext = text
  keyboardScreen.prompt = prompt
  keyboardScreen.askingForOK = false

  if limit == nil then
    limit = 100000
  end
  keyboardScreen.limit = limit

  pd.inputHandlers.push(keyboardScreen, true)
  keyboardScreen.oldUpdate = pd.update
  pd.update = keyboardScreen.update

  pd.keyboard.show(string.unnormalize(text))
end

function keyboardScreen.update()
  local rectWidth = 400 - pd.keyboard.width()
  gfx.clear()

  if keyboardScreen.askingForOK == false then
    gfx.drawTextInRect(keyboardScreen.prompt, 0, 0, rectWidth, 100, nil, nil, align.center)
    gfx.drawTextInRect(keyboardScreen.text, 0, 104, rectWidth, 136, nil, nil, align.center)
  else
    gfx.drawTextInRect("is this good?\n\na to confirm, b to redo, left to quit", 0, 0, rectWidth, 100, nil, nil,
      align.center)
    gfx.drawTextInRect(keyboardScreen.text, 0, 104, rectWidth, 136, nil, nil, align.center)
  end
end

function keyboardScreen.close()
  pd.inputHandlers.pop()
  pd.update = keyboardScreen.oldUpdate

  inScreen = false

  keyboardScreen.callback(string.unnormalize(keyboardScreen.text))
end

function pd.keyboard.keyboardWillHideCallback()
  keyboardScreen.askingForOK = true
end

function pd.keyboard.textChangedCallback()
  if #pd.keyboard.text <= keyboardScreen.limit then
    keyboardScreen.text = string.normalize(pd.keyboard.text)
  else
    pd.keyboard.text = string.sub(pd.keyboard.text, 1, keyboardScreen.limit)
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
    pd.keyboard.show(string.normalize(keyboardScreen.text))
  end
end

function keyboardScreen.leftButtonDown()
  keyboardScreen.text = "_EXITED_KEYBOĀRD"
  keyboardScreen.close()
end
