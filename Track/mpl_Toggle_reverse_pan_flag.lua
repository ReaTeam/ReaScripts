script_title = "mpl Toggle 'Reverse pan' flag on group settings and invert color of track under mouse cursor"

reaper.Undo_BeginBlock()  
  
window, segment, details = reaper.BR_GetMouseCursorContext()
if segment == "track" then    
  track = reaper.BR_GetMouseCursorContext_Track()
  --track = reaper.GetSelectedTrack(0,0)
  if track ~= nil then 
    retval, chunk = reaper.GetTrackStateChunk(track, "")
    --reaper.ShowConsoleMsg("")   
    --reaper.ShowConsoleMsg(chunk)
    chunk_temp = string.sub(chunk, 2)
    close_v1 = string.find(chunk_temp, ">")
    close_v2 = string.find(chunk_temp, "<")
    if close_v2 == nil then close_v2 = 0 end
    close_v = math.min(close_v1, close_v2)
    chunk_part1 = string.sub(chunk_temp, 1, close_v-1 )
    chunk_part2 = "\n"..string.sub(chunk_temp, close_v)  
    if close_v2 == 0 then chunk_part2 = "" end          
    chunk_part1_t = {}
    for line in chunk_part1:gmatch("[^\r\n]+") do  table.insert(chunk_part1_t, line)  end
    
    -- search in first part
    for i = 1 , #chunk_part1_t do
      chunk_part1_t_item = chunk_part1_t[i]
      f_st, f_end = string.find(chunk_part1_t_item, "GROUP_FLAGS") 
      
      -- manipulate group flags
      if f_st ~= nil then 
        change_color = true
        GROUP_FLAGS_t = {}
        for num in chunk_part1_t_item:gmatch("%d+") do table.insert(GROUP_FLAGS_t, num) end
        
        -- BEGIN flags table vvvv
        
        -- fill nills on table
        GROUP_FLAGS_t_size = #GROUP_FLAGS_t
        if GROUP_FLAGS_t_size < 23 then
          for i = GROUP_FLAGS_t_size+1, 23 do
            table.insert(GROUP_FLAGS_t, i, "0")
          end  
        end
        
        -- find active group states for selected track
        active_state = 0
        for i =1, #GROUP_FLAGS_t do
          GROUP_FLAGS_item = GROUP_FLAGS_t[i]
          GROUP_FLAGS_item_n = tonumber(GROUP_FLAGS_item)
          active_state = math.max(active_state, GROUP_FLAGS_item_n)
        end
        -- check and edit reverse volume flag =16        
        if GROUP_FLAGS_t[16] == "0" then GROUP_FLAGS_t[16] = tostring(active_state) else GROUP_FLAGS_t[16] = "0" end 
        
        -- END edit flags table 
        
        -- return table back
        chunk_part1_t[i] = 'GROUP_FLAGS '..table.concat(GROUP_FLAGS_t," ")
      end -- if f_st ~= nil
    end -- for i = 1 , #chunk_part1_t do
    
     -- form chunk part1
    chunk_part1_ret = table.concat(chunk_part1_t, " ".."\n")  
     -- form common chunk
    chunk_ret = "<"..chunk_part1_ret..chunk_part2
    
    reaper.SetTrackStateChunk(track, chunk_ret, true)
    
    -- invert track color
      trackcolor = reaper.GetTrackColor(track)
      R,G,B = reaper.ColorFromNative(trackcolor)
      if  R== 0 and G== 0 and B== 0 then is_default_color = true else is_default_color = false end
      -- prevent default color change
      if is_default_color == false and change_color == true then
        R_inv, G_inv, B_inv = 255 - R, 255 - G, 255- B
        trackcolor_inv = reaper.ColorToNative(R_inv, G_inv, B_inv)
        reaper.SetTrackColor(track, trackcolor_inv)
      end  
  end --if track ~= nil 
end  

  reaper.TrackList_AdjustWindows(false)
  reaper.UpdateArrange()
    
reaper.Undo_EndBlock(script_title, 0) 
