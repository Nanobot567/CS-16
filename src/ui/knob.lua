-- knob ui class

class("Knob").extends()

function Knob:init(x, y, clicks, rot)
  self.x = x
  self.y = y
  self.clicks = 360 / clicks
  self.rotation = 0
  self.freeRotate = rot
end

function Knob:getCurrentClick()
  return math.round(self.rotation / self.clicks, 0)
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
  self.rotation = click * self.clicks
end

function Knob:adjust(amount, backwards)
  self.rotation = (((self.rotation + (amount) * backwards) % 360) + 360) % 360
end

function Knob:click(amount, backwards)
  if self.freeRotate == nil then
    self.rotation = math.normalize(self.rotation + ((amount * self.clicks) * backwards), 0, 360 - self.clicks)
  else
    self.rotation = ((self.rotation + ((amount * self.clicks) * backwards) % 360) + 360) % 360
  end
end

function Knob:draw(selected)
  if selected ~= nil and selected == true then
    gfx.drawRoundRect(self.x - 12, self.y - 12, 24, 24, 2)
  end
  knob:drawRotated(self.x, self.y, self.rotation)
  gfx.drawCircleAtPoint(self.x, self.y, 10)
end


