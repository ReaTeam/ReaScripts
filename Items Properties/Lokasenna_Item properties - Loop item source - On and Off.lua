--[[
Description: Item properties: Loop item source - On and Off
Version: 1.01
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
    Put both actions in a single package
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About:
    Provides dedicated "on" and "off" actions for "Item properties: Loop item source"
MetaPackage: true
Provides:
    [main] . > Lokasenna_Item properties - Loop item source (on).lua
    [main] . > Lokasenna_Item properties - Loop item source (off).lua    
--]]

-- Licensed under the GNU GPL v3

local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local val = string.match(name, "%((.+)%)") == "on" and 1 or 0

local i = 0
while true do
    local item =  reaper.GetSelectedMediaItem(0, i )
    if not item then return end
    reaper.SetMediaItemInfo_Value( item, "B_LOOPSRC", val)
    reaper.UpdateItemInProject( item )
    i = i + 1
end
