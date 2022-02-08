-- @description Explode takes of items across children tracks, optionally mute and lock original items
-- @author amagalma
-- @version 1.20
-- @changelog 
--     - Overhaul handling of grouped items
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Explodes takes of selected items across tracks. Tracks of original items become parent folders and new tracks their children.
--     - Options inside the script to mute and lock the original items and to name the children tracks like their parents. (default: all ON)
--     - Items, that are grouped vertically, when exploded, are grouped per track (= per take) and not all together

----------------------------------------------------------------------------------

-- USER SETTINGS -----
local MUTE = 1      --
local LOCK = 1      -- (1: ON - 0: OFF)
local NAME = 1      --
----------------------


local sel_cnt = reaper.CountSelectedMediaItems( 0 )
if sel_cnt == 0 then return reaper.defer(function() end) end

-- store track properties
local tracks = {}
local folder_depth = {}
local items = {}
local item_groups = {}
local groups = {}
local has_groups = false
local total_takes = 0
local count_groups = 0
for i = 0, sel_cnt-1 do
  local item = reaper.GetSelectedMediaItem( 0, i )
  items[i+1] = item
  local group_id = reaper.GetMediaItemInfo_Value( item, "I_GROUPID" )
  if group_id ~= 0 then
    if not groups[group_id] then
      count_groups = count_groups + 1
      groups[group_id] = count_groups
    end
    item_groups[item] = group_id
    has_groups = true
  end
  local take_cnt = reaper.CountTakes( item )
  -- track maximum number of takes
  if take_cnt > total_takes then total_takes = take_cnt end
  local track = reaper.GetMediaItem_Track( item )
  -- store maximum take number to be exploded for each item's parent track
  if tracks[track] then
    if take_cnt > tracks[track] then
      tracks[track] = take_cnt
    end
  else
    tracks[track] = take_cnt
    folder_depth[track] = reaper.GetMediaTrackInfo_Value( track, "I_FOLDERDEPTH" )
  end
end

-- Do not continue if no takes to explode
if total_takes < 2 then return reaper.defer(function() end) end


-- MAIN ----------------


reaper.Undo_BeginBlock()
reaper.PreventUIRefresh( 1 )

local MaxGroupID = 0
if has_groups then
  -- Get Project Max Group ID
  for i = 0, reaper.CountMediaItems(0) - 1 do
    local item_group_id = reaper.GetMediaItemInfo_Value(reaper.GetMediaItem(0, i), "I_GROUPID")
    if item_group_id > MaxGroupID then
      MaxGroupID = item_group_id
    end
  end
  
 -- Avoid grouping exploded takes
  for item, group_id in pairs(item_groups) do
    reaper.SetMediaItemInfo_Value( item, "I_GROUPID", groups[group_id] + MaxGroupID )
  end
end

reaper.Main_OnCommand(40224, 0) -- Take: Explode takes of items across tracks

if has_groups then
  for item, group_id in pairs(item_groups) do
    reaper.SetMediaItemInfo_Value( item, "I_GROUPID", group_id )
  end
end

--- make the folders and name them
for track, cnt in pairs(tracks) do
  local track_Nr = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER")
  local last_track = reaper.GetTrack( 0, track_Nr - 1 + cnt)
  -- make parent folder
  reaper.SetMediaTrackInfo_Value( track, "I_FOLDERDEPTH", 1)
  -- make end of folder
  reaper.SetMediaTrackInfo_Value( last_track, "I_FOLDERDEPTH", folder_depth[track] - 1 )
  -- name tracks
  if NAME == 1 then
    local _, name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
    for i = 1, cnt do
      local next_track = reaper.GetTrack( 0, track_Nr - 1 + i)
      reaper.GetSetMediaTrackInfo_String( next_track, "P_NAME", name .. " " .. i, true )
    end
  end
end

-- group exploded takes per track, if needed
if has_groups then
  groups = {}
  local last_group = MaxGroupID
  local cur_parent, parent_id, cur_track, track_id
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    local item = reaper.GetSelectedMediaItem( 0, i )
    local group_id = reaper.GetMediaItemInfo_Value( item, "I_GROUPID" )
    if group_id > MaxGroupID then
      local track = reaper.GetMediaItemTrack( item )
      if track ~= cur_track then
        cur_track = track
        track_id = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" )
        local parent = reaper.GetParentTrack( track )
        if parent ~= cur_parent then
          cur_parent = parent
          parent_id = reaper.GetMediaTrackInfo_Value( parent, "IP_TRACKNUMBER" )
        end
      end
      if not groups[group_id] then groups[group_id] = {} end
      groups[group_id][#groups[group_id]+1] = { item, track_id - parent_id }
    end
  end
  for group_id, items in pairs(groups) do
    MaxGroupID = last_group
    for i = 1, #items do
      last_group = MaxGroupID + items[i][2]
      reaper.SetMediaItemInfo_Value( items[i][1], "I_GROUPID", last_group)
    end
  end
end

-- mute original items and lock them
for i = 1, sel_cnt do
  if MUTE == 1 then
    reaper.SetMediaItemInfo_Value( items[i], "B_MUTE", 1 )
  end
  if LOCK == 1 then
    local lockstate = reaper.GetMediaItemInfo_Value( items[i], "C_LOCK")
    reaper.SetMediaItemInfo_Value( items[i], "C_LOCK", lockstate|1 )
  end
end
  
reaper.PreventUIRefresh( -1 )
reaper.TrackList_AdjustWindows( true )
reaper.UpdateArrange()
reaper.Undo_EndBlock( "Explode takes to children tracks", 1|4 )
