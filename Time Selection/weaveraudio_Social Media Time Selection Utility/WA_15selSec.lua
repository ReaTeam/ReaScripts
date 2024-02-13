-- @noindex

-- @description Time selection from current playhead position to 15 seconds later
-- @version 1.0
-- @author WEAVER AUDIO
-- @about
--   This script creates a time selection from the current playhead position to exactly 15 seconds later.
-- @provides
--   . > WeaverAudio/Time selection from current playhead position to 15 seconds later.lua
reaper.Undo_BeginBlock()
local play_pos = reaper.GetPlayPosition()
reaper.GetSet_LoopTimeRange(true, false, play_pos, play_pos + 15, false)
reaper.Undo_EndBlock("Time selection from current playhead position to 15 seconds later", -1)

