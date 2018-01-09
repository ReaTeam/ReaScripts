--[[
   * ReaScript Name: Crop selected region to selected item
   * Lua script for Cockos REAPER
   * Author: HeDa
   * Author URI: http://forum.cockos.com/member.php?u=47822
   * Licence: GPL v3
   * Version: 2.0
]]

local item= reaper.GetSelectedMediaItem(0,0)
if item then 
	local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	local itemDuration = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
	local itemEnd = itemStart + itemDuration

	local markeridx, regionidx = reaper.GetLastMarkerAndCurRegion(0, reaper.GetCursorPosition())
	local retval, isrgnOut, posOut, rgnendOut, nameOut, markrgnindexnumberOut, colorOut = reaper.EnumProjectMarkers3(0, regionidx)
	if retval>0 then 
		reaper.SetProjectMarkerByIndex2(0, regionidx, true, itemStart, itemEnd, markrgnindexnumberOut , "", colorOut, 0)
	else
		reaper.ShowConsoleMsg("\nNo region was found at edit cursor time")
	end
	
else
	reaper.ShowMessageBox("Select the item", "Please",0)
end
