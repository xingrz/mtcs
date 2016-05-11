-- deps

local event = require("event")

local countdown = require("countdown")
local eventbus = require("eventbus")
local detector = require("detector")
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

local S0401 = { state = 0 }

function S0401.layout()
  digital.set(devices.LOCK_S0401, false)
end

function S0401.open()
  digital.set(devices.LOCK_S0401, true)
end

--

local S0402 = { state = 0 }

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

function S0402.lock()
  digital.set(devices.LOCK_S0402, false)
  signal.set(devices.C_S0402, signal.aspects.red)
end

--

local S0402B = { state = 0 }

function S0402B.layout()
  -- 排列 S0402B
  digital.set(devices.LOCK_S0406, false)
  digital.set(devices.LOCK_X0404, true)

  digital.set(devices.W0402, true)
  digital.set(devices.W0404, false)

  -- 排列完成
  signal.set(devices.C_S0402, signal.aspects.yellow)

  chat.say("S0402B 进路排列完成")
end

function S0402B.open()
  digital.set(devices.LOCK_S0402, true)
  chat.say("S0402B 进路开放")
end

function S0402B.lock()
  digital.set(devices.LOCK_S0402, false)

  digital.set(devices.W0402, false)
  digital.set(devices.W0404, true)

  signal.set(devices.C_S0402, signal.aspects.red)

  chat.say("S0402B 进路复位")
end

--

local S0406 = { state = 0 }

function S0406.layout()
  -- 封锁 X0403
  digital.set(devices.LOCK_X0403, false)

  signal.set(devices.C_X0403, signal.aspects.red)
  signal.set(devices.C_X0410, signal.aspects.red)
  signal.set(devices.C_X0408, signal.aspects.red)

  -- 排列 S0406
  digital.set(devices.LOCK_S0405, false)
  digital.set(devices.LOCK_X0408, true)
  digital.set(devices.LOCK_X0410, true)

  digital.set(devices.CONTROL_S0406, true)
  digital.set(devices.CONTROL_S0405, true)

  digital.set(devices.W0408, true)
  digital.set(devices.W0406, true)

  -- 排列完成
  signal.set(devices.C_S0406, signal.aspects.yellow)

  chat.say("S0406 进路排列完成")
end

function S0406.open()
  digital.set(devices.LOCK_S0406, true)
  digital.set(devices.LOCK_X0404, true)
  chat.say("S0406 进路开放")
end

function S0406.lock()
  digital.set(devices.LOCK_S0406, false)

  signal.set(devices.C_S0406, signal.aspects.red)

  digital.set(devices.W0406, false)
  digital.set(devices.W0408, false)
end

--

local X0408 = { state = 0, number = nil }

function X0408.layout()
  digital.set(devices.W0406, false)
  digital.set(devices.W0408, false)

  signal.set(devices.C_X0408, signal.aspects.green)
end

function X0408.open()
  digital.set(devices.LOCK_X0408, true)
end

function X0408.lock()
  digital.set(devices.LOCK_X0408, false)
  signal.set(devices.C_X0408, signal.aspects.red)
end

--

local X0408B = { state = 0 }
-- TODO

--

local X0410 = { state = 0 }

function X0410.layout()
  digital.set(devices.LOCK_X0410, false)
  digital.set(devices.CONTROL_S0406, false)
  signal.set(devices.C_X0410, signal.aspects.green)
end

function X0410.open()
  digital.set(devices.CONTROL_S0405, false)
  digital.set(devices.LOCK_S0405, true)
  digital.set(devices.LOCK_X0410, true)
end

--

local X0403 = { state = 0 }

function X0403.layout()
  signal.set(devices.C_X0403, signal.aspects.green)
end

function X0403.open()
  digital.set(devices.LOCK_S0405, true)
  digital.set(devices.LOCK_X0403, true)
end

--

-- 上行进入存车线

detector.on(devices.DETECTOR_S0402, function(number)
  -- 0: 复位
  if S0402.state == 0 and S0402B.state == 0 then
    if routes.stops(number, STATION_CODE .. "K") then
      S0402B.state = 1
    else
      S0402.state = 1
    end
  end

  ---- 正线

  -- 1: 尝试排列进路
  if S0402.state == 1 then
    if signal.is_green(devices.S0402) then
      S0402.layout()
      S0402.open()
      S0402.state = 2
    else
      S0402.lock()
    end
    return
  end

  -- 2: 已排列进路
  if S0402.state == 2 then
    S0402.state = 3
    return
  end

  ---- 侧线

  if S0402B.state == 1 then
    if signal.is_green(devices.S0402B) then
      S0402B.layout()
      S0402B.open()
      S0402B.state = 2
    else
      S0402.lock()
    end
    return
  end

  -- 2: 已排列进路
  if S0402B.state == 2 then
    S0402B.state = 3
    return
  end
end)

