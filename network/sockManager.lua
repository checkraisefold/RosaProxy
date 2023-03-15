local udp = require("dgram")
local logger = require("../misc/logger")

---@class ManagedSocket
---@field port number
---@field name string
---@field socket table?

---@class SockManager
---@field private _sockets table<number, ManagedSocket>
local SockManager = {
	_sockets = {},
}

---@param name string
---@param port number
---@param host string
---@param onMsg function?
function SockManager:create(name, port, host, onMsg)
	local sockObject = udp.createSocket("udp4")
	if not sockObject then
		logger:error("SockManager", "Failed to create UDP socket!", name, port)
		return
	end
	sockObject:bind(port, host)

	local normalizedPort = port
	if port == 0 then
		local sockAddr = sockObject:address()
		if (not sockAddr) or not sockAddr.port then
			logger:error("SockManager", "Failed to get UDP socket port on system-picked port binding!", name, port)
			return
		end

		normalizedPort = sockAddr.port
	end

	---@type ManagedSocket
	local managedSock = {
		name = name,
		port = normalizedPort,
		socket = sockObject,
	}
	setmetatable(managedSock, { __index = sockObject })
	self._sockets[normalizedPort] = managedSock

    if onMsg then
        sockObject:on("message", onMsg)
    end

	logger:debug("SockManager", "Created UDP socket:", name, normalizedPort)
	return managedSock
end

---@param identifier number|string
function SockManager:get(identifier)
	if type(identifier) == "number" then
		return self._sockets[identifier]
	end

	for _, v in pairs(self._sockets) do
		if v.name == identifier then
			return v
		end
	end
end

logger:info("SockManager", "SockManager initialized!")
return SockManager
