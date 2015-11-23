  script_title = "create_ReaComp_sidechain_routing"
  
  threshold = 0.25
  ratio = 0.06
        
  -- create_ReaComp_sidechain_routing
  -- source - selected track
  -- destination - track under mouse cursor
  
  reaper.Undo_BeginBlock()
  
  -- get source tracks id`s--
    count_tracks = reaper.CountTracks(0)
    if count_tracks ~= nil then
      sel_id_t = {}
      for i = 1, count_tracks do
        track = reaper.GetTrack(0,i-1)
        isselect = reaper.IsTrackSelected(track)
        if isselect == true then 
          i_table = i - 1     
          table.insert(sel_id_t, i_table)
        end
      end  
    end
  if reaper.CountSelectedTracks(0) == 1 then 
  -- get dest track info
    window, segment, details = reaper.BR_GetMouseCursorContext()
    if segment == "track" then
      dest_track = reaper.BR_GetMouseCursorContext_Track()
      retval, track_state_chunk = reaper.GetTrackStateChunk(dest_track, "")
    end  
  
  -- form temp string --
    if sel_id_t ~= nil and #sel_id_t > 0 then
      temp_string = ""
      for i = 1, #sel_id_t do
        source_track_id = sel_id_t[i]
        temp_string = temp_string.."AUXRECV "..source_track_id.." 3 1 0 0 0 0 0 2 -1 4177951 -1 ''".."\n"
      end
    end
  
  -- set new chunk --
    if dest_track ~= nil then
      newchunk = string.gsub(track_state_chunk, "MIDIOUT", temp_string.."MIDIOUT")
      newchunk = string.gsub(newchunk, 'NCHAN 2','NCHAN 4')
      reaper.SetTrackStateChunk(dest_track, newchunk)
            
      --insert reacomp
        reaper.TrackFX_GetByName(dest_track, 'ReaComp (Cockos)', true)
        fx_id = reaper.TrackFX_GetByName(dest_track, 'ReaComp (Cockos)', false)
        reaper.TrackFX_SetOpen(dest_track, fx_id, true)
        reaper.TrackFX_SetParam(dest_track, fx_id, 0, threshold)
        reaper.TrackFX_SetParam(dest_track, fx_id, 1, ratio)    
        reaper.TrackFX_SetParam(dest_track, fx_id, 8, (1/1084)*2)    
    end  
   end 
  --  reaper.ShowConsoleMsg(track_state_chunk)
  
  reaper.UpdateArrange()
  reaper.Undo_EndBlock(script_title, 0)
