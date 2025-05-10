-- @description Track Alphabetizer
-- @author Grayson Solis
-- @version 1.0
-- @provides . > graysonsolis_Track alphabetizer.lua
-- @link https://graysonsolis.com
-- @donation https://paypal.me/GrayTunes


----------------------------------------------------------------------------------------
-- SORT SELECTED TRACKS ALPHABETICALLY
----------------------------------------------------------------------------------------
local function SortSelectedTracksAlphabetically() -- Credit to Mordi for this one
  reaper.ClearConsole()

  -- Helper to print debug messages
  local function Msg(variable)
    reaper.ShowConsoleMsg(tostring(variable) .. "\n")
  end

  -- 1. Count selected tracks
  local selNum = reaper.CountSelectedTracks(0)

  -- 2. Begin undo block
  reaper.Undo_BeginBlock2(0)

  -- 3. Initialize data structures
  local track = {}           -- [i] = { MediaTrack, trackName }
  local trackAboveSelectedIdx = 0

  --------------------------------------------------------------------------------------
  -- FETCH INFO FOR EACH SELECTED TRACK
  --------------------------------------------------------------------------------------
  local function FetchSelectedTracksInfo()
    for i = 1, selNum do
      track[i] = {}
      -- MediaTrack object
      track[i][1] = reaper.GetSelectedTrack(0, i - 1)
      -- Track name
      track[i][2] = ""
      reaper.GetSetMediaTrackInfo_String(track[i][1], "P_NAME", track[i][2], false)
    end
  end

  --------------------------------------------------------------------------------------
  -- DETERMINE INSERTION POINT
  --------------------------------------------------------------------------------------
  local function FetchTrackAboveSelectedIndex()
    trackAboveSelectedIdx = reaper.GetMediaTrackInfo_Value(track[1][1], "IP_TRACKNUMBER") - 1
  end

  --------------------------------------------------------------------------------------
  -- (UN)SELECT TRACKS
  --------------------------------------------------------------------------------------
  local function SetTracksSelected(selected)
    for _, t in ipairs(track) do
      reaper.SetTrackSelected(t[1], selected and true or false)
    end
  end

  --------------------------------------------------------------------------------------
  -- SORT ALPHABETICALLY (DESCENDING)
  --------------------------------------------------------------------------------------
  local function Sort()
    table.sort(track, function(left, right)
      return string.upper(left[2]) > string.upper(right[2])
    end)
  end

  --------------------------------------------------------------------------------------
  -- MOVE TRACKS INTO SORTED ORDER
  --------------------------------------------------------------------------------------
  local function Move()
    reaper.PreventUIRefresh(1)
    SetTracksSelected(false)  -- Unselect all
    for _, t in ipairs(track) do
      reaper.SetTrackSelected(t[1], true)                    -- Select each
      reaper.ReorderSelectedTracks(trackAboveSelectedIdx, 0) -- Move into place
      reaper.SetTrackSelected(t[1], false)                   -- Deselect
    end
    reaper.PreventUIRefresh(-1)
  end

  -- Execute steps if any tracks selected
  FetchSelectedTracksInfo()
  if #track > 0 then
    FetchTrackAboveSelectedIndex()
    Sort()
    Move()
    SetTracksSelected(true)  -- Reselect original tracks
  end

  -- End undo block
  reaper.Undo_EndBlock2(0, "Alphabetically Sort Tracks", -1)
end

----------------------------------------------------------------------------------------
-- RECURSIVE FOLDER PROCESSING
----------------------------------------------------------------------------------------
local function ProcessFolder(folderTrack)
  -- 1. Collect immediate children of this folder
  local children = {}
  for i = 0, reaper.CountTracks(0) - 1 do
    local t = reaper.GetTrack(0, i)
    if reaper.GetMediaTrackInfo_Value(t, "P_PARTRACK") == folderTrack then
      table.insert(children, t)
    end
  end
  if #children == 0 then return end  -- No children, done

  -- 2. Backup current selection
  local origSel = {}
  for i = 0, reaper.CountSelectedTracks(0) - 1 do
    origSel[i + 1] = reaper.GetSelectedTrack(0, i)
  end

  -- 3. Sort this folder’s children
  reaper.Main_OnCommand(40297, 0)  -- Unselect all
  for _, t in ipairs(children) do reaper.SetTrackSelected(t, true) end
  SortSelectedTracksAlphabetically()

  -- 4. Restore original selection
  reaper.Main_OnCommand(40297, 0)
  for _, t in ipairs(origSel) do reaper.SetTrackSelected(t, true) end

  -- 5. Recurse into subfolders
  for _, t in ipairs(children) do
    if reaper.GetMediaTrackInfo_Value(t, "I_FOLDERDEPTH") == 1 then
      ProcessFolder(t)
    end
  end
end

----------------------------------------------------------------------------------------
-- MAIN ENTRY POINT
----------------------------------------------------------------------------------------
local function main()
  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock()

  -- Sort all selected folder tracks
  SortSelectedTracksAlphabetically()
  for i = 0, reaper.CountSelectedTracks(0) - 1 do
    local t = reaper.GetSelectedTrack(0, i)
    if reaper.GetMediaTrackInfo_Value(t, "I_FOLDERDEPTH") == 1 then
      ProcessFolder(t)
    end
  end

  reaper.Undo_EndBlock("Alphabetize Folder Hierarchy", -1)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end

-- Run the script
main()
