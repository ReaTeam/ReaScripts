-- @description Remove empty tracks
-- @author cfillion
-- @version 1.0
-- @provides
--   .
--   [main] . > cfillion_Remove empty tracks (no prompt).lua
-- @link Forum thread https://forum.cockos.com/showthread.php?t=168134
-- @donation https://reapack.com/donate

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

local script_name = select(2, reaper.get_action_context()):match('([^/\\_]+)%.lua$')
local track_index, track_count = 0, reaper.CountTracks()
local bucket, bucket_index = {}, 0

while track_index < track_count do
  local track = reaper.GetTrack(nil, track_index)

  local fx_count   = reaper.TrackFX_GetCount(track)
  local item_count = reaper.CountTrackMediaItems(track)
  local env_count  = reaper.CountTrackEnvelopes(track)
  local depth      = reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH')
  local is_armed   = reaper.GetMediaTrackInfo_Value(track, 'I_RECARM')
  local routing    = reaper.GetTrackNumSends(track, -1) + -- receives
                     reaper.GetTrackNumSends(track,  0) + -- sends
                     reaper.GetTrackNumSends(track,  1)   -- hardware outputs

  if fx_count + item_count + env_count + math.max(depth, 0) + is_armed + routing == 0 then
    bucket[bucket_index] = track
    bucket_index = bucket_index + 1
  end

  track_index = track_index + 1
end

if bucket_index > 0 then
  local dialog_btn

  if script_name:match('no prompt') then
    dialog_btn = 1
  else
    dialog_btn = reaper.ShowMessageBox(
      ('Remove %d empty tracks?'):format(bucket_index), 'Confirmation', 1)
  end

  if dialog_btn == 1 then
    local track_index = 0

    while track_index < bucket_index do
      reaper.DeleteTrack(bucket[track_index])
      track_index = track_index + 1
    end
  end
end

reaper.Undo_EndBlock(script_name, 1)
reaper.PreventUIRefresh(-1)
