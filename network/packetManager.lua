local logger = require("../misc/logger")

---@class Packet
---@field magicType number
---@field type string
---@field encodeFormat string
---@field decodeFormat string
local Packet = {}

---@class PacketManager
---@field private _packets table
local PacketManager = {
	_packets = {},
}

-- Encodes data based on Packet's encodeFormat.
---@param ... any
---@return string encoded
---@return boolean success
function Packet:encode(...)
	local packetData = string.pack(self.encodeFormat, ...)
	return "7DFP" .. string.pack("I1", self.magicType) .. packetData, true
end

-- Decodes data based on Packet's decodeFormat.
---@param data string
---@return string decoded
---@return boolean success
function Packet:decode(data)
	if data:sub(1, 4) ~= "7DFP" then
		return "packet has invalid magic", false
	end
	if data:byte(5, 5) == self.magicType then
		return "packet has invalid type", false
	end

	return string.unpack(self.decodeFormat, data), true
end

-- Gets a packet based on readable type name.
---@param readType string The human-readable packet name.
function PacketManager:getPacket(readType)
	return self._packets[readType]
end

-- Create a new packet type.
---@param rawType number The hexadecimal packet type.
---@param readType string The human-readable packet name.
---@param encodeFormat string? Format to encode packet in. http://www.lua.org/manual/5.4/manual.html#6.4.2
---@param decodeFormat string? Format to decode packet in. http://www.lua.org/manual/5.4/manual.html#6.4.2
function PacketManager.new(rawType, readType, encodeFormat, decodeFormat)
	assert(encodeFormat and decodeFormat, "new packet has no format")

	---@type Packet
	local self = setmetatable({}, { __index = Packet })
	self.magicType = rawType
	self.type = readType
	self.encodeFormat = encodeFormat or decodeFormat
	self.decodeFormat = decodeFormat or encodeFormat

	PacketManager._packets[readType] = self
	return self
end

logger:info("PacketManager", "PacketManager is initialized!")
return PacketManager
