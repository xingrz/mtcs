-- deps

local event = require("event")

local signal = require("signal")

local addresses = require("mapping").load("/mtcs/mapping/04taojin.txt")

print("Minecraft 计算机列控系统 2.0")
print("===========================================\n")

function handle(evt, ...)
  -- print('evt:' .. (...))
end

while true do
  handle(event.pull())
end
