--[[
Description: Item properties: Loop item source - Off
Version: 1.0
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
    Initial release
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About:
    Provides a dedicated "off" action for "Item properties: Loop item source"
--]]

-- Licensed under the GNU GPL v3

local i = 0
while true do
    local item =  reaper.GetSelectedMediaItem(0, i )
    if not item then return end
    reaper.SetMediaItemInfo_Value( item, "B_LOOPSRC", 0)
    reaper.UpdateItemInProject( item )
    i = i + 1
end
