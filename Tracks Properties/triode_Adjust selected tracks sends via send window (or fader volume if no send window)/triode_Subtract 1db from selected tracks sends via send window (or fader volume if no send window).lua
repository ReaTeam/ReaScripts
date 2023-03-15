-- @noindex

scriptName = "Subtract 1db from selected tracks sends via send window (or fader volume if no send window)"
dbValue = -1 ------ you can edit this
warning = true -- change this to false if you don't want a warning if a track send reaches max value
-- Note this script requires its key command scope set to "global + text fields"

send_window = false
hardware_output = false
Stereo = false
master_track = false

master=reaper.GetMasterTrack(0)
selNum = reaper.CountSelectedTracks(0)

function AdjustSendsOnMaster()    
   masterNumSends = reaper.GetTrackNumSends(master, 1)
    
    for s=0, masterNumSends-1 do 
                 local _, sendName = reaper.GetTrackSendName( master, s, "" ) 
                 local channels = reaper.GetTrackSendInfo_Value( master, 1, s, "I_DSTCHAN" ) --     if mono channels value will be 1024.  If stereo it will be index value starting at 0 for any pair including odd
                
                if sendName == send then
              
                   if (channels == 1024 and Stereo == false) or (channels ~= 1024 and Stereo == true) then
                  
                      local sendVolume = reaper.GetTrackSendInfo_Value( master, 1, s, "D_VOL" )  
                      
                      local sendVolume = sendVolume *10^(0.05*dbValue) 

                      if sendVolume>(10^(12/20)) then
                          sendVolume = (10^(12/20))
                      end
                      
                      reaper.CSurf_OnSendVolumeChange( master, s, sendVolume, false )
                      
                  end  
                  
                end 
    end 
end -- for function    


function GetControlsForTrackText()   ---- Many thanks to Edgemeal
  local title = reaper.JS_Localize('Controls for track ', 'common')
  local hwnd = reaper.JS_Window_FindTop(title, false) 
  if hwnd then 
    local arr = reaper.new_array({}, 255)
    local ret = reaper.JS_Window_ArrayAllChild(hwnd, arr) 
    local adr = arr.table()
    for j = 1, #adr do
      local child = reaper.JS_Window_HandleFromAddress(adr[j])
      local id = reaper.JS_Window_AddressFromHandle(reaper.JS_Window_GetLongPtr(child, "ID")) 
      if id == 1038 then return reaper.JS_Window_GetTitle(hwnd), reaper.JS_Window_GetTitle(child) end
    end
  end
end

titlebar_text, child_text = GetControlsForTrackText()


function GetControlsForMasterTrackText()   ---- Many thanks to Edgemeal
  local title = reaper.JS_Localize('Master hardware output controls', 'common')
  local hwnd = reaper.JS_Window_FindTop(title, false) 
  if hwnd then 
    local arr = reaper.new_array({}, 255)
    local ret = reaper.JS_Window_ArrayAllChild(hwnd, arr) 
    local adr = arr.table()
    for j = 1, #adr do
      local child = reaper.JS_Window_HandleFromAddress(adr[j])
      local id = reaper.JS_Window_AddressFromHandle(reaper.JS_Window_GetLongPtr(child, "ID")) 
      if id == 1038 then return reaper.JS_Window_GetTitle(hwnd), reaper.JS_Window_GetTitle(child) end
    end
  end
end

MasterTitlebar_text, MasterChild_text = GetControlsForMasterTrackText()


reaper.Undo_BeginBlock()

------adjust selected track fader volume if no send window is present
if titlebar_text == nil and MasterTitlebar_text == nil then

  if selNum > 0 then
 
    for i = 0, selNum-1 do
      local tr = reaper.GetSelectedTrack(0, i)
      local vol = reaper.GetMediaTrackInfo_Value(tr, 'D_VOL')
      reaper.SetMediaTrackInfo_Value(tr, 'D_VOL', vol*10^(0.05*dbValue))
    end
    
  end  
    
end


if MasterTitlebar_text ~= nil then 
  if string.find(MasterTitlebar_text, "Master hardware output controls") then
   master_track = true
  end 
  
  
  if string.find(MasterChild_text, "Hardware:") then
  
    send = string.match(MasterChild_text, ": (.*)")  -- extract text after the colon and space until space before /
    local FirstChannel = string.match(MasterChild_text, ": (.*) /")  -- l      extract text after the colon and space until space before /
    local SecondChannel = string.match(MasterChild_text, "/ (.*)") -- l      extract text after / 
  
    if SecondChannel then
      send = FirstChannel
      Stereo = true
    end  
    
    hardware_output = true
    
  end
  
end  





if master_track == true then
  AdjustSendsOnMaster()    
end  




