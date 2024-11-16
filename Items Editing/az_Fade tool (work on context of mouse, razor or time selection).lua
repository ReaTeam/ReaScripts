-- @description Fade tool (works on context of mouse, razor or time selection)
-- @author AZ
-- @version 2.2.3
-- @changelog - to avoid simultaneous work of Batch fade tool and changing fade under the mouse - ignore TS if one of it's edges is out of arrange view and the mouse is over an item.
-- @provides
--   az_Fade tool (work on context of mouse, razor or time selection)/az_Options window for az_Fade tool.lua
--   [main] az_Fade tool (work on context of mouse, razor or time selection)/az_Open options for az_Fade tool.lua
-- @link
--   Author's page https://forum.cockos.com/member.php?u=135221
--   Forum thread https://forum.cockos.com/showthread.php?t=293335
-- @donation Donate via PayPal https://www.paypal.me/AZsound
-- @about
--   # Fade tool
--
--   Options window can be opened by pressing the shortcut assigned the script when mouse placed on transport or mixer panel.
--   ----------------------------------------
--   - Use top/bottom mouse placement on the item to define what fade you need, in or out.
--
--     There is two ways that you can change in the options.
--
--           Default is: top / bottom -> fadein / fadeout
--
--           Another is: top / bottom -> close edge fade / far edge fade
--
--   - Use razor edit area for fades and crossfades a pair of items.
--
--   - Use time selection with item selection. Such way you can crossfade items on different tracks.
--
--   - Also you can set both fades for item by selection it's middle part.
--
--   - Create batch fades / crossfades if there is at least one whole item in the area .
--   --------------------------
--
--   - Use razor edit to create envelope transitions
--   - Different mouse cursors define different behavior
--   - You can mirror item fade in envelopes using razor and mouse placement
--
--   --------------------------
--   - There is an option (ON by default) to move edit cursor with offset before first fade. That allows you to listen changes immediately.
--
--   - Locking respected by default.
--
--   - Script warns if non-midi items have too short source for creating crossfade and offer to loop the source.
--
--   - Last batch values can be saved in project (by default)

--[[
TO MODIFY SCRIPT OPTIONS
OPEN THE OPTIONS WINDOW BY RUNNING THE SCRIPT WITH MOUSE ON TRANSPORT OR MIXER PANEL
]]

---------------------------------
--------Options functions--------
--Start load file

ExtStateName = 'AZ_FadeTool'

function GetExtStates(OptionsTable)
  for i, option in ipairs(OptionsTable) do
    if option[3] ~= nil then
      local state = reaper.GetExtState(ExtStateName, option[2])
      
      if state ~= "" then
        local wrong
        local stateType = type(option[3])
        if stateType == 'number' then state = tonumber(state) end
        if stateType == 'boolean' then
          if state == 'true' then state = true else state = false end
        end
        if stateType == 'string' then
          wrong = true
          
          for i = 1, #option[4] do
            local var = option[4][i]
            if state == var then
              wrong = false
              break 
            end
          end
          
        end
        
        if wrong == true then
          reaper.SetExtState(ExtStateName, option[2], tostring(option[3]), true)
        else
          OptionsTable[i][3] = state
        end
      else
        reaper.SetExtState(ExtStateName, option[2], tostring(option[3]), true)
      end
      
    end
  end
end

---------------------

function SetExtStates(OptionsTable)
  for i, option in ipairs(OptionsTable) do 
    if option[3] ~= nil then
      reaper.SetExtState(ExtStateName, option[2], tostring(option[3]), true)
    end
  end
end

---------------------

function OptionsDefaults(NamedTable)
  local text
  
  text = 'Behaviour'
  table.insert(NamedTable, {text, 'Separator', nil})
  
  text = 'Respect snap for mouse on items'
  table.insert(NamedTable, {text, 'RespSnapItems', true })
  
  text = 'Respect snap for mouse on envelopes'
  table.insert(NamedTable, {text, 'RespSnapEnvs', true })
  
  text = 'Ignore locking for mouse editing'
  table.insert(NamedTable, {text, 'IgnoreLockingMouse', false })
  
  text = 'Move edit cursor after setting a fade/crossfade'
  table.insert(NamedTable, {text, 'moveEditCursor', true })
  
  text = 'Offset between fade and edit cursor in seconds'
  table.insert(NamedTable, {text, 'curOffset', 1, "%.2f"})
  
  text = 'Extend item edge to fill razor or time selection'
  table.insert(NamedTable, {text, 'MoveItemEdgeRazor', false })
  
  text = 'Mouse top / bottom placement on item is used for'
  table.insert(NamedTable, {text, 'LRdefine', 'Left/Right fade', {
                                                      'Left/Right fade',
                                                      'Closest/Farthest fade' } })
  
  text = 'Use default shape instead of linear when cutting envelopes'
  table.insert(NamedTable, {text, 'CutShapeUseDef', false })
  
  
  text = 'Batch fades/crossfades defaults'
  table.insert(NamedTable, {text, 'Separator', nil})
  
  text = 'Fade-in'
  table.insert(NamedTable, {text, 'DefaultFadeIn', 30, "%.0f"})
  
  text = 'Fade-out'
  table.insert(NamedTable, {text, 'DefaultFadeOut', 30, "%.0f"})
  
  text = 'Crossfade'
  table.insert(NamedTable, {text, 'DefaultCrossFade', 30, "%.0f"})
  
  
  text = 'Values'
  table.insert(NamedTable, {text, 'ValueType', 'milliseconds', {
                                                      'milliseconds',
                                                      'frames' } })
  
  text = 'Crossfade type'
  table.insert(NamedTable, {text, 'DefCrossType', 'Left', {
                                                      'Left',
                                                      'Centered' } })
  
  text = 'Respect existing fades'
  table.insert(NamedTable, {text, 'RespectExistingFades', true})
  
  text = 'Respect locking'
  table.insert(NamedTable, {text, 'RespectLockingBatch', true})
  
  text = 'Other options'
  table.insert(NamedTable, {text, 'Separator', nil})
  
  text = 'Save and use last batch settings in project'
  table.insert(NamedTable, {text, 'SaveLastBatchPrj', true})
  
end


-------------------------

function SetOptGlobals(NamedTable, OptionsTable)
  for i = 1, #OptionsTable do
    local name = OptionsTable[i][2]
    NamedTable[name] = OptionsTable[i][3]
  end
end

-------------------------
--End load file
-------------------------

function msg(value)
  reaper.ShowConsoleMsg(tostring(value)..'\n')
end

------------------------------
function BatchDefaults(NamedTable)
  local text
  
  text = 'Fade-in'
  table.insert(NamedTable, {text, 'DefaultFadeIn', 30, "%.0f"})
  
  text = 'Fade-out'
  table.insert(NamedTable, {text, 'DefaultFadeOut', 30, "%.0f"})
  
  text = 'Crossfade'
  table.insert(NamedTable, {text, 'DefaultCrossFade', 30, "%.0f"})
  
  text = 'Values'
  table.insert(NamedTable, {text, 'ValueType', 'milliseconds', {
                                                      'milliseconds',
                                                      'frames' } })
  
  
  text = 'Crossfade type'
  table.insert(NamedTable, {text, 'DefCrossType', 'Left', {
                                                      'Left',
                                                      'Centered' } })
  
  text = 'Respect existing fades'
  table.insert(NamedTable, {text, 'RespectExistingFades', true})
  
  text = 'Respect locking'
  table.insert(NamedTable, {text, 'RespectLockingBatch', true})
  
end

-------------------------


function HelloMessage()
  local text = 'Hello friend! It seems you have updated script "az_Fade tool".'
  ..'\n\n'..'The script now has new GUI and more thoughtfull behavior.'
  ..'\n'..'Explore all of them including envelope editing, look here: '
  ..'\n'..'https://forum.cockos.com/showthread.php?t=293335'
  ..'\n\n'..'Please, check the options if they were changed.'
  ..'\n'..'Just press assigned hotkey when mouse placed on the transport or mixer area.'
  ..'\n'..'Have fun!)'
  reaper.ShowMessageBox(text,'Fade tool - Hello!',0)
end

---------------------------------
-----------Work functions--------
---------------------------------

function RazorEditSelectionExists()

    for i=-1, reaper.CountTracks(0)-1 do
        local track
        if i == -1 then
          track =  reaper.GetMasterTrack( 0 )
        else
          track = reaper.GetTrack(0, i)
        end

        local retval, x = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "string", false)

        if x ~= "" then return true end

    end
    
    return false

end

-----------------------

