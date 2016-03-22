-- deps

local event = require("event")

local signal = require("signal")

local addresses = require("mapping").load("/mtcs/mapping/04taojin")

print("Minecraft 计算机列控系统 2.0")
print("===========================================\n")

function show(...)
    local string = ""

    local args = table.pack(...)

    for i = 1, args.n do
        string = string .. tostring(args[i]) .. "\t"
    end

    return string
end

function handle(...)
  print('evt:' .. show(...))
end

while true do
  handle(event.pull())
end
