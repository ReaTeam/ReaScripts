--[[
   * ReaScript Name: Replace selected items with item under mouse cursor
   * Lua script for Cockos REAPER
   * Author: spk77
   * Author URI: http://forum.cockos.com/member.php?u=49553
   * Forum Thread URI: http://forum.cockos.com/showthread.php?t=169979
   * Licence: GPL v3
   * Version: 1.0
  ]]

function replace_selected_items_with_item_under_mouse_cursor()
  local item_t = {}
  local sel_item_count = reaper.CountSelectedMediaItems(0)
  if sel_item_count == 0 then
    return
  end
  
  local window, segment, details = reaper.BR_GetMouseCursorContext()
  local item_under_cursor = reaper.BR_GetMouseCursorContext_Item()

  if item_under_cursor == nil or reaper.IsMediaItemSelected(item_under_cursor) then
    return
  end
 
  local cursor_pos = reaper.GetCursorPosition()
  
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  local j = 1
  for i=1, sel_item_count do
    local item = reaper.GetSelectedMediaItem(0, i-1)
    if item ~= nil and item ~= item_under_cursor then
      item_t[j] = {
                    --id = item,
                    tr = reaper.GetMediaItem_Track(item),
                    position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                    --length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                  }
      j = j + 1
    end
  end
  
  reaper.Main_OnCommand(40006, 0) -- delete items
  reaper.SetMediaItemSelected(item_under_cursor, true) -- select item under mouse cursor
  reaper.Main_OnCommand(40698, 0) -- copy item (under mouse cursor)
  
  local selection_t = {}
  for i=1, #item_t do
    reaper.Main_OnCommand(40289, 0) -- unselect all items
    reaper.SetEditCurPos(item_t[i].position, false, false)
    reaper.Main_OnCommand(40058, 0) -- paste item (under mouse cursor)
    local pasted_item = reaper.GetSelectedMediaItem(0, 0) -- get id from pasted item
    reaper.MoveMediaItemToTrack(pasted_item, item_t[i].tr)
    --reaper.SetMediaItemInfo_Value(pasted_item, "D_LENGTH", item_t[i].length) -- set item length to original item length
    selection_t[i] = pasted_item -- store pasted item's id for "restoring" the selection
  end
	
	-- Select the pasted items
  for i=1, #selection_t do
    reaper.SetMediaItemSelected(selection_t[i], true)
  end
	
  reaper.SetEditCurPos(cursor_pos, false, false)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Replace items with item under mouse cursor", -1)
end

reaper.defer(replace_selected_items_with_item_under_mouse_cursor)
