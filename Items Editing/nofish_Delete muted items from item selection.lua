--[[
   * ReaScript Name: Delete muted items from item selection
   * Lua script for Cockos REAPER
   * Author: nofish
   * Author URI: http://forum.cockos.com/member.php?u=6870
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
-- Delete muted items from item selection v1.0
-- see http://forum.cockos.com/showpost.php?p=1589221&postcount=4
--
-- Version: 1.0

-- for debugging
function msg(m)
  reaper.ShowConsoleMsg(tostring(m) .. "\n")
end

function delete_muted_items_from_selection()
  reaper.Undo_BeginBlock2()
  
  selected_items_count = reaper.CountSelectedMediaItems(0) -- count sel. items 
  
  -- store sel. items in array
  local selected_items_table = {} -- init table
  for i = 0, selected_items_count do
    item = reaper.GetSelectedMediaItem(0, i) -- get selected item
    selected_items_table[#selected_items_table + 1] = item -- ...store this item to end of table
  end
  
  -- loop through array
  for i=1, #selected_items_table do 
    -- reaper.ShowConsoleMsg("Stored item pointer " .. i .. " :")
    -- msg(selected_items_table[i])
    if selected_items_table[i] ~= nil then
      mute_state = reaper.GetMediaItemInfo_Value(selected_items_table[i], "B_MUTE") -- check if item is muted
      if mute_state == 1.0 then -- if item is muted...
        parent_track = reaper.GetMediaItem_Track(selected_items_table[i]) -- ...get the parent track
        reaper.DeleteTrackMediaItem(parent_track, selected_items_table[i]) -- ..and delete the item
      end 
    end
  end -- end of loop through array
  
  reaper.UpdateArrange() 
  reaper.Undo_EndBlock2(0, "Script: delete muted items from item selection",-1)
end -- end of function delete_muted_items_from_selection()

delete_muted_items_from_selection() -- call the function
  
    
