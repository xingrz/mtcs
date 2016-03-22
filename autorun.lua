local fs = require("filesystem")

if (not fs.exists("/mtcs")) then
    fs.copy("install/100_mtcs.lua", "/boot/100_mtcs.lua")
end
