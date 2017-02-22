--[[
ReaScript Name: Name item takes by last marker to cut item
About:
  Names item takes according to the name of the marker that is the last marker
  to cut the items.

  Instructions:

    - Select items
    - Run the script
Author: beaunus
Licence: GPL v3
REAPER: 5.0
Version: 1.0
]]

--[[
 Changelog:
 * v1.0 (2017-02-20)
    + Initial Release
]]

-- Count the number of selected items.
num_selected_items = reaper.CountSelectedMediaItems()

-- Iterate through all selected items.
for i = 0, num_selected_items - 1 do
  -- Get the media item
  item = reaper.GetSelectedMediaItem(0, i)

  -- Get the active take
  take = reaper.GetActiveTake(item)

  -- Find the closest marker to beginning of take
  item_start_position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  item_end_position = item_start_position + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  markeridx, regionidx = reaper.GetLastMarkerAndCurRegion(0, item_end_position)
  retval, isrgn, pos, rgnend, marker_name = reaper.EnumProjectMarkers(markeridx)

  -- Apply new name
  reaper.GetSetMediaItemTakeInfo_String(take, 'P_NAME', marker_name, true)
end
