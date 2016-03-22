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

return digital
