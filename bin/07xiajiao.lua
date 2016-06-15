-- deps

local event = require("event")

local countdown = require("countdown")
local eventbus = require("eventbus")
local detector = require("detector")
local digital = require("digital")
local signal = require("signal")

local chat = require("component").chat_box

local devices = require("devices").load("/mtcs/devices/07xiajiao")

local routes = require("routes")

print("Minecraft 计算机列控系统 2.0")
print("===========================================\n")

local STATION_CODE = "07"
local DURATION = 10

--

local S0701 = { state = 0 }

function S0701.layout()
  digital.set(devices.LOCK_S0703, false)

  signal.set(devices.C_S0703, signal.aspects.red)

  digital.set(devices.W0703, false)
  digital.set(devices.W0701, false)

  signal.set(devices.C_S0701, signal.aspects.green)

  chat.say("S0701 进路排列完成")
end

function S0701.open()
  digital.set(devices.LOCK_S0701, true)
  chat.say("S0701 进路开放")
end

function S0701.reset()
  digital.set(devices.LOCK_S0701, false)
  signal.set(devices.C_S0701, signal.aspects.red)
end

--

local S0703 = { state = 0 }

function S0703.layout()
  digital.set(devices.LOCK_S0701, false)

  signal.set(devices.C_S0701, signal.aspects.red)

  digital.set(devices.W0701, true)
  digital.set(devices.W0703, true)

  signal.set(devices.C_S0703, signal.aspects.green)

  chat.say("S0703 进路排列完成")
end

function S0703.open()
  digital.set(devices.LOCK_S0703, true)
  chat.say("S0703 进路开放")
end

function S0703.reset()
  digital.set(devices.LOCK_S0703, false)
  signal.set(devices.C_S0703, signal.aspects.red)
end

--

local X0702 = { state = 0 }

function X0702.layout()
  digital.set(devices.LOCK_X0702, false)
end

function X0702.open()
  digital.set(devices.LOCK_X0702, true)
end

--

local S0709 = {}

function S0709.layout()
  digital.set(devices.LOCK_S0709, false)

  digital.set(devices.W0707, false)
  digital.set(devices.W0709, false)

  signal.set(devices.C_S0709, signal.aspects.green)

  chat.say("S0709 进路排列完成")
end

function S0709.open()
  digital.set(devices.LOCK_S0709, true)
  chat.say("S0709 进路开放")
end

function S0709.reset()
  digital.set(devices.LOCK_S0709, false)
  signal.set(devices.C_S0709, signal.aspects.red)
end

--

local S0709B = { state = 0 }

function S0709B.layout()
  digital.set(devices.LOCK_S0709, false)

  digital.set(devices.W0707, true)
  digital.set(devices.W0709, true)

  digital.set(devices.CONTROL_R, false)

  digital.set(devices.LOCK_S0705, false)
  digital.set(devices.LOCK_X0707, true)

  signal.set(devices.C_S0709, signal.aspects.yellow)

  chat.say("S0709B 进路排列完成")
end

function S0709B.open()
  digital.set(devices.LOCK_S0709, true)
  chat.say("S0709B 进路开放")
end

function S0709B.reset()
  digital.set(devices.LOCK_S0709, false)

  digital.set(devices.W0707, false)
  digital.set(devices.W0709, false)

  signal.set(devices.C_S0709, signal.aspects.red)
end

--

local X0707 = { state = 0 }

function X0707.layout()
  digital.set(devices.LOCK_X0711, false)

  signal.set(devices.C_X0711, signal.aspects.red)

  digital.set(devices.W0711, true)
  digital.set(devices.W0713, true)

  signal.set(devices.C_X0707, signal.aspects.yellow)

  chat.say("X0707 进路排列完成")
end

function X0707.open()
  digital.set(devices.CONTROL_R, true)
  digital.set(devices.LOCK_S0705, true)
  digital.set(devices.LOCK_X0707, true)
  chat.say("X0707 进路开放")
end

function X0707.reset()
  digital.set(devices.LOCK_X0707, false)

  digital.set(devices.W0711, false)
  digital.set(devices.W0713, false)

  signal.set(devices.C_X0707, signal.aspects.red)
end

--

eventbus.on(devices.S0704, "aspect_changed", function(receiver, aspect)
  digital.set(devices.LOCK_S0704, signal.is_green(devices.S0704))
  signal.green(devices.C_S0704, aspect)
end)

local countdown_s = countdown.bind(devices.COUNTDOWN_S, DURATION, function(delayed)
  digital.set(devices.DOOR_S, false)

  if S0709B.state == 0 then
    if signal.get(devices.S0709) == signal.aspects.green then
      S0709.open()
      return true
    end
  elseif S0709B.state == 2 then
    if signal.get(devices.S0709B) == signal.aspects.green then
      S0709B.open()
      return true
    end
  end

  return false
end)

