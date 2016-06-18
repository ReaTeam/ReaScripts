--[[
  * ReaScript Name: Set time selection to item fade-in
  * Description: Set time selection to item fade-in.
  * Instructions: Select an item and run the script.
  *               - change time selection start/end offset from
  *                 "User settings" below
  * Screenshot: 
  * Notes: 
  * Category: 
  * Author: spk77
  * Author URI: http://forum.cockos.com/member.php?u=49553
  * Licence: GPL v3
  * Forum Thread: 
  * Forum Thread URL:
  * Version: 0.1
  * REAPER:
  * Extensions:
]]
 

--[[
 Changelog:
 * v0.1 (2015-06-18)
    + Initial Release
]]

-------------------
-- User settings --
-------------------
local time_sel_start_offset = 1 -- time selection start point from item fade-in start ("pre-roll")
local time_sel_end_offset = 1   -- time selection end point from item fade-in end     ("post-roll")
---------------------------------------------------------------------------------------------------

function time_sel_to_fade_in()
  local sel_item = reaper.GetSelectedMediaItem(0,0)
  if sel_item == nil then return end
  local item_pos = reaper.GetMediaItemInfo_Value(sel_item, "D_POSITION")
  local fadein_len = reaper.GetMediaItemInfo_Value(sel_item, "D_FADEINLEN")
  local ts_start = item_pos-time_sel_start_offset
  if ts_start-time_sel_start_offset < 0 then ts_start = 0 end
  local ts_end = item_pos+fadein_len+time_sel_end_offset
  reaper.GetSet_LoopTimeRange(true, false, ts_start, ts_end, true)
  reaper.SetEditCurPos(ts_start, true, true)
  --reaper.Undo_OnStateChangeEx("Set time selection to item fade-in", -1, -1)
end

reaper.defer(time_sel_to_fade_in)
