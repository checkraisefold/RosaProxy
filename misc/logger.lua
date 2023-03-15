---@class Logger
---@field private _color boolean
---@field private _logLevel string
---@field private _logFile string?
---@field private _colorCache table
---@field private _initialized boolean
local Logger = {
	_color = true,
	_logLevel = "debug",
	_logFile = nil,
	_colorCache = {},
	_initialized = false,
}

-- Log levels to compare against to determine what logs to push to console
local logLevels = {
	error = 1,
	warn = 2,
	info = 4,
	debug = 8,
}

-- Function that does random math to turn text into a Xterm color for use in vterm ANSI sequence
---@param text string
---@private
function Logger:_textToColor(text)
	if self._colorCache[text] then
		return self._colorCache[text]
	end

	local color = 0
	for char = 1, #text do
		color = color + text:byte(char) * 24
	end

	local colorResult = (color % (230 - 17 + 1)) + 17
	self._colorCache[text] = colorResult
	return colorResult
end

-- Internal logging function used by the wrappers
---@param category string
---@param ... string
---@private
function Logger:_log(methodPrefix, level, category, ...)
	if logLevels[level] > logLevels[self._logLevel] then
		return
	end

	local logText = os.date("%I:%M:%S %p | ")
	local argsTable = { ... }

	if self._color then
		local categoryColor = self:_textToColor(category)
		local categoryPrefix = "\27[38;5;" .. tostring(categoryColor) .. "m[" .. category .. "]\27[0m "
		logText = logText .. methodPrefix .. categoryPrefix .. table.concat(argsTable, " ")

		print(logText)
	else
		local categoryPrefix = "[" .. category .. "] "
		logText = logText .. methodPrefix .. categoryPrefix .. table.concat(argsTable, " ")

		print(logText)
	end
end

-- Error logging wrapper
---@param category string
function Logger:error(category, ...)
	local methodPrefix = nil
	if self._color then
		methodPrefix = "\27[38;5;196mError\27[0m   | "
	else
		methodPrefix = "Error   | "
	end

	self:_log(methodPrefix, "error", category, ...)
end

-- Warning logging wrapper
---@param category string
function Logger:warn(category, ...)
	local methodPrefix = nil
	if self._color then
		methodPrefix = "\27[38;5;208mWarning\27[0m | "
	else
		methodPrefix = "Warning | "
	end

	self:_log(methodPrefix, "warn", category, ...)
end

-- Info logging wrapper
---@param category string
function Logger:info(category, ...)
	local methodPrefix = nil
	if self._color then
		methodPrefix = "\27[38;5;118mInfo\27[0m    | "
	else
		methodPrefix = "Info    | "
	end

	self:_log(methodPrefix, "info", category, ...)
end

-- Debug logging wrapper
---@param category string
function Logger:debug(category, ...)
	local methodPrefix = nil
	if self._color then
		methodPrefix = "\27[38;5;45mDebug\27[0m   | "
	else
		methodPrefix = "Debug   | "
	end

	self:_log(methodPrefix, "debug", category, ...)
end

-- Initializes the members of the Logger class
---@param color boolean?
---@param logLevel string?
---@param file string?
function Logger:init(color, logLevel, file)
	if color == false then
		self._color = false
	end
	self._logLevel = logLevel or "debug"
	self._logFile = file or nil
	self._initialized = true

	self:info("Logger", "Logger initialized!")
end

return Logger
