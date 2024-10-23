-- @description Show VSTi from selected MIDI track sends
-- @author Edgemeal
-- @version 1.0
-- @link Forum Thread https://forum.cockos.com/showthread.php?t=249614
-- @donation Donate https://www.paypal.me/Edgemeal

local track = reaper.GetSelectedTrack(0, 0)
if track ~= nil then
  local send_cnt = reaper.GetTrackNumSends(track, 0)
  for i = 0, send_cnt-1 do
    local dest_track = reaper.GetTrackSendInfo_Value(track, 0, i, "P_DESTTRACK")
    if dest_track ~= nil then
      local vsti_index = reaper.TrackFX_GetInstrument(dest_track)
      if vsti_index > -1 then
        reaper.TrackFX_Show(dest_track, vsti_index, 3)
      end
    end
  end
end
