-- Shorten name
local fs = filesystem
-- Initialize /dev
if fs.initFileSystem("/dev") == false then
    computer.panic("Cannot initialize /dev")
end

local disk_uuid = "EA918DFD4482B5FD9BA3BBABA4CADC7B"
-- Mount our drive to root
fs.mount("/dev/"..disk_uuid, "/")

fs.doFile('/autocraft.lua')
