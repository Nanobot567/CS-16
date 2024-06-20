-- sample editor

sampleEditScreen = {}
sampleEditScreen.oldUpdate = nil
sampleEditScreen.sample = nil
sampleEditScreen.editedSample = nil
sampleEditScreen.callback = nil
sampleEditScreen.changeVal = 1000
sampleEditScreen.sampleLen = 0
sampleEditScreen.trim = { 0, 0 }
sampleEditScreen.side = 1 -- 1 = begin, 2 = end
sampleEditScreen.ctrPixel = 0

function sampleEditScreen.open(sample, callback, image)
  inScreen = true

  sampleEditScreen.sample = sample
  sampleEditScreen.sampleImg = image
  sampleEditScreen.editedSample = nil
  sampleEditScreen.callback = callback
  sampleEditScreen.changeVal = 1000
  sampleEditScreen.trim = { 0, 0 }
  sampleEditScreen.side = 1

  if image ~= nil then
    local done = false
    for x = 400, 0, -1 do
      for y = 40, 0, -1 do
        if image:sample(x, y) == gfx.kColorBlack then
          sampleEditScreen.ctrPixel = 400 - (x / 2)
          done = true
          break
        end
      end
      if done then
        break
      end
    end
  end

  sampleEditScreen.sampleLen = math.round(sample:getLength() * 44100, 0)

  sampleEditScreen.trim[2] = sampleEditScreen.sampleLen

  sampleEditScreen.editedSample = sampleEditScreen.sample:getSubsample(sampleEditScreen.trim[1], sampleEditScreen.trim
    [2])
  sampleEditScreen.samplePlayer = snd.sampleplayer.new(sampleEditScreen.editedSample)

  pd.inputHandlers.push(sampleEditScreen, true)
  sampleEditScreen.oldUpdate = pd.update
  pd.update = sampleEditScreen.update

  gfx.clear()

  sample:play()
end

function sampleEditScreen.update()
  local sidetext = "start"
  gfx.clear()
  local crank = pd.getCrankTicks(settings["cranksens"])
  local side = sampleEditScreen.side

  if crank ~= 0 then
    local otherside = 1 -- IS THAT A MINECRAFT REFERENCE????? :OOOO
    sampleEditScreen.trim[side] += sampleEditScreen.changeVal * crank
    sampleEditScreen.trim[side] = math.normalize(sampleEditScreen.trim[side], 0, sampleEditScreen.sampleLen)

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
    sampleEditScreen.editedSample = sampleEditScreen.sample:getSubsample(sampleEditScreen.trim[1],
      sampleEditScreen.trim[2])
    sampleEditScreen.samplePlayer:setSample(sampleEditScreen.editedSample)
    sampleEditScreen.samplePlayer:play()
  end

  if sampleEditScreen.side == 2 then
    sidetext = "end"
  end

  gfx.drawTextAligned("start: " .. sampleEditScreen.trim[1] .. ", end: " .. sampleEditScreen.trim[2], 200, 104,
    align.center)
  gfx.drawTextAligned("selected: " .. sidetext, 200, 120, align.center)
  gfx.drawTextAligned("a to save, b to discard", 200, 210, align.center)
  fnt8x8:drawTextAligned("changing frames by " .. sampleEditScreen.changeVal, 200, 231, align.center)

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
  sampleEditScreen.changeVal = math.normalize(sampleEditScreen.changeVal + 50, 50, 2000)
end

function sampleEditScreen.downButtonDown()
  sampleEditScreen.changeVal = math.normalize(sampleEditScreen.changeVal - 50, 50, 2000)
end

function sampleEditScreen.close(sample)
  pd.inputHandlers.pop()
  pd.update = sampleEditScreen.oldUpdate

  inScreen = false

  sampleEditScreen.callback(sample)
end

function sampleEditScreen.BButtonDown()
  sampleEditScreen.close(sampleEditScreen.sample)
end

function sampleEditScreen.AButtonDown()
  sampleEditScreen.close(sampleEditScreen.editedSample)
end