function GetEnvelopePointsInRange(envelope, time1, time2)
    local areaStart = math.min(time1, time2)
    local areaEnd = math.max(time1, time2)
    local envelopePoints = {Start = {}, End = {} }
    local oldtime
    local oldvalue
    local pointsNum = reaper.CountEnvelopePoints(envelope)

    for i = 1, pointsNum do
        local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(envelope, i- 1)
        local increase = 1
        
        if oldtime == time and oldvalue == value then
           reaper.DeleteEnvelopePointEx( envelope, -1, i-1)
           increase = 0
        end
        
        if time >= areaStart and time <= areaEnd then --point is in range
          envelopePoints[#envelopePoints + increase] = {
                id = i-1 ,
                time = time,
                value = value,
                shape = shape,
                tension = tension,
                selected = selected
            }
          
          if time - areaStart < 0.02 then --for env RE edge points removing
            envelopePoints.Start[#envelopePoints.Start + increase] = i-1
          end
          
          if areaEnd - time < 0.02 then --for env RE edge points removing
            envelopePoints.End[#envelopePoints.End + increase] = i-1
          end
          
        end
    end
    
    reaper.Envelope_SortPointsEx( envelope, -1 )
    
    return envelopePoints
end


-----------------------

function GetItemsInRange(track, areaStart, areaEnd, areaTop, areaBottom) --returns items, needBatch
    local items = {}
    local itemCount = reaper.CountTrackMediaItems(track)
    local needBatch
    
    for k = 0, itemCount - 1 do 
        local item = reaper.GetTrackMediaItem(track, k)
        local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local itemEndPos = pos+length
        local iLock = reaper.GetMediaItemInfo_Value( item, "C_LOCK" )
        
        if areaBottom ~= nil then
          itemTop = reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_Y")
          itemBottom = itemTop + reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_H")
          --msg("area: "..tostring(areaTop).." "..tostring(areaBottom).."\n".."item: "..itemTop.." "..itemBottom.."\n\n")
        end

        --check if item is in area bounds
        if itemEndPos > areaStart and pos < areaEnd
        and (iLock == 0 or RespectLockingBatch == false) then
        
          if areaBottom and itemTop then
            if itemTop < areaBottom - 0.001 and itemBottom > areaTop + 0.001 then
              table.insert(items,item)
              if pos >= areaStart and itemEndPos <= areaEnd then needBatch = true end
            end
          else
            table.insert(items,item)
            if pos >= areaStart and itemEndPos <= areaEnd then needBatch = true end
          end
          
        end

    end --end for cycle

    return items, needBatch
end

-----------------------
-----------------------

function ParseAreaPerLane(RawTable, itemH) --one level metatable
  local ParsedTable = {}
  local PreParsedTable = {}
  
  local lanesN = math.floor((1/itemH)+0.5)
  local laneW = 1/lanesN
  
  for i=1, lanesN do
    PreParsedTable[i] = {}
  end
  
  ---------------
  for i=1, #RawTable do
      --area data
      local areaStart = tonumber(RawTable[i][1])
      local areaEnd = tonumber(RawTable[i][2])
      local GUID = RawTable[i][3]
      local areaTop = tonumber(RawTable[i][4])
      local areaBottom = tonumber(RawTable[i][5])
      local isEnvelope = GUID ~= '""'
      
    if not isEnvelope then
      areaWidth = math.floor(((areaBottom - areaTop)/itemH)+0.5) -- how many lanes include
      for w=1, areaWidth do
        local areaLane = math.floor((areaBottom/(laneW*w))+0.5)
        --msg(areaLane)
        local smallRect = {
        
              areaStart,
              areaEnd,
              GUID,
              areaBottom - (laneW*w), --areaTop
              areaBottom - (laneW*(w-1)), --areaBottom
              }

        table.insert(PreParsedTable[areaLane], smallRect)
      end
    else
      table.insert(ParsedTable, RawTable[i])
    end
    
  end
  -------------
  
  for i=1, #PreParsedTable do
    local lane = PreParsedTable[i]
    local prevEnd = nil
    for r=1, #lane do
      local smallRect = lane[r]
      
      if prevEnd ~= smallRect[1] then
        table.insert(ParsedTable, smallRect)
      else
        ParsedTable[#ParsedTable][2] = smallRect[2]
      end
      
      prevEnd = smallRect[2]
    end
  end
  
  return ParsedTable
end

-----------------------
-----------------------

function GetRazorEdits() --returns areaMap, needBatch
    ONLYenvelopes = true
    RAZORenvelopes = false
    MouseDistDiff = nil
    local mouseTime =  reaper.BR_PositionAtMouseCursor( false )
    local NeedPerLane = true
    local trackCount = reaper.CountTracks(0)
    local areaMap = {}
    local needBatch
    
    for i = -1, trackCount - 1 do
        local track
        if i == -1 then
          track = reaper.GetMasterTrack( 0 )
        else
          track = reaper.GetTrack(0, i)
        end
        
        local mode = reaper.GetMediaTrackInfo_Value(track,"I_FREEMODE")
        if mode ~= 0 then
        ----NEW WAY----
        --reaper.ShowConsoleMsg("NEW WAY\n")
        
          local ret, area = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS_EXT', '', false)
          
        if area ~= '' then
        --msg(area)
            --PARSE STRING and CREATE TABLE
            local TRstr = {}
            
            for s in area:gmatch('[^,]+')do
              table.insert(TRstr, s)
            end
            
            for i=1, #TRstr do
            
              local rect = TRstr[i]
              TRstr[i] = {}
              for j in rect:gmatch("%S+") do
                table.insert(TRstr[i], j)
              end
              
            end
            
            local testItemH = reaper.GetMediaItemInfo_Value(reaper.GetTrackMediaItem(track,0), "F_FREEMODE_H")
            
            local AreaParsed = ParseAreaPerLane(TRstr, testItemH)
            
            local TRareaTable
            if NeedPerLane == true then TRareaTable = AreaParsed else TRareaTable = TRstr end
        
            --FILL AREA DATA
            local i = 1 
            while i <= #TRareaTable do
                --area data
                local areaStart = tonumber(TRareaTable[i][1])
                local areaEnd = tonumber(TRareaTable[i][2])
                local GUID = TRareaTable[i][3]
                local areaTop = tonumber(TRareaTable[i][4])
                local areaBottom = tonumber(TRareaTable[i][5])
                local isEnvelope = GUID ~= '""' 

                --get item/envelope data
                local items = {}
                local envelopeName, envelope
                local envelopePoints
                
                if isEnvelope == true then RAZORenvelopes = true end
                
                if not isEnvelope then
                  ONLYenvelopes = false
                  local TOneedBatch
                    items, TOneedBatch = GetItemsInRange(track, areaStart, areaEnd, areaTop, areaBottom)
                    if needBatch ~= true then needBatch = TOneedBatch end
                else
                    envelope = reaper.GetTrackEnvelopeByChunkName(track, GUID:sub(2, -2))
                    local ret, envName = reaper.GetEnvelopeName(envelope)

                    envelopeName = envName
                    envelopePoints = GetEnvelopePointsInRange(envelope, areaStart, areaEnd)
                    
                    if mouseTime > 0 then
                      local distDiff
                      if math.abs(mouseTime - areaStart) < math.abs(mouseTime - areaEnd) then
                        distDiff = mouseTime - areaStart
                      else
                        distDiff = areaEnd - mouseTime
                      end
                      if MouseDistDiff == nil or math.abs(distDiff) < math.abs(MouseDistDiff) then
                        MouseDistDiff = distDiff
                      end
                    end
                end

                local areaData = {
                    areaStart = areaStart,
                    areaEnd = areaEnd,
                    areaTop = areaTop,
                    areaBottom = areaBottom,
                    
                    track = track,
                    items = items,
                    
                    --envelope data
                    isEnvelope = isEnvelope,
                    envelope = envelope,
                    envelopeName = envelopeName,
                    envelopePoints = envelopePoints,
                    GUID = GUID:sub(2, -2)
                }

                table.insert(areaMap, areaData)

                i=i+1
            end
          end
        else  
        
        ---OLD WAY for backward compatibility-------
        
          local ret, area = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
          
          if area ~= '' then
            --PARSE STRING
            local str = {}
            for j in string.gmatch(area, "%S+") do
                table.insert(str, j)
            end
        
            --FILL AREA DATA
            local j = 1
            while j <= #str do
                --area data
                local areaStart = tonumber(str[j])
                local areaEnd = tonumber(str[j+1])
                local GUID = str[j+2]
                local isEnvelope = GUID ~= '""'
        
                --get item/envelope data
                local items = {}
                local envelopeName, envelope
                local envelopePoints
                
                if isEnvelope == true then RAZORenvelopes = true end
                
                if not isEnvelope then 
                  ONLYenvelopes = false
                  local TOneedBatch
                    items, TOneedBatch = GetItemsInRange(track, areaStart, areaEnd)
                    if needBatch ~= true then needBatch = TOneedBatch end
                else
                    envelope = reaper.GetTrackEnvelopeByChunkName(track, GUID:sub(2, -2))
                    local ret, envName = reaper.GetEnvelopeName(envelope)
        
                    envelopeName = envName
                    envelopePoints = GetEnvelopePointsInRange(envelope, areaStart, areaEnd)
                    
                    if mouseTime > 0 then
                      local distDiff
                      if math.abs(mouseTime - areaStart) < math.abs(mouseTime - areaEnd) then
                        distDiff = mouseTime - areaStart
                      else
                        distDiff = areaEnd - mouseTime
                      end
                      if MouseDistDiff == nil or math.abs(distDiff) < math.abs(MouseDistDiff) then
                        MouseDistDiff = distDiff
                      end
                    end
                end
        
                local areaData = {
                    areaStart = areaStart,
                    areaEnd = areaEnd,
                    
                    track = track,
                    items = items,
                    
                    --envelope data
                    isEnvelope = isEnvelope,
                    envelope = envelope,
                    envelopeName = envelopeName,
                    envelopePoints = envelopePoints,
                    GUID = GUID:sub(2, -2)
                }
        
                table.insert(areaMap, areaData)
        
                j = j + 3
            end
          end  ---OLD WAY END
        end
    end

    return areaMap, needBatch
end

--------------------------------

function SetCrossfade(Litem,Ritem,areaData)
  if not Litem and not Ritem then return end
  local Ltake
  local Rtake
  if Litem then Ltake = reaper.GetActiveTake(Litem) end
  if Ritem then Rtake = reaper.GetActiveTake(Ritem) end
  
  local LiPos
  local LiLock
  local RiPos
  local RiEnd
  local RiLock
  
  local LiNewEnd
  local RiNewStart
  
  local leftISmidi
  local rightISmidi
  
  -----------Left item edges---------------
  if Litem then
    LiPos = reaper.GetMediaItemInfo_Value( Litem, "D_POSITION" )
    LiEnd = LiPos + reaper.GetMediaItemInfo_Value( Litem, "D_LENGTH" )
    LiLock = reaper.GetMediaItemInfo_Value( Litem, "C_LOCK" )
    
    if LiLock == 1
    and (Opt.IgnoreLockingMouse == true or RespectLockingBatch == false) then
      table.insert(LOCKEDitems, Litem)
      reaper.SetMediaItemInfo_Value( Litem, "C_LOCK", 0 )
    end
    
    if ((edgesLock == 1 and globalLock == 1) or LiLock == 1)
    and Opt.IgnoreLockingMouse == false
    then
      areaData.areaEnd = LiEnd
    end
    
    if reaper.GetMediaItemInfo_Value( Litem, "B_LOOPSRC" ) == 0 then
      local tOffs =  reaper.GetMediaItemTakeInfo_Value( Ltake, "D_STARTOFFS" )
      local source =  reaper.GetMediaItemTake_Source( Ltake )
      local srcLength, lengthIsQN = reaper.GetMediaSourceLength( source )
      local srcEnd = LiPos - tOffs + srcLength
      if lengthIsQN == true then --if take is midi
        srcEnd = areaData.areaEnd
        leftISmidi = true
      end
      LiNewEnd = math.min(srcEnd,areaData.areaEnd)
      reaper.BR_SetItemEdges(Litem, LiPos, LiNewEnd)
    else
      LiNewEnd = areaData.areaEnd
      reaper.BR_SetItemEdges(Litem, LiPos, LiNewEnd)
    end
  end
  
  -----------Right item edges------------
  if Ritem then
    RiPos = reaper.GetMediaItemInfo_Value( Ritem, "D_POSITION" )
    RiEnd = RiPos + reaper.GetMediaItemInfo_Value( Ritem, "D_LENGTH" )
    RiLock = reaper.GetMediaItemInfo_Value( Ritem, "C_LOCK" )
    
    if RiLock == 1
    and (Opt.IgnoreLockingMouse == true or RespectLockingBatch == false) then
      table.insert(LOCKEDitems, Ritem)
      reaper.SetMediaItemInfo_Value( Ritem, "C_LOCK", 0 )
    end
    
    if ((edgesLock == 1 and globalLock == 1) or RiLock == 1)
    and Opt.IgnoreLockingMouse == false
    then
      areaData.areaStart = RiPos
    end
    
    if reaper.GetMediaItemInfo_Value( Ritem, "B_LOOPSRC" ) == 0 then
      local tOffs =  reaper.GetMediaItemTakeInfo_Value( Rtake, "D_STARTOFFS" )
      local source =  reaper.GetMediaItemTake_Source( Rtake )
      local srcLength, lengthIsQN = reaper.GetMediaSourceLength( source )
      local srcStart = RiPos - tOffs
      if lengthIsQN == true then --if take is midi
        srcStart = areaData.areaStart
        rightISmidi = true
      end
      RiNewStart = math.max(srcStart, areaData.areaStart)
      reaper.BR_SetItemEdges(Ritem, RiNewStart, RiEnd)
    else
      RiNewStart = areaData.areaStart
      reaper.BR_SetItemEdges(Ritem, RiNewStart, RiEnd)
    end
  end
  ---------------------------------------
  
  
  -----------Check is a gap between items--------
  if LiNewEnd and RiNewStart and LiNewEnd <= RiNewStart then
    if not GAPanswer then
      local SourceMsg
      if RunBatch == true then
        SourceMsg =
        "There is items pair(s) with don't crossing sources.\n"
        .."\nThey will not be crossfaded"
        GAPanswer = reaper.ShowMessageBox(SourceMsg,"Fade tool",0) 
      else 
        SourceMsg =
        "There is items pair(s) with don't crossing sources.\n\nDo you want to loop their sources?"
        .."\nIf no there will be just fades on the rests if possible."
        GAPanswer = reaper.ShowMessageBox(SourceMsg,"Fade tool",4)
      end
    end
    
    if RunBatch ~= true then
      if GAPanswer == 7 then
        SetFade(Litem, "out", LiNewEnd - areaData.areaStart )
        SetFade(Ritem, "in", areaData.areaEnd - RiNewStart)
      else
        reaper.SetMediaItemInfo_Value( Litem, "B_LOOPSRC", 1 )
        reaper.SetMediaItemInfo_Value( Ritem, "B_LOOPSRC", 1 )
        reaper.BR_SetItemEdges(Litem, LiPos, areaData.areaEnd)
        reaper.BR_SetItemEdges(Ritem, areaData.areaStart, RiEnd)
      end
    end
  end
  
  
  ---------Is new fade------- check for Midi items and items on different lanes/tracks
  if (LiNewEnd and RiNewStart and LiNewEnd > RiNewStart)
  or MoveItemEdgeRazor == true
  then
    local parOut = "D_FADEOUTLEN"
    local parIn = "D_FADEINLEN"
    local parOutA = "D_FADEOUTLEN_AUTO"
    local parInA = "D_FADEINLEN_AUTO"
    
    if not LiNewEnd then LiNewEnd = areaData.areaEnd end
    if not RiNewStart then RiNewStart = areaData.areaStart end
    
    if Litem then
      if MoveItemEdgeRazor == true then
        reaper.SetMediaItemInfo_Value( Litem, parOutA, 0)
        reaper.SetMediaItemInfo_Value( Litem, parOut, LiNewEnd - RiNewStart )
      else
        reaper.SetMediaItemInfo_Value( Litem, parOutA, LiNewEnd - RiNewStart )
      end
      
      local fEdge = RiNewStart
      local InitInFade = reaper.GetMediaItemInfo_Value( Litem, "D_FADEINLEN" )
      local i_autoFin = reaper.GetMediaItemInfo_Value(Litem, "D_FADEINLEN_AUTO")
      if i_autoFin ~= 0 then InitInFade = i_autoFin end
      
      if InitInFade ~= 0 then
        if fEdge < LiPos + InitInFade then
          if i_autoFin ~= 0 then
            local shape = reaper.GetMediaItemInfo_Value(Litem, "C_FADEINSHAPE")
            reaper.SetMediaItemInfo_Value(Litem, "D_FADEINLEN_AUTO", 0)
            reaper.SetMediaItemInfo_Value(Litem, "C_FADEINSHAPE", shape )
          end
          reaper.SetMediaItemInfo_Value( Litem, "D_FADEINLEN", fEdge - LiPos )
        end
      end
      
      
    end
    
    if Ritem then
      if MoveItemEdgeRazor == true then
        reaper.SetMediaItemInfo_Value( Ritem, parInA, 0)
        reaper.SetMediaItemInfo_Value( Ritem, parIn, LiNewEnd - RiNewStart )
      else
        reaper.SetMediaItemInfo_Value( Ritem, parInA, LiNewEnd - RiNewStart )
      end
      
      local fEdge = LiNewEnd
      local InitOutFade = reaper.GetMediaItemInfo_Value( Ritem, "D_FADEOUTLEN" )
      local i_autoFout = reaper.GetMediaItemInfo_Value(Ritem, "D_FADEOUTLEN_AUTO")
      if i_autoFout ~= 0 then InitOutFade = i_autoFout end
      
      if InitOutFade ~= 0 then
        if fEdge > RiEnd - InitOutFade then
          if i_autoFout ~= 0 then
            local shape = reaper.GetMediaItemInfo_Value(Ritem, "C_FADEOUTSHAPE")
            reaper.SetMediaItemInfo_Value(Ritem, "D_FADEOUTLEN_AUTO", 0)
            reaper.SetMediaItemInfo_Value(Ritem, "C_FADEOUTSHAPE", shape )
          end
          reaper.SetMediaItemInfo_Value( Ritem, "D_FADEOUTLEN", RiEnd - fEdge )
        end
      end
    end

  end
  
  return math.min(RiNewStart,LiNewEnd)
end

-----------------------
-----------------------

function GetSetBatchExtStates(DefT, getset) -- set == true, get == false
  local Mtrack = reaper.GetMasterTrack(0)
  local parname = "P_EXT:"..'AZ_Ftool_Batch '
  if getset == true then
    
    for i, option in pairs(DefT) do
      if option[3] ~= nil then
        local ret, str = reaper.GetSetMediaTrackInfo_String
        ( Mtrack, parname..option[2], tostring(option[3]), getset )
      end
    end

  elseif getset == false then
    
    for i, option in pairs(DefT) do
      if option[3] ~= nil then
        local state
        local ret, str = reaper.GetSetMediaTrackInfo_String
        ( Mtrack, parname..option[2], '', getset )
        if str ~= "" and ret ~= false and Opt.SaveLastBatchPrj == true then
          state = str
          local stateType = type(option[3])
          if stateType == 'number' then state = tonumber(str) end
          if stateType == 'boolean' then
            if str == 'true' then state = true else state = false end 
          end
          DefT[i][3] = state
        else
          DefT[i][3] = Opt[option[2]]
        end 
      end
      
    end -- for
    
  end --if getset == false

end

-----------------------
-----------------------
function BatchFadesWindow(razorEdits)
  BDefaults = {}
  BatchDefaults(BDefaults)
  GetSetBatchExtStates(BDefaults, false)
  RunBatch = true
  RazorEditsBatch = razorEdits
  --look for additional file
  local script_path = get_script_path() 
  local file = script_path .. 'az_Fade tool (work on context of mouse, razor or time selection)/'
  ..'az_Options window for az_Fade tool.lua'
  dofile(file)
  OptionsWindow(BDefaults, 'Batch fades/crossfades - Fade Tool')
  
end

-----------------------
-----------------------

function BatchFades()
  reaper.Undo_BeginBlock2( 0 )
  reaper.PreventUIRefresh( 1 )
  local AnyEdit
  BOpt = {}
  SetOptGlobals(BOpt, BDefaults)
  GetSetBatchExtStates(BDefaults, true)
  
  if BOpt.RespectLockingBatch == false then
    RespectLockingBatch = false
    reaper.Main_OnCommandEx(40596,0,0) --Locking: Clear item edges locking mode
    if start_TS ~= end_TS then
      RazorEditsBatch = GetTSandItems(start_TS, end_TS)
    else 
      RazorEditsBatch = GetRazorEdits()
    end
  end
  
  local typeValueCoeff
  if BOpt.ValueType == "milliseconds" then
    typeValueCoeff = 0.001
  elseif BOpt.ValueType == "frames" then
    typeValueCoeff = reaper.parse_timestr_pos( "00:00:00:01", 5 )
  end
  
  for i = 1, #RazorEditsBatch do
    local areaData = RazorEditsBatch[i]
    if not areaData.isEnvelope then
      local items = areaData.items
      
      local PrevEnd
      local PrevFout 
      
      for i, item in pairs(items) do
        local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
        local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
        local iFin = reaper.GetMediaItemInfo_Value( item, "D_FADEINLEN" )
        local iFout = reaper.GetMediaItemInfo_Value( item, "D_FADEOUTLEN" )
        
        if BOpt.RespectExistingFades == false then iFin = 0 iFout = 0 end
        
        if iPos >= areaData.areaStart then 
          if PrevEnd and math.abs(iPos - PrevEnd) < 0.0002 then
            local crossStart, crossEnd
            if BOpt.DefCrossType == 'Left' then
              crossStart = iPos - BOpt.DefaultCrossFade * typeValueCoeff
              crossEnd = iPos
            elseif BOpt.DefCrossType == 'Centered' then
              crossStart = iPos - BOpt.DefaultCrossFade/2 * typeValueCoeff
              crossEnd = iPos + BOpt.DefaultCrossFade/2 * typeValueCoeff
            end
            
            local crossData = {
              areaStart = crossStart,
              areaEnd = crossEnd,
            }
            
            if PrevFout == 0 and iFin == 0 then
              SetCrossfade(items[i-1],item, crossData)
              AnyEdit = 1
            elseif PrevFout == 0 then
              SetFade(items[i-1], "out", BOpt.DefaultFadeOut * typeValueCoeff)
              AnyEdit = 1
            elseif iFin == 0 then
              SetFade(item, "in", BOpt.DefaultFadeIn * typeValueCoeff)
              AnyEdit = 1
            end
            
          elseif not PrevEnd or iPos > PrevEnd then
            if iFin == 0 then
              SetFade(item, "in", BOpt.DefaultFadeIn * typeValueCoeff)
              AnyEdit = 1
            end
            if PrevFout == 0 then
              SetFade(items[i-1], "out", BOpt.DefaultFadeOut * typeValueCoeff)
              AnyEdit = 1
            end
          end
          
          if i == #items and iFout == 0 and iEnd <= areaData.areaEnd then
          --fadeout for the last item
            SetFade(item, "out", BOpt.DefaultFadeOut * typeValueCoeff)
            AnyEdit = 1
          end
        end
        
        PrevEnd = iEnd
        PrevFout = iFout
      end -- for in pairs(items)
      
    end --if not area is Envelope
  end -- end for cycle #razorEdits
  
  
  if AnyEdit == nil then
    reaper.defer(function()end)
  else
    reaper.Main_OnCommandEx(42406, 0, 0)  --Clear RE area
    if start_TS ~= end_TS then
      reaper.Main_OnCommandEx(40020, 0, 0)
      --Time selection: Remove (unselect) time selection and loop points
    end
    UndoString = 'FadeTool - Batch fades/crossfades'
  end
  
  TheRestAfterBatch()
  
end
-----------------------

function TheRestAfterBatch()
  if AutoCrosState == 0 then
    reaper.Main_OnCommandEx(40041,0,0)  --Options: Toggle auto-crossfade on/off
  end
  reaper.PreventUIRefresh(-1)
  RestoreLockedItems()
  
  if globalLock == 1 then
    reaper.Main_OnCommandEx(40569,0,0) --Locking: Enable locking
  end
  if trimContBehItems == 1 then
    reaper.Main_OnCommandEx(41120,0,0) --Options: Enable trim content behind media items when editing
  end
  
  if UndoString ~= nil then
    if sTime then MoveEditCursor(sTime) end
    reaper.Undo_EndBlock2( 0, UndoString, -1 )
    reaper.UpdateArrange()
  else reaper.defer(function()end)
  end
end
-----------------------
-----------------------

function MouseOverWhat(razorEdits)
  if not reaper.APIExists("JS_Mouse_GetCursor") then
    reaper.ShowMessageBox('Missing API!\nInstall js_ReaScriptAPI from ReaPack', 'Fade tool',0)
    return
  end
  local currentcur =  reaper.JS_Mouse_GetCursor()
  local fadeid = {105,184, 529}
  for id=202, 204 do
    local testcur = reaper.JS_Mouse_LoadCursor( id ) --razor envelope up/down
    if testcur == currentcur then return 'razor env' end
  end
  
  for i=1, #fadeid do
    local testcur = reaper.JS_Mouse_LoadCursor( fadeid[i] ) --item fade
    local side
    if fadeid[i] == 105 then side = ' left' end
    if fadeid[i] == 184 then side = ' right' end
    if fadeid[i] == 529 then side = ' left' end
    if testcur == currentcur then return 'item fade'..side end
  end
  return ''
end
-----------------------
-----------------------

function StretchEnv(env,pointsNumber,pointsTable,areaStart,areaEnd)
  local smallAreaStart = pointsTable[1]['time']
  local smallAreaEnd = pointsTable[#pointsTable]['time']
  
  if pointsNumber == 1 then
    local point = pointsTable[1]
    local id = point.id
    local time = point.time
    local value = point.value
    local shape = point.shape
    local tension = point.tension
    local selected = point.selected
    reaper.DeleteEnvelopePointEx( env, -1, id )
    reaper.InsertEnvelopePointEx( env, -1, areaStart, value, shape, 0, false, true )
    reaper.InsertEnvelopePointEx( env, -1, areaEnd, value, shape, tension, false, true )
  else
    local i = pointsNumber
    while i > 0 do
      local point = pointsTable[i]
      local id = point.id
      local time = point.time
      local value = point.value
      local shape = point.shape
      local tension = point.tension
      local selected = point.selected
      
      local relpos = (time-smallAreaStart)/(smallAreaEnd-smallAreaStart)
      local newpos = areaStart + relpos*(areaEnd-areaStart)
      reaper.SetEnvelopePointEx( env,-1,id, newpos, value, shape, tension, false, true )
      
      i=i-1
    end
  end
end

-----------------------
-----------------------

function CutEnv(env,pointsTable,areaEdge1,areaEdge2)
  local areaStart = math.min(areaEdge1,areaEdge2)
  local areaEnd = math.max(areaEdge1,areaEdge2)
  local pointsNumber = #pointsTable
  if pointsNumber == 0 then return false end
  
  local cutShape = 0
  if Opt.CutShapeUseDef == true then cutShape = tonumber(ExtractDefPointShape(env)) end
  
  local inBordRet, inBordVal, _,_,_ = reaper.Envelope_Evaluate( env, areaStart, 192000, 1 )
  local outBordRet, outBordVal, _,_,_ = reaper.Envelope_Evaluate( env, areaEnd, 192000, 1 )

  local PrevPindex = pointsTable[1]["id"] -1
  local InnerPindex = pointsTable[pointsNumber]["id"] 
  local _, prevPtime, prevPvalue, prevPshape, prevPtension, _ =
  reaper.GetEnvelopePointEx(env, -1, PrevPindex)
  local _, inPtime, _, inPshape, inPtension, _ =
  reaper.GetEnvelopePointEx(env, -1, InnerPindex)
  
  local _, afterPtime, afterPvalue, afterPshape, afterPtension, _ =
  reaper.GetEnvelopePointEx(env, -1, pointsTable[pointsNumber]["id"]+1)

  reaper.DeleteEnvelopePointRangeEx( env, -1, areaStart, areaEnd )
  
  reaper.InsertEnvelopePointEx( env, -1, areaStart, inBordVal, cutShape, 0, false, true )
  if inPtension ~= 0 then
    local right_tenscoeff= math.sqrt((afterPtime - pointsTable[pointsNumber]["time"])/(afterPtime - areaEnd))
    inPtension = inPtension/right_tenscoeff
  end
  
  if inPtime ~= areaEnd then
    reaper.InsertEnvelopePointEx( env, -1, areaEnd, outBordVal, inPshape, inPtension, false, true )
  end
  
  if prevPtension ~=0 then
    local left_tenscoeff = math.sqrt((pointsTable[1]["time"] - prevPtime)/(areaStart - prevPtime))
    reaper.SetEnvelopePointEx(env,-1,PrevPindex, prevPtime, prevPvalue, prevPshape, prevPtension/left_tenscoeff, true, true)
  end
  
  return true
end

-----------------------
-----------------------

function GetFadeMouse(item)
  local mpos = reaper.BR_PositionAtMouseCursor(false)
  local ipos =  reaper.GetMediaItemInfo_Value( item,'D_POSITION' )
  local iend = ipos +  reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )
  local finlen =  reaper.GetMediaItemInfo_Value( item,'D_FADEINLEN' )
  local foutlen =  reaper.GetMediaItemInfo_Value( item, 'D_FADEOUTLEN' )
  local finlenAuto =  reaper.GetMediaItemInfo_Value( item,'D_FADEINLEN_AUTO' )
  local foutlenAuto =  reaper.GetMediaItemInfo_Value( item, 'D_FADEOUTLEN_AUTO' )
  local finshape =  reaper.GetMediaItemInfo_Value( item,'C_FADEINSHAPE' )
  local foutshape =  reaper.GetMediaItemInfo_Value( item,'C_FADEOUTSHAPE' )
  
  if finlenAuto > 0 then finlen = finlenAuto end
  if foutlenAuto > 0 then foutlen = foutlenAuto end
  
  local fadeType
  if mpos < iend - foutlen then
    if MouseCUR:match('left') then
      fadeType = "L"
    elseif MouseCUR:match('right') then
      fadeType = "R"
      local leftItem = FindXfadedNeigbourItem(item, ipos, iend, -1)
      
      local lipos =  reaper.GetMediaItemInfo_Value( leftItem,'D_POSITION' )
      iend = lipos +  reaper.GetMediaItemInfo_Value( leftItem, 'D_LENGTH' )
      foutlen =  reaper.GetMediaItemInfo_Value( leftItem, 'D_FADEOUTLEN' )
      foutlenAuto =  reaper.GetMediaItemInfo_Value( leftItem, 'D_FADEOUTLEN_AUTO' )
      foutshape =  reaper.GetMediaItemInfo_Value( leftItem,'C_FADEOUTSHAPE' )
    end
  elseif mpos >= iend - foutlen then
    if MouseCUR:match('right') then
      fadeType = "R"
    elseif MouseCUR:match('left') then
      fadeType = "L"
      local rightItem = FindXfadedNeigbourItem(item, ipos, iend, 1)
      
      ipos =  reaper.GetMediaItemInfo_Value( rightItem,'D_POSITION' )
      finlen =  reaper.GetMediaItemInfo_Value( item,'D_FADEINLEN' )
      finlenAuto =  reaper.GetMediaItemInfo_Value( item,'D_FADEINLEN_AUTO' )
      finshape =  reaper.GetMediaItemInfo_Value( item,'C_FADEINSHAPE' )
    end
  end
  
  if finlenAuto > 0 then finlen = finlenAuto end
  if foutlenAuto > 0 then foutlen = foutlenAuto end
  
  if finshape == 7 then finshape = 1 end
  if foutshape == 7 then foutshape = 1 end
  
  if fadeType == "L" then
    local fT = {0,3,4,3,4,2,2}
    finshape = fT[finshape+1]
    return finshape, ipos, ipos + finlen
  elseif fadeType == "R" then
    local fT = {0,4,3,4,3,2,2}
    foutshape = fT[foutshape+1]
    return foutshape, iend - foutlen, iend
  end
end

-------------------

function ItemFadeToEnv(env,pointsNumber,pointsTable,areaStart,areaEnd)
  local x, y = reaper.GetMousePosition()
  local item_mouse = reaper.GetItemFromPoint(x,y, true)
  local fShape, fStart, fEnd = GetFadeMouse(item_mouse)
  
  if areaStart < fEnd and fStart < areaEnd then
    local _, infVal, _,_,_ = reaper.Envelope_Evaluate( env, areaStart, 192000, 1 )
    local _, outfVal, _,_,_ = reaper.Envelope_Evaluate( env, areaEnd, 192000, 1 )
    
    local Start, End = math.min(areaStart,fStart), math.max(areaEnd,fEnd)
    
    local _, startVal, _,_,_ = reaper.Envelope_Evaluate( env, Start, 192000, 1 )
    local _, endVal, _,_,_ = reaper.Envelope_Evaluate( env, End, 192000, 1 )
    
    local PrevPindex = reaper.GetEnvelopePointByTimeEx( env, -1, Start )
    local InnerPindex = reaper.GetEnvelopePointByTimeEx( env, -1, End )
    local _, _, prevPvalue, prevPshape, prevPtension, _ =
    reaper.GetEnvelopePointEx(env, -1, PrevPindex)
    local _, _, nextPvalue, nextPshape, nextPtension, _ =
    reaper.GetEnvelopePointEx(env, -1, InnerPindex+1)
    
    local _, _, _, inPshape, inPtension, _ =
    reaper.GetEnvelopePointEx(env, -1, InnerPindex)
    
    reaper.DeleteEnvelopePointRangeEx( env, -1, Start, End+0.0001)

    reaper.InsertEnvelopePointEx(env,-1,fStart, infVal, fShape, 0, false, true )
    reaper.InsertEnvelopePointEx(env,-1,fEnd, outfVal, inPshape, inPtension, false, true )
    
    UndoString = 'Fade tool - item fade to envelope'
    return fStart
  end
end

-----------------------
-----------------------

function FadeEnvelope(areaData)
  local areaStart = areaData.areaStart
  local areaEnd = areaData.areaEnd
  
  local fadestart = areaStart

  local env = areaData.envelope
  local envName = areaData.envelopeName
  local envPoints = areaData.envelopePoints
  local GUID = areaData.GUID
  local pointsNumber = #envPoints
  --msg(pointsNumber)
  local inBordRet, inBordVal, _,_,_ = reaper.Envelope_Evaluate( env, areaStart, 192000, 1 )
  local outBordRet, outBordVal, _,_,_ = reaper.Envelope_Evaluate( env, areaEnd, 192000, 1 )
 
  --here we need to get shape from neighbour points
  --get points index by time or earlier then time
  local PrevPindex = reaper.GetEnvelopePointByTimeEx( env, -1, areaStart )
  local InnerPindex = reaper.GetEnvelopePointByTimeEx( env, -1, areaEnd )
  --get time for got points
  local _, prevPtime, prevPvalue, prevPshape, prevPtension, _ =
  reaper.GetEnvelopePointEx(env, -1, PrevPindex)
  local _, _, _, inPshape, inPtension, _ =
  reaper.GetEnvelopePointEx(env, -1, InnerPindex)
  
  
  
  if MouseCUR:match('item fade')=='item fade' then
    fadestart = ItemFadeToEnv(env,pointsNumber,envPoints,areaStart,areaEnd)
    goto continue
  end
  
  if MouseCUR == 'razor env' then
    if pointsNumber > 2 then
      
      if #envPoints.End > 1 or #envPoints.Start > 1 then
        if #envPoints.End > 1 then
          local iE = #envPoints.End
          while iE > 0 do
            reaper.DeleteEnvelopePointEx( env, -1, envPoints.End[iE] )
            iE = iE-1
          end
          
          DONTremoveRazor = true
        end
        
        if #envPoints.Start > 1 then
          local iS = #envPoints.Start
          while iS > 0 do
            reaper.DeleteEnvelopePointEx( env, -1, envPoints.Start[iS] )
            iS = iS-1
          end
          
          DONTremoveRazor = true
        end
        
        if #envPoints.End > 1 then
          reaper.InsertEnvelopePointEx( env, -1, areaEnd, outBordVal, inPshape, inPtension, false, true )
        end
        if #envPoints.Start > 1 then
          reaper.InsertEnvelopePointEx( env, -1, areaStart, inBordVal, prevPshape, prevPtension, false, true )
        end
        
        UndoString = 'Fade tool - remove inner edge points'

      elseif #envPoints.Start <= 1 and #envPoints.End <= 1 then
        CutEnv(env,envPoints,areaStart,areaEnd)
        UndoString = 'Fade tool - Cut envelope segment'
      end
    
    end --if pointsNumber > 2
    
    if pointsNumber <= 2 then
      CutEnv(env,envPoints,areaStart,areaEnd)
      UndoString = 'Fade tool - Cut envelope segment'
    end
  end --if MouseCUR == 'razor env'
  
  
  if MouseCUR ~= 'razor env' then
  
    if pointsNumber > 2 then
      if MouseDistDiff then
        local newStart = areaStart + MouseDistDiff
        local newEnd = areaEnd - MouseDistDiff
        fadestart = math.min(areaStart, newStart)
        
        if MouseDistDiff < 0 then
          areaStart = envPoints[2]['time']
          areaEnd = envPoints[#envPoints -1]['time']
        end

        envPoints = GetEnvelopePointsInRange(env, areaEnd,newEnd)
        local ret = CutEnv(env,envPoints,areaEnd,newEnd)
        reaper.Envelope_SortPointsEx( env, -1 )
        
        envPoints = GetEnvelopePointsInRange(env, areaStart, newStart)
        local ret2 = CutEnv(env,envPoints,areaStart,newStart)
        
        if ret == true or ret2 == true then
          UndoString = 'Fade tool - Smooth env RE area edges with mouse'
        else DONTremoveRazor = true
        end
      else
        DONTremoveRazor = true
      end
      goto continue
    end
    
    if pointsNumber <= 2 and pointsNumber > 0 then
      StretchEnv(env,pointsNumber,envPoints,areaStart,areaEnd)
      UndoString = 'Fade tool - Expand envelope points'
    elseif pointsNumber == 0 then
      local _, _, outPvalue, outPshape, outPtension, _ =
      reaper.GetEnvelopePointEx(env,-1,PrevPindex+1)
      reaper.SetEnvelopePointEx(env,-1,PrevPindex, areaStart, prevPvalue, prevPshape, prevPtension, true, true)
      reaper.SetEnvelopePointEx(env,-1,PrevPindex+1, areaEnd, outPvalue, outPshape, outPtension, true, true)
      UndoString = 'Fade tool - Collapse envelope points'
    end
    --[[ Replaced by Smooth env RE area edges
    if pointsNumber > 2 then
      CutEnv(env,envPoints,areaStart,areaEnd)
      UndoString = 'Fade tool - Cut envelope segment'
    end
    ]]
  end --if MouseCUR ~= 'razor env'
  
  ::continue::
  reaper.Envelope_SortPointsEx( env, -1 )
  
  if UndoString then  --Deselect all env points: 
    local pcount = reaper.CountEnvelopePointsEx(env, -1)
    for i = 0, pcount -1 do
      reaper.SetEnvelopePointEx(env, -1, i, nil, nil, nil, nil, false, true)
    end
  end
  
  return fadestart
end

-----------------------
-----------------------

function FadeRazorEdits(razorEdits, needBatch) --get areaMap table and batch flag
    local areaItems = {}
    local fadeStartT = {}
    local fadeStartEdge
    reaper.PreventUIRefresh(1)
    
    AutoCrosState = reaper.GetToggleCommandState(40041) --Options: Toggle auto-crossfade on/off
    if AutoCrosState == 0 then
      reaper.Main_OnCommandEx(40041,0,0)
    end
    
    if needBatch == true then
      if fulliLock == 0 then
        BatchFadesWindow(razorEdits)
      end
    else
      
      local i = #razorEdits
      while i > 0 do
        local areaData = razorEdits[i]
        
        if not areaData.isEnvelope
        and (RAZORenvelopes == false
        or (window == 'arrange' and (segment == 'track' or segment == 'empty')))
        then
          local items = areaData.items
          local Litem
          local Ritem
          
      
          if #items == 0 or #items > 2 then
            reaper.defer(function()end)
          end
      
          ---------Define L/R items--------
          if #items == 2 then
            local item_1 = items[1]
            local item_2 = items[2]
            local iPos_1 = reaper.GetMediaItemInfo_Value(item_1, "D_POSITION")
            local itemEndPos_1 = iPos_1+reaper.GetMediaItemInfo_Value(item_1, "D_LENGTH")
            local iPos_2 = reaper.GetMediaItemInfo_Value(item_2, "D_POSITION")
            local itemEndPos_2 = iPos_2+reaper.GetMediaItemInfo_Value(item_2, "D_LENGTH")
            
            if iPos_1 <= areaData.areaStart and itemEndPos_1 > areaData.areaStart and iPos_1 <= iPos_2
            and iPos_2 < areaData.areaEnd and itemEndPos_2 >= areaData.areaEnd
            and itemEndPos_1 <= itemEndPos_2
            then
              Litem = item_1
              Ritem = item_2
            end
            
          elseif #items == 1 then
          
            item_1 = items[1]
            local iPos_1 = reaper.GetMediaItemInfo_Value(item_1, "D_POSITION")
            local itemEndPos_1 = iPos_1+reaper.GetMediaItemInfo_Value(item_1, "D_LENGTH")
            if (iPos_1 <= areaData.areaStart and itemEndPos_1 < areaData.areaEnd) or
            (iPos_1 < areaData.areaStart and itemEndPos_1 <= areaData.areaEnd)then
              Litem = item_1
            elseif (iPos_1 >= areaData.areaStart and itemEndPos_1 > areaData.areaEnd) or
            (iPos_1 > areaData.areaStart and itemEndPos_1 >= areaData.areaEnd)then
              Ritem = item_1
            end
          end
      
          -------------1st case-------------
          if #items == 2 and Litem and Ritem
          and (fulliLock == 0 and edgesLock == 0) then
            UndoString = "FadeTool - razor area"
              --create crossfade
              table.insert(fadeStartT, areaData.areaStart)
              SetCrossfade(Litem,Ritem,areaData) 
          end
          -------End of the 1st case-----------
          
          
          -------Other 3 cases-----------
          if fulliLock == 1 then return end
          
          if #items == 1 then
            UndoString = "FadeTool - razor area"
            MoveItemEdgeRazor = Opt.MoveItemEdgeRazor
            
            if Ritem and Litem == nil then  --fade IN
              local item = items[1]
              local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
              if Opt.MoveItemEdgeRazor == true then
                table.insert(fadeStartT, areaData.areaStart)
                SetCrossfade(_,item,areaData)
              else
                fadeStartEdge = SetFade(item, "in", areaData.areaEnd - iPos)
                if fadeStartEdge ~= nil then table.insert(fadeStartT, fadeStartEdge) end
              end
            elseif Litem and Ritem == nil then -- fade OUT
              local item = items[1]
              local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
              local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
              if Opt.MoveItemEdgeRazor == true then
                table.insert(fadeStartT, areaData.areaStart)
                SetCrossfade(item,_,areaData)
              else
                fadeStartEdge = SetFade(item, "out", iEnd - areaData.areaStart)
                if fadeStartEdge ~= nil then table.insert(fadeStartT, fadeStartEdge) end
              end
              
            elseif Litem == nil and Ritem == nil then -- fades on the rests
              local item = items[1]
              local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
              local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
              fadeStartEdge = SetFade(item, "in", areaData.areaStart - iPos)
                              SetFade(item, "out", iEnd - areaData.areaEnd)
              if fadeStartEdge ~= nil then table.insert(fadeStartT, fadeStartEdge) end
              
            end
          end --other 3 cases
          
        elseif areaData.isEnvelope then -- if area is envelope
          if (window == 'arrange' and segment == 'envelope')
          or ONLYenvelopes == true
          then
            if envLock == 0 then
              if not MouseCUR then MouseCUR = MouseOverWhat(razorEdits)end
              table.insert(fadeStartT, FadeEnvelope(areaData))
            end
          end
        end -- if not area is envelope
        i = i-1
      end -- end cycle through areas
      
      if #fadeStartT == 0 and UndoString ~= 'FadeTool - Batch fades/crossfades' then UndoString = nil 
      else
        if DONTremoveRazor ~= true then
          reaper.Main_OnCommandEx(42406, 0, 0)  --Clear RE area
        end
        if start_TS ~= end_TS then
          reaper.Main_OnCommandEx(40020, 0, 0)
          --Time selection: Remove (unselect) time selection and loop points
        end
      end
      
    end --else (if no Batch)
    
    if AutoCrosState == 0 and not RunBatch then
      reaper.Main_OnCommandEx(40041,0,0)  --Options: Toggle auto-crossfade on/off
    end
    reaper.PreventUIRefresh(-1)
    
    return fadeStartT
end

-----------------------------------

function SaveSelItemsByTracks(startTime, endTime) --- time optional
  local SI = {}
  local oldTrack
  local needBatch
  
  for i=0, reaper.CountSelectedMediaItems(0) -1 do
    local TData = {Tname, Titems={} }
    local item = reaper.GetSelectedMediaItem(0,i)
    local iTrack = reaper.GetMediaItemTrack(item)
    
    if startTime and endTime then --is item in range
      local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
      local iLock = reaper.GetMediaItemInfo_Value(item, "C_LOCK")
      
      if iPos < endTime and iEnd > startTime
      and (iLock==0 or RespectLockingBatch == false) then
        if iPos >= startTime and iEnd <= endTime then needBatch = true end
      else
        item = nil
      end
    end
    
    if item then
      if iTrack ~= oldTrack then
        oldTrack = iTrack
        TData.Tname = iTrack
        table.insert(TData.Titems, item)
        table.insert(SI, TData)
      else
        table.insert(SI[#SI].Titems, item )
      end
    end
  end

  return SI, needBatch
end

--------------------------------

function GetTSandItems(start_TS, end_TS) --returns areaMap and needBatch
  local areaMap = {}
  local items = {}
  local SI = {}
  local needBatch
  
  if reaper.CountSelectedMediaItems(0) == 2 then
    local item_1 = reaper.GetSelectedMediaItem(0,0)
    local item_2 = reaper.GetSelectedMediaItem(0,1)

    local iPos_1 = reaper.GetMediaItemInfo_Value(item_1, "D_POSITION")
    local itemEndPos_1 = iPos_1+reaper.GetMediaItemInfo_Value(item_1, "D_LENGTH")
    local iLock_1 = reaper.GetMediaItemInfo_Value(item_1, "C_LOCK")
    
    local iPos_2 = reaper.GetMediaItemInfo_Value(item_2, "D_POSITION")
    local itemEndPos_2 = iPos_2+reaper.GetMediaItemInfo_Value(item_2, "D_LENGTH")
    local iLock_2 = reaper.GetMediaItemInfo_Value(item_2, "C_LOCK")
    
    if iLock_1 == 0 and iLock_2 == 0 then
      if iPos_1 <= start_TS and itemEndPos_1 > start_TS and iPos_1 < iPos_2 and
      iPos_2 < end_TS and itemEndPos_2 >= end_TS and itemEndPos_1 < itemEndPos_2 then
        items[1] = item_1
        items[2] = item_2
      elseif iPos_2 <= start_TS and itemEndPos_2 > start_TS and iPos_2 < iPos_1 and
      iPos_1 < end_TS and itemEndPos_1 >= end_TS and itemEndPos_2 < itemEndPos_1 then
        items[1] = item_2
        items[2] = item_1
      end
    end
    
    if #items == 2 then -- if there are finded left and right items
      local areaData = {
          areaStart = start_TS,
          areaEnd = end_TS,
          
          items = items,
      }
      
      table.insert(areaMap, areaData)
    else
      SI, needBatch = SaveSelItemsByTracks(start_TS, end_TS)
      for t=1, #SI do
        local TData = SI[t]

        local areaData = {
            areaStart = start_TS,
            areaEnd = end_TS,
            
            track = TData.Tname,
            items = TData.Titems,
        }
        
        table.insert(areaMap, areaData)
      end
      --[[
      if #SI == 0 then
        local areaData = {
            areaStart = start_TS,
            areaEnd = end_TS,
            
            track,
            items = {},
        }
        
        table.insert(areaMap, areaData)
      end]]
    end
  else --if not 2 items selected
    SI, needBatch = SaveSelItemsByTracks(start_TS, end_TS)
    
    for t=1, #SI do
      local TData = SI[t]
    
      local areaData = {
          areaStart = start_TS,
          areaEnd = end_TS,
          
          track = TData.Tname,
          items = TData.Titems,
      }
      
      table.insert(areaMap, areaData)
    end
    --[[
    if #SI == 0 then
      local areaData = {
          areaStart = start_TS,
          areaEnd = end_TS,
          
          track,
          items = {},
      }
      
      table.insert(areaMap, areaData)
    end]]
  end
  
  return areaMap, needBatch
end


-----------------------------------
-----------------------------------

function GetTopBottomItemHalf()
local itempart
local x, y = reaper.GetMousePosition()

local item_under_mouse = reaper.GetItemFromPoint(x,y,true)

if item_under_mouse then

  local item_h = reaper.GetMediaItemInfo_Value( item_under_mouse, "I_LASTH" )
  
  local OScoeff = 1
  if reaper.GetOS():match("^Win") == nil then
    OScoeff = -1
  end
  
  local test_point = math.floor( y + (item_h-1) *OScoeff)
  local test_item, take = reaper.GetItemFromPoint( x, test_point, true )
  
  if item_under_mouse == test_item then
    itempart = "header"
  else
    local test_point = math.floor( y + item_h/2 *OScoeff)
    local test_item, take = reaper.GetItemFromPoint( x, test_point, true )
    
    if item_under_mouse ~= test_item then
      itempart = "bottom"
    else
      itempart = "top"
    end
  end

  return item_under_mouse, itempart
else return nil end

end

------------------------------

function SetFade(item, f_type, f_size, shape ) -- returns fadeStartEdge
  if not item then return end

  if f_type == "in" then
    
    local InitOutFade = reaper.GetMediaItemInfo_Value( item, "D_FADEOUTLEN" )
    local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    local iLock = reaper.GetMediaItemInfo_Value( item, "C_LOCK" )
    local i_autoFin = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO")
    
    if (iLock == 0 and fadesLock == 0) or Opt.IgnoreLockingMouse == true
    or RespectLockingBatch == false then
      if InitOutFade ~= 0 then
       local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
       local fEdge = iPos + f_size
        if fEdge > iEnd - InitOutFade then
          reaper.SetMediaItemInfo_Value( item, "D_FADEOUTLEN", iEnd - fEdge )
        end
      end
      
      if i_autoFin ~= 0 then
        shape = reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE")
        reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO", 0)
        reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", shape )
      end 
      reaper.SetMediaItemInfo_Value( item, "D_FADEINLEN", f_size )
      return iPos
    end
    
  elseif f_type == "out" then
  
    local InitInFade = reaper.GetMediaItemInfo_Value( item, "D_FADEINLEN" )
    local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
    local fEdge = iEnd - f_size
    local iLock = reaper.GetMediaItemInfo_Value( item, "C_LOCK" )
    local i_autoFout = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO")
    local i_autoFin = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO")
    if i_autoFin ~= 0 then InitInFade = i_autoFin end
    
    if (iLock == 0 and fadesLock == 0) or Opt.IgnoreLockingMouse == true
    or RespectLockingBatch == false then
      if InitInFade ~= 0 then
        if fEdge < iPos + InitInFade then
          if i_autoFin ~= 0 then
            shape = reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE")
            reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO", 0)
            reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", shape )
          end
          reaper.SetMediaItemInfo_Value( item, "D_FADEINLEN", fEdge - iPos )
        end
      end
      
      if i_autoFout ~= 0 then
        shape = reaper.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE")
        reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO", 0)
        reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", shape )
      end 
      reaper.SetMediaItemInfo_Value( item, "D_FADEOUTLEN", f_size )
      return fEdge
    end
  end
  
end

----------------------------

function SaveSelItems()
  Sitems = {}
  for i = 0, reaper.CountSelectedMediaItems(0) -1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    table.insert(Sitems, item)
  end
  
end

----------------------------

function RestoreSelItems()
  reaper.SelectAllMediaItems(0, false)
  for i = 1, #Sitems do
    local item = Sitems[i]
    reaper.SetMediaItemSelected(item, true)
  end
end

----------------------------

function FindXfadedNeigbourItem(item, i_pos, i_end, step) --step decreasing or increasing item number
  local i_numb = reaper.GetMediaItemInfo_Value(item, "IP_ITEMNUMBER")
  local i_Y = reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_Y")
  local i_H = reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_H")
  local nextItem = item
  local track = reaper.GetMediaItemTrack(item)
  i_numb = i_numb + step
  while nextItem do
    nextItem = reaper.GetTrackMediaItem(track, i_numb)
    if nextItem then
      local ni_pos = reaper.GetMediaItemInfo_Value(nextItem, "D_POSITION")
      local ni_end = ni_pos + reaper.GetMediaItemInfo_Value(nextItem, "D_LENGTH")
      local ni_Y = reaper.GetMediaItemInfo_Value(nextItem, "F_FREEMODE_Y")
      local ni_H = reaper.GetMediaItemInfo_Value(nextItem, "F_FREEMODE_H")
      
      if ((ni_end > i_pos and ni_end < i_end) or (ni_pos > i_pos and ni_pos < i_end))
      and ( ni_Y < i_Y + i_H and ni_Y + ni_H > i_Y )
      then
       return nextItem
      end
      
      if ni_end < i_pos or ni_pos > i_end then break end
    end
    i_numb = i_numb + step
  end
end

----------------------------

function WhatFade(half, leftF, rightF, mPos)
  local f_type
  
  if Opt.LRdefine == 'Closest/Farthest fade' then --cross define
    if half == "top" then
      if (rightF - mPos) <= (mPos - leftF) then
        f_type = "out"
      else
        f_type = "in"
      end
    elseif half == "bottom" then
      if (rightF - mPos) > (mPos - leftF) then
        f_type = "out"
      else
        f_type = "in"
      end
    end
  elseif Opt.LRdefine == 'Left/Right fade' then
    if half == "top" then
      f_type = "in"
    elseif half == "bottom" then
      f_type = "out"
    end
  end
  
  return f_type
end

----------------------------

function SortSelItems(Items, ref_item, ref_leftItem, ref_rightItem, reverseFlag)
  local ret
  local ref_i_pos, ref_i_end, ref_fLeftpos, ref_fRightpos
  ref_i_pos = reaper.GetMediaItemInfo_Value(ref_item, "D_POSITION")
  ref_i_end = ref_i_pos + reaper.GetMediaItemInfo_Value(ref_item, "D_LENGTH")
  local ref_i_autoFin = reaper.GetMediaItemInfo_Value(ref_item, "D_FADEINLEN_AUTO")
  local ref_i_autoFout = reaper.GetMediaItemInfo_Value(ref_item, "D_FADEOUTLEN_AUTO")
  local ref_i_Fin = reaper.GetMediaItemInfo_Value(ref_item, "D_FADEINLEN")
  local ref_i_Fout = reaper.GetMediaItemInfo_Value(ref_item, "D_FADEOUTLEN")
  
  if ref_i_autoFin ~= 0 then
    ref_fLeftpos = ref_i_pos + ref_i_autoFin
  else ref_fLeftpos = ref_i_pos + ref_i_Fin
  end
  if ref_i_autoFout ~= 0 then
    ref_fRightpos = ref_i_end - ref_i_autoFout
  else ref_fRightpos = ref_i_end - ref_i_Fout
  end
  
  for i=0, reaper.CountSelectedMediaItems(0) - 1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    local itemLock = reaper.GetMediaItemInfo_Value( item, "C_LOCK" )
    
    if itemLock == 0 or (Opt.IgnoreLockingMouse == true and item == ref_item) then
      local i_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local i_end = i_pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      
      local fLeftpos, fRightpos
      local leftItem, rightItem
      local leftIlock, rightIlock
      
      local i_autoFin = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO")
      local i_autoFout = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO")
      local i_Fin = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
      local i_Fout = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
      
      if i_autoFin ~= 0 then fLeftpos = i_pos + i_autoFin else fLeftpos = i_pos + i_Fin end
      if i_autoFout ~= 0 then fRightpos = i_end - i_autoFout else fRightpos = i_end - i_Fout end
      
      if i_autoFin ~= 0 then
        leftItem = FindXfadedNeigbourItem(item, i_pos, i_end, -1)
        if leftItem then leftIlock = reaper.GetMediaItemInfo_Value( leftItem, "C_LOCK" ) end
      end
      
      if i_autoFout ~= 0 then
        rightItem = FindXfadedNeigbourItem(item, i_pos, i_end, 1)
        if rightItem then rightIlock = reaper.GetMediaItemInfo_Value( rightItem, "C_LOCK" ) end
      end
      
      if leftIlock == 1 and Opt.IgnoreLockingMouse == false then leftItem = nil end
      if rightIlock == 1 and Opt.IgnoreLockingMouse == false then rightItem = nil end
      
      local ItemData = {}
      ItemData.item = item
      ItemData.i_pos = i_pos
      ItemData.i_end = i_end
      ItemData.fLeftpos = fLeftpos
      ItemData.fRightpos = fRightpos
      ItemData.leftItem = leftItem
      ItemData.rightItem = rightItem
      
      ---Sort items--- 
      if math.abs(i_pos - ref_i_pos) < 0.0002 and math.abs(fLeftpos - ref_fLeftpos) < 0.0002
      and leftItem and ref_leftItem then
        if reverseFlag == true then table.insert(Items.Vert.R, ItemData) ret = true
        else table.insert(Items.Vert.L, ItemData) ret = true
        end
      end
      
      if math.abs(i_end - ref_i_end) < 0.0002 and math.abs(fRightpos - ref_fRightpos) < 0.0002
      and rightItem and ref_rightItem then
        if reverseFlag == true then table.insert(Items.Vert.L, ItemData) ret = true
        else table.insert(Items.Vert.R, ItemData) ret = true
        end
      end
      
      if not ref_leftItem and not leftItem then
        table.insert(Items.Horiz.L, ItemData) ret = true
      end
      
      if not ref_rightItem and not rightItem then
        table.insert(Items.Horiz.R, ItemData) ret = true
      end
      
    end
  end
  return ret
end

----------------------------

function FadeToMouse(item, itemHalf) --returns table of fades start position
  local ilock = reaper.GetMediaItemInfo_Value( item, "C_LOCK" )
  if ilock == 1 and Opt.IgnoreLockingMouse == false then return end

  local mPos = reaper.BR_PositionAtMouseCursor(false)
  local mPosSnapped
  
  if Opt.RespSnapItems == true then mPosSnapped = reaper.SnapToGrid(0,mPos)
  else mPosSnapped = mPos
  end
  
  local Items = {Vert = {L = {}, R ={} },
                 Horiz = {L = {}, R ={} }
                 }
                 
  local fadeStartT = {}
  local fadeStartEdge
  
  local i_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local i_end = i_pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  
  local fLeftpos, fRightpos
  
  local i_autoFin = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO")
  local i_autoFout = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO")
  local i_Fin = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
  local i_Fout = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
  
  local f_type, f_size
  local leftItem, rightItem
  local leftIlock, rightIlock
  
  if i_autoFin ~= 0 then fLeftpos = i_pos + i_autoFin else fLeftpos = i_pos + i_Fin end
  if i_autoFout ~= 0 then fRightpos = i_end - i_autoFout else fRightpos = i_end - i_Fout end
  
  if i_autoFin ~= 0 then
    leftItem = FindXfadedNeigbourItem(item, i_pos, i_end, -1)
    if leftItem then
      leftIlock = reaper.GetMediaItemInfo_Value( leftItem, "C_LOCK" )
    end
  end
  
  if i_autoFout ~= 0 then
    rightItem = FindXfadedNeigbourItem(item, i_pos, i_end, 1)
    if rightItem then
      rightIlock = reaper.GetMediaItemInfo_Value( rightItem, "C_LOCK" )
    end
  end
  
  local reverse
  if leftItem and mPos < fLeftpos then
    f_type = WhatFade(itemHalf, i_pos, fLeftpos, mPos)
    reverse = false
    if f_type == 'out' then
      rightItem = item
      item = leftItem
      reverse = true
    end
  elseif rightItem and mPos > fRightpos then
    f_type = WhatFade(itemHalf, fRightpos, i_end, mPos)
    reverse = false
    if f_type == 'in' then
      leftItem = item
      item = rightItem
      reverse = true
    end
  else
    f_type = WhatFade(itemHalf, fLeftpos, fRightpos, mPos)
  end
  
  if Grouping == 1 then
    SaveSelItems()
    local group = reaper.GetMediaItemInfo_Value( item, "I_GROUPID" )
    if reaper.IsMediaItemSelected(item) == false and group ~= 0 then
      reaper.SetMediaItemSelected(item, true)
    end
    reaper.Main_OnCommandEx(40034,0,0) --Item grouping: Select all items in groups
  end
  
  local LeftSelFlag, RightSelFlag
  local sortSuccess
  if reaper.IsMediaItemSelected(item) == true then
    sortSuccess = SortSelItems(Items, item, leftItem, rightItem, false)
  else
    if leftItem and reaper.IsMediaItemSelected(leftItem) == true
    and (f_type == 'in' or itemHalf == 'header') then
      LeftSelFlag = true
      sortSuccess = SortSelItems(Items, leftItem, nil, item, true)
    end
    if rightItem and reaper.IsMediaItemSelected(rightItem) == true and reverse ~= false
    and (f_type == 'out' or itemHalf == 'header') then
      RightSelFlag = true
      sortSuccess = SortSelItems(Items, rightItem, item, nil, true)
    end
    if sortSuccess ~= true then
      local ItemData = {}
      ItemData.item = item
      ItemData.i_pos = i_pos
      ItemData.i_end = i_end
      ItemData.fLeftpos = fLeftpos
      ItemData.fRightpos = fRightpos
      ItemData.leftItem = leftItem
      ItemData.rightItem = rightItem
      
      table.insert(Items.Vert.L, ItemData)
      table.insert(Items.Vert.R, ItemData)
      table.insert(Items.Horiz.L, ItemData)
      table.insert(Items.Horiz.R, ItemData)
    end
  end
  
  
  if mPos > i_pos and mPos < fLeftpos then
    if mPosSnapped > fLeftpos or mPosSnapped < i_pos then
      mPosSnapped = mPos
    end 
  elseif mPos > fRightpos and mPos < i_end then
    if mPosSnapped < fRightpos or mPosSnapped > i_end then
      mPosSnapped = mPos 
    end
  end
  
  if itemHalf == 'header' then --MOVE CLOSEST XFADE TO MOUSE
    if Opt.IgnoreLockingMouse == false and (edgesLock == 1 and globalLock == 1) then
      return
    end
    
    if leftIlock == 1 and Opt.IgnoreLockingMouse == false then leftItem = nil end
    if rightIlock == 1 and Opt.IgnoreLockingMouse == false then rightItem = nil end
    
    local areaData = {areaStart, areaEnd}
    local ret
    if leftItem and rightItem then
      if mPos - fLeftpos < fRightpos - mPos then -- left xfade
        areaData.areaStart = mPosSnapped - i_autoFin/2
        areaData.areaEnd = mPosSnapped + i_autoFin/2
        for i, itemData in ipairs(Items.Vert.L) do
          local Litem, Ritem
          if LeftSelFlag == true then
            Litem = itemData.item
            Ritem = itemData.rightItem
          elseif RightSelFlag == true then
            Litem = leftItem
            Ritem = item
          else
            Litem = itemData.leftItem
            Ritem = itemData.item
          end
          ret = SetCrossfade(Litem, Ritem, areaData)
        end
      else -- right xfade
        areaData.areaStart = mPosSnapped - i_autoFout/2
        areaData.areaEnd = mPosSnapped + i_autoFout/2
        for i, itemData in ipairs(Items.Vert.R) do
          local Litem, Ritem
          if RightSelFlag == true then
            Litem = itemData.leftItem
            Ritem = itemData.item
          else
            Litem = itemData.item
            Ritem = itemData.rightItem
          end
          ret = SetCrossfade(Litem, Ritem, areaData)
        end
      end
    elseif leftItem then --left xfade
      areaData.areaStart = mPosSnapped - i_autoFin/2
      areaData.areaEnd = mPosSnapped + i_autoFin/2
      for i, itemData in ipairs(Items.Vert.L) do
        local Litem, Ritem
        if LeftSelFlag == true then
          Litem = itemData.item
          Ritem = itemData.rightItem
        elseif RightSelFlag == true then
          Litem = leftItem
          Ritem = item
        else
          Litem = itemData.leftItem
          Ritem = itemData.item
        end
        ret = SetCrossfade(Litem, Ritem, areaData)
      end 
    elseif rightItem then -- right xfade
      areaData.areaStart = mPosSnapped - i_autoFout/2
      areaData.areaEnd = mPosSnapped + i_autoFout/2 
      for i, itemData in ipairs(Items.Vert.R) do
        local Litem, Ritem
        if LeftSelFlag == true then
          Litem = item
          Ritem = rightItem
        elseif RightSelFlag == true then
          Litem = itemData.leftItem
          Ritem = itemData.item
        else
          Litem = itemData.item
          Ritem = itemData.rightItem
        end
        ret = SetCrossfade(Litem, Ritem, areaData)
      end
    end
    
    if ret then
      UndoString = 'FadeTool - move closest xfade to mouse'
      table.insert(fadeStartT, ret)
    end
    return  fadeStartT
  end
  ------------------------
  
  if f_type == 'in' then
    if mPosSnapped <= i_pos + 0.0002 then mPosSnapped = mPos end
    f_size = mPosSnapped - i_pos
  elseif f_type == 'out' then
    if mPosSnapped >= i_end - 0.0002 then mPosSnapped = mPos end
    f_size = i_end - mPosSnapped
  end
  
  if f_type == 'in' and leftItem then --change crossfade
    if Opt.IgnoreLockingMouse == false
    and ((edgesLock == 1 and globalLock == 1) or leftIlock == 1) then
      return
    end
    
    local areaData
    if reverse == true then --msg('right item selected, move Left edge of xfade')
      areaData = {areaStart = mPosSnapped, areaEnd = i_end}
    elseif reverse == false then --msg('move Left edge')
      areaData = {areaStart = mPosSnapped, areaEnd = fLeftpos}
    else
      areaData = {areaStart = i_pos, areaEnd = mPosSnapped}
    end
    
    for i, itemData in ipairs(Items.Vert.L) do
      local Litem, Ritem
      if LeftSelFlag == true then
        Litem = itemData.item
        Ritem = itemData.rightItem
      elseif RightSelFlag == true then
        Litem = leftItem
        Ritem = item
      else
        Litem = itemData.leftItem
        Ritem = itemData.item
      end
      fadeStartEdge = SetCrossfade(Litem, Ritem, areaData)
    end
    
  elseif f_type == 'out' and rightItem then --change cdrossfade
    if Opt.IgnoreLockingMouse == false
    and ((edgesLock == 1 and globalLock == 1) or rightIlock == 1) then
      return
    end
    
    local areaData
    if reverse == true then
      areaData = {areaStart = i_pos, areaEnd = mPosSnapped}
    elseif reverse == false then --msg('right item selected, move Right edge of xfade')
      areaData = {areaStart = fRightpos, areaEnd = mPosSnapped}
    else
      areaData = {areaStart = mPosSnapped, areaEnd = i_end}
    end
    
    for i, itemData in ipairs(Items.Vert.R) do
      local Litem, Ritem
      if RightSelFlag == true then
        Litem = itemData.leftItem
        Ritem = itemData.item
      else
        Litem = itemData.item
        Ritem = itemData.rightItem
      end
      fadeStartEdge = SetCrossfade(Litem, Ritem, areaData)
    end
    
  else --change fade
    if f_type == "in" then
      for i, itemData in ipairs(Items.Horiz.L) do
        fadeStartEdge = SetFade(itemData.item, f_type, f_size) -- item, "in"/"out" f_type, f_size, (shape)
      end
    elseif f_type == "out" then
      for i, itemData in ipairs(Items.Horiz.R) do
        fadeStartEdge = SetFade(itemData.item, f_type, f_size) -- item, "in"/"out" f_type, f_size, (shape)
      end
    end
  end
  
  if fadeStartEdge ~= nil then 
    table.insert(fadeStartT, fadeStartEdge)
    UndoString = 'FadeTool - mouse'
  end
  
  return fadeStartT
end

------------------------------------------

function MoveEditCursor(timeTable)
  if #timeTable > 0 then
    local fadeStartEdge = math.min(table.unpack(timeTable))
    if Opt.moveEditCursor == true then
      reaper.SetEditCurPos2(0, fadeStartEdge - Opt.curOffset, false, false)
    else
      reaper.SetEditCurPos2(0, EcurInit, false, false)
    end
  end
end

-----------------------------------------

function RestoreLockedItems()
  for i=1, #LOCKEDitems do
  local item = LOCKEDitems[i]
  reaper.SetMediaItemInfo_Value( item, "C_LOCK", 1 )
  end
end

-----------------------------------------

function UnselectEnvPoints(env, autoitem_idx, IDtable, timeStart, timeEnd) --env and autoitem are necessary
  
  if timeStart and timeEnd then
  elseif IDtable then
  else
    local pCount = reaper.CountEnvelopePointsEx( env, autoitem_idx ) -1
    for id = 0, pCount do
       local ret, time, value, shape, tension, sel = reaper.GetEnvelopePointEx( env, autoitem_idx, id )
       reaper.SetEnvelopePointEx
       (env, autoitem_idx, id, time, value, shape, tension, false, true )
    end
  end
  
end

-----------------------------------------

function ExtractDefPointShape(env)
  local ret, chunk = reaper.GetEnvelopeStateChunk(env, '', false)
  for line in chunk:gmatch("[^\n]+") do
    if line:match('DEFSHAPE') then
      local value = line:match('%d')
      return value
    end
  end
end

-----------------------------------------

function MovePoint(env, time, item, pointPos)
--pointPos should be 'left' or 'right' relative to time
  if pointPos == 'right' then pointPos = 1 else pointPos = 0 end
  local itemPos = 0
  local takeRate = 1
  local timeSnap
  
  if Opt.RespSnapEnvs == true then
    timeSnap = reaper.SnapToGrid(0, time)
  else timeSnap = time
  end
  
  if item then
    itemPos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local envTake = reaper.GetActiveTake(item)
    takeRate = reaper.GetMediaItemTakeInfo_Value(envTake, 'D_PLAYRATE')
    
    timeSnap = (timeSnap - itemPos ) * takeRate
    time = (time - itemPos) * takeRate
  end
  
  local point_idx = reaper.GetEnvelopePointByTimeEx( env, -1, time ) + pointPos
  local _, pTime, pValue, pShape, pTension, pSelected =
  reaper.GetEnvelopePointEx(env, -1, point_idx)

  if (pTime > timeSnap and pTime < time) or (pTime < timeSnap and pTime > time) then
    timeSnap = time
  end
  
  local pointsNum = reaper.CountEnvelopePointsEx( env, -1 ) -1
  
  if point_idx > -1 and point_idx <= pointsNum then
      UnselectEnvPoints(env, -1)
      reaper.SetEnvelopePointEx( env, -1, point_idx, timeSnap, pValue, pShape, pTension, true, false )
      UndoString = 'FadeTool - move point'
  else
      UnselectEnvPoints(env, -1)
      _, pValue, _, _, _ = reaper.Envelope_Evaluate( env, timeSnap, 192000, 1 )
      --pShape = GetPrefs('defenvs') >> 16 
      pShape = tonumber(ExtractDefPointShape(env))
      reaper.InsertEnvelopePointEx( env, -1, timeSnap, pValue, pShape, 0, true, false )
      UndoString = 'FadeTool - create point'
  end
  
  return (timeSnap + itemPos)/takeRate
end

-----------------------------------------

function PointToMouse(env) --return time table with single point value
  local envItem = reaper.GetEnvelopeInfo_Value(env, 'P_ITEM')
  local retTimeT = {}
  
  if envItem ~= 0 then 
    if Opt.IgnoreLockingMouse == false and takeEnvLock == 1 then return end
    
    local item_mouse, itemHalf = GetTopBottomItemHalf()
    
    if envItem == item_mouse and itemHalf ~= 'header' then
      local mouse_time = reaper.BR_GetMouseCursorContext_Position()
      
      if itemHalf == 'top' then
        retTime = MovePoint(env, mouse_time, envItem, 'left')
      elseif itemHalf == 'bottom' then
        retTime = MovePoint(env, mouse_time, envItem, 'right')
      end
      
    end
    
  else -- if not envItem
     if Opt.IgnoreLockingMouse == false and envLock == 1 then return end
     local x,y = reaper.GetMousePosition()
     
     local OScoeff = 1
     if reaper.GetOS():match("^Win") == nil then OScoeff = -1 end
     
     local envYpos = reaper.GetEnvelopeInfo_Value( env, 'I_TCPY' )
     local envTrack = reaper.GetEnvelopeInfo_Value( env, 'P_TRACK' )
     local envTrackH = reaper.GetMediaTrackInfo_Value( envTrack, 'I_TCPH' )
     
     local envHbig = reaper.GetEnvelopeInfo_Value( env, 'I_TCPH' )
     local envH = reaper.GetEnvelopeInfo_Value( env, 'I_TCPH_USED' )
     local envPad = envHbig - envH
     local mouseEnv
     local testEnv
     
     local track
     local testTrack
     
     if envYpos < envTrackH then --env in media lane
       track, _ = reaper.GetThingFromPoint(x,y)
       local test_y = math.floor( y + (envTrackH/2 - envPad)*OScoeff )
       testTrack, _ = reaper.GetThingFromPoint(x, test_y )
     else --env in separate lane
       local test_y = math.floor( y + (envH/2 + envPad)*OScoeff )
       
       local track, info = reaper.GetThingFromPoint(x,y) 
       if info:match('envelope') == 'envelope' then
         mouseEnv = reaper.GetTrackEnvelope(track, info:match('%d+'))
       end
       
       track, info = reaper.GetThingFromPoint(x, test_y )
       if info:match('envelope') == 'envelope' then
         testEnv = reaper.GetTrackEnvelope(track, info:match('%d+'))
       end
     end
     
     
     local mouse_time = reaper.BR_GetMouseCursorContext_Position()
     
     if (env == mouseEnv and env == testEnv)
     or (envTrack == track and envTrack == testTrack) then --top half
     --msg('top')
       retTime = MovePoint(env, mouse_time, nil, 'left')
     elseif env == mouseEnv 
     or envTrack == track then -- bottom half
     --msg('bottom')
       retTime = MovePoint(env, mouse_time, nil, 'right')
     end --top/bottom
     
  end -- if not envItem

table.insert(retTimeT,retTime)
return retTimeT
end

----------------------------------------

function GetPrefs(key) -- key need to be string as in Reaper ini file
  local iniPath = reaper.get_ini_file()
  local value
  
  for line in io.lines(iniPath) do 
    if line:match(key) then 
      value = tonumber(line:gsub(key..'=',''):format("%.5f"))
    end
    
    if value then return value end
  end
end

----------------------------------------
----------------------------------------
function Main()

EcurInit = reaper.GetCursorPosition()
LOCKEDitems = {}
edgesLock = reaper.GetToggleCommandState(40597) --Locking: Toggle item edges locking mode
fadesLock = reaper.GetToggleCommandState(40600) --Locking: Toggle item fade/volume handles locking mode
envLock = reaper.GetToggleCommandState(40585) --Locking: Toggle track envelope locking mode
takeEnvLock = reaper.GetToggleCommandState(41851) --Locking: Toggle take envelope locking mode
fulliLock = reaper.GetToggleCommandState(40576) --Locking: Toggle full item locking mode

globalLock = reaper.GetToggleCommandState(1135) --Options: Toggle locking

trimContBehItems = reaper.GetToggleCommandState(41117) --Options: Trim content behind media items when editing
Grouping = reaper.GetToggleCommandState(1156) --Options: Toggle item grouping and track media/razor edit grouping

if trimContBehItems == 1 then
  reaper.Main_OnCommandEx(41121,0,0) --Options: Disable trim content behind media items when editing
end

if Opt.IgnoreLockingMouse == true then
  reaper.Main_OnCommandEx(40570,0,0) --Locking: Disable locking
end

if RazorEditSelectionExists() == true then
  reaper.Undo_BeginBlock2( 0 )
  reaper.PreventUIRefresh( 1 )
  sTime = FadeRazorEdits(GetRazorEdits())
  if not RunBatch then RestoreLockedItems() end
  if UndoString then return UndoString end
else
  local env = reaper.GetSelectedEnvelope(0) 
  
  if env then
    reaper.Undo_BeginBlock2( 0 )
    reaper.PreventUIRefresh( 1 )
    sTime = PointToMouse(env)
  end
  if UndoString then return UndoString end
  
  local item_mouse, itemHalf = GetTopBottomItemHalf()
  start_TS, end_TS = reaper.GetSet_LoopTimeRange2( 0, false, false, 0, 0, 0 )
  local startArrange, endArrange = reaper.GetSet_ArrangeView2( 0, false, 0, 0, 0, 0 )
  
  if item_mouse and (start_TS <= startArrange or end_TS >= endArrange) then start_TS = end_TS end
  
  if start_TS ~= end_TS and reaper.CountSelectedMediaItems(0)> 0 and UndoString == nil then
    reaper.Undo_BeginBlock2( 0 )
    reaper.PreventUIRefresh( 1 )
    sTime = FadeRazorEdits(GetTSandItems(start_TS, end_TS))
    if not RunBatch then RestoreLockedItems() end
    if UndoString ~= 'FadeTool - Batch fades/crossfades' and #sTime > 0 then
      UndoString = "FadeTool - time selection"
      return UndoString
    end 
  end
  
  if UndoString == nil then
    
    if item_mouse then --and (Opt.IgnoreLockingMouse == true or fadesLock == 0) then
      reaper.Undo_BeginBlock2( 0 )
      reaper.PreventUIRefresh( 1 )
      sTime = FadeToMouse(item_mouse, itemHalf)
      if Grouping == 1 then RestoreSelItems() end
      RestoreLockedItems()
      if UndoString then return UndoString end
    else
      local x,y = reaper.GetMousePosition()
      local track, info = reaper.GetThingFromPoint(x, y)
      
      if info:match('envelope') == 'envelope' then
        local env = reaper.GetTrackEnvelope(track, info:match('%d+'))
        reaper.Undo_BeginBlock2( 0 )
        reaper.PreventUIRefresh( 1 )
        sTime = PointToMouse(env)
        if UndoString then return UndoString end
      end -- if match envelope
      
    end --if item_mouse
  end -- if not UndoString
  
end

end --end of Main()

---------------------------

function get_script_path()
  local info = debug.getinfo(1,'S');
  local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  --script_path = script_path:gsub('[^/\\]*[/\\]*$','') --one level up
  return script_path
end

---------------------------
-----------START-----------
CurVers = 2.23
version = tonumber( reaper.GetExtState(ExtStateName, "version") )
if version ~= CurVers then
  if not version or version < 2.0 then
    HelloMessage()
  else reaper.ShowMessageBox('The script was updated to version '..CurVers ,'Fade tool',0)
  end
  reaper.SetExtState(ExtStateName, "version", CurVers, true)
  reaper.defer(function()end)
else
  if reaper.APIExists( 'BR_GetMouseCursorContext' ) ~= true then
    reaper.ShowMessageBox('Please, install SWS extension!', 'No SWS extension', 0)
    return
  end
  
  window, segment, details = reaper.BR_GetMouseCursorContext()
  --msg(window) msg(segment) msg(details)
  local tcpActIDstr = reaper.GetExtState(ExtStateName, 'TCPaction')
  local tcpActID
  
  OptDefaults = {}
  OptionsDefaults(OptDefaults)
  GetExtStates(OptDefaults)
  
  if window == 'transport' or window == 'mcp' then 
  --look for additional file
    local script_path = get_script_path() 
    local file = script_path .. 'az_Fade tool (work on context of mouse, razor or time selection)/'
    ..'az_Options window for az_Fade tool.lua'
    dofile(file)
    --ExternalOpen = true
    OptionsWindow(OptDefaults, 'Fade Tool Options')
  elseif window == 'tcp' and tcpActIDstr ~= '' then
    if tcpActIDstr:gsub('%d+', '') == '' then
      tcpActID = tonumber(tcpActIDstr) 
    elseif tcpActIDstr ~= '' then
      tcpActID = tonumber(reaper.NamedCommandLookup(tcpActIDstr))
    end
    reaper.Main_OnCommandEx(tcpActID,0,0)
  else
    Opt = {}
    SetOptGlobals(Opt, OptDefaults)
    UndoString = Main()
    
    if globalLock == 1 and not RunBatch then 
      reaper.Main_OnCommandEx(40569,0,0) --Locking: Enable locking
    end
    if trimContBehItems == 1 and not RunBatch then
      reaper.Main_OnCommandEx(41120,0,0) --Options: Enable trim content behind media items when editing
    end
    
    if UndoString ~= nil then --msg(UndoString)
      if sTime then MoveEditCursor(sTime) end 
      reaper.Undo_EndBlock2( 0, UndoString, -1 )
      reaper.UpdateArrange()
    else
      reaper.defer(function()end)
    end
  end
  
end
