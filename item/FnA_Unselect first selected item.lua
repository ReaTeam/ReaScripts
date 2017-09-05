--[[
 * ReaScript Name: FnA_Unselect first selected item.lua
 * Description: items indexed left to right before advancing to next track
 * Instructions: Run
 * Author: FnA
 * Licence: GPL v3
 * Forum Thread: De-select last selected item
 * Forum Thread URI: http://forum.cockos.com/showthread.php?t=191368
 * REAPER: 5.40
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2017-05-26)
  + Initial Release
--]]

local r = reaper

function Fn_Unselect_First()
  local csi = r.CountSelectedMediaItems(0)
  if csi > 0 then
    r.SetMediaItemSelected(r.GetSelectedMediaItem(0,0), false)
    r.UpdateArrange()
  end
end

Fn_Unselect_First()

function NoUndoPoint () end 
reaper.defer(NoUndoPoint)
