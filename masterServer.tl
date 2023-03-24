local logger = require("./misc/logger")
local utils = require("./misc/utils")
local packetManager = require("./network/packetManager")
local sockManager = require("./network/sockManager")
local packets = require("./packets/masterServer")

---@class MasterServer
---@field host string
---@field port number
---@field socket ManagedSocket?
local MasterServer = {}
local loadedConfig = nil

---@param msg string
---@param port number
---@param host string
function MasterServer:send(msg, port, host)
	self.socket:send(msg, port, host)
end

---@param msg string
---@param responseInfo table
function MasterServer:onMsg(msg, responseInfo)
	if not packetManager:valid(msg) then
		logger:debug("MasterServer", "Invalid packet received from %s:%u.", responseInfo.ip, responseInfo.port)
		return
	end

	local packet = packetManager:getPacket("MasterServer", packetManager:type(msg))
	if not packet then
		logger:debug(
			"MasterServer",
			"Unknown packet received with type %#x from %s:%u.",
			packetManager:type(msg),
			responseInfo.ip,
			responseInfo.port
		)
		return
	end

	if packet.type == "MasterServerPing" then
		local gameConfig = loadedConfig.proxyGameServer
		local leHost = utils.encodeHost(gameConfig.encodeHost)
		local encoded = packet:encode(leHost, gameConfig.port)

		self.socket:send(encoded, responseInfo.port, responseInfo.ip)
	end
end

---@private
function MasterServer:_initSocket()
	self.socket = sockManager.create("MasterServer", self.port, self.host, nil, self.onMsg, self)
end

---@param host string
---@param port number
---@param config table
function MasterServer.create(host, port, config)
	local self = setmetatable({}, { __index = MasterServer })
	self.host = host
	self.port = port

	loadedConfig = config
	self:_initSocket()

	logger:info("MasterServer", "MasterServer on port %u initialized!", port)
	return self
end

return MasterServer
