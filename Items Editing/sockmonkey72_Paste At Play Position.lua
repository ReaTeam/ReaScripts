-- @description Paste At Play Position
-- @author sockmonkey72
-- @version 1.0
-- @changelog 1.0: initial

local pos = reaper.GetPlayPosition()
local editpos = reaper.GetCursorPositionEx(0)

reaper.Undo_BeginBlock2(0)

reaper.PreventUIRefresh(1)

reaper.SetEditCurPos2(0, pos, true, false)
reaper.Main_OnCommand(42398, 0)
reaper.SetEditCurPos2(0, editpos, false, false)

reaper.PreventUIRefresh(-1)

reaper.Undo_EndBlock2(0, "Paste At Play Position", -1)
