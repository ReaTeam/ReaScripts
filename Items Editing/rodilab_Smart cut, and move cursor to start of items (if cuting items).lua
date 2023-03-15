-- @description Smart cut, and move cursor to start of items (if cuting items)
-- @author Rodilab
-- @version 1.0
-- @about
--   Cut items/tracks/envelope points (depending on focus) within time selection, if any (smart cut)
--   If cuting items, then set edit cursor to earliest selected item start position
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

-- Smart cut
reaper.Main_OnCommand(41384,0)

reaper.Undo_EndBlock("Smart cut, and move cursor to start of items (if cuting items)",0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
