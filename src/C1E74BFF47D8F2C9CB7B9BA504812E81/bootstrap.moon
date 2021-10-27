-- COPY & PASTE INTO EEPROM

-- Shorten name
export fs = filesystem
-- Initialize /dev
if not fs.initFileSystem "/dev"
  computer.panic("Cannot initialize /dev")

disk_uuid = "C1E74BFF47D8F2C9CB7B9BA504812E81"

-- Mount our drive to root
fs.mount "/dev/" .. disk_uuid, "/"

requireCache = {}
export require = (filename) ->
  if not requireCache[filename]
    fs.doFile '/' .. filename .. '.lua'
    requireCache[filename] = true


-- require('box')
require('sushi')

