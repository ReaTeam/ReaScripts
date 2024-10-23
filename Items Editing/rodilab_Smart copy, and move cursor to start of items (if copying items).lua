-- @description Smart copy, and move cursor to start of items (if copying items)
-- @author Rodilab
-- @version 1.0
-- @about
--   Copy items/tracks/envelope points (depending on focus) within time selection, if any (smart copy)
--   If copying items, then set edit cursor to earliest selected item start position
--   Pro Tools like
--
--   by Rodrigo Diaz (aka Rodilab)

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

-- Check focus and selected items
local focus = reaper.GetCursorContext2(true)
local count_sel_items = reaper.CountSelectedMediaItems(0)

if focus == 1 and count_sel_items > 0 then
  -- Check time selection
  local sel_start, sel_end = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
  if sel_start == sel_end then
    -- Move cursor to start of items
    reaper.Main_OnCommand(41173,0)
  end
end

-- Smart copy
reaper.Main_OnCommand(41383,0)

reaper.Undo_EndBlock("Smart copy, and move cursor to start of items (if copying items)",0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
