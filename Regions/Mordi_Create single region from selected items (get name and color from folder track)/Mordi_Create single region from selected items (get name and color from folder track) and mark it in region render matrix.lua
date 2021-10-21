-- @noindex

SCRIPT_NAME = "Create single region from selected items (get name and color from folder track) and mark it in region render matrix"

reaper.ClearConsole()

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

-- Init parent variable
parent = track

-- Loop: Get topmost parent
repeat

  -- Get potential parent
  potParent = reaper.GetParentTrack(parent)

  -- Check if potential parent exists
  if potParent == nil then
    break;
  else
    -- Check if potential parent's name starts with "#FX"
    retval, name = reaper.GetTrackName(potParent, "")
    if string.sub(name, 1, 3) == "#FX" then
      break
    end
  end

  parent = potParent
  
until(reaper.GetParentTrack(parent) == nil)

-- Get color of track
color = reaper.GetTrackColor(parent)

-- Get name of track
retval, name = reaper.GetTrackName(parent, "")

-- Create region and store index
rgnIndex = reaper.AddProjectMarker2(0, true, regionPos, regionEnd, name, -1, color)

-- Get number of tracks
num_tracks = reaper.CountTracks(0)

-- Loop through all tracks
for i=0, num_tracks-1 do

  -- Get track
  track = reaper.GetTrack(0, i)
  
  -- Get name of track
  retval, trackName = reaper.GetTrackName(track, "")
  
  -- Get folder depth of track
  folderDepth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
  
  -- Check if names match
  if name == trackName and folderDepth == 1 then
    -- Tick the corresponding box in the region render matrix
    reaper.SetRegionRenderMatrix(0, rgnIndex, track, 1)
  end
end

-- End undo-block
reaper.Undo_EndBlock2(0,SCRIPT_NAME,-1)
