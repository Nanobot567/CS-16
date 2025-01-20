-- settings

settingsScreen = {}
settingsScreen.subMenu = ""
settingsScreen.oldUpdate = nil
settingsScreen.animator = nil
settingsScreen.locationStack = {}

local crankDockList = { "pattern", "track", "fx", "song", "none" }

function settingsScreen.updateOutputs()
  if settings["output"] < 3 then
    settings["output"] = settings["output"] + 1
  else
    settings["output"] = 0
    snd.setOutputsActive(false, true)
  end
  if settings["output"] == 1 then
    snd.setOutputsActive(true, false)
  elseif settings["output"] == 2 then
    snd.setOutputsActive(true, true)
  elseif settings["output"] == 3 then
    local state = snd.getHeadphoneState()
    snd.setOutputsActive(state, not state)
  end
end

function settingsScreen.open()
  inScreen = true

  settingsScreen.updateSettings()

  pd.getSystemMenu():removeAllMenuItems()

  settingsList:setSelectedRow(1)
  settingsList:scrollToRow(1)

  settingsScreen.animator = gfx.animator.new(200, 200, 0, pd.easingFunctions.outQuart)

  pd.inputHandlers.push(settingsScreen, true)
  settingsScreen.oldUpdate = pd.update
  pd.update = settingsScreen.update
end

