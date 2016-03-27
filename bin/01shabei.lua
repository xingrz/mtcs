-- deps

local event = require("event")

local countdown = require("countdown")
local eventbus = require("eventbus")
local digital = require("digital")
local signal = require("signal")

local devices = require("devices").load("/mtcs/devices/01shabei")

local routes = require("routes")

print("Minecraft 计算机列控系统 2.0")
print("===========================================\n")

local STATION_CODE = "01"
local DURATION = 10

digital.set(devices.W0102, false)
digital.set(devices.W0104, false)
digital.set(devices.W0106, false)
digital.set(devices.W0108, false)
digital.set(devices.W0110, false)
digital.set(devices.W0112, false)

-- 上行

digital.set(devices.LOCK_S0101, signal.get(devices.S0101) == signal.aspects.green)
digital.set(devices.LOCK_S0102, signal.get(devices.S0102) == signal.aspects.green)

digital.set(devices.DOOR_S, false)

local countdown_s = countdown.bind(devices.COUNTDOWN_S, DURATION, function(delayed)
  if (signal.get(devices.S0101) == signal.aspects.green) then
    digital.set(devices.DOOR_S, false)
    digital.set(devices.LOCK_S0101, true)
  end
end)

eventbus.on(devices.DETECTOR_S, "minecart", function(detector, type, en, pc, sc, number, o)
  if (number == nil) then
    return
  end

  if (routes.stops(number, STATION_CODE .. "S")) then
    print(os.date() .. " " .. number .. " 上行站内停车")

    digital.set(devices.LOCK_S0101, false)
    countdown_s:start()

    event.timer(2, function()
      digital.set(devices.DOOR_S, true)
    end)
  end
end)

eventbus.on(devices.S0101, "aspect_changed", function(receiver, aspect)
  if (aspect == signal.aspects.green) then
    countdown_s:go()
  end
end)

eventbus.on(devices.S0102, "aspect_changed", function(receiver, aspect)
end)

while true do
  eventbus.handle(event.pull())
end
