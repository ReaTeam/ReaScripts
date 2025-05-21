-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local S = require "modules/settings"

local function LaunchDebugStubIfNeeded()

  local should_debug = S.getSetting("UseDebugger")

  if should_debug then
    reaper.ShowConsoleMsg("Beware, debugging is on. Loading VS debug extension ...")

    -- Use VSCode extension
    local vscode_ext_path = os.getenv("HOME") .. "/.vscode/extensions/"
    local p    = 0
    local sdir = ''
    while sdir do
      sdir = reaper.EnumerateSubdirectories(vscode_ext_path, p)
      if not sdir then
        reaper.ShowConsoleMsg(" failed *******.\n")
        break
      else
        if sdir:match("antoinebalaine%.reascript%-docs") then
          dofile(vscode_ext_path .. "/" .. sdir .. "/debugger/LoadDebug.lua")
          reaper.ShowConsoleMsg(" OK!\n")
          break
        end
      end
      p = p + 1
    end
  end

  -- We override Reaper's defer method for two reasons :
  -- We want the full trace on errors
  -- We want the debugger to pause on errors

  local rdefer = reaper.defer
  reaper.defer = function(c)
    return rdefer(function() xpcall(c,
      function(err)
        reaper.ShowConsoleMsg(err .. '\n\n' .. debug.traceback())
      end)
    end)
  end
end

-- Profiler launcher
local function LaunchProfilerIfNeeded()
    if S.getSetting("UseProfiler") then

        -- Functions need to be preloaded for profiling to be able to instrument them
        -- So, force preload DSP functions before "attach to world"

        -- Require here all files containing things to be profiled.

        local E                     = require "engine_lib"
        local H                     = require "helper_lib"
        local AT                    = require "modules/action_triggers"
        local ART                   = require "modules/articulations"
        local S                     = require "modules/settings"


        local profiler = dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Scripts/Development/cfillion_Lua profiler.lua')
        reaper.defer = profiler.defer
        profiler.attachToWorld() -- after all functions have been defined
        profiler.run()
    end
end

return {
  LaunchDebugStubIfNeeded = LaunchDebugStubIfNeeded,
  LaunchProfilerIfNeeded  = LaunchProfilerIfNeeded
}
