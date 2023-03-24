--local udp = require("dgram")
local timer = require("timer")
local logger = require("./misc/logger")
local utils = require("./misc/utils")
local packetManager = require("./network/packetManager")
local sockManager = require("./network/sockManager")
local packets = require("./packets/gameServer")

---@class ClientSocket
---@field clientHost string
---@field clientPort number
---@field clientIdent any
---@field port number
---@field socket ManagedSocket?
---@field gameServer GameServer
---@field lastTraffic number
---@field private _trafficTimer any
local ClientSocket = {}

---@class GameServer
---@field targetHost string
---@field targetPort number
---@field host string
---@field port number
---@field socket ManagedSocket?
---@field clientSockets table<string, ClientSocket>
---@field masterServer MasterServer
---@field private _cachedTargetInfo string?
---@field private _encodedHost string
local GameServer = {}
local loadedConfig = nil

---@param msg string
---@param responseInfo table
function GameServer:onMasterMsg(msg, responseInfo)
	local packet = packetManager:getPacket("GameServer", packetManager:type(msg))
	if not packet then
		logger:debug(
			"GameServer",
			"Unknown packet received with type %#x from %s:%u.",
			packetManager:type(msg),
			responseInfo.ip,
			responseInfo.port
		)
		return
	end

	if packet.type == "MasterClientAuth" then
		logger:debug(
			"GameServer",
			"Forwarding master server auth to target gameserver for %s:%u",
			responseInfo.ip,
			responseInfo.port
		)
		self.masterServer:send(msg, self.targetPort, self.targetHost)
	end
end

---@param msg string
---@param responseInfo table
function GameServer:onClientMsg(msg, responseInfo)
	local packet = packetManager:getPacket("GameServer", packetManager:type(msg))
	local clientIdent = responseInfo.ip .. ":" .. tostring(responseInfo.port)
	if (not packet) and self.clientSockets[clientIdent] then
		local clientSock = self.clientSockets[clientIdent]
		clientSock:send(msg, self.targetPort, self.targetHost)

		return
	elseif not packet then
		logger:debug(
			"GameServer",
			"Unknown packet received with type %#x from %s:%u.",
			packetManager:type(msg),
			responseInfo.ip,
			responseInfo.port
		)
		return
	end

	if packet.type == "RequestServerInfo" and self._cachedTargetInfo then
		local success, decoded = packet:decode(msg)
		if not success then
			logger:warn("GameServer", "Server info request failed to decode!")
		end

		---@type string
		local info = self._cachedTargetInfo
		local toReply = info:sub(1, 6) .. string.pack("I4", decoded.timestamp) .. info:sub(11)
		self.socket:send(toReply, responseInfo.port, responseInfo.ip)
	elseif packet.type == "ClientInitConnection" then
		local clientSock = self.clientSockets[clientIdent]
		if clientSock then
			clientSock:send(msg, self.targetPort, self.targetHost)
			return
		end

		clientSock = ClientSocket.create(responseInfo.ip, responseInfo.port, self, clientIdent)
		clientSock:send(msg, self.targetPort, self.targetHost)
	end
end

---@param msg string
---@param responseInfo table
function GameServer:onServerMsg(msg, responseInfo)
	local packet = packetManager:getPacket("GameServer", packetManager:type(msg))
	if not packet then
		logger:debug(
			"GameServer",
			"Unknown packet received with type %#x from %s:%u.",
			packetManager:type(msg),
			responseInfo.ip,
			responseInfo.port
		)
		return
	end

	if packet.type == "ServerInfoReply" then
		self._cachedTargetInfo = msg
	end
end

---@param msg string
---@param responseInfo table
function GameServer:onMsg(msg, responseInfo)
	if not packetManager:valid(msg) then
		logger:debug("GameServer", "Invalid packet received from %s:%u.", responseInfo.ip, responseInfo.port)
	end

	local masterConfig = loadedConfig.targetMasterServer
	if responseInfo.ip == self.targetHost and responseInfo.port == self.targetPort then
		self:onServerMsg(msg, responseInfo)
	elseif responseInfo.ip == masterConfig.host and responseInfo.port == masterConfig.port then
		self:onMasterMsg(msg, responseInfo)
	else
		self:onClientMsg(msg, responseInfo)
	end
end

