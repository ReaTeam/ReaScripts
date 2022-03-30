-- @description Exclude tracks or envelopes from razor area depending on mouse placement
-- @author AZ
-- @version 1.1
-- @changelog Added fixed lanes support
-- @about
--   # Exclude tracks or envelopes from razor area depending on mouse placement
--
--   - if mouse over track, envelopes will exclude
--   - if mouse over envelope, tracks will exclude

function msg(value)
  reaper.ShowConsoleMsg(tostring(value).."\n")
end


function ExcludeFromRazorArea()
    local trackCount = reaper.CountTracks(0)
    
    for i = 0, trackCount - 1 do
        local track = reaper.GetTrack(0, i)
        local mode = reaper.GetMediaTrackInfo_Value(track,"I_FREEMODE")
        
      if mode ~= 0 then
      
      ----NEW WAY----
        local ret, area = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS_EXT', '', false)
        
        if area ~= '' then
            --PARSE STRING and CREATE TABLE
            local TRstr = {}
            --msg(area)
            for k in area:gmatch('[^,]+')do
              table.insert(TRstr, k)
            end
            
            for i=1, #TRstr do
            
              local rect = TRstr[i]
              TRstr[i] = {}
              for j in rect:gmatch("%S+") do
                table.insert(TRstr[i], j)
              end
              --msg(table.concat(TRstr[i], " ").."\n")
            end
            
            
            --CLEANUP TABLE
            local i=1
            while i <= #TRstr do
                
                local GUID = TRstr[i][3]
                local isEnvelope = GUID ~= '""'
                
                if ex_var == "envelope" then
                  
                  if isEnvelope then
                    table.remove(TRstr, i)
                  else
                    i = i+1
                  end
                  
                elseif ex_var == "track" then
                  
                  if not isEnvelope then
                    table.remove(TRstr, i)
                  else
                    i = i+1
                  end
                  
                else
                  reaper.ShowMessageBox("No exclude type","Whoops",0)
                end
                
            end
            
            ---META-TABLE TO SIMPLE---
            for i=1, #TRstr do
              TRstr[i] = table.concat(TRstr[i], " ")
            end
            ---------------------
            --msg("\nedit:\n"..table.concat(TRstr, ",").."\n")
            reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS_EXT', table.concat(TRstr, ","), true)
            
        end
        
      else --OLD WAY--
      
        local ret, area = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
        --msg(area.."\n")
        if area ~= '' then
            --PARSE STRING and CREATE TABLE
            local str = {}
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
                  
                  if not isEnvelope then
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
            
            --msg("\nedit:\n"..table.concat(str, " ").."\n\n")
            reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', table.concat(str, " "), true)
            
        end -- if area ~= ''
      end -- if track mode
    end  -- for track count
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
