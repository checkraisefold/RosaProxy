-- SubProxifier, a Sub Rosa server proxy project created by checkraisefold.
-- Load configuration file
local _config = require("./misc/config")
local config = _config:init("config.json")
if not config then
	return
end

-- Load the logger
local logger = require("./misc/logger")
logger:init(config.logger.logColor, config.logger.logLevel)

-- Module imports
local masterServer = require("./masterServer")
local gameServer = require("./gameServer")
require("./packets/gameServer")
require("./packets/masterServer")

local proxyConfig = config.proxyGameServer
local targetConfig = config.targetGameServer
local masterConfig = config.proxyMasterServer

local currMaster = masterServer.create(masterConfig.host, masterConfig.port, config)
gameServer.create(targetConfig.host, targetConfig.port, proxyConfig.host, proxyConfig.port, config, currMaster)
