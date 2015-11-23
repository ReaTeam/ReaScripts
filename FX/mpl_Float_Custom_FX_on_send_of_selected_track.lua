plugin_name = "ReaVerb"

sel_track = reaper.GetSelectedTrack(0,0)
plugname_lc = string.lower(plugin_name)
if sel_track ~= nil then
    count_sends = reaper.GetTrackNumSends(sel_track, 0)
    for i = 1, count_sends do
      send_track = reaper.BR_GetMediaTrackSendInfo_Track(sel_track, 0, i-1, 1)
      fx_count = reaper.TrackFX_GetCount(send_track)
      if fx_count ~= nil then
        for j = 1, fx_count do
          retval, fx_name = reaper.TrackFX_GetFXName(send_track, j-1, "")
          fx_name_lc = string.lower(fx_name)
          if string.find(fx_name_lc, plugname_lc) ~= nil then
            reaper.TrackFX_Show(send_track, j-1, 3)
          end
        end  
      end
    end    
end
