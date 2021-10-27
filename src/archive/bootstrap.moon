-- COPY & PASTE INTO EEPROM

-- Shorten name
export fs = filesystem
-- Initialize /dev
if not fs.initFileSystem "/dev"
  computer.panic("Cannot initialize /dev")

disk_uuid = "EA918DFD4482B5FD9BA3BBABA4CADC7B"

-- Mount our drive to root
fs.mount "/dev/" .. disk_uuid, "/"

requireCache = {}
export require = (filename) ->
  if not requireCache[filename]
    fs.doFile '/' .. filename .. '.lua'
    requireCache[filename] = true


-- require('box')
require('util')
require('inv')
queryInventory()

