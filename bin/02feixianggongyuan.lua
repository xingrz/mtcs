-- deps

local event = require("event")

local countdown = require("countdown")
local eventbus = require("eventbus")
local digital = require("digital")
local signal = require("signal")

local devices = require("devices").load("/mtcs/devices/02feixianggongyuan")

local routes = require("routes")

print("Minecraft 计算机列控系统 2.0")
print("===========================================\n")

local STATION_CODE = "02"
local DURATION = 10

digital.set(devices.LOCK_S0201, true)
digital.set(devices.DOOR_S, false)

local countdown_s = countdown.bind(devices.COUNTDOWN_S, DURATION, function(delayed)
  if (signal.get(devices.S0201) == signal.aspects.green) then
    print(os.date() .. " 发车")
    -- digital.set(devices.DOOR_S, false)
    digital.set(devices.LOCK_S0201, true)
  else
    print(os.date() .. " 等待信号")
  end
end)

eventbus.on(devices.DETECTOR_S, "minecart", function(detector, type, en, pc, sc, number, o)
  if (number == nil) then
    return
  end

  print(os.date() .. " 到站: " .. number)

  if (routes.stops(number, STATION_CODE .. "S")) then
    print(os.date() .. " " .. number .. " 停靠本站")

    digital.set(devices.LOCK_S0201, false)
    countdown_s:start()
    -- digital.set(devices.DOOR_S, true)
  else
    print(os.date() .. " " .. number .. " 不停靠本站")
  end
end)

eventbus.on(devices.S0201, "aspect_changed", function(receiver, aspect)
  print(os.date() .. " 信号 " .. aspect)
  if (aspect == signal.aspects.green) then
    countdown_s:go()
  end
end)

-- function show(...)
--     local string = ""
--
--     local args = table.pack(...)
--
--     for i = 1, args.n do
--         string = string .. tostring(args[i]) .. "\t"
--     end
--
--     return string
-- end
--
-- function handle(...)
--   print('evt:' .. show(...))
-- end

while true do
  eventbus.handle(event.pull())
end
