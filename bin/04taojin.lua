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

eventbus.on(devices.DETECTOR_S0402, "minecart", function(d, t, n, p, s, number, o)
  if (number == nil) then
    return
  end

  -- 如果折返
  if (routes.stops(number, STATION_CODE .. "X")) then
    print(os.date() .. " " .. number .. " 准备折返")
  end
end)

while true do
  eventbus.handle(event.pull())
end