eventbus.on(devices.DETECTOR_S, "minecart", function(detector, type, en, pc, sc, number, o)
  if number == nil then
    return
  end

  if routes.stops(number, STATION_CODE .. "S") then
    chat.say(number .. " 下行站内停车")

    digital.set(devices.LOCK_S0709, false)
    countdown_s:start()

    event.timer(2, function()
      digital.set(devices.DOOR_S, true)
    end)
  end

  if routes.stops(number, STATION_CODE .. "R") then
    S0709B.state = 1

    if signal.get(devices.S0709B) == signal.aspects.green then
      S0709B.layout()
      S0709B.state = 2
    else
      signal.set(devices.C_S0709, signal.aspects.red)
    end
  elseif S0709B.state == 0 then
    S0709.state = 1

    if signal.get(devices.S0709) == signal.aspects.green then
      S0709.layout()
      S0709.state = 2
    else
      signal.set(devices.C_S0709, signal.aspects.red)
    end
  end

  if (routes.stops(number, STATION_CODE .. "X")) then
    X0707.state = 1
  end
end)

eventbus.on(devices.S0709, "aspect_changed", function(receiver, aspect)
  if S0709.state ~= 0 then
    signal.green(devices.C_S0709, aspect)
  end

  if S0709.state == 1 and aspect == signal.aspects.green then
    S0709.layout()
    S0709.state = 2
    countdown_s:go()
  end
end)

eventbus.on(devices.S0709B, "aspect_changed", function(receiver, aspect)
  if S0709B.state ~= 0 then
    signal.yellow(devices.C_S0709, aspect)
  end

  if S0709B.state == 1 and aspect == signal.aspects.green then
    S0709B.layout()
    S0709B.state = 2
    countdown_s:go()
  end
end)

eventbus.on(devices.DETECTOR_S0705, "minecart", function(detector, type, en, pc, sc, number, o)
  if number == nil then
    return
  end

  if S0709B.state == 2 then
    S0709B.reset()
    S0709B.state = 0
  end

  if X0707.state == 1 then
    event.timer(2, function()
      X0707.state = 2

      if signal.get(devices.X0707) == signal.aspects.green then
        X0707.layout()
        X0707.open()
        X0707.state = 3
      end
    end)
  end
end)

eventbus.on(devices.X0707, "aspect_changed", function(receiver, aspect)
  if X0707.state ~= 0 then
    signal.yellow(devices.C_X0707, aspect)
  end

  if X0707.state == 2 then
    X0707.layout()
    X0707.open()
    X0707.state = 3
  end
end)

eventbus.on(devices.X0711, "aspect_changed", function(receiver, aspect)
  if X0707.state <= 1 then
    signal.green(devices.C_X0711, aspect)
    digital.set(devices.LOCK_X0711, aspect == signal.aspects.green)
  end
end)

eventbus.on(devices.DETECTOR_X0702, "minecart", function(detector, type, en, pc, sc, number, o)
  if number == nil then
    return
  end

  if X0707.state == 3 then
    X0707.reset()
    X0707.state = 0
  end
end)

local countdown_x = countdown.bind(devices.COUNTDOWN_X, DURATION, function(delayed)
  digital.set(devices.DOOR_X, false)

  if signal.get(devices.X0702) == signal.aspects.green then
    X0702.open()
    X0702.state = 0
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

    X0702.state = 1
    X0702.layout()

    countdown_x:start()

    event.timer(2, function()
      digital.set(devices.DOOR_X, true)
    end)
  end
end)

eventbus.on(devices.X0702, "aspect_changed", function(receiver, aspect)
  if X0702.state == 1 then
    countdown_x:go()
  else
    digital.set(devices.LOCK_X0702, signal.is_green(devices.X0702))
    signal.green(devices.C_X0702, aspect)
  end
end)

--

eventbus.on(chat.address, "chat_message", function(c, user, message)
  if message == "X0702.open" then
    countdown_x:stop()
    digital.set(devices.DOOR_X, false)
    X0702.open()
  end

  if message == "S0704.open" then
    digital.set(devices.LOCK_S0704, true)
  end

  if message == "S0709B.open" then
    countdown_s:stop()
    digital.set(devices.DOOR_S, false)
    S0709B.layout()
    S0709B.open()
    S0709B.state = 2
  end

  if message == "X0707.open" then
    X0707.layout()
    X0707.open()
    X0707.state = 3
  end

  if message == "X0711.open" then
    X0707.reset()
    X0707.state = 0
    digital.set(devices.LOCK_X0711, true)
  end
end)

--

digital.set(devices.LOCK_S0701, false)
digital.set(devices.LOCK_X0702, false)
digital.set(devices.LOCK_S0703, false)
digital.set(devices.LOCK_S0704, false)
digital.set(devices.LOCK_S0705, false)
digital.set(devices.LOCK_X0707, false)
digital.set(devices.LOCK_S0709, false)
digital.set(devices.LOCK_X0711, false)

digital.set(devices.CONTROL_R, false)

digital.set(devices.W0701, false)
digital.set(devices.W0703, false)

digital.set(devices.W0707, false)
digital.set(devices.W0709, false)

digital.set(devices.W0711, false)
digital.set(devices.W0713, false)

signal.set(devices.C_S0701, signal.aspects.red)
signal.set(devices.C_S0703, signal.aspects.red)
signal.set(devices.C_S0705, signal.aspects.red)
signal.set(devices.C_X0707, signal.aspects.red)
signal.set(devices.C_S0709, signal.aspects.red)
signal.set(devices.C_X0711, signal.aspects.red)

digital.set(devices.DOOR_S, false)
digital.set(devices.DOOR_X, false)

chat.setName("厦滘")
chat.setDistance(100)
chat.say("系统初始化完毕")

while true do
  eventbus.handle(event.pull())
end
