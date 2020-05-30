-- @description Render time selection to new track
-- @author DSG
-- @version 1.0
-- @screenshot Screen https://stash.reaper.fm/39352/DSG_-_Render_time_selection_to_new_track.gif
-- @about
--   # DSG - Render time selection to new track
--
--   Quick render selected tracks to new track using the time selection as boundaries
--
--   Key features:
--
--   - Habitual way if you used FL earlier
--   - Excludes selected folder tracks for prevent multiple render of children track

function hasSelectedTrack()
   return reaper.CountSelectedTracks(0) > 0
end

function hasSelection()
  timeselstart, timeselend = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  return timeselstart < timeselend
end

function getFilename(path)
  local start, finish = path:find('[%w%s!-={-|]+[_%.].+')
  return path:sub(start, #path)
end

function trackIsFolder(track)
  return reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") >= 1
end

function trackHasParent(track)
  return reaper.GetMediaTrackInfo_Value(track, "P_PARTRACK") ~= 0.0
end

function getParentTrack(track)
  return reaper.GetParentTrack(track)
end

function alert(msg)
  reaper.ShowMessageBox(msg, "Alert", 0)
end

function run()
  -- Check selection
  if(not hasSelection()) then
    reaper.ShowMessageBox("No time selection", "Error", 0)
    return false
  end

  -- Check selected tracks
  if(not hasSelectedTrack()) then
    reaper.ShowMessageBox("No tracks selected", "Error", 0)
    return false
  end

  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock()

  -- BounceTrack Create
  local trackCount = reaper.CountTracks(0)

  reaper.InsertTrackAtIndex(trackCount, 1)
  local bounceTrack = reaper.GetTrack(0, trackCount)

  -- Routing
  local selectedTracks = {}
  local selectedTrackCount = reaper.CountSelectedTracks(0)
  local lastSelectedTrackIdx
  local lastSelectedTrack

  for i = 0, selectedTrackCount - 1 do
    local track = reaper.GetSelectedTrack(0, i)
    selectedTracks[i] = track
    reaper.CreateTrackSend(track, bounceTrack)
    if(i == selectedTrackCount - 1) then
      lastSelectedTrack = track
      lastSelectedTrackIdx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    end
  end

  -- Render
  reaper.SetOnlyTrackSelected(bounceTrack, 1)
  reaper.Main_OnCommand(41716, 0) -- Track: Render selected area of tracks to stereo post-fader stem tracks (and mute originals)

  -- Remove Sends and Bounce Track
  for i,track in pairs(selectedTracks) do
    reaper.RemoveTrackSend(track, 0, reaper.GetTrackNumSends(track, 0)-1)
  end

  reaper.DeleteTrack(bounceTrack)

  -- Change name, color and position
  local stem = reaper.GetSelectedTrack(0, 0)
  local stemItem = reaper.GetTrackMediaItem(stem, 0)
  local stemItemTake = reaper.GetActiveTake(stemItem)

  local takeSource = reaper.GetMediaItemTake_Source(stemItemTake)
  local filename = reaper.GetMediaSourceFileName(takeSource, "")
  local trackName = getFilename(filename)

  reaper.SetTrackColor(stem, reaper.ColorToNative(255, 0, 0))
  reaper.GetSetMediaTrackInfo_String(stem, "P_NAME", trackName, true)
  reaper.GetSetMediaItemTakeInfo_String(stemItemTake, "P_NAME", trackName, true)

  if(trackIsFolder(lastSelectedTrack) or trackHasParent(lastSelectedTrack)) then
    local trackNewLastSelectedTrackIdx = trackCount + 1
    local iteration = 0
    for i = lastSelectedTrackIdx, trackCount do
      iteration = iteration + 1
      local track = reaper.GetTrack(0, i)

      if(reaper.GetParentTrack(track) == nil) then
        trackNewLastSelectedTrackIdx = i
        break
      end
    end

    lastSelectedTrackIdx = trackNewLastSelectedTrackIdx
  end

  reaper.ReorderSelectedTracks(lastSelectedTrackIdx, 0)

  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.SetMixerScroll(stem)
  reaper.Main_OnCommand(40913, 0) -- Track: Vertical scroll selected tracks into view
  reaper.Main_OnCommand(40632, 0) -- Go to start of loop

  reaper.Undo_EndBlock("Render time selection to stem track", 0)
end

-- Smart exclude folders
local excludedFolders = {}

for i = 0, reaper.CountSelectedTracks(0) - 1 do
  local track = reaper.GetSelectedTrack(0, i)

  if(trackHasParent(track)) then
    local parentTrack = reaper.GetParentTrack(track)
    table.insert(excludedFolders, parentTrack)

    while trackHasParent(parentTrack) do
       parentTrack = reaper.GetParentTrack(parentTrack)
       table.insert(excludedFolders, parentTrack)
    end
  end
end

for i,track in pairs(excludedFolders) do
    reaper.SetMediaTrackInfo_Value(track, "I_SELECTED", 0)
end

run()
