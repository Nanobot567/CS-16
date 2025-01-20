-- moar stats!!!!

local RECT = pd.geometry.rect.new(0, 30, 400, 210)

local t = {}
local pdstats, stats = {}, {
  kernel = "0",
  serial = "0",
  game = "0",
  GC = "0",
  wifi = "0",
  audio = "0",
  idle = "0"
}

local ticks = 0

local refresh = math.floor(pd.display.getRefreshRate() / 2)

local function statsUpdate()
  ticks = ticks + 1

  if ticks == refresh then -- to reduce calls to stats
    ticks = 0
    pdstats = pd.getStats()

    if pdstats == nil then
      pdstats = {}
    end

    stats = {
      kernel = "0",
      serial = "0",
      game = "0",
      GC = "0",
      wifi = "0",
      audio = "0",
      idle = "0"
    }


    for k, v in pairs(pdstats) do
      stats[k] = v
    end

    t = {
      "-- CPU --\n",
      "idle: ",
      stats.idle,
      "\nkernel: ",
      stats.kernel,
      "\ngame: ",
      stats.game,
      "\ngc: ",
      stats.GC,
      "\naudio: ",
      stats.audio
    }
  end

  gfx.setImageDrawMode(gfx.kDrawModeCopy)

  fnt8x8:drawText(table.concat(t), RECT)
end

return { "cpu stats", statsUpdate }
