-- @version 0.1
-- @author spk77
-- @changelog
--   + initial release
-- @description Set solo for send X
-- @about
--   # Set solo for send X
--
--  Sets solo for send X (by muting all other sends on the track). This works on selected tracks.

-- @provides
--   [nomain] .
--   [main] spk77_Set solo for send 1.lua
--   [main] spk77_Set solo for send 2.lua
--   [main] spk77_Set solo for send 3.lua
--   [main] spk77_Set solo for send 4.lua
--   [main] spk77_Set solo for send 5.lua

function solo_send(send_index)
  local tr_count = reaper.CountSelectedTracks(0)
  if tr_count == 0 then
    return
  end
  reaper.Undo_BeginBlock()
  for i=1, tr_count do
    local tr = reaper.GetSelectedTrack(0, i-1)
    if tr ~= nil then
      -- count hardware outs (this is needed to get the correct send index)
      local tr_num_hw_outs = reaper.GetTrackNumSends(tr, 1)
      local send_count = reaper.GetTrackNumSends(tr, 0)
      if send_index > tr_num_hw_outs + send_count-1 then
        goto continue
      end
      
      for i=tr_num_hw_outs, send_count-1 do
        local ret, is_muted = reaper.GetTrackSendUIMute(tr, i)
        if i == send_index then
          if is_muted then
            reaper.ToggleTrackSendUIMute(tr, tr_num_hw_outs + i)
          end
        elseif i ~= send_target then
          if not is_muted then
            reaper.ToggleTrackSendUIMute(tr, tr_num_hw_outs + i)
          end
        end
      end
    end
  ::continue::
  end
  reaper.Undo_EndBlock("Set solo for send", -1)
end
