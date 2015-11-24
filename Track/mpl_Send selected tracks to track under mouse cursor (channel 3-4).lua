  script_title = "Send selected tracks to track under mouse cursor (channel 3-4)"
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
      temp_string = temp_string.."AUXRECV "..source_track_id.." 0 1 0 0 0 0 0 2 -1 4177951 -1 ''".."\n"
    end
  end

-- set new chunk --
  if dest_track ~= nil then
    newchunk = string.gsub(track_state_chunk, "MIDIOUT", temp_string.."MIDIOUT")  
    reaper.SetTrackStateChunk(dest_track, newchunk)
  end  
  

reaper.UpdateArrange()
reaper.Undo_EndBlock(script_title, 0)
