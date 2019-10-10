-- @description Create single region from selected items (get name and color from folder track)
-- @author Mordi
-- @version 1.0
-- @screenshot Creating regions from items https://i.imgur.com/xUg7bSU.gif
-- @about
--   # Create single region from selected items (get name and color from folder track)
--
--   Made for exporting sound effects. Select all the items that make up your sound effect, and run this script. A region will be created which encompasses all the items and inherits its name and color from the parent track of the topmost item.
--
--   See screenshot.
--
--   This script works well with "Set render matrix by comparing track names and region names.lua".

SCRIPT_NAME = "Create single region from selected items (get name and color from folder track)"

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

selectedItemNum = reaper.CountSelectedMediaItems()

-- Abort if no items are selected
if selectedItemNum == 0 then
  return
end

-- Begin undo-block
reaper.Undo_BeginBlock2(0)

-- Get total span of items
regionPos = 0
regionEnd = 0
topTrackIndex = 0
for i = 0, selectedItemNum-1 do
  -- Get item
  item = reaper.GetSelectedMediaItem(0, i)
  
  -- Get item position
  itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  
  -- Get item length
  itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  
  -- Get track from item
  itemTrack = reaper.GetMediaItem_Track(item)
  
  -- Get track index from item track
  itemTrackIndex = reaper.GetMediaTrackInfo_Value(itemTrack, "IP_TRACKNUMBER")
  
  -- Use first item as initial start and end
  if i == 0 then
    regionPos = itemPos
    regionEnd = itemPos + itemLength
    topTrackIndex = itemTrackIndex
  end
  
  -- Check start
  if regionPos > itemPos then
    regionPos = itemPos
  end
  
  -- Check end
  if regionEnd < itemPos + itemLength then
    regionEnd = itemPos + itemLength
  end
  
  -- Check track index
  if itemTrackIndex < topTrackIndex then
    topTrackIndex = itemTrackIndex
  end
  
end

-- Get track from track index
track = reaper.GetTrack(0, topTrackIndex-1)

-- Get parent of topmost track
parent = reaper.GetParentTrack(track)

-- If it has no parent, use the topmost track instead
if parent == nil then
  parent = track
end

-- Get color of track
color = reaper.GetTrackColor(parent)

-- Get name of track
retval, name = reaper.GetTrackName(parent, "")

-- Create region
reaper.AddProjectMarker2(0, true, regionPos, regionEnd, name, -1, color)

-- End undo-block
reaper.Undo_EndBlock2(0,SCRIPT_NAME,-1)
