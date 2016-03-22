local event = require("event")
local segment = require("segment")

local countdown = { number = 0 }

local _timer = nil
local _side
local _duration

function countdown.init(side, duration)
  _side = side
  _duration = duration

  segment.put(_side, 11)
  os.sleep(0.5)
  segment.put(_side, 25)
  os.sleep(0.5)
  segment.put(_side, 88)
  os.sleep(0.5)
  segment.clear(_side)
end

function countdown.start(callback)
  countdown.number = _duration
  _update()

  _timer = event.timer(1, function()
    _tick()
    _update()
    countdown.go(callback)
  end, 115)
end

function countdown.stop()
  if (_timer ~= nil) then
    event.cancel(_timer)
    _timer = nil
  end

  segment.clear(_side)
end

function countdown.go(callback)
  if (countdown.number <= 0) then
    callback(-countdown.number)
  end
end

function _tick()
  countdown.number = countdown.number - 1
end

function _update()
  segment.put(_side, math.abs(countdown.number))
end

return countdown
