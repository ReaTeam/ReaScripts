-- @description Explode takes of items across tracks (according to their source files)
-- @author amagalma
-- @version 1.10
-- @changelog 
--    - Don't create empty tracks when the selected items have empty take lanes
-- @link https://forum.cockos.com/showthread.php?t=261306
-- @donation https://www.paypal.me/amagalma
-- @about Differs from native action, because it ensures that each track will contain only one source file (recording pass)


local item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt == 0 then return reaper.defer(function() end) end

-- Save item selection
local sel_items = {}
for i = 0, item_cnt-1 do
  sel_items[i+1] = reaper.GetSelectedMediaItem( 0, i )
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh( 1 )


-- Get all tracks in project (needed for empty takes)
local All_tracks = {}
for tr = 0, reaper.CountTracks( 0 ) - 1 do
  All_tracks[reaper.GetTrack( 0, tr )] = true
end


-- Explode takes of items across tracks
reaper.Main_OnCommand(40224, 0)
-- Fix item selection
item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt == 0 then
  for i = 1, #sel_items do
    reaper.SetMediaItemSelected( sel_items[i], true )
  end
  item_cnt = #sel_items
else
  for i = 1, #sel_items do
    reaper.SetMediaItemSelected( sel_items[i], false )
  end
end


-- SORT ITEMS
local cur_id = 0 -- first selected item id

::BEGIN::
local Parent_Track_cnt = 0
local Sources = {}
local Sources_cnt = 0
local Sources_to_sort = {}
local Items = {}
local first_track_id = false
local src_filename
local prev_track_id

-- Count tracks and sources, break if not consecutive
local cur_track
for i = cur_id, item_cnt-1 do
  cur_id = i
  local item = reaper.GetSelectedMediaItem( 0, i )
  -- Track
  local track = reaper.GetMediaItem_Track( item )
  local track_id = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" )
  if not first_track_id then
    first_track_id = track_id
    prev_track_id = first_track_id
  end
  if track_id ~= prev_track_id then
    if track_id == prev_track_id + 1 then
      prev_track_id = track_id
    else -- not consecutive then break and store item
      break
    end
  end
  if track ~= cur_track then
    cur_track = track
    Parent_Track_cnt = Parent_Track_cnt + 1
  end
  -- Source
  local take = reaper.GetActiveTake( item )
  if take then
    local src = reaper.GetMediaItemTake_Source( take )
    local src_type = reaper.GetMediaSourceType( src, "" )
    if src_type == "SECTION" then
      src = reaper.GetMediaSourceParent( src )
    end
    local item_chunk = ({reaper.GetItemStateChunk( item, "", false )})[2]
    local recpass = item_chunk:match(reaper.BR_GetMediaItemTakeGUID( take ):gsub("-", "%%-") .. "\nRECPASS (%d+)") or ""
    src_filename = recpass .. "#" .. reaper.GetMediaSourceFileName( src )
    if not Sources[src_filename] then
      Sources_cnt = Sources_cnt + 1
      Sources[src_filename] = Sources_cnt - 1
      Sources_to_sort[Sources_cnt] = src_filename
    end
  end
  -- Item and Source File association
  if not Items[item] then
    Items[item] = src_filename
  end
end
local last_track_id = reaper.GetMediaTrackInfo_Value( cur_track, "IP_TRACKNUMBER" )

-- Sort sources according to filename/recpass
table.sort(Sources_to_sort, function(a,b) return a<b end)
for i = 1, Sources_cnt do
  Sources[Sources_to_sort[i]] = i - 1
end

-- Add tracks for sources
if Parent_Track_cnt ~= Sources_cnt then
  for i = 1, Sources_cnt - Parent_Track_cnt do
    reaper.InsertTrackAtIndex( last_track_id-1, false )
  end
end

-- Sort to tracks
for item, src_filename in pairs(Items) do
  local track = reaper.CSurf_TrackFromID( first_track_id + Sources[src_filename], false )
  reaper.MoveMediaItemToTrack( item, track )
end

if cur_id ~= item_cnt-1 then
  goto BEGIN
end

reaper.Main_OnCommand(40548, 0) -- Heal splits in items

-- Delete empty tracks (needed for empty takes)
for tr = reaper.CountTracks( 0 )-1, 0, -1 do
  local track = reaper.GetTrack( 0, tr )
  if not All_tracks[track] then
    local id = reaper.CSurf_TrackToID( track, false)
    if reaper.GetTrackNumMediaItems( track ) == 0 then
      reaper.DeleteTrack( track )
    end
  end
end

reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()
reaper.Undo_EndBlock( "Sort items to tracks by source filename", 4 )
