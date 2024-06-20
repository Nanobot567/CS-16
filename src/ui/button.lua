-- button ui class

class("Button").extends()

function Button:init(x, y, w, h, text, smallfont)
  self.drawSmall = smallfont
  self.x = x
  self.y = y
  self.w = w
  self.h = h
  self.text = text
end

function Button:draw(selected, pressed)
  local w = self.w
  local h = self.h

  if w == nil and h == nil then
    if self.drawSmall == true then
      w = fnt8x8:getTextWidth(self.text) + 5
    else
      w = fnt:getTextWidth(self.text) + 5
    end
    h = 13
  end

  if pressed == true then
    gfx.setColor(gfx.kColorWhite)
  end

  local fontdraw = fnt
  gfx.drawRect(self.x, self.y, w, h)

  if pressed == true then
    gfx.setColor(gfx.kColorBlack)
  end

  if selected ~= nil then
    gfx.drawRoundRect(self.x - 3, self.y - 3, w + 6, h + 6, 2)
  end

  if self.drawSmall ~= nil then
    fontdraw = fnt8x8
  end
  fontdraw:drawText(self.text, self.x + 2, self.y + 2)
end

