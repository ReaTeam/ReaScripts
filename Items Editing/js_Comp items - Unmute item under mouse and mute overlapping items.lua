--[[
ReaScript name: js_Comp items - Unmute item under mouse and mute overlapping items.lua
Version: 0.90
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=193258
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION

  This script allows easy comping of items that were recorded in free item positioning mode.
  
  It activates (unmutes) the item under mouse and mutes overlapping items on the same track.
  
  Items that only overlap slightly, due to crossfades, will not be muted.  (The maximum allowed overlap can be edited in the script.)
  
  The script can be linked to a left-click mouse modifier in the "Media item" or "Media item bottom half" contexts.
]]

--[[
  Changelog:
  * v0.90 (2019-07-04)
    + Initial release.
]]

fadeLen = 0.1

--reaper.BR_GetMouseCursorContext()
--item = reaper.BR_GetMouseCursorContext_Item()
x, y = reaper.GetMousePosition()
item = reaper.GetItemFromPoint(x, y, false)
if item then
    reaper.Undo_BeginBlock2(0)
    itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    itemEnd   = itemStart + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    track = reaper.GetMediaItem_Track(item)
    reaper.SetMediaItemInfo_Value(item, "B_MUTE", 0)
    
    for i = 0, reaper.CountTrackMediaItems(track)-1 do
        otherItem = reaper.GetTrackMediaItem(track, i)
        otherStart = reaper.GetMediaItemInfo_Value(otherItem, "D_POSITION")
        otherEnd   = otherStart + reaper.GetMediaItemInfo_Value(otherItem, "D_LENGTH")
        if otherItem ~= item and otherStart < itemEnd-fadeLen and otherEnd > itemStart+fadeLen then
            reaper.SetMediaItemInfo_Value(otherItem, "B_MUTE", 1)
        end
    end
    
    reaper.UpdateArrange()
    reaper.Undo_EndBlock2(0, "Comp FIPM items", -1)
end
