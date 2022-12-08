-- @description Move edit cursor to under mouse position
-- @author JRTaylorMusic
-- @version 1.0
-- @about
--   # Move edit cursor under mouse position
--   ## This script is to help in building custom actions for mouse modifiers

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

here = reaper.BR_PositionAtMouseCursor(true)
reaper.SetEditCurPos(here, true, false)

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Move edit cursor to under mouse position", -1)
