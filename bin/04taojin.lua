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

local s0402 = 0  -- S0402 进路：0 未开通，1 正线，2 侧线

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
  else
    s0402 = 1
  end

  if (s0402 == 1) then
    if (signal.get(devices.S0402) == signal.aspects.green) then
      print(os.date() .. " " .. number .. " 准备进入上行站台")
      signal.set(devices.C_S0402, signal.aspects.green)
      digital.set(devices.LOCK_S0402, true)
    else
      print(os.date() .. " " .. number .. " 上行站外停车，等待信号进入上行站台")
      signal.set(devices.C_S0402, signal.aspects.red)
      digital.set(devices.LOCK_S0402, false)
    end
  else
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
      print(os.date() .. " " .. number .. " 准备进入上行站台")
      digital.set(devices.LOCK_S0402, true)
    end
  end
end)

eventbus.on(devices.S0402B, "aspect_changed", function(r, aspect)
  if (s0402 == 2) then
    signal.set(devices.C_S0402, aspect)
    if (aspect == signal.aspects.green) then
      print(os.date() .. " " .. number .. " 准备进入存车线")
      digital.set(devices.W0402, true)
      digital.set(devices.W0404, true)
      digital.set(devices.LOCK_S0402, true)
    end
  end
end)

eventbus.on(devices.DETECTOR_S0401, "minecart", function(d, t, n, p, s, number, o)
  if (number == nil) then
    return
  end

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
