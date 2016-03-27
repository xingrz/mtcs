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

-- 上行进入存车线

local s0402 = 0  -- S0402 进路：0 未开通，1 正线，2 侧线

-- 重启复位
digital.set(devices.LOCK_S0402, signal.get(devices.S0402) == signal.aspects.green)

eventbus.on(devices.DETECTOR_S0402, "minecart", function(d, t, n, p, s, number, o)
  if (number == nil) then
    return
  end

  -- 如果 S0402 进路已排列，则忽略检测
  if (s0402 ~= 0) then
    return
  end

  if (routes.stops(number, STATION_CODE .. "K")) then
    s0402 = 2
    if (signal.get(devices.S0402B) == signal.aspects.green) then
      print(os.date() .. " " .. number .. " 准备进入存车线")
      signal.set(devices.C_S0402, signal.aspects.green)
      digital.set(devices.W0402, true)
      digital.set(devices.W0404, true)
      digital.set(devices.LOCK_S0402, true)
    else
      print(os.date() .. " " .. number .. " 上行站外停车，等待信号进入存车线")
      signal.set(devices.C_S0402, signal.aspects.red)
      digital.set(devices.LOCK_S0402, false)
    end
  else
    s0402 = 1
    if (signal.get(devices.S0402) == signal.aspects.green) then
      print(os.date() .. " " .. number .. " 准备进入上行站台")
      signal.set(devices.C_S0402, signal.aspects.green)
      digital.set(devices.LOCK_S0402, true)
    else
      print(os.date() .. " " .. number .. " 上行站外停车，等待信号进入上行站台")
      signal.set(devices.C_S0402, signal.aspects.red)
      digital.set(devices.LOCK_S0402, false)
    end
  end
end)

eventbus.on(devices.DETECTOR_S0406, "minecart", function(d, t, n, p, s, number, o)
  if (number == nil) then
    return
  end

  if (s0402 == 2) then
    print(os.date() .. " " .. number .. " 已进入存车线")
    s0402 = 0
    signal.set(devices.C_S0402, signal.aspects.red)
    digital.set(devices.LOCK_S0402, false)
    digital.set(devices.W0402, false)
    digital.set(devices.W0404, false)
  end
end)

eventbus.on(devices.S0402, "aspect_changed", function(r, aspect)
  if (s0402 == 1) then
    signal.set(devices.C_S0402, aspect)
    if (aspect == signal.aspects.green) then
      print(os.date() .. " 列车准备进入上行站台")
      digital.set(devices.LOCK_S0402, true)
    end
  end
end)

eventbus.on(devices.S0402B, "aspect_changed", function(r, aspect)
  if (s0402 == 2) then
    signal.set(devices.C_S0402, aspect)
    if (aspect == signal.aspects.green) then
      print(os.date() .. " 列车准备进入存车线")
      digital.set(devices.W0402, true)
      digital.set(devices.W0404, true)
      digital.set(devices.LOCK_S0402, true)
    end
  end
end)

-- 存车线进入下行

local s0406 = 0  -- S0406 进路：0 未开通，1 进入下行正线，2 到达下行站台，3 下行站台换向

eventbus.on(devices.DETECTOR_X0404, "minecart", function(d, t, n, p, s, number, o)
  if (number == nil) then
    return
  end

  -- 如果 S0406 进路已排列，则忽略检测
  if (s0406 ~= 0) then
    return
  end

  if (routes.stops(number, STATION_CODE .. "X")) then
    s0406 = 1
    if (signal.get(devices.S0406) == signal.aspects.green) then
      print(os.date() .. " " .. number .. " 准备从存车线进入下行站台")

      -- 封锁 X0403
      signal.set(devices.C_X0403, signal.aspects.red)
      digital.set(devices.LOCK_X0403, false)
      digital.set(devices.LOCK_S0405, false)

      -- 扳道
      digital.set(devices.W0406, true)
      digital.set(devices.W0408, true)

      -- 开放下行站台
      signal.set(devices.C_X0408, signal.aspects.red)
      digital.set(devices.CONTROL_S0405, true)
      digital.set(devices.LOCK_X0408, true)

      -- 开放 S0406
      signal.set(devices.C_S0406, signal.aspects.green)
      digital.set(devices.LOCK_S0406, true)
    else
      print(os.date() .. " " .. number .. " 存车线等待信号进入下行站台")
      signal.set(devices.C_S0406, signal.aspects.red)
      digital.set(devices.LOCK_S0406, false)
    end
  end
end)

