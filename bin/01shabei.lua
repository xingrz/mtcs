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

local x0108 = 0
local s0106 = 0

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

  if (routes.stops(number, STATION_CODE .. "R") and s0106 == 2) then
    s0106 = 0
    digital.set(devices.W0110, false)
    digital.set(devices.W0112, false)
  end
end)

eventbus.on(devices.S0101, "aspect_changed", function(receiver, aspect)
  if (aspect == signal.aspects.green) then
    countdown_s:go()
  end
end)

eventbus.on(devices.S0102, "aspect_changed", function(receiver, aspect)
  -- TODO
end)

-- 下行

digital.set(devices.LOCK_X0103, signal.get(devices.X0103) == signal.aspects.green)
digital.set(devices.LOCK_X0108, signal.get(devices.X0108) == signal.aspects.green)

digital.set(devices.DOOR_X, false)

eventbus.on(devices.X0103, "aspect_changed", function(receiver, aspect)
  digital.set(devices.LOCK_X0103, aspect == signal.aspects.green)
end)

-- 排列入折返线进路
function layoutForX0108B()
  digital.set(devices.LOCK_S0106, false)
  digital.set(devices.LOCK_X0104, true)
  digital.set(devices.CONTROL_R, true)
  digital.set(devices.W0106, true)
  digital.set(devices.W0108, true)
end

local countdown_x = countdown.bind(devices.COUNTDOWN_X, DURATION, function(delayed)
  if (x0108 == 0 and signal.get(devices.X0108) == signal.aspects.green) then
    digital.set(devices.DOOR_X, false)
    digital.set(devices.LOCK_X0204, true)
  elseif (x0108 == 1 and signal.get(devices.X0108B) == signal.aspects.green) then
    layoutForX0108B()
    digital.set(devices.DOOR_X, false)
    digital.set(devices.LOCK_X0204, true)
  end
end)

eventbus.on(devices.DETECTOR_X, "minecart", function(detector, type, en, pc, sc, number, o)
  if (number == nil) then
    return
  end

  signal.set(devices.C_X0108, signal.aspects.red)

  if (routes.stops(number, STATION_CODE .. "X")) then
    print(os.date() .. " " .. number .. " 下行站内停车")

    digital.set(devices.LOCK_X0108, false)
    countdown_x:start()

    event.timer(2, function()
      digital.set(devices.DOOR_X, true)
    end)
  end

  if (routes.stops(number, STATION_CODE .. "R")) then
    print(os.date() .. " " .. number .. " 已排列入折返线进路")

    x0108 = 1

    if (signal.get(devices.X0108B) == signal.aspects.green) then
      layoutForX0108B()
    end

    signal.set(devices.C_X0108, signal.get(devices.X0108B))
  else
    signal.set(devices.C_X0108, signal.get(devices.X0108))
  end

  if (routes.stops(number, STATION_CODE .. "S")) then
    print(os.date() .. " " .. number .. " 已排列出折返线进路")
    s0106 = 1
  end
end)

eventbus.on(devices.X0108, "aspect_changed", function(receiver, aspect)
  if (x0108 == 0) then
    signal.set(devices.C_X0108, aspect)
    if (aspect == signal.aspects.green) then
      countdown_x:go()
    end
  end
end)

eventbus.on(devices.X0108B, "aspect_changed", function(receiver, aspect)
  if (x0108 == 1) then
    signal.set(devices.C_X0108, aspect)
    if (aspect == signal.aspects.green) then
      countdown_x:go()
    end
  end
end)

-- 折返线

function openS0106()
  -- 封锁 S0102
  signal.set(devices.C_S0102, signal.aspects.red)
  digital.set(devices.LOCK_S0102, false)

  -- 开放 S0106
  digital.set(devices.W0110, true)
  digital.set(devices.W0112, true)
  digital.set(devices.CONTROL_R, false)
  digital.set(devices.LOCK_S0106, true)
  digital.set(devices.LOCK_X0104, true)
end

eventbus.on(devices.DETECTOR_X0104, "minecart", function(detector, type, en, pc, sc, number, o)
  if (number == nil) then
    return
  end

  if (x0108 == 1) then
    x0108 = 0

    -- 道岔复位
    digital.set(devices.W0106, false)
    digital.set(devices.W0108, false)
  end

  if (s0106 == 1) then
    s0106 = 2
    signal.set(devices.C_S0106, signal.get(devices.S0102))
    if (signal.get(devices.S0102) == signal.aspects.green) then
      openS0106()
    end
  end
end)

eventbus.on(devices.S0102, "aspect_changed", function(receiver, aspect)
  if (s0106 == 2) then
    signal.set(devices.C_S0106, aspect)
    if (aspect == signal.aspects.green) then
      openS0106()
    end
  else
    -- signal.set(devices.C_S0106, aspect)
    -- digital.set(devices.LOCK_S0102, aspect == signal.aspects.green)
    -- TODO
  end
end)

while true do
  eventbus.handle(event.pull())
end
