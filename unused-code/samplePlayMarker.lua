-- this is unused code for the sampleEditScreen play marker.

sampleEditScreen.sampleImg = nil
sampleEditScreen.playMarkerAnimator = nil
sampleEditScreen.samplePlayer = nil
sampleEditScreen.endPixel = {0, 0}

function sampleEditScreen.open()
  
end

function sampleEditScreen.update()
  if (sampleEditScreen.samplePlayer:isPlaying() == false) and sampleEditScreen.playMarkerAnimator:ended() == false then
    local curval = sampleEditScreen.playMarkerAnimator:currentValue()
    sampleEditScreen.playMarkerAnimator = gfx.animator.new(0, curval, curval)
  end
end

function sampleEditScreen.resetAnimator()
  local diff = sampleEditScreen.trim[1]/300
  sampleEditScreen.playMarkerAnimator = gfx.animator.new(sampleEditScreen.sample:getLength()*1000, diff, sampleEditScreen.endPixel[1]-(diff*1.2)) -- FIX MARKER
end
