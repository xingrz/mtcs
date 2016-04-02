-- deps

local event = require("event")

local countdown = require("countdown")
local eventbus = require("eventbus")
local digital = require("digital")
local signal = require("signal")

local chat = require("component").chat_box

local devices = require("devices").load("/mtcs/devices/03xichang")

local routes = require("routes")

print("Minecraft 计算机列控系统 2.0")
print("===========================================\n")

local STATION_CODE = "03"
local DURATION = 10

--

local S0301 = { state = 0, number = nil }

function S0301.layout()
  digital.set(devices.LOCK_S0301, false)
end

function S0301.open()
  digital.set(devices.LOCK_S0301, true)
end

function S0301.reset()
  S0301.state = 0
  S0301.number = nil
end

--

local X0304 = { state = 0, number = nil }

function X0304.layout()
  digital.set(devices.LOCK_X0304, false)
end

function X0304.open()
  digital.set(devices.LOCK_X0304, true)
end

function X0304.reset()
  X0304.state = 0
  X0304.number = nil
end

--

-- 上行

digital.set(devices.LOCK_S0301, signal.get(devices.S0301) == signal.aspects.green)
digital.set(devices.LOCK_S0302, signal.get(devices.S0302) == signal.aspects.green)

digital.set(devices.DOOR_S, false)

eventbus.on(devices.S0302, "aspect_changed", function(receiver, aspect)
  digital.set(devices.LOCK_S0302, aspect == signal.aspects.green)
end)

local countdown_s = countdown.bind(devices.COUNTDOWN_S, DURATION, function(delayed)
  digital.set(devices.DOOR_S, false)

  if signal.get(devices.S0301) == signal.aspects.green then
    S0301.open()
    S0301.reset()
    return true
  end

  return false
end)

eventbus.on(devices.DETECTOR_S, "minecart", function(detector, type, en, pc, sc, number, o)
  if number == nil then
    return
  end

  if routes.stops(number, STATION_CODE .. "S") then
    chat.say(number .. " 上行站内停车")

    S0301.state = 1
    S0301.number = number
    S0301.layout()

    countdown_s:start()

    event.timer(2, function()
      digital.set(devices.DOOR_S, true)
    end)
  end
end)

eventbus.on(devices.S0301, "aspect_changed", function(receiver, aspect)
  if S0301.state == 1 then
    countdown_s:go()
  else
    digital.set(devices.LOCK_S0301, aspect == signal.aspects.green)
  end
end)

-- 下行

digital.set(devices.LOCK_X0303, signal.get(devices.X0303) == signal.aspects.green)
digital.set(devices.LOCK_X0304, signal.get(devices.X0304) == signal.aspects.green)

digital.set(devices.DOOR_X, false)

eventbus.on(devices.X0303, "aspect_changed", function(receiver, aspect)
  digital.set(devices.LOCK_X0303, aspect == signal.aspects.green)
end)

local countdown_x = countdown.bind(devices.COUNTDOWN_X, DURATION, function(delayed)
  digital.set(devices.DOOR_X, false)

  if signal.get(devices.X0304) == signal.aspects.green then
    X0304.open()
    X0304.reset()
    return true
  end

  return false
end)

eventbus.on(devices.DETECTOR_X, "minecart", function(detector, type, en, pc, sc, number, o)
  if (number == nil) then
    return
  end

  if signal.get(devices.X0304) ~= signal.aspects.green then
    digital.set(devices.LOCK_X0304, false)
  end

  if routes.stops(number, STATION_CODE .. "X") then
    chat.say(number .. " 下行站内停车")

    X0304.state = 1
    X0304.number = number
    X0304.layout()

    countdown_x:start()

    event.timer(2, function()
      digital.set(devices.DOOR_X, true)
    end)
  end
end)

eventbus.on(devices.X0304, "aspect_changed", function(receiver, aspect)
  if X0304.state == 1 then
    countdown_x:go()
  else
    digital.set(devices.LOCK_X0304, aspect == signal.aspects.green)
  end
end)

chat.setName("西场")
chat.setDistance(100)
chat.say("系统初始化完毕")

while true do
  eventbus.handle(event.pull())
end
