-- @description Sort selected tracks alphabetically
-- @author Mordi
-- @version 1.0
-- @about
--   # Sort selected tracks alphabetically
--
--   Sorts selected tracks based on track name. All tracks will be lumped together below the track immediately above the topmost selected track.

SCRIPT_NAME = "Sort selected tracks alphabetically"

reaper.ClearConsole()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

-- Get number of selected tracks
selNum = reaper.CountSelectedTracks(0)

-- Begin undo-block
reaper.Undo_BeginBlock2(0)

-- Initialize
track = {} -- [1] == MediaTrack, [2] == Track name
trackName = {}
trackNumber = {}
trackAboveSelectedIdx = 0

function FetchSelectedTracksInfo()
  for i = 1, selNum do
    track[i] = {}
  
    -- Get track
    track[i][1] = reaper.GetSelectedTrack(0, i-1)
    
    -- Get name
    track[i][2] = ""
    retval, track[i][2] = reaper.GetSetMediaTrackInfo_String(track[i][1], "P_NAME", track[i][2], false)
  end
end

function FetchTrackAboveSelectedIndex()
  -- Get index of track above selection
  trackAboveSelectedIdx = reaper.GetMediaTrackInfo_Value(track[1][1], "IP_TRACKNUMBER") - 1
end

function SetTracksSelected(selected)
  for i = 1, #track do
    reaper.SetTrackSelected(track[i][1], selected)
  end
end

function Sort()
  -- Alphabetical sort (descending)
  table.sort(track, function (left, right)
      return string.upper(left[2]) > string.upper(right[2])
  end)
end

function Move()
  reaper.PreventUIRefresh(1)
  SetTracksSelected(0) -- Unselect all
  for i, t in ipairs(track) do -- Loop through
    reaper.SetTrackSelected(t[1], 1) -- Select track
    reaper.ReorderSelectedTracks(trackAboveSelectedIdx, 0) -- Reorder track
    reaper.SetTrackSelected(t[1], 0) -- Unselect track
  end
  reaper.PreventUIRefresh(-1)
end

-- Do stuff
FetchSelectedTracksInfo()
if #track > 0 then
  FetchTrackAboveSelectedIndex()
  Sort()
  Move()
  SetTracksSelected(1)
end

-- End undo-block
reaper.Undo_EndBlock2(0,SCRIPT_NAME,-1)
