local component = require("component")

local signal = { aspects = component.digital_receiver_box.aspects, listeners = {} }

function signal.handle(address, aspect)
  if (signal.listeners[address] ~= nil) then
    signal.listeners[address](aspect)
  end
end

function signal.listen(address, listener)
  signal.listeners[address] = listener
  listener(signal.get(address))
end

function signal.get(address)
  return component.proxy(address).getSignal()
end

function signal.set(address, aspect)
end

function signal.color(aspect)
  if (aspect == signal.aspects.green) then
    return 0x00FF00
  elseif (aspect == signal.aspects.yellow) then
    return 0xFFFF00
  elseif (aspect == signal.aspects.red) then
    return 0xFF0000
  else
    return 0x000000
  end
end

return signal