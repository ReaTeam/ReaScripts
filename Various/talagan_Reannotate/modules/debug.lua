-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local S = require "modules/settings"

-- Debugger launcher
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
    ---@diagnostic disable-next-line: duplicate-set-field
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
        local EmojImGui             = require "emojimgui"

        local ImGui                 = require "ext/imgui"
        local ImGuiMd               = require "reaimgui_markdown"
        local ImGuiMdCore           = require "reaimgui_markdown/markdown-imgui"

        local QuickPreviewOverlay   = require "widgets/quick_preview_overlay"
        local OverlayCanvas         = require "widgets/overlay_canvas"

        local Notes                 = require "classes/notes"
        local Sticker               = require "classes/sticker"
        local Color                 = require "classes/color"
        local AppContext            = require "classes/app_context"
        local ArrangeViewWatcher    = require "classes/arrange_view_watcher"

        local profiler = dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Scripts/Development/cfillion_Lua profiler.lua')
        reaper.defer = profiler.defer
        profiler.attachTo('reaper')
        profiler.attachToWorld() -- after all functions have been defined
        profiler.run()
    end
end

return {
    LaunchDebugStubIfNeeded = LaunchDebugStubIfNeeded,
    LaunchProfilerIfNeeded  = LaunchProfilerIfNeeded
}
