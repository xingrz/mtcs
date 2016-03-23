-- deps

local event = require("event")
local eventbus = require("eventbus")

local signal = require("signal")

local devices = require("devices").load("/mtcs/devices/04taojin")

print("Minecraft 计算机列控系统 2.0")
print("===========================================\n")

eventbus.on(devices.DETECTOR_X, "minecart", function(detector, type, en, pc, sc, number, o)
  print("detected minecart " .. owner)
end)

eventbus.on(devices.R_S0406, "aspect_changed", function(receiver, aspect)
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
