-- @description Apply track/take FX to items (mono output) and place in new track
-- @author amagalma
-- @version 1.00
-- @about
--   # Applies the track/take FX to selected items (mono output) and places them in a new track above or below
--     - Setting for "above/below" inside the script (default: below)

----------------------------------------------------------------------------------

-- USER SETTINGS -----------------------------------------------------------
local place = 0 -- enter 0 to explode below  OR  enter -1 to explode above
----------------------------------------------------------------------------

----------------------------------------------------------------------------------

local reaper = reaper
local sel_cnt = reaper.CountSelectedMediaItems( 0 )
if sel_cnt < 1 then return reaper.defer(function() end) end

-- store selected items, and insert tracks below or above tracks with items (only once)
local sel_items = {}
local item_tracks = {}
for i = 0, sel_cnt-1 do
  local item = reaper.GetSelectedMediaItem( 0, i )
  local track = reaper.GetMediaItem_Track( item )
  local GUID = reaper.GetTrackGUID( track )
  local track_Nr = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" )
  sel_items[#sel_items+1] = item
  -- insert tracks below or above tracks with items
  if not item_tracks[GUID] then -- insert only once
    reaper.InsertTrackAtIndex( track_Nr + place, false )
    item_tracks[GUID] = true
  end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh( 1 )

reaper.Main_OnCommand(40361, 0) -- Item: Apply track/take FX to items (mono output)

local new_items = {}
for i = 1, #sel_items do
  -- Copy item to track below and crop to active take
  reaper.SelectAllMediaItems( 0, false )
  reaper.SetMediaItemSelected( sel_items[i], true )
  reaper.Main_OnCommand(40698, 0) -- Edit: Copy items
  reaper.Main_OnCommand(41173, 0) -- Item navigation: Move cursor to start of items
  local track = reaper.GetMediaItem_Track( sel_items[i] )
  local _, name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
  local track_Nr = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" )
  if place == -1 then place = -2 end
  local next_track = reaper.GetTrack( 0, track_Nr + place )
  reaper.GetSetMediaTrackInfo_String( next_track, "P_NAME", name .. " effects", true )
  reaper.SetOnlyTrackSelected( next_track )
  reaper.Main_OnCommand(40058, 0) -- Item: Paste items/tracks
  reaper.Main_OnCommand(40131, 0) -- Take: Crop to active take in items
  -- Delete active take from original item
  local new_item = reaper.GetSelectedMediaItem( 0, 0 )
  new_items[#new_items+1] = new_item
  reaper.SetMediaItemSelected(new_item, false )
  reaper.SetMediaItemSelected( sel_items[i], true )
  reaper.Main_OnCommand(40129, 0) -- Take: Delete active take from items
end

-- select new items
  reaper.SelectAllMediaItems( 0, false )
for i = 1, #new_items do
  reaper.SetMediaItemSelected(new_items[i] , true )
end

reaper.PreventUIRefresh( -1 )
reaper.TrackList_AdjustWindows( true )
reaper.UpdateArrange()
reaper.Undo_EndBlock( "Apply mono FX to items, place in new track", 1 )
