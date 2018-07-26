--[[
    Description: Set region at edit cursor to time selection
    Version: 1.0.0
    Author: Thonex
    Changelog:
        Initial Release
]]--

function Main()

  Cur_Pos =  reaper.GetCursorPosition()                                                             
  markeridx, regionidx = reaper.GetLastMarkerAndCurRegion( 0, Cur_Pos)                              
  retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( regionidx )  
  local L_Start, R_End = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)                     
  reaper.SetProjectMarker( markrgnindexnumber, true, L_Start, R_End, name )
end

Main()