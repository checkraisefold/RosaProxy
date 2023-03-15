-- SubProxifier, a Sub Rosa server proxy project created by checkraisefold.
-- Load configuration file
local _config = require("./misc/config")
local config = _config:init("config.json")
if not config then
	return
end

-- Module imports
local logger = require("./misc/logger")
local sockManager = require("./network/sockManager")

logger:init(config.logger.logColor, config.logger.logLevel)
