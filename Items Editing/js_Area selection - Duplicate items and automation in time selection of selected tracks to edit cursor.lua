--[[
ReaScript name: js_Area selection - Duplicate items and automation in time selection of selected tracks to edit cursor.lua
Version: 0.90
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=193258
Donation: https://www.paypal.me/juliansader
About:
  # Description

  Copies all items and automation from the time selection of selected tracks to the position of the edit cursor.

  All automation, even from tracks without any items, will be copied.

  NOTE: A potential problem is that pre-existing envelope points in the area where the automation is pasted will not be overwritten, so old and new points will be mixed.

  # Instructions

  Select the area to be copied (i.e. select time and tracks), place edit cursor at paste position, and run script.
]]

--[[
  Changelog:
  * v1.0 (2017-07-01)
    + Initial beta release.
]]

-------------------------------------------------------------------
-- Do some preliminary checks that selections and API are available

-- Prevent REAPER from automatically creating undo points.
function noUndo()
end
reaper.defer(noUndo)

-- Is a usable time selection available?
timeSelectionStart, timeSelectionEnd = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, true)
if timeSelectionStart >= timeSelectionEnd then
    return
end

-- Are any tracks selected?
numSelTracks = reaper.CountSelectedTracks(0)
if numSelTracks == 0 then 
    return
end

-- Is SWS installed?
if not reaper.APIExists("ULT_SetMediaItemNote") then
    reaper.ShowMessageBox("This script requires the SWS/S&M extension.\n\nThe SWS/S&M extension can be downloaded from www.sws-extension.org.", "ERROR", 0)
    return false 
end

-- Checks done, so start undo block.
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)    


-----------------------------------------------------------------------------------------------
-- This script manages to duplicate envelope points even when no items are above these points,
--    by inserting temporary empty item across the time selection in all selected tracks.
-- Then, if "Option: Move envelope points with items" is active, REAPER's native item-duplication
--    Actions such as "Item: Copy selected area of items" will copy all envelope points in time selection.
-- This loop also selects all items that overlap time selection, since the Action
--    "Item: Copy selected area of items" only works on selected items.
reaper.SelectAllMediaItems(0, false)
for t = 0, numSelTracks-1 do -- numSelTracks has been defined above
    local track = reaper.GetSelectedTrack(0, t)
    for i = 0, reaper.GetTrackNumMediaItems(track)-1 do
        local item = reaper.GetTrackMediaItem(track, i)
        local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local itemEnd = itemStart + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        if itemStart < timeSelectionEnd and itemEnd > timeSelectionStart then
            reaper.SetMediaItemSelected(item, true)
        end
    end
    local newItem = reaper.AddMediaItemToTrack(track)
    reaper.SetMediaItemInfo_Value(newItem, "D_POSITION", timeSelectionStart)
    reaper.SetMediaItemInfo_Value(newItem, "D_LENGTH", timeSelectionEnd - timeSelectionStart)
    -- Will it look better if the items are given a distinctive color?
    --reaper.SetMediaItemInfo_Value(newItem, "I_CUSTOMCOLOR", reaper.ColorToNative(0,0,0)|0x01000000)
    -- Give temporary items a distinctive note, so that can be found later again.
    reaper.ULT_SetMediaItemNote(newItem, "Area select (temporary)")
    reaper.SetMediaItemSelected(newItem, true)
end


--------------------------------------------------------------------------
-- Use REAPER's native Actions to duplicate the item slices and automation
-- First, try to find state of "Option: Move envelope points with items" by checking toolbar button
local prevToggleState_MoveEnvPointWithItems = reaper.GetToggleCommandStateEx(0, 40070) -- 0 = Main section; 40070 = Options: Envelope points move with media items
reaper.Main_OnCommandEx(reaper.NamedCommandLookup("_SWS_MVPWIDON"), -1, 0) -- SWS: Set move envelope points with items on
reaper.Main_OnCommandEx(40060, -1, 0) -- Item: Copy selected area of items
reaper.Main_OnCommandEx(40914, -1, 0) -- Track: Set first selected track as last touched track
reaper.Main_OnCommandEx(40058, -1, 0) -- Item: Paste items/tracks
-- Reset state of "Move envelope points with items"
if prevToggleState_MoveEnvPointWithItems == 0 then
    reaper.Main_OnCommandEx(reaper.NamedCommandLookup("_SWS_MVPWIDOFF"), -1, 0) -- SWS: Set move envelope points with items off
end


-------------------------
-- Delete temporary items
for t = 0, reaper.CountSelectedTracks(0)-1 do
    local track = reaper.GetSelectedTrack(0, t)
    local tItems = {}
    for i = 0, reaper.GetTrackNumMediaItems(track)-1 do
        local item = reaper.GetTrackMediaItem(track, i)
        if reaper.ULT_GetMediaItemNote(item) == "Area select (temporary)" then
            tItems[#tItems+1] = item
        end
    end
    for _, item in ipairs(tItems) do
        reaper.DeleteTrackMediaItem(track, item)
    end
end


reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock2(0, "Duplicate items and automation", -1)
