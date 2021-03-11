-- @noindex

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

-- Save selected items in a list
local count = reaper.CountSelectedMediaItems(0)
local selected_items = {}
for i=0, count-1 do
  selected_items[i] = reaper.GetSelectedMediaItem(0,i)
end

-- Unselect all items
reaper.Main_OnCommand(40289,0)
-- Select all items on selected track
reaper.Main_OnCommand(40421,0)
-- Move edit cursor right
reaper.Main_OnCommand(40319,0)
-- Unselect all items
reaper.Main_OnCommand(40289,0)
-- Recover selection
for i=0, count-1 do
  reaper.SetMediaItemSelected(selected_items[i],true)
end

reaper.Undo_EndBlock("Move cursor right to nearest item edge in selected tracks",0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
