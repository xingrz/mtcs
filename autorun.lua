local fs = require("filesystem")

if (not fs.exists("/mtcs")) then
  print("Detected a new computer, installing MTCS")
  fs.copy("/mnt/9b2/install/100_mtcs.lua", "/boot/100_mtcs.lua")
  print("MTCS is install, please reboot")
end
