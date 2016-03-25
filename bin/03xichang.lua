-- deps

local event = require("event")

local countdown = require("countdown")
local eventbus = require("eventbus")
local digital = require("digital")
local signal = require("signal")

local devices = require("devices").load("/mtcs/devices/03xichang")

local routes = require("routes")

print("Minecraft 计算机列控系统 2.0")
print("===========================================\n")

local STATION_CODE = "03"
local DURATION = 10

-- 上行

digital.set(devices.LOCK_S0301, signal.get(devices.S0301) == signal.aspects.green)
digital.set(devices.LOCK_S0302, signal.get(devices.S0302) == signal.aspects.green)

digital.set(devices.DOOR_S, false)

local countdown_s = countdown.bind(devices.COUNTDOWN_S, DURATION, function(delayed)
  if (signal.get(devices.S0301) == signal.aspects.green) then
    digital.set(devices.DOOR_S, false)
    digital.set(devices.LOCK_S0301, true)
  end
end)

eventbus.on(devices.DETECTOR_S, "minecart", function(detector, type, en, pc, sc, number, o)
  if (number == nil) then
    return
  end

  if (routes.stops(number, STATION_CODE .. "S")) then
    print(os.date() .. " " .. number .. " 上行站内停车")

    digital.set(devices.LOCK_S0301, false)
    countdown_s:start()

    event.timer(2, function()
      digital.set(devices.DOOR_S, true)
    end)
  end
end)

eventbus.on(devices.S0301, "aspect_changed", function(receiver, aspect)
  if (aspect == signal.aspects.green) then
    countdown_s:go()
  end
end)

eventbus.on(devices.S0302, "aspect_changed", function(receiver, aspect)
  digital.set(devices.LOCK_S0302, aspect == signal.aspects.green)
end)

-- 下行

digital.set(devices.LOCK_X0303, signal.get(devices.X0303) == signal.aspects.green)
digital.set(devices.LOCK_X0304, signal.get(devices.X0304) == signal.aspects.green)

digital.set(devices.DOOR_X, false)

local countdown_x = countdown.bind(devices.COUNTDOWN_X, DURATION, function(delayed)
  if (signal.get(devices.X0304) == signal.aspects.green) then
    digital.set(devices.DOOR_X, false)
    digital.set(devices.LOCK_X0304, true)
  end
end)

eventbus.on(devices.DETECTOR_X, "minecart", function(detector, type, en, pc, sc, number, o)
  if (number == nil) then
    return
  end

  if (routes.stops(number, STATION_CODE .. "X")) then
    print(os.date() .. " " .. number .. " 下行站内停车")

    digital.set(devices.LOCK_X0304, false)
    countdown_x:start()

    event.timer(2, function()
      digital.set(devices.DOOR_X, true)
    end)
  end
end)

eventbus.on(devices.X0304, "aspect_changed", function(receiver, aspect)
  if (aspect == signal.aspects.green) then
    countdown_x:go()
  end
end)

eventbus.on(devices.X0303, "aspect_changed", function(receiver, aspect)
  digital.set(devices.LOCK_X0303, aspect == signal.aspects.green)
end)

while true do
  eventbus.handle(event.pull())
end
