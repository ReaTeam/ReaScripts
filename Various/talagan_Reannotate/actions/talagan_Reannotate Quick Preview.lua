-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local ACTION      = debug.getinfo(1,"S").source
local ACTION_DIR  = (ACTION:match[[^@?(.*[\/])[^\/]-$]]):gsub("talagan_Reannotate/actions/$","/") -- Works both in dev and prod

package.path      = package.path .. ";" .. ACTION_DIR .. "talagan_Reannotate/?.lua"
package.path      = package.path .. ";" .. reaper.ImGui_GetBuiltinPath() .. '/?.lua'

-- Priorize my dev paths over distribution paths
package.path      = package.path .. ";" .. (reaper.GetResourcePath() .. "/Scripts/Talagan Dev/talagan_ReaImGui Markdown") .. '/?.lua'
package.path      = package.path .. ";" .. (reaper.GetResourcePath() .. "/Scripts/Talagan Dev/talagan_EmojImGui") .. '/?.lua'

package.path      = package.path .. ";" .. (reaper.GetResourcePath() .. "/Scripts/ReaTeam Scripts/Development/talagan_ReaImGui Markdown") .. '/?.lua'
package.path      = package.path .. ";" .. (reaper.GetResourcePath() .. "/Scripts/ReaTeam Scripts/Development/talagan_EmojImGui") .. '/?.lua'

local Dependencies        = require "ext/dependencies"
if not Dependencies.checkDependencies() then
  return
end

local AppContext          = require "classes/app_context"
local QuickPreviewOverlay = require "widgets/quick_preview_overlay"

local S                   = require "modules/settings"
local D                   = require "modules/debug"

S.setSetting("UseDebugger", true)
S.setSetting("UseProfiler", false)
D.LaunchDebugStubIfNeeded()
D.LaunchProfilerIfNeeded()

local app_ctx     = AppContext:new()
local overlay     = QuickPreviewOverlay:new()

-- Force focus on the main window to avoid glitches
reaper.JS_Window_SetFocus(app_ctx.mv.hwnd)

if app_ctx.launch_context:isLaunchedByKeyboardShortcut() then
  -- The action is launched by shortcut
  -- Prevent the action to be re-launched (flag == 2).
  -- We'll track the holding of the shortcut and quit when released
  reaper.set_action_options(4|2)
else
  -- The action is launched from a button... or something else
  -- We want it to keep running until it's toggled off
  reaper.set_action_options(1|4)
end

--log("Launched")

function MainLoop()
  app_ctx:tick()

  if app_ctx.launch_context:isLaunchedByKeyboardShortcut() and not app_ctx.launch_context:isShortcutStillPressed() then
    app_ctx.shortcut_was_released_once = true
  end

  --log("Running...")
  app_ctx:updateWindowLayouts()

  if app_ctx.arrange_view_watcher:tick() then
    overlay:updateVisibleThings()
  end

  overlay:draw()

  if app_ctx.want_quit then
    return
  end

  -- Defer the loop
  reaper.defer(MainLoop)
end

-- Set focus to the arrange view. This prevent bugs
-- For example if the MIDI Editor has focus, the held shortcut
-- Will glitch
reaper.defer(MainLoop)

-- Register cleanup function on script exit
reaper.atexit(function()
  -- Restore focus.
  reaper.JS_Window_SetFocus(app_ctx.launch_context.focused_hwnd)
  reaper.set_action_options(8)
  --log("Exiting.")
end)
