-- ramona visualizer for cs-16 by nanobot567
--
-- fox who bops her head to the beat!

local SCALE = 2 -- set image scale here!
local TRACK = 0 -- if you would like to have her bop her head to a track's notes, set that here! (set to 0 to revert)


local ramona_open = gfx.image.new("visualizers/ramona/images/open"):scaledImage(SCALE)
local ramona_blink = gfx.image.new("visualizers/ramona/images/blink"):scaledImage(SCALE)
local ramona_talk = gfx.image.new("visualizers/ramona/images/talk"):scaledImage(SCALE)
local ramona_twitch = gfx.image.new("visualizers/ramona/images/twitch"):scaledImage(SCALE)
local ramona_closed = gfx.image.new("visualizers/ramona/images/closed"):scaledImage(SCALE)
local ramona_closed2 = gfx.image.new("visualizers/ramona/images/closed-2"):scaledImage(SCALE)

local ramonaWidth, ramonaHeight = ramona_open:getSize()
local drawHeight = 220 - ramonaHeight

local blinkTimer = 0
local twitchTimer = 0
local talkTimer = 0

local speechOptions = {
  "sounding good!",
  "no, keep playing\nthe song!",
  "i like this one\na lot.",
  "bangerrrrr.",
  "be sure to save,\nhaha.",
  "thanks for enabling\nme, by the way!",
  "turn it up!!",
  "we getting out of\nthe playdate with\nthis one.",
  "let. them. cook!!",
  "betcha didn't know\nthere's lore behind\ncs-16...",
  "hopefully i don't\nsound like a\nbroken record, haha...",
  "anyway, hope you've\n been doing\nalright!",
  "man, it gets boring\nin here\nsometimes..."
}
local speech = ""
local lastSpeech = "blannnnk"
local speechHeightAdjustment = 0

-- by default bops head on every quarter note

local animateCheck1 = function (data) -- check if you can play first frame of animation
  return data.beat
end

local animateCheck2 = function (data) -- second frame
  return data.step % 8 == 2 and seq:isPlaying()
end

if TRACK ~= 0 then
  animateCheck1 = function(data)
    if #data.tracks[TRACK]:getNotes(data.sequencer:getCurrentStep(), data.sequencer:getCurrentStep() + 8) > 0 and seq:isPlaying() then
      return true
    end
    return false
  end

  animateCheck2 = function(data)
    if #data.tracks[TRACK]:getNotes(data.sequencer:getCurrentStep() - 8, data.sequencer:getCurrentStep()) > 0 and seq:isPlaying() then
      return true
    end
    return false
  end
end


local function ramonaUpdate(data)
  gfx.pushContext()

  if data.settings["dark"] then
    gfx.setColor(gfx.kColorBlack)
  else
    gfx.setColor(gfx.kColorWhite)
  end

  gfx.fillRect(0, drawHeight, ramonaWidth, ramonaHeight)

  gfx.setImageDrawMode(gfx.kDrawModeNXOR)
  if animateCheck1(data) then
    ramona_closed2:draw(0, drawHeight)
  elseif animateCheck2(data) then
    ramona_closed:draw(0, drawHeight)
  else
    if seq:isPlaying() then
      ramona_open:draw(0, drawHeight)
      blinkTimer, twitchTimer, talkTimer = 0, 0, 0
    else
      if twitchTimer == 0 and blinkTimer == 0 and talkTimer == 0 then
        if math.random(1, 120) == 1 then
          blinkTimer = 4
        elseif math.random(1, 210) == 1 then
          twitchTimer = 2
        elseif math.random(1, 1000) == 1 then
          talkTimer = 250
          speech = speechOptions[math.random(1, #speechOptions)]
          while speech == lastSpeech do
            speech = speechOptions[math.random(1, #speechOptions)]
          end
          _, speechHeightAdjustment = gfx.getTextSizeForMaxWidth(speech, 400, nil, fnt8x8)
          speechHeightAdjustment = speechHeightAdjustment / 2
        end
      end

      if blinkTimer > 0 then
        blinkTimer -= 1
        ramona_blink:draw(0, drawHeight)
      elseif twitchTimer > 0 then
        twitchTimer -= 1
        ramona_twitch:draw(0, drawHeight)
      elseif talkTimer > 0 then
        talkTimer -= 1
        ramona_talk:draw(0, drawHeight)
        rains1x:drawText(speech, ramonaWidth + 2, (drawHeight + (ramonaHeight / 2) - speechHeightAdjustment))
      else
        ramona_open:draw(0, drawHeight)
      end
    end
  end
  gfx.popContext()
end

return {"ramona", ramonaUpdate}
