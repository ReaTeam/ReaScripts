  retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
  track = reaper.GetTrack(0,tracknumber-1)
  if track ~= nil then
    retval, chunk = reaper.GetTrackStateChunk(track, "")
    chunk_t={}  
    for line in chunk:gmatch("[^\r<]+") do  table.insert(chunk_t, line)  end
    if chunk_t ~= nil then
      fx_count = 0 
      for i = 1, #chunk_t do
        chunk_t_item = chunk_t[i]
        chunk_t2 = {}
        for line1 in chunk_t_item:gmatch("[^\r\n]+") do  table.insert(chunk_t2, line1)  end
        find = string.find(chunk_t_item, 'FXID' )
        if find ~= nil then
          fx_count = fx_count +1 
          if fx_count == fxnumber + 1 then fx_chunk_id = i end
          if fx_count == fxnumber + 2 then fx_chunk_id_next = i end
        end        
      end
      if fx_chunk_id_next ~= nil then limit = fx_chunk_id_next-1 else limit = #chunk_t - 1 end
      for i = fx_chunk_id, limit do
        chunk_t_item = chunk_t[i]
        if string.find(chunk_t_item, 'PROGRAMENV '..paramnumber) then     
          chunk_t2 = {}
          for line1 in chunk_t_item:gmatch("[^\r\n]+") do  table.insert(chunk_t2, line1)  end                
          break
        end        
      end
    end
  

  -- draw chunk_t2
  
    retval, param_name = reaper.TrackFX_GetParamName(track, fxnumber, paramnumber, "")
    
    gfx.init("Parameters Modulation", 200, 800, 0);
      gfx.setfont(1, "Calibri", 18);
      x,y = 10, 5
      gfx.x=x;
      gfx.y =y
      gfx.printf("Par name:  "..param_name);
      st_find = string.find(chunk_t2[1], 'PROGRAMENV '..paramnumber)
      if st_find~=nil then
        x = x +10
        for i = 2, #chunk_t2-3 do
          chunk_t2_item = chunk_t2[i]
          if chunk_t2_item ~= '>' then
            y = y+18
            chunk_t3 = {}
            for line1 in chunk_t2_item:gmatch('[%g]+') do  table.insert(chunk_t3, line1)  end          
            gfx.x=x
            gfx.y=y
            gfx.printf(chunk_t3[1])
            x = x + 10
            for j = 2, #chunk_t3 do
                y = y + 18
                gfx.x=x
                gfx.y=y
                gfx.printf(chunk_t3[j])   
            end  
          end   
          x = x -10
        end
       else
         x = x +10
         y = y +18
         gfx.x=x
         gfx.y=y                     
         gfx.printf('(No modulation)')
      end  
  end   
