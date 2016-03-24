local devices = {}

function devices.load(file)
  local result = {}

  local f = io.open(file)

  for address, name in string.gmatch(f:read("*a"), "[^ ]+[ ]+([^ ]+)[ ]+([^ \n]+)\n") do
    result[name] = address
  end

  f:close()

  return result
end

return devices
