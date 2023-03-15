-- @noindex

reaper.Undo_BeginBlock(0)
reaper.PreventUIRefresh(1)

-- Save selected items in a list
local count = reaper.CountSelectedMediaItems(0)
local selected_items = {}
for i=0, count-1 do
  selected_items[i] = reaper.GetSelectedMediaItem(0,i)
end

local old_cursor = reaper.GetCursorPosition()

-- Unselect all items
reaper.Main_OnCommand(40289,0)
-- Select all items on selected track
reaper.Main_OnCommand(40421,0)
-- Move edit cursor left
reaper.Main_OnCommand(40318,0)
-- Unselect all items
reaper.Main_OnCommand(40289,0)
-- Recover selection
for i=0, count-1 do
  reaper.SetMediaItemSelected(selected_items[i],true)
end

local new_cursor = reaper.GetCursorPosition()
local sel_in, sel_out = reaper.GetSet_LoopTimeRange(false,false,0,0,false)

if sel_in ~= sel_out and sel_out > new_cursor then
  reaper.GetSet_LoopTimeRange(true, true, new_cursor, sel_out, false )
else
  reaper.GetSet_LoopTimeRange(true, true, new_cursor, old_cursor, false )
end

reaper.Undo_EndBlock("Move cursor left to nearest item edge in selected tracks ans set time selection",0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
