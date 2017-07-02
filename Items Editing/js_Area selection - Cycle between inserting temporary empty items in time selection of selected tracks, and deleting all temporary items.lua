--[[
ReaScript name: js_Area selection - Cycle between inserting temporary empty items in time selection of selected tracks, and deleting all temporary items.lua
Version: 0.91
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=193258
Donation: https://www.paypal.me/juliansader
About:
  # Description

  This script facilitates "Area selection" and "Area copy"; i.e. moving or duplicating all items and automation in the time selection of selected tracks, including automation from tracks without any items.  

  The script cycles between
  1) inserting temporary empty items into the time selection of selected tracks, and 
  2) deleting all temporary items from the project.

  When the temporary items are inserted, Crtl-drag can be used to copy the items and automation to their new position or even to other tracks.  Pre-existing envelope points in the paste target area will be overwritten.

  # Instructions

  1) Select time and tracks
  2) Run the script to insert temporary items across the time selection
  3) Ctrl-drag the items to their new position
  4) Run the script again to remove the (duplicated) temporary items.
]]

--[[
  Changelog:
  * v0.90 (2017-07-01)
    + Initial beta release.
  * v0.91 (2016-07-02)
    + Trying to fix download problem.
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
function insertEmptyItems()
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
end


---------------------------
function deleteEmptyItems() 
    for t = 0, reaper.CountTracks(0)-1 do
        local track = reaper.GetTrack(0, t)
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
end


---------------------------------------------------
---------------------------------------------------
-- Check cycle and either add or remove empty items
if reaper.GetExtState("js_Area copy", "Cycle") == "Has inserted" then
    deleteEmptyItems()
    reaper.SetExtState("js_Area copy", "Cycle", "Has deleted", true)
    undoString = "Delete temporary empty items"
else
    insertEmptyItems()
    reaper.SetExtState("js_Area copy", "Cycle", "Has inserted", true)
    undoString = "Insert temporary empty items"
end

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock2(0, undoString, -1)
