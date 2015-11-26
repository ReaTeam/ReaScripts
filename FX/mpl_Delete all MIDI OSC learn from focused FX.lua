  --[[
   * ReaScript Name: Delete all MIDI OSC learn from focused fx
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
   
  script_title = "Delete all MIDI OSC learn from focused fx"
  reaper.Undo_BeginBlock()
  
  _, tracknumber, _, fxnumber = reaper.GetFocusedFX()
  track = reaper.GetTrack(0,tracknumber-1)
  if track ~= nil and fxnumber ~= nil then 
    _, trackname = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
    _, fxname = reaper.TrackFX_GetFXName(track, fxnumber, '')
    ret = reaper.MB('Do you wanna delete MIDI/OSC learn from'..'\n'..
      'Track '..tracknumber..'\n'..'    '..trackname..'\n'..
      'FX '..(fxnumber+1)..'\n'..'    '..fxname..'?', 'Delete MIDI/OSC learn', 4)
    if ret == 6 then
      _, chunk = reaper.GetTrackStateChunk(track, "")
      countfx = reaper.TrackFX_GetCount(track)
      
      -- split track chunk
      cut_pos = {}
      fx_chunk = {}
      for i = 1, countfx do
        cut_pos[i] = string.find(chunk, 'BYPASS',cut_pos_end)
        cut_pos_end = string.find(chunk, 'BYPASS',cut_pos[i]+20)
        if cut_pos_end == nil then
          fx_chunk[i] = string.sub(chunk, cut_pos[i])
         else
          fx_chunk[i] = string.sub(chunk, cut_pos[i], cut_pos_end-1)
        end
      end
      
      -- split fx chunk
      fx_chunk_t={}
      for line in fx_chunk[fxnumber+1]:gmatch("[^\r\n]+") do  table.insert(fx_chunk_t, line)  end
      for i = 1, #fx_chunk_t do
        if fx_chunk_t[i]:find('PARMLEARN') ~= nil then fx_chunk_t[i] = '' end
      end
  
      -- return fx chunk
      fx_chunk[fxnumber+1] = table.concat(fx_chunk_t, '\n')
      
      -- return track chunk
      chunk_out = string.sub(chunk, 1, cut_pos[1]-1)..table.concat(fx_chunk, '\n')
      reaper.SetTrackStateChunk(track, chunk_out)
    end
  end --if track ~= nil   
  
  reaper.Undo_EndBlock(script_title,0)
