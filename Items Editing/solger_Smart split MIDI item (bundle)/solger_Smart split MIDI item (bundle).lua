-- @description Smart split MIDI item (bundle)
-- @author solger
-- @version 1.0
-- @changelog First version
-- @metapackage
-- @provides
--   [main] . > solger_Smart split MIDI item 1 (trim shorter note parts at cursor).lua
--   [main] . > solger_Smart split MIDI item 2 (trim left note parts at cursor).lua
--   [main] . > solger_Smart split MIDI item 3 (trim right note parts at cursor).lua
--   [nomain] solger_Smart split MIDI item functions.lua
-- @about
--   These scripts split a MIDI item and trim the (shorter, left or right) note parts at the cursor position. The threshold of the note part length which should be trimmed can be adjusted in each script (by default all notes under the cursor are trimmed).
--
--   Also big thanks to Stevie and me2beats for some code snippets and ideas :)
--   So make sure to check out their repositories, as well.

---------------------------------------------------------------------------
-- noteLength: 0.25 = sixteenth note | 0.5 = eighth note | 1 = quarter note
---------------------------------------------------------------------------
-- noteMultiplier: 0 = no threshold (all selected notes are trimmed)
--------------------------------------------------------------------
local noteLength = 0.25
local noteMultiplier = 0
--------------------------------------------------------------------

local scriptName = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local trimMode = tonumber(scriptName:match("Smart split MIDI item (%d+)"))

package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path
require 'solger_Smart split MIDI item functions'

reaper.Undo_BeginBlock()
  local trimThreshold = noteLength * noteMultiplier
  SmartSplit(trimMode, trimThreshold)
reaper.Undo_EndBlock(scriptName, 1)
