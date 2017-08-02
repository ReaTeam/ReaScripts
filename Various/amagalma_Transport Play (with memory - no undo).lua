-- @description amagalma_Transport Play (with memory - no undo)
-- @author amagalma
-- @version 1.0
-- @about
--   # Plays and stores starting position
--
--   - To be used in conjunction with my other "Transport (with memory - no undo)" scripts

function NoUndoPoint () end

playstate=reaper.GetPlayState()
if playstate > 0 then
  reaper.Main_OnCommand(1008, 0) -- Transport: Pause
else
  pos = reaper.GetCursorPosition()
  reaper.SetExtState("Play-Stop with memory", "Position", tostring(pos), 0)
  reaper.Main_OnCommand(1007, 0) -- Transport: Play
end
reaper.defer(NoUndoPoint)
