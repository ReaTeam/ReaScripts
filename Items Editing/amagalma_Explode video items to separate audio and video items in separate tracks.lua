-- @description Explode video items to separate audio and video items in separate tracks
-- @author amagalma
-- @version 1.20
-- @donation https://www.paypal.me/amagalma
-- @changelog - Force all video takes in selected items to be video-only, and the copies in the added tracks to be audio-only
-- @about
--   - Explodes each selected video item into separate items for the video and the audio part. Original items are turned into video-only items, and the new audio-only items are placed in a new track underneath.
--   - Supports items with any number of takes
--   - Only selected items with at least one video take will be processed
--   - Undo will be created only if something is changed
--
--   Inside the script you can specify:
--   1) the name for the new audio-only tracks
--   2) the suffix for the video-only items
--   3) the suffix for the audio-only items
--   4) whether to group video-only and audio-only items together

local name_for_new_audio_only_tracks = "  -- video Audio only"
local suffix_for_video_only_items = " VIDEO"
local suffix_for_audio_only_items = " AUDIO"
local group_video_and_audio_items_together = true

---------------------------------------------------------------

local sel_item_cnt = reaper.CountSelectedMediaItems(0)
if sel_item_cnt == 0 then
  return reaper.defer(function() end)
end

local videoitems_per_track = {}
local itemCount_per_track = {}
local tracks_n = 0
local item_pairs = {}
local item_pairs_n = 0

-- Get video items
for i = 0, sel_item_cnt - 1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  local take_cnt = reaper.CountTakes( item )
  if take_cnt ~= 0 then
    for i = 0, take_cnt-1 do
      local take = reaper.GetTake( item, i )
      local src = reaper.GetMediaItemTake_Source( take )
      if reaper.GetMediaSourceType( src ) == "VIDEO" then
        local track = reaper.GetMediaItem_Track(item)
        if not videoitems_per_track[track] then
          videoitems_per_track[track] = {}
          tracks_n = tracks_n + 1
          itemCount_per_track[track] = 0
        end
        itemCount_per_track[track] = itemCount_per_track[track] + 1
        videoitems_per_track[track][itemCount_per_track[track]] = item
        break
      end
    end
  end
end

if tracks_n == 0 then
  return reaper.defer(function() end)
end


local function DisableAudioOrVideo( item, disable_what )
  -- item must be video item
  -- if what == "audio" then disable audio else disable video
  local audio = disable_what:lower() == "audio"
  local command = audio and "AUDIO 0" or "VIDEO_DISABLED"
  local _, chunk = reaper.GetItemStateChunk( item, "", false )
  local t, t_n = {}, 0
  local take_guids = {}
  for line in chunk:gmatch("[^\r\n]+") do
    t_n = t_n + 1
    if line == "<SOURCE VIDEO" then
      t[t_n] = line
      -- get GUID for renaming
      for i = t_n-1, 1, -1 do
        local guid = t[i]:match("GUID (.+)")
        if guid then
          take_guids[guid] = true
          break
        end
      end
      t_n = t_n + 1
      line = command
    elseif line == "AUDIO 0" or line == "VIDEO_DISABLED" then
      line = ""
    end
    t[t_n] = line
  end
  reaper.SetItemStateChunk(item, table.concat(t, "\n"), false)
  for guid in pairs(take_guids) do
    local take = reaper.GetMediaItemTakeByGUID( 0, guid )
    local name = reaper.GetTakeName(take)
    local suffix = audio and suffix_for_video_only_items or suffix_for_audio_only_items
    reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", name .. suffix, true )
  end
end


reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)

local cur_pos = reaper.GetCursorPosition()
local ar_st, ar_en = reaper.GetSet_ArrangeView2(0,0,0,0,0,0)

-- Copy the video items to an inserted track below
for track, items in pairs(videoitems_per_track) do
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
    -- Paste new item
    reaper.Main_OnCommand(41173, 0) -- Move cursor to start of items
    reaper.Main_OnCommand(42398, 0) -- Paste items/tracks
    local new_item = reaper.GetSelectedMediaItem(0,0)
    item_pairs_n = item_pairs_n + 1
    item_pairs[item_pairs_n] = { item, new_item }
    if group_video_and_audio_items_together then
      reaper.SetMediaItemSelected( item, true )
      reaper.Main_OnCommand(40032, 0) -- Group items
    end
  end
end

-- Apply the settings
for i = 1, item_pairs_n do
  DisableAudioOrVideo( item_pairs[i][1], "audio" )
  DisableAudioOrVideo( item_pairs[i][2], "video" )
end

-- Restore view
reaper.SetEditCurPos(cur_pos,false,false)
reaper.GetSet_ArrangeView2(0,1,0,0,ar_st, ar_en)
reaper.SelectAllMediaItems(0, false)
for i = 1, #item_pairs do
  reaper.SetMediaItemSelected(item_pairs[i][1],true)
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock2(0,"Split video to separate audio/video items", 1|4)
