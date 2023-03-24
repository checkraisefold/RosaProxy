local utils = {}

---@param str string
---@param sep string
function utils.strSplit(str, sep)
	local parts = {}
	local pos = 0
	local splitIterator = function()
		return str:find(sep, pos, true)
	end
	for sepStart, sepEnd in splitIterator do
		table.insert(parts, str:sub(pos, sepStart - 1))
		pos = sepEnd + 1
	end
	table.insert(parts, str:sub(pos))
	return parts
end

-- Encodes an IP address in little endian.
---@param host string
function utils.encodeHost(host)
	local tempEncode = {}
	local splitHost = utils.strSplit(host, ".")

	local loopIdx = 1
	for i = #splitHost, 1, -1 do
		tempEncode[loopIdx] = splitHost[i]
		loopIdx = loopIdx + 1
	end

	return string.pack("BBBB", table.unpack(tempEncode))
end

return utils
