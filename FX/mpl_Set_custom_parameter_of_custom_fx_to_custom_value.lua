plug_name = "LeCto"
param_name = "Oversampling" -- it is better to type
set_value = 1 -- insert here (0..1) values

param_name_lc = string.lower(param_name)
trackcount = reaper.CountTracks(0)
if trackcount ~= nil then
  for i = 1, trackcount do
    track = reaper.GetTrack(0,i-1)
    fx_count = reaper.TrackFX_GetCount(track)
    if fx_count ~= nil then
      for j = 1, fx_count do
        retval, fx_name = reaper.TrackFX_GetFXName(track, j-1, "")
        if string.find(fx_name, plug_name) ~= nil then
          par_count = reaper.TrackFX_GetNumParams(track, j-1);
          for k = 1, par_count do
            retval, par_name = reaper.TrackFX_GetParamName(track, j-1, k-1, "")
            par_name_lc = string.lower(par_name)
            if string.find(par_name_lc, param_name_lc) ~= nil then
              reaper.TrackFX_SetParam(track, j-1, k-1, set_value)
            end
          end
        end
      end
    end  
  end
end
