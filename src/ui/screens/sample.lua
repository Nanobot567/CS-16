-- sampler

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
sampleScreen.waveformLastXY = { 0, 20 }

local state = "press A to arm..."

function sampleScreen.open(callback)
  inScreen = true

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
  sampleScreen.waveformLastXY = { 0, 20 }
  state = "press A to arm..."


  if callback ~= nil then
    sampleScreen.callback = callback
  end

  if settings["stoponsample"] == true then
    seq:stop()
    seq:allNotesOff()
  end

  pd.inputHandlers.push(sampleScreen, true)
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
    local y = 40 + ((-snd.micinput.getLevel()) * 40)
    gfx.pushContext(sampleScreen.waveformImage)
    gfx.drawLine(lastxy[1], lastxy[2], x, y)
    gfx.popContext()
    sampleScreen.waveformLastXY = { x, y }
    sampleScreen.waveformImage:draw(0, 55)
  end

  gfx.drawTextAligned(state, 200, 0, align.center)
  gfx.drawRect(50, 110, 300, 20)
  gfx.fillRect(50, 110, snd.micinput.getLevel() * 300, 20)
  fnt8x8:drawTextAligned(math.round(snd.micinput.getLevel(), 2), 200, 116, align.center)
  fnt8x8:drawTextAligned("will start recording from " .. snd.micinput.getSource() .. " if volume = " ..
    sampleScreen.recAt, 200, 231, align.center)
  gfx.drawTextAligned(tostring(sampleScreen.recTimer.currentTime / 1000) .. " / 5.0", 200, 20, align.center)
  pd.timer.updateTimers()
end

function sampleScreen.close()
  pd.inputHandlers.pop()
  pd.update = sampleScreen.oldUpdate
  if settings["saveWaveforms"] == true then
    sampleScreen.callback({ sampleScreen.sample, sampleScreen.waveformImage:copy() })
  else
    sampleScreen.callback(sampleScreen.sample)
  end

  inScreen = false

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
    gfx.drawTextInRect("save?\n\na to save, b to redo, right to hear again", 20, 85, 360, 200, nil, nil, align.center)
    sampleScreen.waveformImage:drawCentered(400 - (sampleScreen.waveformAnimator:currentValue() / 2), 45)
    pd.stop()
    ::continue::
  end)
end

function sampleScreen.AButtonDown()
  if sampleScreen.waitForButton == true then
    pd.start()
    displayInfo("saved as " .. listview:getSelectedRow() .. ".pda")
    sampleScreen.sample:save(songdir .. listview:getSelectedRow() .. ".pda")
    if settings["savewavs"] == true then
      sampleScreen.sample:save(songdir .. listview:getSelectedRow() .. ".wav")
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
    sampleScreen.waveformLastXY = { 0, 20 }

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
  sampleScreen.recAt = math.round(sampleScreen.recAt, 2)
  sampleScreen.recAt = math.max(0.0, math.min(1.0, (sampleScreen.recAt)))
end

