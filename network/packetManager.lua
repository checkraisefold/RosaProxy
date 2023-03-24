local logger = require("../misc/logger")

---@class Packet
---@field magicType number
---@field type string
---@field encodeFormat string?
---@field decodeFormat string?
---@field encodeObjects table?
---@field decodeObjects table?
local Packet = {}

---@class PacketManager
---@field private _packets table
local PacketManager = {
	_packets = {},
}

-- Encodes data based on Packet's encodeFormat.
---@param ... any
---@return string encoded
function Packet:encode(...)
	local packedTable = { ... }
	if self.encodeObjects then
		packedTable = {}
		for i, v in pairs(...) do
			packedTable[self.encodeObjects[i]] = v
		end
	end

	local packetData = string.pack(self.encodeFormat, table.unpack(packedTable))
	return "7DFP" .. string.pack("I1", self.magicType) .. packetData
end

-- Decodes data based on Packet's decodeFormat.
---@param data string
---@return boolean success
---@return any ...
function Packet:decode(data)
	if data:sub(1, 4) ~= "7DFP" then
		logger:debug("PacketManager", "Packet has invalid magic!")
		return false, "packet has invalid magic"
	end
	if data:byte(5) ~= self.magicType then
		logger:debug("PacketManager", "Packet has invalid type!")
		return false, "packet has invalid type"
	end
	if self.decodeObjects then
		local decodedResult = {}
		local unpacked = { string.unpack(self.decodeFormat, data:sub(6)) }
		table.remove(unpacked, #unpacked)

		for i, v in pairs(unpacked) do
			decodedResult[self.decodeObjects[i]] = v
		end

		return true, decodedResult
	end

	return true, string.unpack(self.decodeFormat, data:sub(6))
end

-- Gets a packet based on raw packet type.
---@param scope string The packet's scope.
---@param rawType number The raw packet type.
---@return Packet?
function PacketManager:getPacket(scope, rawType)
	return self._packets[scope][rawType]
end

-- Checks if a packet is valid.
---@param data string?
function PacketManager:valid(data)
	if (not data) or type(data) ~= "string" then
		return false
	end

	-- 7DFP magic and packet type (1 byte)
	if #data < 5 then
		return false
	end
	if data:sub(1, 4) ~= "7DFP" and data:sub(1, 4) ~= "7DFF" then
		return false
	end

	return true
end

-- Gets an encoded packet's type.
---@param data string
function PacketManager:type(data)
    return data:byte(5, 5)
end

-- Create a new packet type.
---@param scope string The scope for the packet to be used in.
---@param rawType number The hexadecimal packet type.
---@param readType string The human-readable packet name.
---@param encodeFormat string? Format to encode packet in. http://www.lua.org/manual/5.4/manual.html#6.4.2
---@param decodeFormat string? Format to decode packet in. http://www.lua.org/manual/5.4/manual.html#6.4.2
---@param decodeObjects table? Table of objects to decode to.
---@param encodeObjects table? Table of objects to encode from.
---@return Packet
function PacketManager.new(scope, rawType, readType, encodeFormat, decodeFormat, decodeObjects, encodeObjects)
	assert(encodeFormat or decodeFormat, "new packet has no format")

	if not PacketManager._packets[scope] then
		PacketManager._packets[scope] = {}
	end

	---@type Packet
	local self = setmetatable({}, { __index = Packet })
	self.magicType = rawType
	self.type = readType
	self.encodeFormat = encodeFormat or decodeFormat
	self.decodeFormat = decodeFormat or encodeFormat
	self.decodeObjects = decodeObjects
	self.encodeObjects = encodeObjects or decodeObjects

	-- Translates encodeObjects into a format for Packet:encode for better time complexity
	if self.encodeObjects then
		local internalEncodeObjects = {}
		for i, v in pairs(self.encodeObjects) do
			internalEncodeObjects[v] = i
		end

		self.encodeObjects = internalEncodeObjects
	end

	PacketManager._packets[scope][rawType] = self
	return self
end

logger:info("PacketManager", "PacketManager is initialized!")
return PacketManager
