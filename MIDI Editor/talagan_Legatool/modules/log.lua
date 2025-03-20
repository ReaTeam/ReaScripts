-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Legatool

-- Logger with log levels

local LOG_LEVEL_DEBUG   = 2
local LOG_LEVEL_INFO    = 1
local LOG_LEVEL_NONE    = 0

local log_level         = LOG_LEVEL_NONE

local function _log(str, level)
    if not (log_level >= level) then return end

    reaper.ShowConsoleMsg(str)
end

local function _dbg(str)    _log(str, LOG_LEVEL_DEBUG)  end
local function _info(str)   _log(str, LOG_LEVEL_INFO)   end

local function _set_level(level)
    log_level = level
    if log_level < LOG_LEVEL_NONE  then log_level = LOG_LEVEL_NONE end
    if log_level > LOG_LEVEL_DEBUG then log_level = LOG_LEVEL_DEBUG end
end

local function _get_level()
    return log_level
end

return {
    LOG_LEVEL_DEBUG   = LOG_LEVEL_DEBUG,
    LOG_LEVEL_INFO    = LOG_LEVEL_INFO,
    LOG_LEVEL_NONE    = LOG_LEVEL_NONE,

    getLevel = _get_level,
    setLevel = _set_level,
    info  = _info,
    debug = _dbg,
}
