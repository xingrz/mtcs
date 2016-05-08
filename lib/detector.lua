local detector = {}

local eventbus = require("eventbus")

function detector.on(address, listener)
  eventbus.on(address, "minecart", function(detector, type, entityName, primaryColor, secondaryColor, number, owner)
    if number ~= nil then
      listener(number)
    end
  end)
end

return detector
