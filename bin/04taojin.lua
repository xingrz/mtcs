-- deps

local event = require("event")

local countdown = require("countdown")
local eventbus = require("eventbus")
local digital = require("digital")
local signal = require("signal")

local chat = require("component").chat_box

local devices = require("devices").load("/mtcs/devices/04taojin")

local routes = require("routes")

print("Minecraft 计算机列控系统 2.0")
print("===========================================\n")

local STATION_CODE = "04"
local DURATION = 10

-- state: 0 = 未排列进路, 1 = 等待信号, 2 = 开放

--

local S0402 = { state = 0, number = nil }

function S0402.layout()
  -- 排列 S0402
  digital.set(devices.W0402, false)
  digital.set(devices.W0404, true)

  -- 排列完成
  signal.set(devices.C_S0402, signal.aspects.green)
end

function S0402.open()
  digital.set(devices.LOCK_S0402, true)
end

--

local S0402B = { state = 0, number = nil }

function S0402B.layout()
  -- 排列 S0402B
  digital.set(devices.LOCK_S0406, false)
  digital.set(devices.LOCK_X0404, true)

  digital.set(devices.W0402, true)
  digital.set(devices.W0404, false)

  -- 排列完成
  signal.set(devices.C_S0402, signal.aspects.green)

  chat.say("S0402B 进路排列完成")
end

function S0402B.open()
  digital.set(devices.LOCK_S0402, true)
  chat.say("S0402B 进路开放")
end

function S0402B.reset()
  digital.set(devices.LOCK_S0402, false)

  digital.set(devices.W0402, false)
  digital.set(devices.W0404, true)

  signal.set(devices.C_S0402, signal.get(devices.S0402))

  S0402B.state = 0
  S0402B.number = nil

  chat.say("S0402B 进路复位")
end

--

local S0406 = { state = 0, number = nil }

function S0406.layout()
  -- 封锁 X0403
  digital.set(devices.LOCK_X0403, false)

  signal.set(devices.C_X0408, signal.aspects.red)
  signal.set(devices.C_X0403, signal.aspects.red)

  -- 排列 X0108
  digital.set(devices.LOCK_S0405, false)
  digital.set(devices.LOCK_X0408, true)

  digital.set(devices.CONTROL_S, true)

  digital.set(devices.W0408, true)
  digital.set(devices.W0406, true)

  -- 排列完成
  signal.set(devices.C_S0406, signal.aspects.green)

  chat.say("S0406 进路排列完成")
end

function S0406.open()
  digital.set(devices.LOCK_S0406, true)
  digital.set(devices.LOCK_X0404, true)
  chat.say("S0406 进路开放")
end

function S0406.reset()
  digital.set(devices.LOCK_S0406, false)

  signal.set(devices.C_S0406, signal.aspects.red)

  digital.set(devices.W0406, false)
  digital.set(devices.W0408, false)

  chat.say("S0406 进路复位")
end

--

local X0408 = { state = 0, number = nil }

function X0408.layout()
  signal.set(devices.C_X0408, signal.aspects.green)
end

function X0408.open()
  digital.set(devices.CONTROL_S, false)
  digital.set(devices.LOCK_S0405, true)
  digital.set(devices.LOCK_X0408, true)
end

function X0408.reset()
  X0408.state = 0
  X0408.number = nil
end

--

local X0408B = { state = 0, number = nil }
-- TODO

--

local X0403 = { state = 0, number = nil }

function X0403.layout()
  signal.set(devices.C_X0403, signal.aspects.green)
end

function X0403.open()
  digital.set(devices.LOCK_S0405, true)
  digital.set(devices.LOCK_X0403, true)
end

function X0403.reset()
  X0403.state = 0
  X0403.number = nil
end

--

-- 上行进入存车线

eventbus.on(devices.DETECTOR_S0402, "minecart", function(d, t, n, p, s, number, o)
  if number == nil then
    return
  end

  -- 忽略车尾
  if S0402.state ~= 0 or S0402B.state ~= 0 then
    return
  end

  -- 如果运行图包含存车线
  if routes.stops(number, STATION_CODE .. "K") then
    S0402B.state = 1
    S0402B.number = number

    if signal.get(devices.S0402B) == signal.aspects.green then
      S0402B.layout()
      S0402B.open()
      S0402B.state = 2
    else
      digital.set(LOCK_S0402, false)
      signal.set(devices.C_S0402, signal.aspects.red)
    end
  else
    S0402.state = 1
    S0402.number = number

    if signal.get(devices.S0402) == signal.aspects.green then
      S0402.layout()
      S0402.open()
      S0402.state = 2
    else
      digital.set(LOCK_S0402, false)
      signal.set(devices.C_S0402, signal.aspects.red)
    end
  end
end)

eventbus.on(devices.S0402, "aspect_changed", function(r, aspect)
  if S0402.state ~= 0 then
    signal.set(devices.C_S0402, aspect)
  end

  if S0402.state == 1 and aspect == signal.aspects.green then
    S0402.layout()
    S0402.open()
    S0402.state = 2
  end
end)

