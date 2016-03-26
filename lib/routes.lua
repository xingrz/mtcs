local routes = {}

function load(train)
  local result = {}

  local f = io.open("/mtcs/routes/" .. string.sub(train, 4, 6))

  if (f == nil) then
    return {}
  end

  for code in string.gmatch(f:read("*a"), "(%d+%u)[ ]*[^ \n]*\n") do
    table.insert(result, code)
  end

  f:close()

  return result
end

function routes.stops(train, station)
  for i, code in pairs(load(train)) do
    if (code == station) then
      return true
    end
  end

  return false
end

function routes.bound(train, station)
  local route = load(train)
  return route[#route] == station
end

return routes
