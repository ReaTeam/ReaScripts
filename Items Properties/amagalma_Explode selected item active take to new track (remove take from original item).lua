-- @description Explode selected item active take to new track (remove take from original item)
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Explodes the active take of all selected items to new tracks and removes the exploded take from the original items.
--
--   - Smart undo


local item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt == 0 then return reaper.defer(function() end) end

local tracks = {}
local position = math.huge
local items_unselect = {}
local items_with_takes = {}
local items_with_takes_cnt = 0
local sel_tracks = reaper.CountSelectedTracks( 0 )
local selected_tracks = {}
local cur_pos = reaper.GetCursorPosition()

-- Get info
for i = 0, item_cnt-1 do
  local item = reaper.GetSelectedMediaItem( 0, i )
  local take_cnt = reaper.CountTakes( item )
  if take_cnt > 1 then
    items_with_takes[item] = true
    items_with_takes_cnt = items_with_takes_cnt + 1
    local track = reaper.GetMediaItem_Track( item )
    if not tracks[track] then tracks[track] = reaper.CSurf_TrackToID( track, false ) end
    local pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    if pos < position then position = pos end
  else
    items_unselect[item] = true
  end
end

if items_with_takes_cnt == 0 then return reaper.defer(function() end) end


reaper.Undo_BeginBlock()
reaper.PreventUIRefresh( 1 )

-- Unselect selected tracks
if sel_tracks ~= 0 then
  for tr = sel_tracks-1, 0, -1  do
    local track = reaper.GetSelectedTrack( 0, tr )
    selected_tracks[#selected_tracks+1] = track
    reaper.SetTrackSelected( track, false )
  end
end

-- Get tracks in order
local t = {}
for track, id in pairs(tracks) do
  t[#t+1] = {id, track}
end
tracks, t = t, nil
table.sort(tracks, function(a,b) return a[1] > b[1] end)

-- Unselect items with <2 takes
for item in pairs(items_unselect) do
  reaper.SetMediaItemSelected( item, false )
end

-- Insert tracks
for tr = 1, #tracks do
  reaper.InsertTrackAtIndex( tracks[tr][1], false )
end

-- Copy paste items and crop to active take
reaper.Main_OnCommand(40698, 0) -- Copy items
reaper.Main_OnCommand(40129, 0) -- Delete active take from items
reaper.SetEditCurPos( position, false, false )
local new_track = reaper.CSurf_TrackFromID( tracks[#tracks][1] + 1, false )
reaper.SetOnlyTrackSelected( new_track )
reaper.Main_OnCommand(40914, 0) -- Set first selected track as last touched track
reaper.Main_OnCommand(42398, 0) -- Paste items/tracks
reaper.Main_OnCommand(40131, 0) -- Crop to active take in items
reaper.SetTrackSelected( new_track, false )

-- Restore selected tracks
if sel_tracks ~= 0 then
  for tr = 1, #selected_tracks  do
    reaper.SetTrackSelected( selected_tracks[tr], true )
  end
end

reaper.SetEditCurPos( cur_pos, false, false )
reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()
reaper.Undo_EndBlock( "Explode active take to new track (remove take from original item)", 1|4 )
