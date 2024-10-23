-- @description Set render matrix by comparing track names and region names
-- @author Mordi
-- @version 1.2
-- @changelog Fixed a similar bug where markers would interfere with regions.
-- @screenshot Set render matrix https://i.imgur.com/AHBjNrn.gif
-- @about
--   #Set render matrix by comparing track names and region names
--
--   This script will compare all region names to track names. When it finds a match, it will edit the region render matrix to render that region through that track. Originally meant to make it simpler to export sound effects.
--
--   See screenshot for demonstration.
--
--   Works well with "Create single region from selected items (get name and color from folder track).lua".


SCRIPT_NAME = "Set render matrix by comparing track names and region names"

reaper.ClearConsole()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

-- Begin undo-block
reaper.Undo_BeginBlock2(0)

-- Get number of regions
retval, num_markers, num_regions = reaper.CountProjectMarkers(0)

-- Get number of tracks
num_tracks = reaper.CountTracks(0)

-- Loop through all markers and regions
for i = 0, num_regions+num_markers-1 do
  retval, isrgn, pos, rgnend, rgnName, rgnIndex = reaper.EnumProjectMarkers(i)
  
  -- Check if this marker is a region
  if isrgn then
  
    -- Loop through all tracks
    for n=0, num_tracks-1 do
    
      -- Get track
      track = reaper.GetTrack(0, n)
      
      -- Get name of track
      retval, trackName = reaper.GetTrackName(track, "")
      
      -- Get folder depth of track
      folderDepth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
      
      -- Check if names match
      if rgnName == trackName and folderDepth == 1 then
        
        -- Tick the corresponding box in the region render matrix
        reaper.SetRegionRenderMatrix(0, rgnIndex, track, 1)
      end
      
    end
  end
end

-- Initialize array for storing list of regions which are not ticked for rendering
deadRegions = {}
deadRegionsIndex = 0

-- Loop through all markers and regions
for i = 0, num_regions+num_markers-1 do
  retval, isrgn, pos, rgnend, rgnName, rgnIndex = reaper.EnumProjectMarkers(i)
  
  -- Check if this marker is a region
  if isrgn then
    
    -- Get first track which this region will be rendering through (if any)
    track = reaper.EnumRegionRenderMatrix(0, rgnIndex, 0)
    
    -- If no track was found...
    if track == nil then
      
      -- Format position to hh:mm:ss
      time = reaper.format_timestr(pos, "")
    
      -- Add name of region to array
      deadRegions[deadRegionsIndex] = rgnIndex .. " - " .. rgnName .. " (" .. time .. ")"
      deadRegionsIndex = deadRegionsIndex + 1
      
    end
  end
end

-- Show a message if any regions will not be rendered
if deadRegionsIndex > 0 then

  str = deadRegionsIndex .. " region(s) have not been tagged for rendering:"
  
  -- Max number of regions to display in message
  maxRegionsInList = 10
  
  -- Loop through dead regions array
  for i = 0, deadRegionsIndex-1 do
    
    -- Check if number of regions listed are over the maximum
    if i >= maxRegionsInList then
      str = str .. "\n" .. "...and " .. (deadRegionsIndex - maxRegionsInList) .. " more."
      break
    else
      str = str .. "\n" .. deadRegions[i]
    end
  end
  
  reaper.ShowMessageBox(str, "Set render matrix by comparing track names and region names", 0)
  
end

-- End undo-block
reaper.Undo_EndBlock2(0,SCRIPT_NAME,-1)
