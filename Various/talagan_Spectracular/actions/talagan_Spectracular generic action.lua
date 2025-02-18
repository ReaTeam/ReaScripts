-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local ACTION    = debug.getinfo(1,"S").source

PATH            = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]]

package.path    = PATH                          .. "/?.lua" .. ";"                      .. package.path
package.path    = PATH                          .. "talagan_Spectracular/?.lua" .. ";"  .. package.path

local DEPS      = require "ext/dependencies"
if not DEPS.checkDependencies() then return end

package.path    = reaper.ImGui_GetBuiltinPath() .. '/?.lua'                     .. ";"  .. package.path

-----------------------------------------------
-- Developer / low level stuff / debug / profile

local S         = require "modules/settings"
local Debugger  = require "modules/debug"
local LOG       = require "modules/log"
local UNIT_TEST = require "modules/unit_test"
local App       = require "talagan_Spectracular/app"

S.setSetting("UseDebugger", false)
S.setSetting("UseProfiler", false)
LOG.setLevel(LOG.LOG_LEVEL_NONE)

Debugger.LaunchDebugStubIfNeeded()
Debugger.LaunchProfilerIfNeeded()
if S.getSetting("UseDebugger") then  UNIT_TEST.launch() end

-----------------------------------------------

App.run({action=ACTION})
