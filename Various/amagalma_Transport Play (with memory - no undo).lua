-- @description Transport: Play (with memory - no undo)
-- @author amagalma
-- @version 1.1
-- @about
--   # Plays and stores starting position
--
--   - To be used in conjunction with my other "Transport (with memory - no undo)" scripts

--[[
 Changelog:
 * v1.1 (2017-09-25)
  + when resuming play after pause, cursor position is saved in memory as new starting point
--]]

--------------------------------------------------------------------------------------------

local reaper = reaper

function NoUndoPoint() end

local playstate = reaper.GetPlayState()
-- if already playing, then pause
if playstate > 0 and playstate & 2 ~= 2 then
  reaper.Main_OnCommand(1008, 0) -- Transport: Pause
-- if already paused, then save this location as new starting point (that you can return to) and play
elseif playstate & 2 == 2 then
  local pos = reaper.GetCursorPosition()
  reaper.SetExtState("Play-Stop with memory", "Position", tostring(pos), 0)
  reaper.Main_OnCommand(1008, 0) -- Transport: Pause
-- is stopped then, save location to memory and then play
else
  local pos = reaper.GetCursorPosition()
  reaper.SetExtState("Play-Stop with memory", "Position", tostring(pos), 0)
  reaper.Main_OnCommand(1007, 0) -- Transport: Play
end
reaper.defer(NoUndoPoint)
