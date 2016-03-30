local event = require("event")
local segment = require("segment")
local component = require("component")

local countdown = {}
countdown.__index = countdown

function countdown.bind(address, duration, callback)
  local self = setmetatable({}, countdown)

  if (component.type(address) ~= "redstone") then
    print("countdown should be bound to a redstone component")
    return nil
  end

  self.remains = 0
  self.timer = nil
  self.duration = duration
  self.callback = callback

  self.segment = segment.bind(address)
  self.segment:clear()

  return self
end

function countdown.start(self)
  self.remains = self.duration
  self._update(self)

  self._timer = event.timer(1, function()
    self._tick(self)
    self._update(self)
    self.go(self)
  end, 115)
end

function countdown.stop(self)
  if (self._timer ~= nil) then
    event.cancel(self._timer)
    self._timer = nil
  end

  self.segment:clear()
end

function countdown.go(self)
  if (self._timer ~= nil and self.remains <= 0) then
    if (self.callback(-self.remains)) then
      self.stop(self)
    end
  end
end

function countdown._tick(self)
  self.remains = self.remains - 1
end

function countdown._update(self)
  self.segment:put(math.abs(self.remains))
end

return countdown
