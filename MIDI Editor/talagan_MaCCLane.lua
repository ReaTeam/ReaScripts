--[[
@description MaCCLane : Tabs for the MIDI Editor
@version 0.2.5
@author Ben 'Talagan' Babut
@license MIT
@donation https://www.paypal.com/donate/?business=3YEZMY9D6U8NC&no_recurring=1&currency_code=EUR
@links
  Forum Thread : https://forum.cockos.com/showthread.php?t=298707
@changelog
  - [Feature] Embeddable in toolbar button
  - [Feature] Launchable from MIDI Editor section
@provides
  [main=main,midi_editor] .
  [nomain] talagan_MaCCLane/classes/**/*.lua
  [nomain] talagan_MaCCLane/ext/**/*.lua
  [nomain] talagan_MaCCLane/images/**/*.lua
  [nomain] talagan_MaCCLane/lib/**/*.lua
  [nomain] talagan_MaCCLane/modules/**/*.lua
  [nomain] talagan_MaCCLane/app.lua
  [main=main,midi_editor] talagan_MaCCLane/actions/generic_action.lua > talagan_MaCCLane Launch tab by number 1.lua
  [main=main,midi_editor] talagan_MaCCLane/actions/generic_action.lua > talagan_MaCCLane Launch tab by number 2.lua
  [main=main,midi_editor] talagan_MaCCLane/actions/generic_action.lua > talagan_MaCCLane Launch tab by number 3.lua
  [main=main,midi_editor] talagan_MaCCLane/actions/generic_action.lua > talagan_MaCCLane Launch tab by number 4.lua
  [main=main,midi_editor] talagan_MaCCLane/actions/generic_action.lua > talagan_MaCCLane Launch tab by number 5.lua
  [main=main,midi_editor] talagan_MaCCLane/actions/generic_action.lua > talagan_MaCCLane Launch tab by number 6.lua
  [main=main,midi_editor] talagan_MaCCLane/actions/generic_action.lua > talagan_MaCCLane Launch tab by number 7.lua
  [main=main,midi_editor] talagan_MaCCLane/actions/generic_action.lua > talagan_MaCCLane Launch tab by number 8.lua
  [main=main,midi_editor] talagan_MaCCLane/actions/generic_action.lua > talagan_MaCCLane Launch tab by role FooRole.lua
  [main=main,midi_editor] talagan_MaCCLane/actions/generic_action.lua > talagan_MaCCLane Launch tab by name BarName.lua
  [data] talagan_MaCCLane/data/_PUT_YOUR_MACCLANE_TEMPLATES_HERE.md > MaCCLane/
  [data] talagan_MaCCLane/data/toolbar_icons/toolbar_macclane.png > toolbar_icons/toolbar_macclane.png
@about
  # Purpose

    MaCCLane is a widget that installs itself at the bottom of the MIDI Editor and brings a tab system to quickly call MIDI Editor configurations. This may include CC Lanes, window layout, piano roll, midi chans, and more.

    Proposed tabs are contextual to what's being edited, and may be stored in the project, on the track or on the edited item. They can thus be stored in track templates, or may be stored as templates themselves.

    Tabs are complex objects that can be configured partially to apply a custom ME configuration, or record/restore an aspect of a MIDI editor

  # Install Notes

    This tool need additional ReaScript packages. You'll be prompted at launch if you don't have them yet.

  # Reaper forum thread

    The official discussion thread is located here : https://forum.cockos.com/showthread.php?t=298707

  # Documentation

    No documentation yet (see forum thread ATM)

  # Credits

    Special thanks to Christian Fillion for ReImGui, Julian Sader for the JS API. Thanks to all donators and brain contributors, special thanks to @Seventh Sam, @Hipox, @lolol !

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
LOG.setLevel(LOG.LOG_LEVEL_CRITICAL)

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
