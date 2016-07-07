--[[
  * ReaScript Name: Split all items at edit cursor
  * Description: - splits all non-locked items at edit cursor
  *              - locked items are ignored
  *              - item selection remain untouched
  * Instructions:
  * Screenshot: 
  * Notes: 
  * Category: 
  * Author: spk77
  * Author URI: http://forum.cockos.com/member.php?u=49553
  * Licence: GPL v3
  * Forum Thread: 
  * Forum Thread URL: http://forum.cockos.com/showthread.php?t=177434
  * Version: 1.1
  * REAPER:
  * Extensions:
]]
 

--[[
 Changelog:
 * v1.0 (2015-05-29)
    + Initial Release
 * v1.1 (2015-07-07)
    + Locked items are ignored
]]  


local r = reaper

function get_items_under_edit_cursor(cursor_pos, num_items)
  local t = {}
  for i=1, num_items do
    local item = r.GetMediaItem(0, i-1)
    if item ~= nil then
      local take = r.GetActiveTake(item)
      if take ~= nil and r.GetMediaItemInfo_Value(item, "C_LOCK") == 0.0 then
        local length = r.GetMediaItemInfo_Value(item, "D_LENGTH")
        local pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
        if pos < cursor_pos and pos+length > cursor_pos then
          t[#t+1] = item
        end
      end
    end
  end
  return t
end

function split(item_table, split_pos)
  r.Undo_BeginBlock()
  for i=1, #item_table do
    local item = item_table[i] 
    r.SplitMediaItem(item, split_pos)
  end
  r.UpdateArrange()
  r.Undo_EndBlock("Split all items at edit cursor (ignore locked items)", -1)
end


function main()
  local num_items = r.CountMediaItems(0)
  if num_items == 0 then return end
  local cursor_pos = r.GetCursorPosition()
  local t = get_items_under_edit_cursor(cursor_pos, num_items)
  if #t == 0 then return end
  split(t, cursor_pos)
end   

r.defer(main)

