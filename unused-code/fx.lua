-- unused code for fx support.

-- in uiToolkit

fxScreen = {}
fxScreen.inst = nil
fxScreen.instLoc = nil
fxScreen.oldUpdate = nil
fxScreen.ui = {
  {Knob(30,30,11),Knob(90,30,11),Knob(150,30,11)}, -- bitcrush
  {Knob(30,30,21),Knob(90,30,11)}, -- opf
  {Knob(30,30,5),Knob(90,30,21),Knob(150,30,11),Knob(210,30,11),Knob(270,30,11)}, -- tpf
  {Knob(30,30,11),Knob(90,30,11)}, -- ringmod
  {Knob(30,30,11),Knob(90,30,11),Knob(150,30,11),Knob(210,30,11)}, -- od
  {Knob(30,30,11),Knob(90,30,11),Knob(150,30,11),Knob(210,30,11),Knob(270,30,11)} -- delay
}
fxScreen.fx = {snd.bitcrusher.new,snd.onepolefilter.new,snd.twopolefilter.new,snd.ringmod.new,snd.overdrive.new,snd.delayline.new}
fxScreen.fxNames = {"bitcrusher","one pole filter","two pole filter","ringmod","overdrive","delayline"}
fxScreen.appliedFx = {}
fxScreen.appliedFxNames = {}
fxScreen.appliedFxParams = {}
fxScreen.edit = 0
fxScreen.currentElem = 1

function fxScreen.open()
  --fxScreen.inst = inst
  --fxScreen.instLoc = table.find(instrumentTable,inst)

  fxList:set(table.join(fxScreen.appliedFxNames, {"add effect +"}))
  fxList:setSelectedRow(1)

  pd.inputHandlers.push(fxScreen,true)
  fxScreen.oldUpdate = pd.update
  pd.update = fxScreen.update
end

function fxScreen.update()
  gfx.clear()

  local crank = pd.getCrankTicks(settings["cranksens"])

  if crank ~= 0 and fxScreen.edit ~= 0 then
    local elem = fxScreen.currentElem
    local knob = fxScreen.ui[fxScreen.edit][elem]
    local eff = fxScreen.appliedFx[fxScreen.edit]
    local effName = fxScreen.appliedFxNames[fxScreen.edit]
    knob:click(1,crank)
    print(knob:getCurrentClick())

    local click = knob:getCurrentClick()

    if effName == "bitcrusher" then
      if elem == 1 then
        eff:setAmount((click-1)*0.1)
      elseif elem == 2 then
        eff:setUndersampling((click-1)*0.1)
      else
        eff:setMix((click)*0.1)
      end
    elseif effName == "one pole filter" then
      if elem == 1 then
        eff:setParameter((click-11)*0.1)
      elseif elem == 2 then
        eff:setMix((click)*0.1)
      end
    elseif effName == "two pole filter" then
      local types = {"lowpass","highpass","bandpass","notch","peq","lowshelf","highshelf"}
      if elem == 1 then
        eff:setType(types[click+1])
      elseif elem == 2 then
        eff:setFrequency(click*1000)
      elseif elem == 3 then
        eff:setResonance(click*0.1)
      elseif elem == 4 then
        eff:setGain(click*0.5)
      elseif elem == 5 then
        eff:setMix((click)*0.1)
      end
    elseif effName == "ringmod" then
      if elem == 1 then
        eff:setFrequency(click*5)
      elseif elem == 2 then
        eff:setMix((click)*0.1)
      end
    elseif effName == "overdrive" then
      if elem == 1 then
        eff:setGain(click*2)
      elseif elem == 2 then
        eff:setLimit(click*2)
      elseif elem == 3 then
        eff:setOffset(click*2)
      elseif elem == 4 then
        eff:setMix((click)*0.1)
      end
    end
  end

  if fxScreen.edit ~= 0 then
    local sel = false
    for i = 1, #fxScreen.ui[fxScreen.edit], 1 do
      local sel = nil
      if i == fxScreen.currentElem then
        sel = true
      end
      fxScreen.ui[fxScreen.edit][i]:draw(sel)
    end
  else
    fxList:drawInRect(0,0,400,240)
  end
end

function fxScreen.close()
  pd.inputHandlers.pop()
  pd.update = fxScreen.oldUpdate
end

function fxScreen.BButtonDown()
  if fxScreen.edit == 0 then
    fxScreen.close()
  else
    fxScreen.edit = 0
  end
end

function fxScreen.AButtonDown()
  local selRow = fxList:getSelectedRow()
  if fxListContents[selRow] == "add effect +" then
    fxList:set(fxScreen.fxNames)
    fxList:setSelectedRow(1)
  elseif table.find(fxListContents, "add effect +") == -1 then
    local eff
    if fxListContents[selRow] == "delayline" then
      eff = fxScreen.fx[selRow](0.3)
    else
      eff = fxScreen.fx[selRow]()
    end
    table.insert(fxScreen.appliedFxNames,fxScreen.fxNames[selRow])
    --eff:setMix(1)
    --eff:setUndersampling(0.75)

    --snd.addEffect(eff)
    snd.addEffect(eff)
    table.insert(fxScreen.appliedFx, eff)
    fxList:set(table.join(fxScreen.appliedFxNames, {"add effect +"}))
    fxList:setSelectedRow(1)
  else
    fxScreen.edit = table.find(fxScreen.fxNames,fxScreen.appliedFxNames[selRow])
  end
end

function fxScreen.downButtonDown()
  fxList:selectNextRow()
end

function fxScreen.upButtonDown()
  fxList:selectPreviousRow()
end

function fxScreen.rightButtonDown()
  if fxListContents[fxList:getSelectedRow()] ~= "add effect +" and fxScreen.edit == 0 then
    -- remove effect name and eff from two lists
    snd.removeEffect(fxScreen.appliedFx[fxList:getSelectedRow()])
    table.remove(fxScreen.appliedFx[fxList:getSelectedRow()])
    table.remove(fxScreen.appliedFxNames[fxList:getSelectedRow()])
  else
    fxScreen.currentElem += 1
  end
end

function fxScreen.leftButtonDown()
  fxScreen.currentElem -= 1
end


