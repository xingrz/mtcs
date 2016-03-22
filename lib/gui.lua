local unicode = require("unicode")

return function(gpu)

  local gui = {}

  function gui.fill(gpu, x, y, w, h, color)
    local back = gpu.getBackground()

    gpu.setBackground(color)
    gpu.fill(x * 2 - 1, y, w * 2, h, " ")

    gpu.setBackground(back)
  end

  function gui.button(gpu, x, y, text, pressed)
    local fore = gpu.getForeground()
    local back = gpu.getBackground()

    if (pressed) then
      gpu.setForeground(0x000000)
      gpu.setBackground(0xFFFFFF)
    else
      gpu.setForeground(0xFFFFFF)
      gpu.setBackground(0x222222)
    end

    local length = unicode.wlen(text)

    fill(x, y, length / 2 + 2, 3, gpu.getBackground())
    gpu.set(x * 2 - 1 + 2, y + 1, text)

    gpu.setForeground(fore)
    gpu.setBackground(back)
  end

  return gui

end
