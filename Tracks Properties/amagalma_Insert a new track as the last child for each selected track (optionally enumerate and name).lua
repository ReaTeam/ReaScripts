-- @description Insert a new track as the last child for each selected track (optionally enumerate and name)
-- @author amagalma
-- @version 1.00
-- @screenshot https://i.ibb.co/QPFstXH/Insert-a-new-track-as-the-last-child-for-each-selected-track-optionally-enumerate-and-name.gif
-- @donation https://www.paypal.me/amagalma
-- @about
--   Inserts a new track as the last child for each selected track (parent folder)
--
--   - Optionally enumerate and name inserted children for each folder (settings inside the script - enabled by default)
--   - Default name: "{parent name} Take ##" (## : denotes two-digit enumeration)
--   - If the selected track is not already a parent, then it becomes a parent folder and a new child is inserted


-- USER SETTINGS ----------------------------------
local enumerate_childs = true -- (true or false)
local name = "Take" -- Prefix for the enumeration
local use_parent_name = true
---------------------------------------------------


local track_cnt = reaper.CountSelectedTracks( 0 )
if track_cnt == 0 then return end

-- Create table
local total_depth = 0
local t = {}
for i = 0, reaper.CountTracks( 0 ) - 1 do
  local tr = reaper.GetTrack( 0, i )
  local depth = reaper.GetMediaTrackInfo_Value( tr, "I_FOLDERDEPTH" )
  t[i+1] = {tr, total_depth, depth}
  total_depth = total_depth + depth
end

reaper.PreventUIRefresh( 1 )

-- Iterate through selected items
for k = 0, track_cnt-1 do
  local track = reaper.GetSelectedTrack( 0, k )
  local parent_name = use_parent_name and
    ({reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )})[2] or ""
  local track_id = reaper.CSurf_TrackToID( track, false )
  local sel_track_total_depth = t[track_id][2]
  local sel_track_depth_value = t[track_id][3]
  local last_track_id, last_track_total_depth, last_track_depth_value, last_track
  local num_of_tracks_in_folder = 1
  local continue = true
  -- Find last child / insert position
  for i = track_id, #t do
    local tr = t[i][1]
    local cur_track_total_depth = t[i][2]
    local depth_val = t[i][3]
    if track == tr then
      if depth_val <= 0 then
        last_track_id, last_track_total_depth, last_track_depth_value =
         - (i + 1), cur_track_total_depth, depth_val
         continue = false
      end
    end
    if continue then
      if cur_track_total_depth == sel_track_total_depth + 1 then
        num_of_tracks_in_folder = num_of_tracks_in_folder + 1
      end
      if depth_val < 0 and cur_track_total_depth > sel_track_total_depth then
        last_track_id, last_track_total_depth, last_track_depth_value =
        i + 1, cur_track_total_depth, depth_val
        last_track = tr
        continue = false
      end
    end
  end
  local newval, first_track, second_track_val
  if last_track_id < 0 then
    last_track_id = -last_track_id
    first_track, newval = track, 1
    second_track_val = sel_track_depth_value - 1
  else
    first_track, newval = last_track, sel_track_total_depth + 1 - last_track_total_depth
    second_track_val = last_track_depth_value - newval
  end
  -- Insert new last child track
  reaper.InsertTrackAtIndex( last_track_id - 1, true )
  reaper.SetMediaTrackInfo_Value( first_track, "I_FOLDERDEPTH", newval )
  local second_track = reaper.CSurf_TrackFromID( last_track_id, false )
  reaper.SetMediaTrackInfo_Value( second_track, "I_FOLDERDEPTH", second_track_val )
  if enumerate_childs then
    local trackname = parent_name .. " " .. name .. " "
    reaper.GetSetMediaTrackInfo_String( second_track, "P_NAME",
            trackname .. string.format("%02i", num_of_tracks_in_folder), true )
  end
  -- Update table if needed
  if track_cnt > 1 then
    table.insert(t, last_track_id, { reaper.CSurf_TrackFromID( last_track_id, false ),
                                      t[last_track_id-1][2], second_track_val})
    t[last_track_id-1][3] = newval
  end
end

reaper.PreventUIRefresh( -1 )
reaper.TrackList_AdjustWindows( 0 )

-- Undo
local undo = "Insert new track as last child of selected track" .. 
                                      (track_cnt > 1 and "s" or "")
reaper.Undo_OnStateChangeEx2( 0, undo, 1, -1 )