eventbus.on(devices.S0402, "aspect_changed", function(r, aspect)
  -- 1: 尝试排列进路
  if S0402.state == 1 then
    if signal.is_green(devices.S0402) then
      S0402.layout()
      S0402.open()
      S0402.state = 2
    else
      S0402.lock()
    end
  end

  -- 2: 已排列进路
  -- 3: 已通过
  if S0402.state >= 2 then
    if not signal.is_green(devices.S0402) then
      S0402.lock()
      S0402.state = 0
    end
  end
end)

eventbus.on(devices.S0402B, "aspect_changed", function(r, aspect)
  -- 1: 尝试排列进路
  if S0402B.state == 1 then
    if signal.is_green(devices.S0402B) then
      S0402B.layout()
      S0402B.open()
      S0402B.state = 2
    else
      S0402B.lock()
    end
  end

  -- 2: 已排列进路
  -- 3: 已通过
  if S0402B.state >= 2 then
    signal.yellow(devices.C_S0402, aspect)
  end
end)

detector.on(devices.DETECTOR_S0406, function(number)
  -- 2: 已排列进路
  -- 3: 已通过
  if S0402B.state >= 2 then
    S0402B.lock()
    S0402B.state = 0
  end
end)

-- 存车线进入下行

detector.on(devices.DETECTOR_X0404, function(number)
  -- 忽略车尾
  if S0406.state == 2 then
    S0406.state = 3
    return
  end

  if routes.stops(number, STATION_CODE .. "X") then
    S0406.state = 1

    if signal.is_green(devices.S0406) then
      S0406.layout()
      S0406.open()
      S0406.state = 2
    else
      S0406.lock()
    end
  end
end)

eventbus.on(devices.S0406, "aspect_changed", function(r, aspect)
  if S0406.state ~= 0 then
    signal.yellow(devices.C_S0406, aspect)
  end

  if S0406.state == 1 and signal.is_green(devices.S0406) then
    S0406.layout()
    S0406.open()
    S0406.state = 2
  end
end)

detector.on(devices.DETECTOR_X0408, function(number)
  if S0406.state == 3 then
    return
  end

  -- 0: 复位
  if X0408.state == 0 then
    X0408.state = 1
  end

  -- 1: 尝试排列进路
  if X0408.state == 1 then
    if signal.is_green(devices.X0408) then
      X0408.layout()
      X0408.open()
      X0408.state = 2
    else
      X0408.lock()
    end
    return
  end

  -- 2: 已排列进路
  if X0408.state == 2 then
    X0408.state = 3
    return
  end

  -- TODO: X0408B
end)

eventbus.on(devices.X0408, "aspect_changed", function(receiver, aspect)
  -- 1: 尝试排列进路
  if X0408.state == 1 then
    if signal.is_green(devices.X0408) then
      X0408.layout()
      X0408.open()
      X0408.state = 2
    else
      X0408.lock()
    end
  end

  -- 2: 已排列进路
  -- 3: 已通过
  if X0408.state >= 2 then
    if not signal.is_green(devices.X0408) then
      X0408.lock()
      X0408.state = 0
    end
  end
end)

eventbus.on(devices.X0408B, "aspect_changed", function(receiver, aspect)
  -- TODO
end)

-- 下行站台

local countdown_x = countdown.bind(devices.COUNTDOWN_X, DURATION, function(delayed)
  if signal.is_green(devices.X0410) then
    X0410.state = 2
    X0410.open()
    return true
  end

  return false
end)

detector.on(devices.DETECTOR_X0410, function(number)
  -- 无论如何必须复位 S0406 进路
  S0406.lock()

  -- MARK 1
  if S0406.state == 3 then
    S0406.state = 0
  end

  -- 车尾经过时复位进路
  if X0410.state == 2 then
    X0410.state = 0
    return
  end

  -- 禁止从下行上线该站的折返列车
  -- 假如折返列车从正线顺向插入
  -- 会识别车位地点码，但无法锁车，导致继续计时
  -- 下趟折返列车进入时会将进路复位，导致无法出站

  if routes.stops(number, STATION_CODE .. "X") then
    chat.say(number .. " 下行站内停车")

    X0410.state = 1
    X0410.layout()

    countdown_x:start()

    event.timer(2, function()
      digital.set(devices.DOOR_X, true)
    end)
  end
end)

