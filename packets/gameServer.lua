local packetManager = require("../network/packetManager")
local packets = {}

local requestServInfoObjects = { "gameVersion", "timestamp" }
packets.requestServerInfo =
	packetManager.new("GameServer", 0x00, "RequestServerInfo", "I1I4", nil, requestServInfoObjects)

packets.masterServerPing = packetManager.new("GameServer", 0x40, "MasterServerPing", "")
packets.serverInfoReply = packetManager.new("GameServer", 0x01, "ServerInfoReply", "")
packets.clientInitConnection = packetManager.new("GameServer", 0x02, "ClientInitConnection", "")
packets.masterClientAuth = packetManager.new("GameServer", 0x42, "MasterClientAuth", "")

return packets
