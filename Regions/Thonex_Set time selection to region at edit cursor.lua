--[[
    Description: Set time selection to region at edit cursor
    Version: 1.0.0
    Author: Thonex
    Changelog:
        Initial Release
]]--



function Main()
  
  Cur_Pos =  reaper.GetCursorPosition()                                                             
  markeridx, regionidx = reaper.GetLastMarkerAndCurRegion( 0, Cur_Pos)
  retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(  regionidx )
  reaper.GetSet_LoopTimeRange(true, false, pos, rgnend, false )
end

Main()