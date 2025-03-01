--[[
@description MaCCLane : Tabs for the MIDI Editor
@version 0.1.1
@author Ben 'Talagan' Babut
@license MIT
@donation https://www.paypal.com/donate/?business=3YEZMY9D6U8NC&no_recurring=1&currency_code=EUR
@links
  Forum Thread : https://forum.cockos.com/showthread.php?t=298707
@changelog
  - Moved '+' buttons in tab editor to the left (thanks @Seventh Sam)
  - Fixed wrong colors for track and item tabs under windows / native endianess problem (thanks @Seventh Sam)
  - Added font size configuration (thanks @Seventh Sam)
  - New action entries will propose "MIDI Editor" by default (thanks @Seventh Sam)
  - Replaced "Overload" by "Override" in the UI, less confusing (thanks @Seventh Sam)
  - Added search to CC Lane Combo boxes (thanks @Seventh Sam)
@provides
  [main=main] .
  [nomain] talagan_MaCCLane/**/*.lua
  [data] talagan_MaCCLane/data/_PUT_YOUR_MACCLANE_TEMPLATES_HERE.md > MaCCLane/
@about
  # Purpose

    MaCCLane is a widget that installs itself at the bottom of the MIDI Editor and brings a tab system to quickly call MIDI Editor configurations. This may include CC Lanes, window layout, piano roll, midi chans, and more.

    Proposed tabs are contextual to what's being edited, and may be stored in the project, on the track or on the edited item. They can thus be stored in track templates, or may be stored as templates themselves.

  # Install Notes

    This tool need additional ReaScript packages. You'll be prompted at launch if you don't have them yet.

  # Reaper forum thread

    The official discussion thread is located here : https://forum.cockos.com/showthread.php?t=298707

  # Documentation

    No documentation yet (see forum thread ATM)

  # Credits

    Special thanks to Christian Fillion for ReImGui, Julian Sader for the JS API. Thanks to all donators and brain contributors !!

--]]


-- Path
PATH            = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]]

package.path    = PATH  .. "/?.lua" .. ";"                  .. package.path
package.path    = PATH  .. "talagan_MaCCLane/?.lua" .. ";"  .. package.path

local DEPS      = require "ext/dependencies"
if not DEPS.checkDependencies() then return end

package.path    = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path

-----------------------------------------------
-- Developer / low level stuff / debug / profile

local S         = require "modules/settings"
local Debugger  = require "modules/debug"
local LOG       = require "modules/log"
local App       = require "talagan_MaCCLane/app"

S.setSetting("UseDebugger", false)
S.setSetting("UseProfiler", false)
LOG.setLevel(LOG.LOG_LEVEL_NONE)

Debugger.LaunchDebugStubIfNeeded()
Debugger.LaunchProfilerIfNeeded()

--------------------------------

-- Tell the script to be terminated if relaunched.
-- Check the existence of the function for sanity (added in v 7.03)
if reaper.set_action_options ~= nil then
  reaper.set_action_options(1);
end

-----------------------------------------------

App.run({action=debug.getinfo(1,"S").source})
