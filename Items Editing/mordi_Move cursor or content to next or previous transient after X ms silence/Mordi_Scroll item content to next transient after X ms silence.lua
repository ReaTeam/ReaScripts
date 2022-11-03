-- @noindex

reaper.ClearConsole()
function msg(val)
  reaper.ShowConsoleMsg(tostring(val) .. "\n")
end

SCRIPT_NAME = "Scroll item content to next transient after X ms silence"

sel_num = reaper.CountSelectedMediaItems(0)

if sel_num == 0 then
  return
end

-- Check that we have the required script
cmd_id = reaper.NamedCommandLookup("_RSfada8d66fc67ae31f4460bea24e811bf6045b81b")
if cmd_id == nil or cmd_id == 0 then
  reaper.ShowMessageBox("Looks like you're missing a required script: 'Mordi_Move to next transient after X ms silence'", SCRIPT_NAME, 0)
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
  
  -- Elongate item
  local take = reaper.GetActiveTake(item)
  local source = reaper.GetMediaItemTake_Source(take)
  local source_length = reaper.GetMediaSourceLength(source)
  local take_offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  local take_playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  reaper.SetMediaItemLength(item, (source_length - take_offset) / take_playrate, true)
  
  -- Move cursor to start of item
  local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  reaper.SetEditCurPos(item_start, false, false)
  
  -- Run "move to next transient" script
  reaper.Main_OnCommand(cmd_id, 0)
  
  -- Revert item length
  reaper.SetMediaItemLength(item, item_length, true)
  
  -- Scroll item contents based on distance
  local distance = reaper.GetCursorPosition() - item_start
  reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", take_offset + (distance * take_playrate))
  
  reaper.SetMediaItemSelected(item, false) -- Deselect item
end

-- Load initial item selection
for i = 0, sel_num - 1 do
  reaper.SetMediaItemSelected(saved_items[i], true)
end

-- Move cursor back to initial position
reaper.SetEditCurPos(pos_initial_s, false, false)

-- Restore arrange view scroll info
reaper.GetSet_ArrangeView2(0, true, 0, 0, arrange_start, arrange_end)

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock2(0,SCRIPT_NAME,-1)
