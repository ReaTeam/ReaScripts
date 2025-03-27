--[[
@description Legatool : legato tool for the MIDI Editor
@version 0.4.2
@author Ben 'Talagan' Babut
@license MIT
@donation https://www.paypal.com/donate/?business=3YEZMY9D6U8NC&no_recurring=1&currency_code=EUR
@links
  Forum Thread TODO https://forum.cockos.com/
@changelog
  - [Bug Fix] Re-activated accidentally commented trick that allows the ME to receive editing shortcuts when using Legatool (Legatool's window should be on the top of the editor AND give back focus to it)
@provides
  [main=midi_editor] .
  [nomain] talagan_Legatool/modules/**/*.lua
  [nomain] talagan_Legatool/ext/**/*.lua
  [nomain] talagan_Legatool/app.lua
@about
  # Purpose
  Legatool is a simple tool for editing "legatos" i.e. two consecutive notes for which you want to keep the relation between the first note's end and the second note's start.
  Some VSTs build part of their legato logic on this relation ; but sometimes your legato will not sound "in time" and you want to move the transition without breaking its sound.
  Thatis when  Legatool is useful.
  # How to use
  Launch it from MIDI Editor > actions. Legatool will start to run in the background and watch for your MIDI Editor selections.
  If two notes are selected in the active take, the adjusting window will appear. Otherwise, Legatool will remain silent and invisible.
  The UI is extremly simple, it's just one slider representing the full span (first midi note start - second midi note end).
  By adjusting the slider, you will move both first note's end and second note's start.
  # Toolbar support
  You can attach Legatool to your MIDI Editor's toolbar, so it can be toggled on/off.
  In ON state, it runs in the background, and will only be visible if the MIDI note selection is pertinent. In OFF state, it's just not launched at all.
--]]

-- Path
PATH            = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]]

package.path    = PATH  .. "/?.lua" .. ";"                  .. package.path
package.path    = PATH  .. "talagan_Legatool/?.lua" .. ";"  .. package.path

local DEPS      = require "ext/dependencies"
if not DEPS.checkDependencies() then return end

package.path    = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path

-----------------------------------------------
-- Developer / low level stuff / debug / profile

local S         = require "modules/settings"
local Debugger  = require "modules/debug"
local LOG       = require "modules/log"
local App       = require "talagan_Legatool/app"

S.setSetting("UseDebugger", false)
S.setSetting("UseProfiler", false)
LOG.setLevel(LOG.LOG_LEVEL_NONE)

Debugger.LaunchDebugStubIfNeeded()
Debugger.LaunchProfilerIfNeeded()

--------------------------------

-- Tell the script to be terminated if relaunched.
-- Check the existence of the function for sanity (added in v 7.03)
if reaper.set_action_options ~= nil then
  reaper.set_action_options(1)
end

-----------------------------------------------

App.run({action=debug.getinfo(1,"S").source})
