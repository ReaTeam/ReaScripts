--[[
   * ReaScript Name: Create regions (with tail) from selected items
   * Lua script for Cockos REAPER
   * Author: spk77
   * Author URI: http://forum.cockos.com/member.php?u=49553
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
-- Create regions (with tail) from selected items
-- Lua script by SPK77 13-Sep-2015 (requested by areeman) http://forum.cockos.com/showthread.php?t=166371
--
-- Version: 0.2015.9.13

function dialog(title)
  local ret, retvals = reaper.GetUserInputs(title, 1, "Set tail length", "1.0")
  if ret then
    return retvals
  end
  return ret
end


function create_region(reg_start, reg_end, name)
  local index = reaper.AddProjectMarker2(0, true, reg_start, reg_end, name, -1, 0)
end


----------
-- Main --
----------

function main()
  local item_count = reaper.CountSelectedMediaItems(0)
  if item_count == 0 then
    return
  end
  local tail_len = dialog("Set tail length")
  if not tail_len then
    return
  end
  for i = 1, reaper.CountSelectedMediaItems(0) do
    local item = reaper.GetSelectedMediaItem(0, i-1)
    if item ~= nil then
      local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      local item_end = item_pos + item_len
      local take = reaper.GetActiveTake(item)
      local take_name = ""
      if take ~= nil then
        take_name = reaper.GetTakeName(take)
      end
      create_region(item_pos, item_end+tail_len, take_name)
    end
  end
  reaper.Undo_OnStateChangeEx("Create regions (with tail) from selected items", -1, -1)
end

reaper.defer(main)

