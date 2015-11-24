 -- this script is ONLY for use with mpl_AB_floating_fx.lua --
 
 retval, track, item, fxnum = reaper.GetFocusedFX()
  track = reaper.GetTrack(0, track-1)
  if retval == 1 then -- if track fx
  
      -- get current config  
      config_t = {}
      fx_guid = reaper.TrackFX_GetFXGUID(track, fxnum)    
      count_params = reaper.TrackFX_GetNumParams(track, fxnum)
      if count_params ~= nil then        
        for i = 1, count_params do
          value = reaper.TrackFX_GetParam(track, fxnum, i-1)
          tostring(value)
          table.insert(config_t, i, value)
        end  
      end              
      config_t_s = table.concat(config_t,"_")

              
        -- store current config
        reaper.SetProjExtState(0, "AB_fx_tables", fx_guid, config_t_s)
    
  end 
