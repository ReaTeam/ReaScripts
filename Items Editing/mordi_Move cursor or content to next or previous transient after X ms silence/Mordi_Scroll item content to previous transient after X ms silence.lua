-- @noindex

reaper.ClearConsole()
function msg(val)
  reaper.ShowConsoleMsg(tostring(val) .. "\n")
end

SCRIPT_NAME = "Scroll item content to previous transient after X ms silence"

sel_num = reaper.CountSelectedMediaItems(0)

if sel_num == 0 then
  return
end

-- Check that we have the required script
cmd_id = reaper.NamedCommandLookup("_RS943d7ae16ca8e3b49e6b00e18a5145c8ca4b3c7c")
if cmd_id == nil or cmd_id == 0 then
  reaper.ShowMessageBox("Looks like you're missing a required script: 'Mordi_Move to previous transient after X ms silence'", SCRIPT_NAME, 0)
  return
end

reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)

-- Save item selection
saved_items = {}
for i = 0, sel_num - 1 do
  saved_items[i] = reaper.GetSelectedMediaItem(0, i) -- Save item
end

-- Deselect all
for i = 0, sel_num - 1 do
  reaper.SetMediaItemSelected(saved_items[i], false) -- Deselect item
end

-- Save edit cursor position
pos_initial_s = reaper.GetCursorPosition()

-- Save arrange view scroll info
arrange_start, arrange_end = reaper.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)

for i = 0, sel_num - 1 do
  local item = saved_items[i]

  reaper.SetMediaItemSelected(item, true) -- Select item
  
  -- Save item length
  local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  
  -- Get some info on item and take
  local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local take = reaper.GetActiveTake(item)
  local take_offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  local take_playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  
  -- If take offset is already all the way left, we can skip this item
  if take_offset <= 0 then
    goto continue
  end
  
  -- Reset take offset
  reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", 0)
  reaper.SetMediaItemLength(item, item_length + take_offset / take_playrate, true)
  
  -- Move cursor to where the item start used to be
  reaper.SetEditCurPos(item_start + take_offset / take_playrate, false, false)
  
  -- Run "move to previous transient" script
  reaper.Main_OnCommand(cmd_id, 0)
  
  -- Revert item length
  reaper.SetMediaItemLength(item, item_length, true)
  
  -- Scroll item to where we found the transient
  reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", (reaper.GetCursorPosition() - item_start) * take_playrate)
  
  ::continue::
  
  reaper.SetMediaItemSelected(item, false) -- Deselect item
end


-- Load initial item selection
for i = 0, sel_num - 1 do
  reaper.SetMediaItemSelected(saved_items[i], true)
end

-- Move cursor back to initial position
reaper.SetEditCurPos(pos_initial_s, true, false)

-- Restore arrange view scroll info
reaper.GetSet_ArrangeView2(0, true, 0, 0, arrange_start, arrange_end)

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock2(0,SCRIPT_NAME,-1)
