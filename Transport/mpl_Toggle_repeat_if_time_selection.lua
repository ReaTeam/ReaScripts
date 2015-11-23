function auto() local startOut1, endOut1
  startOut, endOut = reaper.GetSet_LoopTimeRange2(0, false, true, 0, 0, true)
  curr_timesel = endOut - startOut
  if curr_timesel ~= prev_timesel then
    if curr_timesel > 0 then
      reaper.GetSetRepeatEx(0,1)    
    else
      reaper.GetSetRepeatEx(0,0)
    end
  end    
  prev_timesel = curr_timesel
  reaper.defer(auto)
end

function main_loop()
  windowOut = reaper.BR_GetMouseCursorContext()
  if windowOut ~= "transport" then
    mode = 1        
   else
    mode = 0         
  end  
  if mode == 1 then
    auto()  
  end
  reaper.defer(main_loop)
end

main_loop()
