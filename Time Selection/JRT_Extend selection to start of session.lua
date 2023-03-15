-- @description Extend selection to start of session
-- @author JRTaylorMusic
-- @version 1.0
-- @about Like Shift+Return in ProTools, this action sets the time selection start to the beginning of the project, then selects all items on selected tracks within the new time selection.

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
local pos = reaper.GetCursorPosition()
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
local pos = reaper.GetCursorPosition()

in_point, out_point = reaper.GetSet_LoopTimeRange( false, false, 0, 0, false )

start = 0.0

if in_point == out_point
  then 
  reaper.GetSet_LoopTimeRange(1, 0, start, pos, 0)  
  else
  reaper.GetSet_LoopTimeRange(1, 0, start, out_point, 0)
end

reaper.Main_OnCommand(40718, 0)

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("JRT_Extend selection to start of session", -1)

in_point, out_point = reaper.GetSet_LoopTimeRange( false, false, 0, 0, false )

start = 0.0

if in_point == out_point
  then	
  reaper.GetSet_LoopTimeRange(1, 0, start, pos, 0)
  else
  reaper.GetSet_LoopTimeRange(1, 0, start, out_point, 0)
end

reaper.Main_OnCommand(40718, 0)

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("JRT_Move selection start to beginning", -1)
