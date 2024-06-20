-- lines visualizer for cs-16 by nanobot567
--
-- speedlines looking thing


class("LineParticle").extends()

function LineParticle:init(x, minlen, maxlen)
  if x ~= nil then
    self.x = x
  else
    self.x = math.random(1, 400)
  end

  if minlen then
    self.minlen = minlen
  else
    self.minlen = 4
  end

  if maxlen then
    self.maxlen = maxlen
  else
    self.maxlen = 12
  end

  self.y = math.random(20, 220)
  self.xrestart = 410
  self.speed = math.random(8, 16)
  self.length = self.speed + math.random(self.minlen, self.maxlen)
end

function LineParticle:update(playing)
  if self.x > self.xrestart and playing then
    self.x = -20
    self.y = math.random(20, 220)
    self.speed = math.random(8, 16)
    self.length = self.speed + math.random(self.minlen, self.maxlen)
  else
    self.x += self.speed
  end

  gfx.setLineWidth(2)

  if self.x + self.length > 0 then
    gfx.drawLine(self.x, self.y, self.x + self.length, self.y)
  end
  gfx.setLineWidth(1)
end

function LineParticle:move(x, y)
  if x then
    self.x = x
  end

  if y then
    self.y = y
  end
end


local lines = {}

for i = 1, 8 do
  table.insert(lines, LineParticle(nil, 20, 40))
end

function linesUpdate(data)
  for i, v in ipairs(lines) do
    v:update(data.playing)
  end
end

return {"lines", linesUpdate}
