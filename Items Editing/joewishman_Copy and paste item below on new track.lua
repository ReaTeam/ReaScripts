-- @description Copy and paste item below on new track
-- @author JoeWishman
-- @version 1.0
-- @about
--   Run the script to copy the selected clip to the track below.
--   If no tracks exist, the script will create one.
--   Cheers

function copyItemDown()
  local item = reaper.GetSelectedMediaItem(0, 0)
  if not item then return end

  local src_track = reaper.GetMediaItemTrack(item)
  local src_idx = reaper.GetMediaTrackInfo_Value(src_track, "IP_TRACKNUMBER") - 1
  local dest_idx = src_idx + 1

  local track_count = reaper.CountTracks(0)
  while dest_idx >= track_count do
    reaper.InsertTrackAtIndex(track_count, true)
    track_count = track_count + 1
  end

  local dest_track = reaper.GetTrack(0, dest_idx)
  if not dest_track then return end

  local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

  local new_item = reaper.AddMediaItemToTrack(dest_track)
  reaper.SetMediaItemInfo_Value(new_item, "D_POSITION", pos)
  reaper.SetMediaItemInfo_Value(new_item, "D_LENGTH", len)

  local take = reaper.GetMediaItemTake(item, 0)
  if take then
    local source = reaper.GetMediaItemTake_Source(take)
    local new_take = reaper.AddTakeToMediaItem(new_item)
    reaper.SetMediaItemTake_Source(new_take, source)
  end

  reaper.UpdateArrange()
end

reaper.Undo_BeginBlock()
copyItemDown()
reaper.Undo_EndBlock("Copy Item Down 1 Track", -1)

