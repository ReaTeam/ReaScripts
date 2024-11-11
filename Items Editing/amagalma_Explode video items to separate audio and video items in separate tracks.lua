-- @description Explode video items to separate audio and video items in separate tracks
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about
--   - Explodes each selected item into separate items for the video and the audio part. Original items are turned into video-only  items, and the new audio--only  items are placed in a new track underneath.
--
--   Inside the script you can specify:
--   1) the name for the new audio-only  tracks
--   2) the suffix for the video-only  items
--   3) the suffix for the audio-only  items
--   4) whether to group video-only  and audio-only  items together

name_for_new_audio_only_tracks = "  -- video Audio only"
suffix_for_video_only_items = " VIDEO"
suffix_for_audio_only_items = " AUDIO"
group_video_and_audio_items_together = true

---------------------------------------------------------------

local sel_item_cnt = reaper.CountSelectedMediaItems(0)
if sel_item_cnt == 0 then
  return reaper.defer(function() end)
end

local videoitems_by_track = {}
local tracks_n = 0
local takeGUIDsAndAddresses_by_item = {}
local new_items = {}

for i = 0, sel_item_cnt - 1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  local take = reaper.GetActiveTake(item)
  if take then
    local src = reaper.GetMediaItemTake_Source( take )
    if reaper.GetMediaSourceType( src ) == "VIDEO" then
      local track = reaper.GetMediaItem_Track(item)
      if not videoitems_by_track[track] then
        videoitems_by_track[track] = {}
        tracks_n = tracks_n + 1
      end
      videoitems_by_track[track][#videoitems_by_track[track]+1] = item
      local _, take_guid = reaper.GetSetMediaItemTakeInfo_String( take, "GUID", "", false )
      takeGUIDsAndAddresses_by_item[item] = {take_guid, take}
    end
  end
end

if tracks_n == 0 then
  return reaper.defer(function() end)
end

local function DisableAudioOrVideo(item,take_guid,audio,take)
  -- item must be video item
  -- if audio == true then disable audio else disable video
  local command = audio and "AUDIO 0" or "VIDEO_DISABLED"
  local take_guid = "GUID " .. take_guid
  local search_guid = true
  local _, chunk = reaper.GetItemStateChunk( item, "", false )
  local t, t_n = {}, 0
  for line in chunk:gmatch("[^\r\n]+") do
    t_n = t_n + 1
    if search_guid then
      if line == take_guid then
        search_guid = false
      end
    elseif search_guid == false then
      if line == "<SOURCE VIDEO" then
        t[t_n] = line
        t_n = t_n + 1
        line = command
        search_guid = nil
      end
    end
    t[t_n] = line
  end
  reaper.SetItemStateChunk(item, table.concat(t, "\n"), false)
  if take then
    local name = reaper.GetTakeName(take)
    local suffix = audio and suffix_for_video_only_items or suffix_for_audio_only_items
    reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", name .. suffix, true )
  end
end


reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)

local cur_pos = reaper.GetCursorPosition()
local ar_st, ar_en = reaper.GetSet_ArrangeView2(0,0,0,0,0,0)

-- Do the thing
for track, items in pairs(videoitems_by_track) do
  local track_id = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" )
  reaper.InsertTrackInProject( 0, track_id, 1 )
  local newtrack = reaper.GetTrack( 0, track_id )
  reaper.GetSetMediaTrackInfo_String( newtrack, "P_NAME", name_for_new_audio_only_tracks, true )
  reaper.SetOnlyTrackSelected( newtrack )
  for i = 1, #items do
    reaper.SelectAllMediaItems(0, false)
    local item = items[i]
    reaper.SetMediaItemSelected( item, true )
    reaper.Main_OnCommand(40698, 0) -- Copy items
    -- Disable audio
    local take_guid = takeGUIDsAndAddresses_by_item[item][1]
    local take = takeGUIDsAndAddresses_by_item[item][2]
    DisableAudioOrVideo(item,take_guid,true,take)
    -- Paste new item
    reaper.Main_OnCommand(41173, 0) -- Move cursor to start of items
    reaper.Main_OnCommand(42398, 0) -- Paste items/tracks
    local new_item = reaper.GetSelectedMediaItem(0,0)
    new_items[#new_items+1] = new_item
    take = reaper.GetActiveTake(new_item)
    DisableAudioOrVideo(new_item,take_guid,false,take)
    if group_video_and_audio_items_together then
      reaper.SetMediaItemSelected( item, true )
      reaper.Main_OnCommand(40032, 0) -- Group items
    end
  end
end

-- Restore view
reaper.SetEditCurPos(cur_pos,false,false)
reaper.GetSet_ArrangeView2(0,1,0,0,ar_st, ar_en)
reaper.SelectAllMediaItems(0, false)
for i = 1, #new_items do
  reaper.SetMediaItemSelected(new_items[i],true)
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock2(0,"Split video to separate audio/video items", 1|4)
