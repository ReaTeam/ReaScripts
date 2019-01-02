-- @description Move selected items to new individual tracks
-- @author Mordi
-- @version 1.0
-- @link Mordi's website http://www.mordi.net/
-- @screenshot https://i.imgur.com/wESKPou.gif
-- @about
--   Takes all selected items and moves them to new individual tracks.
--   You get the option to line them up vertically or keep their horizontal position.


-- Print function
function print(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end

SCRIPT_TITLE = "Move selected items to new individual tracks"

-- Get some data on selected items
function get_selected_items_data()
  local t={}
  for i=1, reaper.CountSelectedMediaItems(0) do
    t[i] = {}
    local item = reaper.GetSelectedMediaItem(0, i-1)
    if item ~= nil then
      t[i].item = item
      t[i].track = reaper.GetMediaItemTrack(item)
      t[i].pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local tk_id = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")
      local tk = reaper.GetMediaItemTake(item, tk_id)
      retval, t[i].name = reaper.GetSetMediaItemTakeInfo_String(tk, "P_NAME", "", false)
    end
  end
  return t
end

-- Get track id of the last track with selected items on it
function get_last_track_with_selected_items(sel_items_data)
  local count = reaper.CountTracks(0)
  local last_id = 0
  for i=0, count-1 do
    local tr = reaper.GetTrack(0, i)
    for n=1, #sel_items_data do
      if tr == sel_items_data[n].track then
        last_id = i
      end
    end
  end
  return last_id
end

-- Initialize
sel = get_selected_items_data()

if next(sel) == nil then
  reaper.ShowMessageBox("No items selected", SCRIPT_TITLE, 0)
  return
end

should_line_up = reaper.ShowMessageBox("Do you want the items to line up vertically?", SCRIPT_TITLE, 3)

-- Check if "cancel" was pressed
if should_line_up == 2 then
  return
end

reaper.Undo_BeginBlock()

items_track_id = get_last_track_with_selected_items(sel)
index = 1

-- Loop through selected items
for i=1, #sel do
    
  -- Add new track
  local tr_index = items_track_id + i
  reaper.InsertTrackAtIndex(tr_index, true)
  
  -- Get new track
  local tr = reaper.GetTrack(0, tr_index)
  
  -- Rename track
  reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", sel[i].name, true)
  
  -- Move item to track
  reaper.MoveMediaItemToTrack(sel[i].item, tr)
  
  -- Move item to first item's position
  if should_line_up == 6 then
    reaper.SetMediaItemPosition(sel[i].item, sel[1].pos, false)
  end
  
end

reaper.Undo_EndBlock(SCRIPT_TITLE, 0)

-- Redraw arrange window to make sure it's up to date
reaper.UpdateArrange()