local computer = require("computer")
local keyboard = require("keyboard")
local component = require("component")

local eventbus = { listeners = {} }

function eventbus.handle(event, address, ...)
  if (eventbus.listeners[address] == nil) then
    return
  end

  if (eventbus.listeners[address][event] == nil) then
    return
  end

  eventbus.listeners[address][event](component.proxy(address), ...)
end

function eventbus.on(address, event, listener)
  if (eventbus.listeners[address] == nil) then
    eventbus.listeners[address] = {}
  end

  eventbus.listeners[address][event] = listener
end

if (component.isAvailable('keyboard')) then
  eventbus.on(component.keyboard.address, "key_up", function(k, char, code, p)
    if (keyboard.isAltDown() and code == keyboard.keys.r) then
      computer.shutdown(true)
    end
  end)
end

return eventbus
