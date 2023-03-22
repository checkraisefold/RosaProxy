local logger = require("./logger")
local json = require("json")
local io = require("io")

---@class Config
---@field private _config table
---@field private _initialized boolean
local Config = {
	_config = {},
	_initialized = false,
}

function Config:get()
	if self._initialized then
		return self._config
	end

	logger:warn("Config", "Config:get() called before init! Returning empty table!")
	return {}
end

function Config:set(key, value)
	if self._initialized then
		self._config[key] = value
		return true
	end

	logger:warn("Config", "Config:set() called before init! Returning false!")
	return false
end

---@param path string
function Config:init(path)
	local configFile, fileErr = io.open(path, "r")
	if not configFile then
		logger:error("Config", "Failed to open configuration file!", fileErr)
		return false
	end

	local configText = configFile:read("a")
	if not configText then
		logger:error("Config", "Failed to read configuration file!")
		return false
	end

	local parsedConfig, parseCode, parseErr = json.parse(configText)
	if (not parsedConfig) or type(parsedConfig) ~= "table" then
		logger:error("Config", "Failed to parse configuration file!", parseCode, parseErr)
		return false
	end

	logger:info("Config", "Config initialized!")

	self._config = parsedConfig
	self._initialized = true

	return self._config
end

return Config
