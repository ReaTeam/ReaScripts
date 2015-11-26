  --[[
   * ReaScript Name: Delete all MIDI OSC learn from selected track
   * Description: 
   * Instructions: 
   * Author: Michael Pilyavskiy
   * Author URl: http://forum.cockos.com/member.php?u=70694
   * Repository: 
   * Repository URl: 
   * File URl:
   * Licence: GPL v3
   * Forum Thread: Delete all MIDI OSC learn
   * Forum Thread URl: http://forum.cockos.com/showthread.php?t=169021
   * REAPER: 5.0 
   * Extensions: 
   --]]
   
  --[[
   * Changelog:   
   * v1.0 (2015-11-19)
    + Initial Release
   --]] 

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