if titlebar_text ~= nil then


  if string.find(titlebar_text, "Controls for track ") then
    send_track = string.sub(titlebar_text, 19)
    send_track = tonumber(string.match(send_track, '%d+')) -- extract track number
    send_window = true
  end  




  Unnamed = false

  if string.find(child_text, "Send to track ") then
    send = string.match(child_text,'%b""')  --- extract text in quotes
    send = string.gsub(send , '"', "") 

  
    if send == "" then
      send = string.match(child_text, "Send to (.+) ") -- extract track number
      Unnamed = true
    end   
  
  end  


  if string.find(child_text, "Hardware:") then

    send = string.match(child_text, ": (.*)")  -- extract text after the colon and space until space before /
    local FirstChannel = string.match(child_text, ": (.*) /")  -- l     extract text after the colon and space until space before /
    local SecondChannel = string.match(child_text, "/ (.*)") -- l     extract text after / 

    if SecondChannel then
      send = FirstChannel
      Stereo = true
    end  
  
    hardware_output = true
  
  end


  -- if active send window track is not selected then temporarily select this track also

  for i = 0, reaper.GetNumTracks() - 1 do
    local tr = reaper.GetTrack(0, i)
    local tracknumber = reaper.GetMediaTrackInfo_Value(tr , 'IP_TRACKNUMBER')
    local tracknumber = math.floor(tracknumber) 
 
    if tracknumber == send_track then
      selected = reaper.IsTrackSelected( tr )
      reaper.SetTrackSelected( tr, 1 )
      if selected == false then
        target = tr 
      end
    end
  end 



end -- for if titlebar_text not nil


master_selected = reaper.IsTrackSelected( master )
if master_selected == true and master_track == false and send_window == false then
  local vol = reaper.GetMediaTrackInfo_Value(master, 'D_VOL')
  reaper.SetMediaTrackInfo_Value(master, 'D_VOL', vol*10^(0.05*dbValue))
end

----- adjust sends on selected tracks by xdb  --- thanks partly due to bFooz

selNum = reaper.CountSelectedTracks(0)  
exceededTracks = {}
anyExceeded = false

    
for t=0, selNum-1 do
    local track = reaper.GetSelectedTrack(0,t)   
    local trackNumSends = reaper.GetTrackNumSends(track, 0) -- get number of track sends
    local hw = reaper.GetTrackNumSends(track, 1) -- get number of of hardware outs 
    local trackExceeded = false

    if hardware_output == true then
    iterator = hw else
    iterator = trackNumSends
    end
    
    for s=0, iterator-1 do 
    
    if hardware_output == false then 
      offset = s+hw else
      offset = s
    end  
    
      _, sendName = reaper.GetTrackSendName( track, offset, "" )  --- offset: need to bump up s value to account for sends
      channels = reaper.GetTrackSendInfo_Value( track, 1, s, "I_DSTCHAN" )
      
      local sendExceeds = false
            
        if Unnamed == true and hardware_output == false then
          sendName = string.lower(sendName)
        end 
        
        if hardware_output == true then
                    category = 1 else
                    category = 0
                        
        end  
                  
            
        if sendName == send then
        
          if (channels == 1024 and Stereo == false) or (channels ~= 1024 and Stereo == true) or hardware_output == false then

            local sendVolume = reaper.GetTrackSendInfo_Value( track, category, s, "D_VOL" )  ------ this only counts the send category but s includes both

            sendVolume = sendVolume *10^(0.05*dbValue) 

            if sendVolume>(10^(12/20)) then
              sendVolume = (10^(12/20))
              sendExceeds = true
              trackExceeded = true
            end
            
            reaper.CSurf_OnSendVolumeChange( track, offset, sendVolume, false )
            end
            
            if sendExceeds then
              local trackNumber = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
               if exceededTracks[trackNumber]==nil then
                    exceededTracks[trackNumber] = {}
               end
              exceededTracks[trackNumber][#exceededTracks[trackNumber]+1]=sendName
              anyExceeded = true
            end 
            
          end -- for if channels == 1024 etc...  
    end --for s        
end --for i



if anyExceeded and warning == true and selNum > 1 then
      local infoString = "Script: "..scriptName..":\n\nMax send level reached on the following sends:\n"
      for key,sends in pairs(exceededTracks) do
            local track = reaper.GetTrack(0, key-1)
            local trackNum = math.floor(key)
            local _, trackName = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
            if trackName=="" then
                  trackName = "Track "..trackNum
            end
            infoString = infoString.."\nTrack: "..trackNum.."\t "..trackName
            local s
            for s=1, #sends do
                  local sendName = sends[s]
                  infoString = infoString .. "\t--> " .. sendName
            end
            
      end 
      reaper.MB(infoString, "Warning", 0)
end  




if master_selected == true and master_track == false and send_window == true then
AdjustSendsOnMaster() 
end


reaper.TrackList_AdjustWindows(false)

if selected == false then 
  reaper.SetTrackSelected( target, 0 ) -- unselect track if it was unselected originally
end 


reaper.Undo_EndBlock(scriptName, -1)
