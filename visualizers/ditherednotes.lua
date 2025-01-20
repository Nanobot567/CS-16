-- dithered active notes

local DITHER_TYPE = gfx.image.kDitherTypeDiagonalLine

local img = gfx.image.new(20, 20)
local inst

local function ditheredNotesUpdate(data)
  for i = 1, 16 do
    inst = data["instruments"][i]
    if inst:isPlaying() then
      gfx.setColor(gfx.kColorXOR)

      gfx.pushContext(img)
      gfx.setColor(gfx.kColorBlack)
      gfx.fillRoundRect(0, 0, 20, 20, 2)
      gfx.popContext()

      gfx.setImageDrawMode(gfx.kDrawModeCopy)
      img:drawFaded((i * 25) - 22, 110, (instrumentTable[i]:getEnvelope():getValue()), DITHER_TYPE)

      gfx.setColor(gfx.kColorBlack)
    end
  end
end

return { "ditherednotes", ditheredNotesUpdate }
