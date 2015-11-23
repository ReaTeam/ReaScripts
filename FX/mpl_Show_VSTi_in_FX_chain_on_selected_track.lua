  script_title = "Show VSTi in FX chain on selected track"
  reaper.Undo_BeginBlock() 
  
  selected_tracks_count = reaper.CountSelectedTracks(0);
  for i=1, selected_tracks_count do -- loop selected tracks
    track = reaper.GetSelectedTrack(0, i-1)
    if track ~= nil then
      vsti_id = reaper.TrackFX_GetInstrument(track)
      if vsti_id ~= nil then
        reaper.TrackFX_Show(track, vsti_id, 1) -- select in fx chain      
      end 
    end -- if track ~= nil then
  end -- loop selected tracks

  reaper.Undo_EndBlock(script_title, 0)
