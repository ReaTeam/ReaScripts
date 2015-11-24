   script_title = "Delete all MIDI OSC learn from selected track"
   reaper.Undo_BeginBlock()
   
   track = reaper.GetSelectedTrack(0,0)
    if track ~= nil then
      _, chunk = reaper.GetTrackStateChunk(track, '')
      chunk_t = {}
      for line in chunk:gmatch("[^\r\n]+") do  table.insert(chunk_t, line)  end
      for i = 1, #chunk_t do
        chunk_t_item = chunk_t[i]
        st_find = string.find(chunk_t_item, 'PARMLEARN')
        if st_find == 1 then
          chunk_t[i] = ''
        end
      end
      new_chunk = table.concat(chunk_t, '\n')
      reaper.SetTrackStateChunk(track, new_chunk)
    end
    
    reaper.Undo_EndBlock(script_title,0)
