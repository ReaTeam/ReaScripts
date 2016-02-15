--[[
   * ReaScript Name: Crop selected region to selected item
   * Lua script for Cockos REAPER
   * Author: HeDa
   * Author URI: http://forum.cockos.com/member.php?u=47822
   * Licence: GPL v3
   * Version: 1.0
]]

local startOut, endOut = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
retval, num_markersOut, num_regionsOut = reaper.CountProjectMarkers(0)
Regions={}
if retval>0 then 
	for i = 1, num_regionsOut+num_markersOut do
		local retval, isrgnOut, posOut, rgnendOut, nameOut, markrgnindexnumberOut, colorOut = reaper.EnumProjectMarkers3(0, i-1)
		Regions[i]={index=markrgnindexnumberOut, posStart=posOut, posEnd=rgnendOut, name=nameOut, color=colorOut, isregion=isrgnOut}
	end
end
for k,v in pairs(Regions) do
	if Regions[k].posStart == startOut and Regions[k].posEnd==endOut then 
		selectedregion=k
		break
	end
end

item= reaper.GetSelectedMediaItem(0,0)
if item then 
	itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	itemDuration = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
	itemEnd = itemStart + itemDuration
	fit=reaper.SetProjectMarkerByIndex2(0, selectedregion-1, true, itemStart, itemEnd, Regions[selectedregion].index,  Regions[selectedregion].name,  Regions[selectedregion].color, 0)
else
	reaper.ShowMessageBox("Select the item", "Please",0)
end
