--[[
  * ReaScript Name: Sort selected items by length (ascending)
  * Description:    Sorts selected items from shortest to longest
  * Instructions:   - Select items
  *                 - Run the script
  * Screenshot: 
  * Notes: 
  * Category: 
  * Author: Mordi & spk77
  * Author URI:
  * Licence: GPL v3
  * Forum Thread: 
  * Forum Thread URL: http://forum.cockos.com/showthread.php?t=178620
  * Version: 1.0
  * REAPER:
  * Extensions:
]]
 

--[[
 Changelog:
 * v1.0 (2016-06-26)
    + Changed script to only work on selected items.
]]

function get_item_lengths()
  local t={}
  for i=1, reaper.CountSelectedMediaItems(0) do
    t[i] = {}
    local item = reaper.GetSelectedMediaItem(0, i-1)
    if item ~= nil then
      t[i].item = item
      t[i].len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    end
  end
  return t
end

sort_func = function(a,b) -- https://forums.coronalabs.com/topic/37595-nested-sorting-on-multi-dimensional-array/
              if (a.len < b.len) then
                -- primary sort on length -> a before b
                return true
              --[[
              elseif (a.len > b.len) then
                -- primary sort on length -> b before a
                return false
              else
                -- primary sort tied, resolve w secondary sort on position
                return a.position < b.position
              --]]
              end
            end
              
function sort_items_by_length()
  local data = get_item_lengths()
  if #data == 0 then return end
  local pos = reaper.GetMediaItemInfo_Value(data[1].item, "D_POSITION") -- get first item pos
  
  table.sort(data, sort_func)
  
  for i=1, #data do
    local l = data[i].len
    reaper.SetMediaItemInfo_Value(data[i].item, "D_POSITION", pos)
    pos=pos+l
  end
  reaper.UpdateArrange()
  reaper.Undo_OnStateChangeEx("Sort items by length (ascending)", -1, -1)
end

sort_items_by_length()
