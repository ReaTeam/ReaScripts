-- @description amagalma_Transport Play-Stop (with memory - no undo)
-- @author amagalma
-- @version 1.0
-- @about
--   # Plays or Stops and stores starting or ending position
--
--   - To be used in conjunction with my other "Transport (with memory - no undo)" scripts

function NoUndoPoint() end 

playstate=reaper.GetPlayState()
if playstate > 0 then
    reaper.Main_OnCommand(40434, 0) --View: Move edit cursor to play cursor
    reaper.Main_OnCommand(1016, 0) --Transport: Stop
    pos = reaper.GetCursorPosition()
    reaper.SetExtState("Play-Stop with memory", "Position2", tostring(pos), 0)
else
    pos = reaper.GetCursorPosition()
    reaper.SetExtState("Play-Stop with memory", "Position", tostring(pos), 0)
    reaper.Main_OnCommand(1007, 0) -- Transport: Play
end
reaper.defer(NoUndoPoint)
