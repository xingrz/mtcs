local component = require("component")
local top = require("sides").top

local segment = {}
segment.__index = segment

local numbers = {
  [0] = 0xFC, [1] = 0x0C, [2] = 0xDA, [3] = 0x9E, [4] = 0x2E,
  [5] = 0xB6, [6] = 0xF6, [7] = 0x1C, [8] = 0xFE, [9] = 0xBE
}

local off = { [0] = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }

function segment.bind(address)
  local self = setmetatable({}, segment)

  if (component.type(address) ~= "redstone") then
    print("segment should be bound to a redstone component")
    return nil
  end

  self.address = address

  return self
end

function segment.put(self, number)
  local l = number % 10
  local h = (number - l) / 10

  local result = {}

  local ls = numbers[l]

  for i = 15, 8, -1 do
    result[i] = bit32.band(ls, 1) * 0xFF
    ls = bit32.rshift(ls, 1)
  end

  local hs = numbers[h]

  for i = 7, 0, -1 do
    result[i] = bit32.band(hs, 1) * 0xFF
    hs = bit32.rshift(hs, 1)
  end

  component.proxy(self.address).setBundledOutput(top, result)
end

function segment.clear(self)
  component.proxy(self.address).setBundledOutput(top, off)
end

return segment