eventbus.on(devices.X0410, "aspect_changed", function(receiver, aspect)
  if S0406.state == 2 or S0406.state == 3 then
    return
  end

  signal.green(devices.C_X0410, aspect)

  if X0410.state == 1 then
    countdown_x:go()
  else
    digital.set(devices.LOCK_X0410, aspect == signal.aspects.green)
  end
end)

eventbus.on(devices.X0403, "aspect_changed", function(receiver, aspect)
  if S0406.state == 0 then
    signal.green(devices.C_X0403, aspect)
    digital.set(devices.LOCK_X0403, aspect == signal.aspects.green)
  end
end)

-- 上行进站

eventbus.on(devices.S0412, "aspect_changed", function(receiver, aspect)
  digital.set(devices.LOCK_S0412, aspect == signal.aspects.green)
end)

local countdown_s = countdown.bind(devices.COUNTDOWN_S, DURATION, function(delayed)
  digital.set(devices.DOOR_S, false)

  if signal.get(devices.S0401) == signal.aspects.green then
    S0401.open()
    S0401.state = 0
    return true
  end

  return false
end)

detector.on(devices.DETECTOR_S0401, function(number)
  if routes.stops(number, STATION_CODE .. "S") then
    chat.say(number .. " 上行站内停车")

    S0401.state = 1
    S0401.layout()

    countdown_s:start()

    event.timer(2, function()
      digital.set(devices.DOOR_S, true)
    end)
  end
end)

eventbus.on(devices.S0401, "aspect_changed", function(receiver, aspect)
  if S0401.state == 1 then
    countdown_s:go()
  else
    digital.set(devices.LOCK_S0401, aspect == signal.aspects.green)
  end
end)

--

eventbus.on(chat.address, "chat_message", function(c, user, message)
  if message == "S0401.open" then
    countdown_s:stop()
    digital.set(devices.DOOR_S, false)
    S0401.open()
  end

  if message == "S0402.open" then
    S0402.layout()
    S0402.open()
    S0402.state = 3
  end

  if message == "S0402B.open" then
    S0402B.layout()
    S0402B.open()
    S0402B.state = 3
  end

  if message == "S0406.open" then
    S0406.layout()
    S0406.open()
    S0406.state = 2
  end

  if message == "X0403.open" then
    digital.set(devices.LOCK_X0403, true)
  end

  if message == "X0408.open" then
    X0408.layout()
    X0408.open()
    X0408.state = 3
  end

  if message == "X0410.open" then
    countdown_x:stop()
    digital.set(devices.DOOR_X, false)
    X0410.layout()
    X0410.open()
    X0410.state = 2
  end

  if message == "S0412.open" then
    digital.set(devices.LOCK_S0412, true)
  end
end)

digital.set(devices.LOCK_S0401, false)
digital.set(devices.LOCK_S0402, false)
digital.set(devices.LOCK_X0403, signal.get(devices.X0403) == signal.aspects.green)
digital.set(devices.LOCK_X0404, false)
digital.set(devices.LOCK_S0406, false)
digital.set(devices.LOCK_X0408, false)
digital.set(devices.LOCK_X0410, false)
digital.set(devices.LOCK_S0412, signal.get(devices.S0412) == signal.aspects.green)

digital.set(devices.W0402, false)
digital.set(devices.W0404, true)
digital.set(devices.W0406, false)
digital.set(devices.W0408, false)

digital.set(devices.CONTROL_S0405, false)
digital.set(devices.CONTROL_S0406, false)

signal.set(devices.C_S0402, signal.aspects.red)
signal.set(devices.C_X0403, signal.aspects.red)
signal.set(devices.C_S0406, signal.aspects.red)
signal.set(devices.C_X0408, signal.aspects.red)
signal.set(devices.C_X0410, signal.aspects.red)
signal.set(devices.C_S0412, signal.aspects.red)

chat.setName("淘金")
chat.setDistance(100)
chat.say("系统初始化完毕")

while true do
  eventbus.handle(event.pull())
end