-- Encodes the GameServer host in little endian.
---@private
function GameServer:_encodeHost()
	local proxyConfig = loadedConfig.proxyGameServer
	self._encodedHost = utils.encodeHost(proxyConfig.encodeHost)
end

-- Initializes GameServer socket field and sets up periodic pings.
---@private
function GameServer:_initSocket()
	self.socket = sockManager.create(
		"GameServer",
		self.port,
		self.host,
		{ targetHost = self.targetHost, targetPort = self.targetPort },
		self.onMsg,
		self
	)

	local proxyConfig = loadedConfig.proxyGameServer
	local masterConfig = loadedConfig.targetMasterServer
	local function updateCachedInfo()
		local toSend = {}
		toSend.gameVersion = loadedConfig.gameVersion
		toSend.timestamp = (os.clock() * 1000) % ((2 ^ 32) - 1)

		local encoded = packets.requestServerInfo:encode(toSend)
		self.socket:send(encoded, self.targetPort, self.targetHost)
	end
	local function pingMaster()
		local encoded = packets.masterServerPing:encode()
		self.socket:send(encoded, masterConfig.port, masterConfig.host)
	end

	-- Periodically ping the master server and update server info.
	timer.setInterval(proxyConfig.updateCachedInfoInterval, function()
		updateCachedInfo()
	end)
	timer.setInterval(proxyConfig.pingMasterInterval, function()
		pingMaster()
	end)

	-- Update both immediately as the gameserver starts.
	updateCachedInfo()
	pingMaster()
end

-- Creates a GameServer object.
---@param targetHost string The host (IP) of the Sub Rosa dedicated server you wish to proxy.
---@param targetPort number Port of dedicated server.
---@param host string Host to bind proxy gameserver to.
---@param port number Port to bind proxy gameserver to.
---@param config table Config loaded from config module.
---@param masterServer MasterServer The master server to use.
function GameServer.create(targetHost, targetPort, host, port, config, masterServer)
	local self = setmetatable({}, { __index = GameServer })
	self.targetHost = targetHost
	self.targetPort = targetPort
	self.host = host
	self.port = port
	self.clientSockets = {}
	self.masterServer = masterServer

	loadedConfig = config
	self:_encodeHost()
	self:_initSocket()

	logger:info("GameServer", "GameServer on port %u initialized!", port)
	return self
end

function ClientSocket:send(...)
	self.lastTraffic = os.clock()
	return self.socket:send(...)
end

---@param msg string
---@param responseInfo table
function ClientSocket:onMsg(msg, responseInfo)
	local server = self.gameServer
	if (responseInfo.ip ~= server.targetHost) or (responseInfo.port ~= server.targetPort) then
		logger:debug("GameServer", "ClientSocket mismatch. %s:%u", responseInfo.ip, responseInfo.port)
		return
	end

	self.lastTraffic = os.clock()
	server.socket:send(msg, self.clientPort, self.clientHost)
end

function ClientSocket:destroy()
	self.gameServer.clientSockets[self.clientIdent] = nil
	self.socket:destroy()
	self.socket = nil
	self.gameServer = nil
	timer.clearInterval(self._trafficTimer)
end

---@param clientHost string
---@param clientPort number
---@param gameServer GameServer
---@param clientIdent string
function ClientSocket.create(clientHost, clientPort, gameServer, clientIdent)
	local self = setmetatable({}, { __index = ClientSocket })
	local clientConfig = loadedConfig.clientSockets

	self.clientHost = clientHost
	self.clientPort = clientPort
	self.clientIdent = clientIdent
	self.socket = sockManager.create("ClientSocket", 0, clientConfig.host, nil, ClientSocket.onMsg, self)
	self.port = self.socket.port
	self.lastTraffic = os.clock()

	self.gameServer = gameServer
	self.gameServer.clientSockets[clientIdent] = self

	self._trafficTimer = timer.setInterval((clientConfig.stayAlive + 10) * 1000, function()
		print("RAN TIMER", os.clock(), self.lastTraffic,(os.clock() - self.lastTraffic))
		if (os.clock() - self.lastTraffic) > clientConfig.stayAlive then
			logger:debug(
				"GameServer",
				"Client socket ran out of stayAlive on port %u. Client was %s:%u.",
				self.port,
				self.clientHost,
				self.clientPort
			)
			self:destroy()
		end
	end)

	return self
end

return GameServer