eventbus.on(devices.S0406, "aspect_changed", function(r, aspect)
  if (s0406 == 1) then
    signal.set(devices.C_S0406, aspect)
    if (aspect == signal.aspects.green) then
      print(os.date() .. " 列车准备从存车线进入下行站台")

      -- 封锁 X0403
      signal.set(devices.C_X0403, signal.aspects.red)
      digital.set(devices.LOCK_X0403, false)
      digital.set(devices.LOCK_S0405, false)

      -- 扳道
      digital.set(devices.W0406, true)
      digital.set(devices.W0408, true)

      -- 开放下行站台
      digital.set(devices.CONTROL_S0405, true)
      digital.set(devices.LOCK_X0408, true)

      -- 开放 S0406
      signal.set(devices.C_S0406, signal.aspects.green)
      digital.set(devices.LOCK_S0406, true)
    end
  end
end)

-- 下行站台

digital.set(devices.LOCK_X0403, signal.get(devices.X0403) == signal.aspects.green)
digital.set(devices.LOCK_X0408, signal.get(devices.X0408) == signal.aspects.green)

digital.set(devices.DOOR_X, false)
digital.set(devices.CONTROL_S0405, false)

local countdown_x = countdown.bind(devices.COUNTDOWN_X, DURATION, function(delayed)
  if (signal.get(devices.X0408) == signal.aspects.green) then
    print(os.date() .. " 下行站台发车")

    digital.set(devices.DOOR_X, false)
    digital.set(devices.CONTROL_S0405, false)
    digital.set(devices.LOCK_S0405, true)
    digital.set(devices.LOCK_X0408, true)
  end
end)

eventbus.on(devices.DETECTOR_X0408, "minecart", function(d, t, n, p, s, number, o)
  if (number == nil) then
    return
  end

  -- S0406 进路复位
  if (s0406 == 1) then
    print(os.date() .. " " .. number .. " 已从存车线进入下行站台")

    s0406 = 2 -- 到达下行站台

    -- 存车线信号复位
    signal.set(devices.C_S0406, signal.aspects.red)
    digital.set(devices.LOCK_S0406, false)

    -- 道岔复位
    digital.set(devices.W0406, false)
    digital.set(devices.W0408, false)

    countdown_x:start()

    event.timer(2, function()
      digital.set(devices.DOOR_X, true)
    end)
  elseif (s0406 == 2) then
    print(os.date() .. " " .. number .. " 完成折返，下行发车")
    s0406 = 3 -- 换向
    event.timer(2, function()
      s0406 = 0 -- 进路复位
    end)
  elseif (s0406 == 0) then
    if (routes.stops(number, STATION_CODE .. "X")) then
      print(os.date() .. " " .. number .. " 下行站内停车")

      digital.set(devices.LOCK_X0408, false)
      countdown_x:start()

      event.timer(2, function()
        digital.set(devices.DOOR_X, true)
      end)
    end
  end
end)

eventbus.on(devices.X0408, "aspect_changed", function(receiver, aspect)
  if (s0406 ~= 1) then
    signal.set(devices.C_X0408, aspect)
    if (aspect == signal.aspects.green) then
      countdown_x:go()
    end
  end
end)

eventbus.on(devices.X0408B, "aspect_changed", function(receiver, aspect)
  -- TODO
end)

eventbus.on(devices.X0403, "aspect_changed", function(receiver, aspect)
  if (s0406 == 0) then
    signal.set(devices.C_X0403, aspect)
    digital.set(devices.LOCK_X0403, aspect == signal.aspects.green)
  end
end)

-- 上行进站

eventbus.on(devices.DETECTOR_S0401, "minecart", function(d, t, n, p, s, number, o)
  if (number == nil) then
    return
  end

  -- S0402 进路复位
  if (s0402 == 1) then
    s0402 = 0
    signal.set(devices.C_S0402, signal.aspects.red)
    digital.set(devices.LOCK_S0402, false)
  end

  -- TODO ...
end)

while true do
  eventbus.handle(event.pull())
end
