-- deps

local event = require("event")

local countdown = require("countdown")
local eventbus = require("eventbus")
local digital = require("digital")
local signal = require("signal")

local devices = require("devices").load("/mtcs/devices/04taojin")

local routes = require("routes")

print("Minecraft 计算机列控系统 2.0")
print("===========================================\n")

local STATION_CODE = "04"
local DURATION = 10

local s0402_branch = false

eventbus.on(devices.DETECTOR_S0402, "minecart", function(d, t, n, p, s, number, o)
  if (number == nil) then
    return
  end

  -- 是否折返
  s0402_branch = routes.stops(number, STATION_CODE .. "X")

  if (s0402_branch) then
    print(os.date() .. " " .. number .. " 准备折返")

    if (signal.get(devices.S0402B) == signal.aspects.green) then
      digital.set(devices.W0402, true)
      digital.set(devices.W0404, true)
      digital.set(devices.LOCK_S0402, true)
    else
      digital.set(devices.LOCK_S0402, false)
      signal.set(devices.C_S0402, signal.aspects.red)
    end
  else
    if (signal.get(devices.S0402) == signal.aspects.green) then
      digital.set(devices.W0402, false)
      digital.set(devices.W0404, false)
      digital.set(devices.LOCK_S0402, true)
    else
      digital.set(devices.LOCK_S0402, false)
      signal.set(devices.C_S0402, signal.aspects.red)
    end
  end
end)

eventbus.on(devices.S0402, "aspect_changed", function(r, aspect)
  if (not s0402_branch) then
    signal.set(devices.C_S0402, aspect)
  end
end)

eventbus.on(devices.S0402B, "aspect_changed", function(r, aspect)
  if (s0402_branch) then
    signal.set(devices.C_S0402, aspect)
  end
end)

while true do
  eventbus.handle(event.pull())
end
