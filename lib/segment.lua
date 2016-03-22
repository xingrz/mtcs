local rs = require("component").redstone

local segment = {}

local numbers = {
  [0] = 0xFC, [1] = 0x0C, [2] = 0xDA, [3] = 0x9E, [4] = 0x2E,
  [5] = 0xB6, [6] = 0xF6, [7] = 0x1C, [8] = 0xFE, [9] = 0xBE
}

local off = { [0] = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }

function segment.put(display, number)
  local l = number % 10
  local h = (number - l) / 10

  local result = {}

  local ls = numbers[l]

  for i = 7, 0, -1 do
    result[i] = bit32.band(ls, 1) * 0xFF
    ls = bit32.rshift(ls, 1)
  end

  local hs = numbers[h]

  for i = 15, 8, -1 do
    result[i] = bit32.band(hs, 1) * 0xFF
    hs = bit32.rshift(hs, 1)
  end

  rs.setBundledOutput(display, result)
end

local countdown = 0

function segment.clear(display)
  rs.setBundledOutput(display, off)
end

return segment
