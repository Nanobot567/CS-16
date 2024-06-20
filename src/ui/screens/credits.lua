creditsScreen = {}
creditsScreen.oldUpdate = nil
creditsScreen.current = 1

creditsScreen.features = { "drhitchcockco - number/total setting",
  "justyouraveragehomie - waveform view, live record, swing, and much more!" }
creditsScreen.thanks = { "my family", "lil figurative", "trisagion media", "the trisagion insurgence",
  "r.y.e. (i taikatsu'y, y'yaitimu!! mrak'y ni t'dumeri-tae-ou kitsu-kus.)",
  "m.r. (hei vibao!!)" }

function creditsScreen.open()
  inScreen = true

  creditsScreen.current = 1
  creditsScreen.updateText()

  pd.inputHandlers.push(creditsScreen, true)
  creditsScreen.oldUpdate = pd.update
  pd.update = creditsScreen.update
end

function creditsScreen.update()

end

function creditsScreen.updateText()
  local text
  gfx.clear()

  if creditsScreen.current == 1 then -- used if statements so credits could be dynamic!
    text = "\ncs-16 v" .. pd.metadata.version .. "\n\ndeveloped by nanobot567\n\n\n\n-- feature requesters --"
  elseif creditsScreen.current == 2 then
    text = "\nspecial thanks to...\n\n\n\n\n\n\n\n\n\n\nyou guys are awesome! :)"
  end

  gfx.drawTextInRect(text, 0, 0, 400, 240, nil, nil, align.center)

  if creditsScreen.current == 1 then
    gfx.drawTextInRect(
      "\n\n" .. table.concat(creditsScreen.features, "\n\n"),
      0,
      128, 400, 240, nil, nil, align.center, fnt8x8)
  elseif creditsScreen.current == 2 then
    gfx.drawTextInRect(
      table.concat(creditsScreen.thanks, "\n\n"), 0, 48,
      400, 240, nil, nil,
      align.center, fnt8x8)
  elseif creditsScreen.current == 3 then
    gfx.drawTextInRect(
      "nanobot567: open source, forever.\n\n\n\nthe cs-16 font is a modified version of the 'Tron' font from idleberg's playdate arcade fonts (https://github.com/idleberg/playdate-arcade-fonts).\n\nthe 'rains' fonts (referred to as the system fonts) are from the playdate sdk resources folder, with a couple positioning changes.\n\nall of the source code is under the mit license and is available at...\n\nhttps://github.com/nanobot567/cs-16\n\nthe cs-16 manual is available online at...\n\nhttps://(CS-16 GH)/blob/main/MANUAL.md\n\n\n\nthanks for using cs-16!!",
      2, 0, 396, 240, nil, nil, align.center, fnt8x8)
  end
  gfx.drawTextInRect("credits - use left / right to navigate, B to exit", 0, 232, 400, 8, nil, nil, align.center, fnt8x8)
end

function creditsScreen.BButtonDown()
  creditsScreen.close()
end

function creditsScreen.leftButtonDown()
  if creditsScreen.current > 1 then
    creditsScreen.current -= 1
    creditsScreen.updateText()
  end
end

function creditsScreen.rightButtonDown()
  if creditsScreen.current < 3 then
    creditsScreen.current += 1
    creditsScreen.updateText()
  else
    creditsScreen.close()
  end
end

function creditsScreen.close()
  pd.inputHandlers.pop()
  pd.update = creditsScreen.oldUpdate
 
  inScreen = false
end

