-- Adobe Audition behaviour playback: 
-- play/pause/play from pause position/return to first position

playstate = reaper.GetPlayState()
play_pos = reaper.GetPlayPosition()
pause_pos1 = reaper.GetCursorPositionEx(0)
marker_name = "Start"
valOut = reaper.GetExtState("playBack_state", "Pause")
if valOut ~= nil then 
  pause_pos = tonumber(valOut)
end  

------------------------------------
-- if stopped press play
markers_t = {}
if playstate == 0 then
  retval, num_markersOut, num_regionsOut = reaper.CountProjectMarkers(0)
    if num_markersOut ~= nil then
      for j = 1, num_markersOut, 1 do
        retval, isrgnOut, posOut, rgnendOut, nameOut, markrgnindexnumberOut, colorOut = reaper.EnumProjectMarkers3(0, j-1)
        if posOut <= pause_pos1 then
         table.insert(markers_t, posOut)
        end 
      end  
    end  
    
  if markers_t == nil then new_marker_id = 1 
   else 
    if #markers_t  == 1 then new_marker_id = #markers_t + 1 else new_marker_id = #markers_t + 1 end
    if #markers_t == 0 then new_marker_id = 0 else if markers_t[1] > pause_pos1 then new_marker_id = 2 end end
  end
   
      --reaper.ShowConsoleMsg(previous_marker_id)
      
  reaper.AddProjectMarker(0, false, pause_pos1, pause_pos1, marker_name, new_marker_id)  
  reaper.Main_OnCommandEx(reaper.NamedCommandLookup("_BR_SAVE_CURSOR_POS_SLOT_1"), 0, 0) 
  reaper.OnPlayButton()
  reaper.DeleteExtState("playBack_state", "Pause", true)     
end

------------------------------------
-- if playing from start press pause

if playstate == 1 and pause_pos == nil then
    reaper.CSurf_OnPause()       
    reaper.SetExtState("playBack_state", "Pause", play_pos, true)
end

------------------------------------
-- if playing from pause press stop
if playstate == 1 and pause_pos ~= nil and play_pos > pause_pos then
  reaper.CSurf_OnStop()  
  reaper.Main_OnCommandEx(reaper.NamedCommandLookup("_BR_RESTORE_CURSOR_POS_SLOT_1"), 0, 0)
  reaper.DeleteExtState("playBack", "State", true)
  pause_pos2 = reaper.GetCursorPositionEx(0)
  
  retval, num_markersOut, num_regionsOut = reaper.CountProjectMarkers(0)
  if num_markersOut ~= nil then
    for i = 1, num_markersOut, 1 do
      retval, isrgnOut, posOut, rgnendOut, nameOut, markrgnindexnumberOut, colorOut = reaper.EnumProjectMarkers3(0, i-1)
      if nameOut == marker_name then
        reaper.DeleteProjectMarkerByIndex(0, i-1) 
      end  
    end
  end
  
end

------------------------------------  
-- if paused press play
if playstate == 2 then    
  reaper.SetExtState("playBack_state", "Pause", pause_pos1, true)
  reaper.OnPlayButton()
end  
  
