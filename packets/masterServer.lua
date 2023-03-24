local packetManager = require("../network/packetManager")
local packets = {}

packets.masterServerPing = packetManager.new("MasterServer", 0x40, "MasterServerPing", "c4I2", "")

return packets
