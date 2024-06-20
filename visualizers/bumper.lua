-- bumper visualizer for cs-16 by nanobot567
--
-- sets the display offset so the screen bumps to the beat :sunglasses:

local function bumperUpdate(data)
  if data.beat then
    pd.display.setOffset(0, 3)
  elseif data.step % 8 == 2 then
    pd.display.setOffset(0, 1)
  else
    pd.display.setOffset(0, 0)
  end
end

return {"bumper", bumperUpdate}
