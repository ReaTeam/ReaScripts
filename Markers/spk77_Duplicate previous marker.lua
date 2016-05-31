--[[
  * ReaScript Name: Duplicate previous marker
  * Description: 
  * Instructions:
  * Screenshot: 
  * Notes: 
  * Category: 
  * Author: spk77
  * Author URI: http://forum.cockos.com/member.php?u=49553
  * Licence: GPL v3
  * Forum Thread: 
  * Forum Thread URL: http://forum.cockos.com/showthread.php?t=177407
  * Version: 1.0
  * REAPER:
  * Extensions:
]]
 

--[[
 Changelog:
 * v1.0 (2015-05-31)
    + Initial Release
]]


function main()
  local cursor_pos = reaper.GetCursorPosition()
  local markeridx, regionidx = reaper.GetLastMarkerAndCurRegion(0, cursor_pos)
  local ret, isrgn, pos, rgnend, name, markrgnindex, color = reaper.EnumProjectMarkers3(0, markeridx)
  if color > 0 then
    local r, g, b = reaper.ColorFromNative(color)
    color = reaper.ColorToNative(r,g,b)|0x1000000
  end
  reaper.AddProjectMarker2(0, false, cursor_pos, 0, name, -1, color)
  reaper.Undo_OnStateChangeEx("Duplicate previous marker", -1, -1)
end

main()



