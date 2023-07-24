-- @description Replace with an empty item
-- @author ilovemedia
-- @version 1.0
-- @about
--   # Replace with an empty item
--
--   Replace the selected item with an empty one with the same name, duration and position.

-- Get the selected item at the current position
local selectedItem = reaper.GetSelectedMediaItem(0, 0)
local take = reaper.GetActiveTake(selectedItem)
local takeName = reaper.GetTakeName(take)
local itemStart = reaper.GetMediaItemInfo_Value(selectedItem, "D_POSITION")
local itemEnd = itemStart + reaper.GetMediaItemInfo_Value(selectedItem, "D_LENGTH")
local itemColor = reaper.GetMediaItemInfo_Value(selectedItem, "I_CUSTOMCOLOR", color)

reaper.GetSet_LoopTimeRange(true, false, itemStart, itemEnd, false) -- Set time selection to match the item to replace

reaper.DeleteTrackMediaItem(reaper.GetMediaItem_Track(selectedItem), selectedItem) -- Delete the original item

reaper.Main_OnCommand(40214,0) -- Insert new item

local emptyItem = reaper.GetSelectedMediaItem(0, 0)
if emptyItem ~= nil then
  local emptyTake = reaper.GetActiveTake(emptyItem)
  reaper.GetSetMediaItemTakeInfo_String(emptyTake, "P_NAME", takeName, true) -- Rename take to the original name
  reaper.SetMediaItemInfo_Value(emptyItem, "I_CUSTOMCOLOR", itemColor) -- Set original color
end

reaper.UpdateArrange()
