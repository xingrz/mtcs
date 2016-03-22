local digital = require("digital")

local revt = { listeners = {}, last = {} }

function revt.handle(side)
  return function(address, which)
    if (side == which) then
      for port, listener in pairs(revt.listeners) do
        compare(side, port, listener)
      end
    end
  end
end

function revt.listen(side, port, listener)
  revt.listeners[port] = listener
  compare(side, port, listener)
end

function compare(side, port, listener)
  local on = digital.on(side, port)
  if (revt.last[port] ~= on) then
    revt.last[port] = on
    listener(on)
  end
end

return revt
