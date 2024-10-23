-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local S = require "modules/settings"

local function LaunchDebugStubIfNeeded()
    if not S.getSetting("UseDebugger") then
      return
    end

    local mav_repo =  reaper.GetResourcePath() .. '/Scripts/Mavriq ReaScript Repository/Various/'

    package.cpath = package.cpath .. ';' .. mav_repo .. 'Mavriq-Lua-Sockets/?.dll' .. ';' .. mav_repo .. 'Mavriq-Lua-Sockets/?.so'
    package.path  = package.path .. ';' ..  mav_repo .. 'Debugging/?.lua' .. ';' ..  mav_repo .. 'Mavriq-Lua-Sockets/?.lua'

    -- Try to load mobedebug
    local succ, mobdebug = pcall(require, "mobdebug")

    if not succ then
      reaper.ShowConsoleMsg("Warning : Launched in Debugger mode, but the debug stub is not installed.\n\z
      You need to install Mavriq Lua Sockets. And, to debug in Visual Studio Code, Lua MobDebug adapter.\n\z
      Continuing without debugger.\n\z
      To turn the Debugger mode off and remove this message, launch the 'OneSmallStep toggle debugger' action.\n\z")
      return
    end

    function ErrorHandler(err)
      reaper.ShowConsoleMsg(err .. '\n' .. debug.traceback())
      mobdebug.pause()
    end

    -- We override Reaper's defer method for two reasons :
    --  We want the full trace on errors
    --  We want the debugger to pause on errors
    local rdefer = reaper.defer
    reaper.defer = function(c)
      return rdefer(function() xpcall(c, ErrorHandler) end)
    end

    mobdebug.start()
  end

  return {
    LaunchDebugStubIfNeeded = LaunchDebugStubIfNeeded
  }