eventbus.on(devices.S0402B, "aspect_changed", function(r, aspect)
  if S0402B.state ~= 0 then
    signal.set(devices.C_S0402, aspect)
  end

  if S0402B.state == 1 and aspect == signal.aspects.green then
    S0402B.layout()
    S0402B.open()
    S0402B.state = 2
  end
end)

eventbus.on(devices.DETECTOR_S0406, "minecart", function(d, t, n, p, s, number, o)
  if (number == nil) then
    return
  end

  if routes.stops(number, STATION_CODE .. "K") and S0402B.state == 2 then
    S0402B.reset()
    signal.set(devices.C_S0402, signal.get(devices.S0402))
  end
end)

-- 存车线进入下行

eventbus.on(devices.DETECTOR_X0404, "minecart", function(d, t, n, p, s, number, o)
  if number == nil then
    return
  end

  -- 忽略车尾
  if S0406.state == 2 then
    S0406.state = 3
    return
  end

  if routes.stops(number, STATION_CODE .. "X") then
    S0406.state = 1
    S0406.number = number

    if signal.get(devices.S0406) == signal.aspects.green then
      S0406.layout()
      S0406.open()
      S0406.state = 2
    else
      digital.set(LOCK_S0406, false)
      signal.set(devices.C_S0406, signal.aspects.red)
    end
  end
end)

eventbus.on(devices.S0406, "aspect_changed", function(r, aspect)
  if S0406.state ~= 0 then
    signal.set(devices.C_S0406, aspect)
  end

  if S0406.state == 1 and aspect == signal.aspects.green then
    S0406.layout()
    S0406.open()
    S0406.state = 2
  end
end)

-- 下行站台

local countdown_x = countdown.bind(devices.COUNTDOWN_X, DURATION, function(delayed)
  if (signal.get(devices.X0408) == signal.aspects.green) then
    X0408.layout()
    X0408.open()
    X0408.state = 2
    return true
  end

  return false
end)

eventbus.on(devices.DETECTOR_X0408, "minecart", function(d, t, n, p, s, number, o)
  if number == nil then
    return
  end

  -- 无论如何必须复位 S0406 进路
  S0406.reset()
  if S0406.state == 3 then
    S0406.state = 0
    S0406.number = nil
  end

  -- 车尾经过时复位进路
  if X0408.state == 2 then
    X0408.reset()
    return
  end

  -- 禁止从下行上线该站的折返列车
  -- 假如折返列车从正线顺向插入
  -- 会识别车位地点码，但无法锁车，导致继续计时
  -- 下趟折返列车进入时会将进路复位，导致无法出站

  if routes.stops(number, STATION_CODE .. "X") or routes.stops(number, STATION_CODE .. "K") then
    X0408.state = 1
    X0408.number = number
  end

  if X0408.state == 1 then
    chat.say(number .. " 下行站内停车")

    digital.set(devices.LOCK_X0408, false)
    countdown_x:start()

    event.timer(2, function()
      digital.set(devices.DOOR_X, true)
    end)

    if signal.get(devices.X0408) == signal.aspects.green then
      X0408.layout()
      X0408.state = 2
    else
      signal.set(devices.C_X0408, false)
    end
  end
end)

eventbus.on(devices.X0408, "aspect_changed", function(receiver, aspect)
  if S0406.state ~= 2 and S0406.state ~= 3 then
    signal.set(devices.C_X0408, aspect)
    if X0408.state == 1 then
      countdown_x:go()
    else
      digital.set(devices.LOCK_X0408, aspect == signal.aspects.green)
    end
  end
end)

eventbus.on(devices.X0408B, "aspect_changed", function(receiver, aspect)
  -- TODO
end)

eventbus.on(devices.X0403, "aspect_changed", function(receiver, aspect)
  if S0406.state == 0 then
    signal.set(devices.C_X0403, aspect)
    digital.set(devices.LOCK_X0403, aspect == signal.aspects.green)
  end
end)

-- 上行进站

eventbus.on(devices.DETECTOR_S0401, "minecart", function(d, t, n, p, s, number, o)
  if (number == nil) then
    return
  end

  -- TODO ...
end)

eventbus.on(chat.address, "chat_message", function(c, user, message)
  if message == "S0402B.open" then
    S0402B.layout()
    S0402B.open()
    S0402B.state = 2
  end

  if message == "S0406.open" then
    S0406.layout()
    S0406.open()
    S0406.state = 2
  end

  if message == "X0408.open" then
    countdown_x:stop()
    digital.set(devices.DOOR_X, false)
    X0408.layout()
    X0408.open()
    X0408.state = 2
  end
end)

digital.set(devices.LOCK_S0402, false)
digital.set(devices.LOCK_X0403, false)
digital.set(devices.LOCK_X0404, false)
digital.set(devices.LOCK_S0406, false)
digital.set(devices.LOCK_X0408, false)

digital.set(devices.W0402, false)
digital.set(devices.W0404, true)
digital.set(devices.W0406, false)
digital.set(devices.W0408, false)

chat.setName("淘金")
chat.setDistance(100)
chat.say("系统初始化完毕")

while true do
  eventbus.handle(event.pull())
end