function settingsScreen.update()
  if settingsList.needsDisplay or settingsScreen.animator:ended() == false
  then
    gfx.clear()
    settingsList:drawInRect(settingsScreen.animator:currentValue(), 0, 400, 240)

    if settingsScreen.subMenu == "" then
      fnt8x8:drawTextAligned("settings", 200, 0, align.center)
    else
      fnt8x8:drawTextAligned("settings/" .. string.sub(settingsScreen.subMenu, 1, #settingsScreen.subMenu - 1), 200, 0,
        align.center)
    end
    fnt8x8:drawTextAligned("cs-16 version " .. pd.metadata.version .. ", build " .. pd.metadata.buildNumber, 200, 231,
      align.center)
  end

  pd.timer.updateTimers()
end

function settingsScreen.close()
  settingsScreen.animator = nil
  pd.inputHandlers.pop()
  pd.update = settingsScreen.oldUpdate

  applyMenuItems("song")

  inScreen = false
end

function settingsScreen.upFolder()
  local oldmenu = settingsScreen.subMenu

  if oldmenu == "ui/visualizer/" then
    settingsScreen.subMenu = "ui/"
  else
    settingsScreen.subMenu = ""
  end
  settingsScreen.updateSettings()
  settingsList:setSelectedRow(table.remove(settingsScreen.locationStack))
  settingsList:scrollToTop()
  settingsScreen.animator = gfx.animator.new(200, -200, 0, pd.easingFunctions.outQuart)
end

function settingsScreen.downButtonDown()
  settingsList:selectNextRow()
end

function settingsScreen.upButtonDown()
  settingsList:selectPreviousRow()
end

function settingsScreen.leftButtonDown()
  local row = settingsList:getSelectedRow()

  if row == 3 and settingsScreen.subMenu == "general/" then
    settingsScreen.updateOutputs()
  elseif row == 4 and settingsScreen.subMenu == "general/" then
    settings["cranksens"] = table.cycle(crankSensList, settings["cranksens"], true)
  elseif row == 6 and settingsScreen.subMenu == "behavior/" then
    settings["crankDockedScreen"] = table.cycle(crankDockList, settings["crankDockedScreen"], true)
  end
  settingsScreen.updateSettings()
end

function settingsScreen.rightButtonDown()
  local row = settingsList:getSelectedRow()

  if row == 3 and settingsScreen.subMenu == "general/" then
    settingsScreen.updateOutputs()
  elseif row == 4 and settingsScreen.subMenu == "general/" then
    settings["cranksens"] = table.cycle(crankSensList, settings["cranksens"])
  elseif row == 5 and settingsScreen.subMenu == "behavior/" then
    settings["crankDockedScreen"] = table.cycle(crankDockList, settings["crankDockedScreen"])
  end
  settingsScreen.updateSettings()
end

function settingsScreen.BButtonDown()
  if settingsScreen.subMenu == "" then
    settingsScreen.close()
  else
    settingsScreen.upFolder()
  end
end

function settingsScreen.AButtonDown()
  local row = settingsList:getSelectedRow()
  local text = settingsListContents[settingsList:getSelectedRow()]

  local refresh = true

  if settingsScreen.subMenu == "" then
    settingsScreen.subMenu = text
    settingsList:setSelectedRow(1)
    settingsScreen.animator = gfx.animator.new(200, 200, 0, pd.easingFunctions.outQuart)

    table.insert(settingsScreen.locationStack, row)
  else
    if text == "*Ā*" then
      settingsScreen.upFolder()
      refresh = false
    end

    if settingsScreen.subMenu == "ui/" then
      if row == 2 then
        settings["dark"] = not settings["dark"]
        pd.display.setInverted(settings["dark"])
      elseif row == 3 then
        settingsScreen.subMenu = "ui/visualizer/"
        settingsList:setSelectedRow(1)
        settingsScreen.animator = gfx.animator.new(200, 200, 0, pd.easingFunctions.outQuart)

        table.insert(settingsScreen.locationStack, row)
      elseif row == 4 then
        settings["num/max"] = not settings["num/max"]
      elseif row == 5 then
        settings["showNoteNames"] = not settings["showNoteNames"]
      elseif row == 6 then
        settings["screenAnimation"] = not settings["screenAnimation"]
      elseif row == 7 then
        settings["useSystemFont"] = not settings["useSystemFont"]
        if settings["useSystemFont"] == true then
          fnt = rains2x
          fnt8x8 = rains1x
        else
          fnt = gfx.font.new("fnt/modified-tron")
          fnt8x8 = gfx.font.new("fnt/modified-tron-8x8")
        end
        gfx.setFont(fnt)

        buttons = {
          Button(5, 5, nil, nil, "back", true),
          Button(333 - (fnt8x8:getTextWidth("toggle") / 2), 53, nil, nil, "toggle", true),
          Button(53 - (fnt8x8:getTextWidth("select") / 2), 125, nil, nil, "select", true),
          Button(143 - (fnt8x8:getTextWidth("play") / 2), 125, nil, nil, "play", true)
        }

        allElems = { buttons[1], knobs[1], knobs[2], knobs[3], knobs[4], knobs[5], buttons[2], buttons[3], buttons[4],
          knobs[6], knobs[7], knobs[8], knobs[9] }
      elseif row == 8 then
        settings["logscreens"] = not settings["logscreens"]
      elseif row == 9 then
        settings["fxvfx"] = not settings["fxvfx"]
      elseif row == 10 then
        if settings["50fps"] == false then
          messageBox.open(
            "warning!\n\nrunning cs-16 at 50fps will reduce your battery life, but improve performance.\n\nare you sure you want to enable this?\n\na = yes, b = no",
            function(ans)
              if ans == "yes" then
                settings["50fps"] = not settings["50fps"]
                if settings["50fps"] == true then
                  pd.display.setRefreshRate(50)
                else
                  pd.display.setRefreshRate(30)
                end
              end
              settingsScreen.updateSettings()
            end)
        else
          settings["50fps"] = not settings["50fps"]
          pd.display.setRefreshRate(30)
        end
      end
    elseif settingsScreen.subMenu == "ui/visualizer/" then
      if text ~= "----- external -----" then
        text = pd.string.trimTrailingWhitespace(string.split(text, ":")[1])

        settings["visualizer"][text] = not settings["visualizer"][text]
      end
    elseif settingsScreen.subMenu == "behavior/" then
      if row == 2 then
        settings["playonload"] = not settings["playonload"]
      elseif row == 3 then
        settings["stoponsample"] = not settings["stoponsample"]
      elseif row == 4 then
        settings["smallerTempoIncrements"] = not settings["smallerTempoIncrements"]
      elseif row == 5 then
        settings["stopontempo"] = not settings["stopontempo"]
      elseif row == 6 then
        settings["crankDockedScreen"] = table.cycle(crankDockList, settings["crankDockedScreen"])
      end
    elseif settingsScreen.subMenu == "recording/" then
      if row == 8 then
        local quant = settings["recordQuantization"]
        if quant == 1 then -- every #th note
          settings["recordQuantization"] = 2
        elseif quant == 2 then
          settings["recordQuantization"] = 4
        elseif quant == 4 then
          settings["recordQuantization"] = 1
        end
      elseif row > 1 then
        keyboardScreen.open("enter a new track number for this button (1-16):", "", 2, function(t)
          local num = tonumber(t)
          if num ~= nil then
            if num > 0 and num < 17 then
              if row == 2 then
                settings["aRecTrack"] = num
              elseif row == 3 then
                settings["bRecTrack"] = num
              elseif row == 4 then
                settings["upRecTrack"] = num
              elseif row == 5 then
                settings["downRecTrack"] = num
              elseif row == 6 then
                settings["leftRecTrack"] = num
              elseif row == 7 then
                settings["rightRecTrack"] = num
              end
              settingsScreen.updateSettings()
            end
          end
        end)
      end
    elseif settingsScreen.subMenu == "general/" then
      if row == 2 then
        keyboardScreen.open("enter new author name:", settings["author"], 15, function(t)
          if t ~= "_EXITED_KEYBOĀRD" then
            settings["author"] = t
            if songdir == "temp/" then
              songAuthor = t
            end
            settingsScreen.updateSettings()
          end
        end)
      elseif row == 3 then
        settingsScreen.updateOutputs()
      elseif row == 4 then
        settings["cranksens"] = table.cycle(crankSensList, settings["cranksens"])
      elseif row == 5 then
        settings["foldersPrecedeFiles"] = not settings["foldersPrecedeFiles"]
      elseif row == 6 then
        creditsScreen.open()
      end
    elseif settingsScreen.subMenu == "sampling/" then
      if row == 2 then
        settings["sample16bit"] = not settings["sample16bit"]
      elseif row == 3 then
        settings["saveWaveforms"] = not settings["saveWaveforms"]
      elseif row == 4 then
        settings["savewavs"] = not settings["savewavs"]
      end
    end
  end

  if refresh then
    settingsScreen.updateSettings()
  end
end

function settingsScreen.updateSettings()
  if settingsScreen.subMenu == "" then
    settingsList:set({ "general/", "behavior/", "recording/", "sampling/", "ui/" })
  elseif settingsScreen.subMenu == "general/" then
    local outputText = "speaker"
    if settings["output"] == 1 then
      outputText = "headset"
    elseif settings["output"] == 2 then
      outputText = "speaker, headset"
    elseif settings["output"] == 3 then
      outputText = "auto"
    end

    settingsList:set({
      "*Ā*",
      "author: " .. settings["author"],
      "output: " .. outputText,
      "crank speed: " .. settings["cranksens"],
      "folders > files: " .. tostring(settings["foldersPrecedeFiles"]),
      "credits..."
    })
  elseif settingsScreen.subMenu == "behavior/" then
    local screen = settings["crankDockedScreen"]

    if screen == "pattern" then
      screen = "ptn"
    elseif screen == "track" then
      screen = "trk"
    end

    settingsList:set({
      "*Ā*",
      "play on load: " .. tostring(settings["playonload"]),
      "stop if sampling: " .. tostring(settings["stoponsample"]),
      "precise tempo chg: " .. tostring(settings["smallerTempoIncrements"]),
      "tempo edit stop: " .. tostring(settings["stopontempo"]),
      "crank dock screen: " .. tostring(screen)
    })
  elseif settingsScreen.subMenu == "recording/" then
    settingsList:set({
      "*Ā*",
      "_Ⓐ_ button track: " .. tostring(settings["aRecTrack"]),
      "_Ⓑ_ button track: " .. tostring(settings["bRecTrack"]),
      "_⬆️_ button track: " .. tostring(settings["upRecTrack"]),
      "_⬇️_ button track: " .. tostring(settings["downRecTrack"]),
      "_⬅️_ button track: " .. tostring(settings["leftRecTrack"]),
      "_➡️_ button track: " .. tostring(settings["rightRecTrack"]),
      "quantization: " .. tostring(settings["recordQuantization"])
    })
  elseif settingsScreen.subMenu == "sampling/" then
    local format = "16 bit"
    if settings["sample16bit"] == false then
      format = "8 bit"
    end
    settingsList:set({
      "*Ā*",
      "sample format: " .. format,
      "save waveforms: " .. tostring(settings["saveWaveforms"]),
      "save .wav samples: " .. tostring(settings["savewavs"])
    })
  elseif settingsScreen.subMenu == "ui/" then
    settingsList:set({
      "*Ā*",
      "dark mode: " .. tostring(settings["dark"]),
      "visualizer...",
      "show number/total: " .. tostring(settings["num/max"]),
      "show note names: " .. tostring(settings["showNoteNames"]),
      "animate scrn move: " .. tostring(settings["screenAnimation"]),
      "use system font: " .. tostring(settings["useSystemFont"]),
      "show log screens: " .. tostring(settings["logscreens"]),
      "fx screen vfx: " .. tostring(settings["fxvfx"]),
      "50fps: " .. tostring(settings["50fps"])
    })
  elseif settingsScreen.subMenu == "ui/visualizer/" then
    local tempSet = {
      "*Ā*",
      "sine: " .. tostring(settings["visualizer"]["sine"]),
      "notes: " .. tostring(settings["visualizer"]["notes"]),
      "stars: " .. tostring(settings["visualizer"]["stars"]),
      "----- external -----"
    }

    for i, v in ipairs(externalVisualizers) do
      if settings["visualizer"][v[1]] == nil then
        settings["visualizer"][v[1]] = false
      end

      table.insert(tempSet, v[1] .. ": " .. tostring(settings["visualizer"][v[1]]))
    end

    settingsList:set(tempSet)
  end
  saveSettings()
end
