-- drawing functions

function drawCursor()
  gfx.setColor(gfx.kColorXOR)
  gfx.setLineWidth(3)
  gfx.drawRect((cursor[1] * 25) + 1, (cursor[2] * 25) + 1, 23, 23)
  gfx.setLineWidth(1)
  gfx.setColor(gfx.kColorBlack)
end

function drawNoteOn()
  local modCurrentSeqStep = seq:getCurrentStep() / 8
  local markerX, markerY

  markerY = math.floor((modCurrentSeqStep - 1) / 16) * 25
  markerX = ((modCurrentSeqStep - 1) % 16) * 25

  local olddraw = gfx.getImageDrawMode()
  gfx.setImageDrawMode(gfx.kDrawModeNXOR)

  if seq:isPlaying() then
    noteOn:draw(markerX, markerY)
  end

  gfx.setImageDrawMode(olddraw)
end

local lasty

function drawSteps()
  currentSeqStep = seq:getCurrentStep()

  currentStepsImage:draw(0, 0)

  local activeStr = ""
  for i = 1, #tracks do
    activeStr = activeStr .. tostring(tracks[i]:getNotesActive())
  end

  gfx.drawTextAligned(activeStr, 200, lasty + 27, align.center)
end

function updateStepsImage() -- optimization, babyyyy!
  gfx.pushContext(currentStepsImage)

  gfx.clear(gfx.kColorClear)

  local markerX, markerY
  lasty = 0

  local olddraw = gfx.getImageDrawMode()
  gfx.setImageDrawMode(gfx.kDrawModeWhiteTransparent)

  for i = 1, stepCount / 8 do
    markerY = math.floor((i - 1) / 16) * 25
    markerX = (((i - 1) % 16) * 25)

    noteOff:draw(markerX, markerY)
    lasty = markerY
  end

  gfx.setImageDrawMode(olddraw)

  gfx.popContext()
end

function updateInstsImage()
  gfx.pushContext(currentInstsImage)

  gfx.clear(gfx.kColorClear)

  local notes = selectedTrack:getNotes()
  for i = 1, #notes do -- replace with 1 if no swing
    local step = (notes[i]["step"] / 8) - 1
    if step >= stepCount / 8 then
      break
    end
    local stepx, stepy
    if step > 15 then
      stepx = (step % 16) * 25
      stepy = (math.floor(step / 16)) * 25
    else
      stepx = (step) * 25
      stepy = 0
    end

    local olddraw = gfx.getImageDrawMode()
    gfx.setImageDrawMode(gfx.kDrawModeWhiteTransparent)

    notePlaced:fadedImage(notes[i]["velocity"], gfx.image.kDitherTypeBayer4x4):draw(stepx, stepy)

    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)

    -- this goofy ahh solution is used instead of drawTextInRect.
    -- mainly because...
    -- a) drawTextInRect is VERY memory intensive
    -- b) it's much faster

    if settings["showNoteNames"] then
      gfx.fillRect(stepx+4, stepy+4, 8, 17)

      local text = MIDInotes[notes[i]["note"] - 20]
      local tagoroctave = string.sub(text, 2, 2)

      if tagoroctave == "#" then
        fnt8x8:drawText(string.sub(text, 1, 2), stepx + 4, stepy + 4)
        fnt8x8:drawText(string.sub(text, 3, 3), stepx + 4, stepy + 12)
      else
        fnt8x8:drawText(string.sub(text, 1, 1), stepx + 4, stepy + 4)
        fnt8x8:drawText(tagoroctave, stepx + 4, stepy + 12)
      end
      --gfx.drawTextInRect(MIDInotes[notes[i]["note"]-20], stepx+4, stepy+4, 16, 20, nil, nil, nil, fnt8x8)
    end

    gfx.setImageDrawMode(olddraw)
  end

  gfx.popContext()
end

function drawInsts()
  local oldDraw = gfx.getImageDrawMode()

  gfx.setImageDrawMode(gfx.kDrawModeCopy)
  currentInstsImage:draw(0, 0)
  gfx.setImageDrawMode(oldDraw)
end

function drawFxTriangle(ptx, pty, direction, size, fill)
  local point1x, point1y, point2x, point2y

  if direction == nil then
    direction = "n"
  end

  if direction == "n" then
    point1x = ptx - size
    point1y = pty + size
    point2x = ptx + size
    point2y = pty + size
  elseif direction == "s" then
    point1x = ptx - size
    point1y = pty - size
    point2x = ptx + size
    point2y = pty - size
  elseif direction == "e" then
    point1x = ptx - size
    point1y = pty - size
    point2x = ptx - size
    point2y = pty + size
  elseif direction == "w" then
    point1x = ptx + size
    point1y = pty - size
    point2x = ptx + size
    point2y = pty + size
  end

  if fill then
    gfx.fillTriangle(ptx, pty, point1x, point1y, point2x, point2y)
  else
    gfx.drawTriangle(ptx, pty, point1x, point1y, point2x, point2y)
  end
end

function drawCenteredScaled(img, x, y, scale)
  local imgSizeW, imgSizeH = img:getSize()

  local modImg = gfx.image.new(imgSizeW * 2, imgSizeH * 2, gfx.kColorClear)
  gfx.pushContext(modImg)
  img:drawScaled(0, 0, scale)
  gfx.popContext()
  modImg:drawCentered(x, y)
end


-- visualizer particle class

class("Particle").extends()

function Particle:init()
  if x ~= nil then
    self.x = x
  else
    self.x = math.random(1, 400)
  end
  self.y = math.random(20, 220)
  self.xrestart = 410
  self.speed = math.random() + math.random(1, 1)
  self.radius = self.speed
end

function Particle:update()
  if self.x > self.xrestart then
    self.x = -20
    self.y = math.random(20, 220)
    self.speed = math.random() + math.random(1, 1)
    self.radius = self.speed
  else
    self.x += self.speed
  end

  gfx.fillCircleAtPoint(self.x, self.y, self.radius)
end
