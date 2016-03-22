local bitmap = {}

function bitmap.load(gpu, file)
  local w, h = gpu.getResolution()
  local bg = gpu.getBackground()

  local f = io.open(file, "rb")
  f:seek("set", 0x36)

  for y = h, 1, -1 do
    for x = 1, w, 2 do
      local s = f:read(3)

      local r = string.byte(s, 3)
      local g = string.byte(s, 2)
      local b = string.byte(s, 1)

      local p = 0
      p = bit32.bor(bit32.lshift(p, 8), r)
      p = bit32.bor(bit32.lshift(p, 8), g)
      p = bit32.bor(bit32.lshift(p, 8), b)

      gpu.setBackground(p)
      gpu.fill(x, y, 2, 1, " ")
    end
  end

  f:close()

  gpu.setBackground(bg)
end

return bitmap
