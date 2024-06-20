-- cs-16 effects!!

class("CS16effect").extends()

validEffects = {
  ["tape"] = "",
  ["wtr"] = "",
  ["echo"] = "",
  ["ovd"] = ""
}

validEffectsNames = {}

for k, v in pairs(validEffects) do
  table.insert(validEffectsNames, k)
end

appliedFX = {}

function CS16effect:init(name, effects, intensities, params, notches)
  self.name = name
  self.effects = effects
  self.intesities = intensities
  self.params = params

  if notches == nil then
    self.notches = 10
  else
    self.notches = notches
  end

  self.overallValue = 0.0

  self.isEnabled = false
  self.locked = false

  self.paramsValues = {}

  local initVal

  for i, v in ipairs(self.params) do
    if type(intensities[i]) == "table" then
      initVal = intensities[i][1]
    else
      initVal = intensities[i]
    end
    self.paramsValues[i] = initVal
  end
end

function CS16effect:toggle()
  self.isEnabled = not self.isEnabled
  if self.isEnabled then
    for i, v in ipairs(self.effects) do
      playdate.sound.addEffect(v)
    end
  else
    for i, v in ipairs(self.effects) do
      playdate.sound.removeEffect(v)
    end
  end
end

function CS16effect:enable()
  if not self.locked then
    self:disable()

    for i, v in ipairs(self.effects) do
      playdate.sound.addEffect(v)
    end

    self.isEnabled = true
  end
end

function CS16effect:disable()
  if not self.locked then
    for i, v in ipairs(self.effects) do
      playdate.sound.removeEffect(v)
    end

    self.isEnabled = false
  end
end

function CS16effect:getEnabled()
  return self.isEnabled
end

function CS16effect:notch(num)
  if num == nil then
    num = 1
  end

  for i, effect in ipairs(self.effects) do
    local intensity = self.intesities[i]
    local lowIntensity = 0
    if type(intensity) == "table" then
      lowIntensity = intensity[1]
      intensity = intensity[2]
    end

    if lowIntensity > intensity then
      lowIntensity, intensity = intensity, lowIntensity
    end

    self:modifyParam(effect, self.params[i], ((intensity - lowIntensity) / self.notches) * num, i)
  end

  self.overallValue = math.round(math.normalize(self.overallValue + (0.1 * num), 0, 1), 2)
end

function CS16effect:modifyParam(effect, param, value, index)
  if index == nil then
    index = table.indexOfElement(self.effects, effect)
  end

  local curVal = self.paramsValues[index]

  local lowIntensity = 0
  local intensity = self.intesities[index]

  if type(intensity) == "table" then
    lowIntensity = self.intesities[index][1]
    intensity = self.intesities[index][2]
  end

  if lowIntensity > intensity then
    lowIntensity, intensity = intensity, lowIntensity
    value *= -1
  end

  self.paramsValues[index] = math.round(math.normalize(value + curVal, lowIntensity, intensity), 2)

  curVal = self.paramsValues[index]

  -- parmasean

  if param == "mix" then
    effect:setMix(curVal)
  elseif param == "gain" then
    effect:setGain(curVal)
  elseif param == "limit" then
    effect:setLimit(curVal)
  elseif param == "amount" then
    effect:setAmount(curVal)
  elseif param == "undersampling" then
    effect:setUndersampling(curVal)
  elseif param == "frequency" then
    effect:setFrequency(curVal)
  end
end

function CS16effect:getOverallValue()
  return self.overallValue
end

function CS16effect:setName(name)
  self.name = name
end

function CS16effect:getName()
  return self.name
end

function CS16effect:setLocked(locked)
  if locked == nil then
    locked = true
  end

  self.locked = locked
end

function CS16effect:getLocked()
  return self.locked
end

local tapeHiPass = playdate.sound.twopolefilter.new("hipass")
tapeHiPass:setFrequency(700)
tapeHiPass:setMix(0)

local tapeLoPass = playdate.sound.twopolefilter.new("lopass")
tapeLoPass:setFrequency(1300)
tapeLoPass:setMix(0)

local tapeOverdrive = playdate.sound.overdrive.new()
tapeOverdrive:setGain(1)
tapeOverdrive:setLimit(2)
tapeOverdrive:setMix(0.3)


local bitcrushBitcrush = playdate.sound.bitcrusher.new()
bitcrushBitcrush:setAmount(0.6)
bitcrushBitcrush:setUndersampling(0.4)
bitcrushBitcrush:setMix(1)


local waterLoPass = playdate.sound.twopolefilter.new("lopass")
waterLoPass:setFrequency(1300)
waterLoPass:setMix(0)


local overdriveOverdrive = playdate.sound.overdrive.new()
overdriveOverdrive:setLimit(2)
overdriveOverdrive:setGain(2)
overdriveOverdrive:setMix(0)

-- if you can ever figure out how to get it to stay on beat...
-- local testEffect4 = playdate.sound.delayline.new(0.05)

-- for i=0, 5 do
--   testEffect4:addTap(i * 0.01)
-- end

-- testEffect4:setFeedback(0.3)
-- testEffect4:setMix(0)

tapeEffect = CS16effect("tape", { tapeHiPass, tapeLoPass, tapeOverdrive }, { 1, 1, { 0.3, 0.8 } },
  { "mix", "mix", "mix" },
  10)
bitcrushEffect = CS16effect("btc", { bitcrushBitcrush, bitcrushBitcrush }, { { 0.6, 0.9 }, { 0.4, 0.85 } },
  { "amount", "undersampling" }, 10)
waterEffect = CS16effect("wtr", { waterLoPass, waterLoPass }, { { 1300, 800 }, 1 },
  { "frequency", "mix" }, 10)
overdriveEffect = CS16effect("ovd", { overdriveOverdrive, overdriveOverdrive, overdriveOverdrive }, { 1, 3, { 2, 1.2 } },
  { "mix", "gain", "limit" }, 10)

tapeEffect:notch(5)
bitcrushEffect:notch(5)
waterEffect:notch(5)
overdriveEffect:notch(5)

CS16effects = { tapeEffect, bitcrushEffect, waterEffect, overdriveEffect }
