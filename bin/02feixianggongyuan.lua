-- deps

local event = require("event")

local countdown = require("countdown")
local eventbus = require("eventbus")
local digital = require("digital")
local signal = require("signal")

local chat = require("component").chat_box

local devices = require("devices").load("/mtcs/devices/02feixianggongyuan")

local routes = require("routes")

print("Minecraft 计算机列控系统 2.0")
print("===========================================\n")

local STATION_CODE = "02"
local DURATION = 10

--

local S0201 = { state = 0, number = nil }

function S0201.layout()
  digital.set(devices.LOCK_S0201, false)
end

function S0201.open()
  digital.set(devices.LOCK_S0201, true)
end

function S0201.reset()
  S0201.state = 0
  S0201.number = nil
end

--

local X0204 = { state = 0, number = nil }

function X0204.layout()
  digital.set(devices.LOCK_X0204, false)
end

function X0204.open()
  digital.set(devices.LOCK_X0204, true)
end

function X0204.reset()
  X0204.state = 0
  X0204.number = nil
end

--

-- 上行

digital.set(devices.LOCK_S0201, signal.get(devices.S0201) == signal.aspects.green)
digital.set(devices.LOCK_S0202, signal.get(devices.S0202) == signal.aspects.green)

digital.set(devices.DOOR_S, false)

eventbus.on(devices.S0202, "aspect_changed", function(receiver, aspect)
  digital.set(devices.LOCK_S0202, aspect == signal.aspects.green)
end)

local countdown_s = countdown.bind(devices.COUNTDOWN_S, DURATION, function(delayed)
  digital.set(devices.DOOR_S, false)

  if signal.get(devices.S0201) == signal.aspects.green then
    S0201.open()
    S0201.reset()
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

    S0201.state = 1
    S0201.number = number
    S0201.layout()

    countdown_s:start()

    event.timer(2, function()
      digital.set(devices.DOOR_S, true)
    end)
  end
end)

eventbus.on(devices.S0201, "aspect_changed", function(receiver, aspect)
  if S0201.state == 1 then
    countdown_s:go()
  else
    digital.set(devices.LOCK_S0201, aspect == signal.aspects.green)
  end
end)

-- 下行

digital.set(devices.LOCK_X0203, signal.get(devices.X0203) == signal.aspects.green)
digital.set(devices.LOCK_X0204, signal.get(devices.X0204) == signal.aspects.green)

digital.set(devices.DOOR_X, false)

eventbus.on(devices.X0203, "aspect_changed", function(receiver, aspect)
  digital.set(devices.LOCK_X0203, aspect == signal.aspects.green)
end)

local countdown_x = countdown.bind(devices.COUNTDOWN_X, DURATION, function(delayed)
  digital.set(devices.DOOR_X, false)

  if signal.get(devices.X0204) == signal.aspects.green then
    X0204.open()
    X0204.reset()
    return true
  end

  return false
end)

eventbus.on(devices.DETECTOR_X, "minecart", function(detector, type, en, pc, sc, number, o)
  if number == nil then
    return
  end

  if (routes.stops(number, STATION_CODE .. "X")) then
    chat.say(number .. " 下行站内停车")

    X0204.state = 1
    X0204.number = number
    X0204.layout()

    countdown_x:start()

    event.timer(2, function()
      digital.set(devices.DOOR_X, true)
    end)
  end
end)

eventbus.on(devices.X0204, "aspect_changed", function(receiver, aspect)
  if X0204.state == 1 then
    countdown_x:go()
  else
    digital.set(devices.LOCK_X0204, aspect == signal.aspects.green)
  end
end)

chat.setName("飞翔公园")
chat.setDistance(100)
chat.say("系统初始化完毕")

while true do
  eventbus.handle(event.pull())
end
