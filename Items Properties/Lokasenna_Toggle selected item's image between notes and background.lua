--[[
Description: Toggle selected item's image between notes and background
Version: 1.0.1
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	Initial release
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
Extensions: SWS/S&M 2.8.3
--]]

-- Licensed under the GNU GPL v3

reaper.Undo_BeginBlock()

reaper.PreventUIRefresh(1)

count_sel_items = reaper.CountSelectedMediaItems(0)
for i = 0, count_sel_items - 1 do

	cur_item = reaper.GetSelectedMediaItem(0,i)
	local retval, img, flags = reaper.BR_GetMediaItemImageResource(cur_item)

	if not retval then return 0 end

	if flags == 0 then          flags = 1
	elseif flags ==1 then     flags = 0
	elseif flags ==2 then     flags = 3
	elseif flags ==3 then     flags = 2
	end

	reaper.BR_SetMediaItemImageResource(cur_item, img, flags)     

end
reaper.PreventUIRefresh(-1)

reaper.Undo_EndBlock("Toggle selected item's image between notes and background", 4)
