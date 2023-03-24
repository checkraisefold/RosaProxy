local utils = {}

---@param str string
---@param sep string
function utils.strSplit(str: string, sep: string)
	local parts = {}
	local pos = 0
	local splitIterator = function()
		return str:find(sep, pos, true)
	end
	for sepStar, sepEnd in splitIterator do
		table.insert(parts, str:sub(pos, sepStart - 1))
		pos = sepEnd + 1
	end
	table.insert(parts, str:sub(pos))
	return parts
end

-- Encodes an IP address in little endian.
---@param host string
function utils.encodeHost(host: string): string
	local tempEncode = {}
	local splitHost: {string} = utils.strSplit(host, ".")

	local loopIdx = 1
	for i = #splitHost, 1, -1 do
		tempEncode[loopIdx] = splitHost[i]
		loopIdx = loopIdx + 1
	end

	return string.pack("BBBB", table.unpack(tempEncode))
end

return utils
