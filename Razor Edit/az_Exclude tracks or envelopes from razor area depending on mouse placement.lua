-- @description Exclude tracks or envelopes from razor area depending on mouse placement
-- @author AZ
-- @version 1.0
-- @about
--   # Exclude tracks or envelopes from razor area depending on mouse placement
--
--   - if mouse over track, envelopes will exclude
--   - if mouse over envelope, tracks will exclude


function ExcludeFromRazorArea()
    local trackCount = reaper.CountTracks(0)
    
    for i = 0, trackCount - 1 do
        local track = reaper.GetTrack(0, i)
        local ret, area = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
        
        if area ~= '' then
            --PARSE STRING and CREATE TABLE
            local str = {}
            local env_str = {}
            for j in string.gmatch(area, "%S+") do
                table.insert(str, j)
            end
            
            --CLEANUP TABLE
            local j = 1
            
            while j <= #str do
                
                local GUID = str[j+2]
                local isEnvelope = GUID ~= '""'
                
                if ex_var == "envelope" then
                  
                  if isEnvelope then
                    table.remove(str, j)
                    table.remove(str, j)
                    table.remove(str, j)
                  else
                    j = j + 3
                  end
                  
                elseif ex_var == "track" then
                  
                  if  GUID == '""' then
                    table.remove(str, j)
                    table.remove(str, j)
                    table.remove(str, j)
                  else
                    j = j + 3
                  end
                  
                else
                  reaper.ShowMessageBox("No exclude type","Whoops",0)
                end
                
            end
            
            --reaper.ShowConsoleMsg("\nedit:\n"..table.concat(str, " ").."\n\n")
            reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', table.concat(str, " "), true)
            
        end
    end
end



----START CODE----
window, segment, details = reaper.BR_GetMouseCursorContext()
 if window == "tcp" or "arrange" then
   if segment == "track" then
     ex_var = "envelope"
     reaper.Undo_BeginBlock2( 0 )
     reaper.PreventUIRefresh( 1 )
     ExcludeFromRazorArea()
     reaper.PreventUIRefresh( -1 )
     reaper.Undo_EndBlock2( 0, "Exclude envelopes from RE", -1 )
   elseif segment == "envelope" then
     ex_var = "track"
     reaper.Undo_BeginBlock2( 0 )
     reaper.PreventUIRefresh( 1 )
     ExcludeFromRazorArea()
     reaper.PreventUIRefresh( -1 )
     reaper.Undo_EndBlock2( 0, "Exclude tracks from RE", -1 )
   else
     reaper.defer(function()end)
   end
 else
   reaper.defer(function()end)
 end
