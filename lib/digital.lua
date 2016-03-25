local component = require("component")
local sides = require("sides")

local digital = {}

function digital.set(address, on)
  local value

  if (on) then
    value = 0xFF
  else
    value = 0x00
  end

  component.proxy(address).setOutput(sides.top, value)
end

function digital.i(address)
  return component.proxy(address).getInput(sides.top) > 0
end

function digital.o(address)
  return component.proxy(address).getOutput(sides.top) > 0
end

return digital
