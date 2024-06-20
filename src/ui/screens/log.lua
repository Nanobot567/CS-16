-- log screen, for the cools haha

logScreen = {}
logScreen.log = {}

function logScreen.init()
  logScreen.log = {}
end

function logScreen.append(text)
  if settings["logscreens"] == true then
    gfx.clear()

    table.insert(logScreen.log, text)

    if #logScreen.log > 30 then
      table.remove(logScreen.log, 1)
    end

    for index, value in ipairs(logScreen.log) do
      local yval = (index - 1) * 8

      if index == 1 then
        yval = 0
      end

      rains1x:drawText(value, 2, yval)
    end

    pd.display.flush()
  end
end
