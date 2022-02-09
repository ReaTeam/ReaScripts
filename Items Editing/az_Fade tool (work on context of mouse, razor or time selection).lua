-- @description Fade tool (work on context of mouse, razor or time selection)
-- @author AZ
-- @version 1.1
-- @changelog
--   -fixed some bugs
--   -added butch fades/crossfades
--   -added fixed lanes experimental support
-- @about
--   #Fade tool
--
--   - Use top/bottom mouse placement on the item to define what fade you need, in or out.
--
--     There is two ways that you can change in the User Area of the code.
--
--           Default is top / bottom - fadein / fadeout
--
--           Another is top / bottom - close edge fade / far edge fade
--
--   - Use razor edit area for fades and crossfades a pair of items.
--
--   - Use time selection with item selection. Such way you can crossfade items on different tracks.
--
--   - Also you can set both fades for item by selection it's middle part.
--
--   - Create batch fades / crossfades if there are more than 2 items selected.
--
--   - There is option (ON by default) to move edit cursor with offset before first fade. That allows you to listen changes immediately.
--
--   Script warns if non-midi items have too short source for creating crossfade and offer to loop source.
--
--
--   P.S. There is experimental support for fixed media lanes being in pre-release versions.

------USER AREA-------
moveEditCursor = true -- move cursor after fade set
curOffset = 1 -- offset between fade and edit cursor in sec
LRdefine = 2 -- 1 = cross define, based on close and far edge, 2 = top item half: fadein, bottom: fadeout
DefaultFade = 30 -- Default fade in ms
DefaultCrossFade = 30 -- Default crossfade in ms
DefCrossType = 1 -- 1 = pre-crossfade, 2 = centered crossfade
RespectExistingFades = "yes" --For default batch fades/crossfades
----------------------

function msg(value)
  reaper.ShowConsoleMsg(tostring(value)..'\n')
end

---------------------------------

function RazorEditSelectionExists()

    for i=0, reaper.CountTracks(0)-1 do

        local retval, x = reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0,i), "P_RAZOREDITS", "string", false)

        if x ~= "" then return true end

    end
    
    return false

end

-----------------------

function GetEnvelopePointsInRange(envelopeTrack, areaStart, areaEnd)
    local envelopePoints = {}

    for i = 1, reaper.CountEnvelopePoints(envelopeTrack) do
        local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(envelopeTrack, i - 1)

        if time >= areaStart and time <= areaEnd then --point is in range
            envelopePoints[#envelopePoints + 1] = {
                id = i-1 ,
                time = time,
                value = value,
                shape = shape,
                tension = tension,
                selected = selected
            }
        end
    end

    return envelopePoints
end


-----------------------

function GetItemsInRange(track, areaStart, areaEnd, areaTop, areaBottom)
    local items = {}
    local itemCount = reaper.CountTrackMediaItems(track)
    for k = 0, itemCount - 1 do 
        local item = reaper.GetTrackMediaItem(track, k)
        local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local itemEndPos = pos+length
        
        if areaBottom ~= nil then
          itemTop = reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_Y")
          itemBottom = itemTop + reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_H")
          --msg("area: "..tostring(areaTop).." "..tostring(areaBottom).."\n".."item: "..itemTop.." "..itemBottom.."\n\n")
        end

        --check if item is in area bounds
        if itemEndPos > areaStart and pos < areaEnd then
        
          if areaBottom and itemTop then
            if itemTop < areaBottom - 0.001 and itemBottom > areaTop + 0.001 then
              table.insert(items,item)
            end
          else
            table.insert(items,item)
          end
          
        end

    end --end for cycle

    return items
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

function GetRazorEdits()
    local NeedPerLane = true
    local trackCount = reaper.CountTracks(0)
    local areaMap = {}
    for i = 0, trackCount - 1 do
        local track = reaper.GetTrack(0, i)
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
                
                if not isEnvelope then
                --reaper.ShowConsoleMsg(areaTop.." "..areaBottom.."\n\n")
                    items = GetItemsInRange(track, areaStart, areaEnd, areaTop, areaBottom)
                else
                    envelope = reaper.GetTrackEnvelopeByChunkName(track, GUID:sub(2, -2))
                    local ret, envName = reaper.GetEnvelopeName(envelope)

                    envelopeName = envName
                    envelopePoints = GetEnvelopePointsInRange(envelope, areaStart, areaEnd)
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
                
                if not isEnvelope then
                    items = GetItemsInRange(track, areaStart, areaEnd)
                else
                    envelope = reaper.GetTrackEnvelopeByChunkName(track, GUID:sub(2, -2))
                    local ret, envName = reaper.GetEnvelopeName(envelope)
        
                    envelopeName = envName
                    envelopePoints = GetEnvelopePointsInRange(envelope, areaStart, areaEnd)
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

    return areaMap
end

--------------------------------

function SetCrossfade(Litem,Ritem,areaData)
  local Ltake = reaper.GetActiveTake(Litem)
  local Rtake = reaper.GetActiveTake(Ritem)
  local LiNewEnd
  local RiNewStart
  
  -----------Left item edges---------------
  local LiPos = reaper.GetMediaItemInfo_Value( Litem, "D_POSITION" )
  if reaper.GetMediaItemInfo_Value( Litem, "B_LOOPSRC" ) == 0 then
    local tOffs =  reaper.GetMediaItemTakeInfo_Value( Ltake, "D_STARTOFFS" )
    local source =  reaper.GetMediaItemTake_Source( Ltake )
    local srcLength, lengthIsQN = reaper.GetMediaSourceLength( source )
    local srcEnd = LiPos - tOffs + srcLength
    if lengthIsQN == true then --if take is midi
      srcEnd = areaData.areaEnd
    end
    LiNewEnd = math.min(srcEnd,areaData.areaEnd)
    reaper.BR_SetItemEdges(Litem, LiPos, LiNewEnd)
  else
    LiNewEnd = areaData.areaEnd
    reaper.BR_SetItemEdges(Litem, LiPos, LiNewEnd)
  end
  
  -----------Right item edges------------
  local RiPos = reaper.GetMediaItemInfo_Value( Ritem, "D_POSITION" )
  local RiEnd = RiPos + reaper.GetMediaItemInfo_Value( Ritem, "D_LENGTH" )
  if reaper.GetMediaItemInfo_Value( Ritem, "B_LOOPSRC" ) == 0 then
    local tOffs =  reaper.GetMediaItemTakeInfo_Value( Rtake, "D_STARTOFFS" )
    local source =  reaper.GetMediaItemTake_Source( Rtake )
    local srcLength, lengthIsQN = reaper.GetMediaSourceLength( source )
    local srcStart = RiPos - tOffs
    if lengthIsQN == true then --if take is midi
      srcStart = areaData.areaStart
    end
    RiNewStart = math.max(srcStart, areaData.areaStart)
    reaper.BR_SetItemEdges(Ritem, RiNewStart, RiEnd)
  else
    RiNewStart = areaData.areaStart
    reaper.BR_SetItemEdges(Ritem, RiNewStart, RiEnd)
  end
  ---------------------------------------
  
  
  -----------Chech is a gap between items--------
  if LiNewEnd and RiNewStart and LiNewEnd <= RiNewStart then
    local SourceMsg =
    "There is items pair with don't crossing sources.\n\nDo you want to loop their sources?"
    .."\nIf no there will be just longest fades."
    if reaper.ShowMessageBox(SourceMsg,"Fade tool",4) == 7 then
      SetFade(Litem, "out", LiNewEnd - areaData.areaStart )
      SetFade(Ritem, "in", areaData.areaEnd - RiNewStart)
    else
      reaper.SetMediaItemInfo_Value( Litem, "B_LOOPSRC", 1 )
      reaper.SetMediaItemInfo_Value( Ritem, "B_LOOPSRC", 1 )
      reaper.BR_SetItemEdges(Litem, LiPos, areaData.areaEnd)
      reaper.BR_SetItemEdges(Ritem, areaData.areaStart, RiEnd)
    end
  end
  
  
  ---------Is new fade------------
  if LiNewEnd and RiNewStart and LiNewEnd > RiNewStart then
    if reaper.GetMediaItemInfo_Value( Litem, "D_FADEOUTLEN_AUTO") == 0 then
      SetFade(Litem, "out", LiNewEnd - RiNewStart)
    end
    
    if reaper.GetMediaItemInfo_Value( Ritem, "D_FADEINLEN_AUTO") == 0 then
      SetFade(Ritem, "in", LiNewEnd - RiNewStart)
    end
  end
end

-----------------------

function FadeRazorEdits(razorEdits) --get table
    local areaItems = {}
    local fadeStartT = {}
    
    reaper.PreventUIRefresh(1)
    
    local state = reaper.GetToggleCommandState(40041) --Options: Toggle auto-crossfade on/off
    if state == 0 then
      reaper.Main_OnCommandEx(40041,0,0)
    end
    
    for i = 1, #razorEdits do
        local areaData = razorEdits[i]
        if not areaData.isEnvelope then
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
              
              if iPos_1 <= areaData.areaStart and itemEndPos_1 > areaData.areaStart and iPos_1 <= iPos_2 and
              iPos_2 < areaData.areaEnd and itemEndPos_2 >= areaData.areaEnd and itemEndPos_1 <= itemEndPos_2 then
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
            if #items == 2 and Litem and Ritem then
              UndoString = "Set crossfade in RE area"
                --create crossfade
                table.insert(fadeStartT, areaData.areaStart)
                SetCrossfade(Litem,Ritem,areaData)
                
                reaper.Main_OnCommandEx(42406, 0, 0)  --Clear RE area
                if start_TS ~= end_TS then
                  reaper.Main_OnCommandEx(40020, 0, 0)
                  --Time selection: Remove (unselect) time selection and loop points
                end
            end
            -------End of the 1st case-----------
            
            -------Other 3 cases-----------
            if #items == 1 then
              UndoString = "Set fade by RE area"
              if Ritem and Litem == nil then  --fade IN
                local item = items[1]
                local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
                SetFade(item, "in", areaData.areaEnd - iPos)
                table.insert(fadeStartT, iPos)
                
                reaper.Main_OnCommandEx(42406, 0, 0)  --Clear RE area
                if start_TS ~= end_TS then
                  reaper.Main_OnCommandEx(40020, 0, 0)
                  --Time selection: Remove (unselect) time selection and loop points
                end
              elseif Litem and Ritem == nil then -- fade OUT
                local item = items[1]
                local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
                local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
                SetFade(item, "out", iEnd - areaData.areaStart)
                table.insert(fadeStartT, areaData.areaStart)
                
                reaper.Main_OnCommandEx(42406, 0, 0)  --Clear RE area
                if start_TS ~= end_TS then
                  reaper.Main_OnCommandEx(40020, 0, 0)
                  --Time selection: Remove (unselect) time selection and loop points
                end
              elseif Litem == nil and Ritem == nil then -- fades on the rests
                local item = items[1]
                local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
                local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
                SetFade(item, "in", areaData.areaStart - iPos)
                SetFade(item, "out", iEnd - areaData.areaEnd)
                table.insert(fadeStartT, iPos)
                
                reaper.Main_OnCommandEx(42406, 0, 0)  --Clear RE area
                if start_TS ~= end_TS then
                  reaper.Main_OnCommandEx(40020, 0, 0)
                  --Time selection: Remove (unselect) time selection and loop points
                end
              end
            end
            
            ----------Batch default fades/crossfades-----------
            if (#items == 2 and (not Litem or not Ritem)) or #items > 2 then
            local done, str = reaper.GetUserInputs
            ( "Batch fades/crossfades", 4, "Fade ms,Crossfade ms,Pre-crossfade or centered,Respect existing fades",
            tostring(DefaultFade)..','..tostring(DefaultCrossFade)..','..tostring(DefCrossType)..
            ','..tostring(RespectExistingFades))
              if done == true then
                UndoString = "Batch default fades/crossfades"
                
                local ret = {}
                for s in str:gmatch('[^,]+')do
                  table.insert(ret, s)
                end
                DefaultFade = tonumber(ret[1])
                DefaultCrossFade = tonumber(ret[2])
                DefCrossType = tonumber(ret[3])
                RespectExistingFades = ret[4]
                
                local PrevEnd
                local PrevFout
                local AnyEdit
                
                for i, item in pairs(items) do
                  local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
                  local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
                  local iFin = reaper.GetMediaItemInfo_Value( item, "D_FADEINLEN" )
                  local iFout = reaper.GetMediaItemInfo_Value( item, "D_FADEOUTLEN" )
                  
                  if RespectExistingFades ~= "yes" then iFin = 0 iFout = 0 end
                  
                  if iPos >= areaData.areaStart then
                    if iPos == PrevEnd then
                      local crossStart, crossEnd
                      if DefCrossType == 1 then
                        crossStart = iPos - DefaultCrossFade/1000
                        crossEnd = iPos
                      else
                        crossStart = iPos - DefaultCrossFade/2000
                        crossEnd = iPos + DefaultCrossFade/2000
                      end
                      
                      local crossData = {
                        areaStart = crossStart,
                        areaEnd = crossEnd,
                      }
                      
                      if PrevFout == 0 and iFin == 0 then
                        SetCrossfade(items[i-1],item, crossData)
                        AnyEdit = 1
                      elseif PrevFout == 0 then
                        SetFade(items[i-1], "out", DefaultFade/1000)
                        AnyEdit = 1
                      elseif iFin == 0 then
                        SetFade(item, "in", DefaultFade/1000)
                        AnyEdit = 1
                      end
                      
                    elseif not PrevEnd or iPos > PrevEnd then
                      if iFin == 0 then
                        SetFade(item, "in", DefaultFade/1000)
                        AnyEdit = 1
                      end
                      if PrevFout == 0 then
                        SetFade(items[i-1], "out", DefaultFade/1000)
                        AnyEdit = 1
                      end
                    end
                    
                    if i == #items and iFout == 0 and iEnd <= areaData.areaEnd then --fadeout for the last item
                      SetFade(item, "out", DefaultFade/1000)
                      AnyEdit = 1
                    end
                  end
                  
                  PrevEnd = iEnd
                  PrevFout = iFout
                end
                
                if AnyEdit == nil then
                  reaper.defer(function()end)
                else
                  reaper.Main_OnCommandEx(42406, 0, 0)  --Clear RE area
                  if start_TS ~= end_TS then
                    reaper.Main_OnCommandEx(40020, 0, 0)
                    --Time selection: Remove (unselect) time selection and loop points
                  end
                end
                
              end
            end

        end
    end
    
    if state == 0 then
      reaper.Main_OnCommandEx(40041,0,0)  --Options: Toggle auto-crossfade on/off
    end
    reaper.PreventUIRefresh(-1)
    
    return fadeStartT
end

-----------------------------------

function SaveSelItemsByTracks(startTime, endTime) --- time optional
  local SI = {}
  local oldTrack
  
  for i=0, reaper.CountSelectedMediaItems(0) -1 do
    local TData = {Tname, Titems={} }
    local item = reaper.GetSelectedMediaItem(0,i)
    local iTrack = reaper.GetMediaItemTrack(item)
    
    if startTime and endTime then --is item in range
      local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
      if iPos < endTime and iEnd > startTime then
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

  return SI
end

--------------------------------

function GetTSandItems(start_TS, end_TS)
  local areaMap = {}
  local items = {}
  
  if reaper.CountSelectedMediaItems(0) == 2 then
    local item_1 = reaper.GetSelectedMediaItem(0,0)
    local item_2 = reaper.GetSelectedMediaItem(0,1)

    local iPos_1 = reaper.GetMediaItemInfo_Value(item_1, "D_POSITION")
    local itemEndPos_1 = iPos_1+reaper.GetMediaItemInfo_Value(item_1, "D_LENGTH")
    local iPos_2 = reaper.GetMediaItemInfo_Value(item_2, "D_POSITION")
    local itemEndPos_2 = iPos_2+reaper.GetMediaItemInfo_Value(item_2, "D_LENGTH")
    
    if iPos_1 <= start_TS and itemEndPos_1 > start_TS and iPos_1 < iPos_2 and
    iPos_2 < end_TS and itemEndPos_2 >= end_TS and itemEndPos_1 < itemEndPos_2 then
      items[1] = item_1
      items[2] = item_2
    elseif iPos_2 <= start_TS and itemEndPos_2 >start_TS and iPos_2 < iPos_1 and
    iPos_1 < end_TS and itemEndPos_1 >= end_TS and itemEndPos_2 < itemEndPos_1 then
      items[1] = item_2
      items[2] = item_1
    end
    
    if #items == 2 then
      local areaData = {
          areaStart = start_TS,
          areaEnd = end_TS,
          
          items = items,
      }
      
      table.insert(areaMap, areaData)
    else
      local SI = SaveSelItemsByTracks(start_TS, end_TS)
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
      
      if #SI == 0 then
        local areaData = {
            areaStart = start_TS,
            areaEnd = end_TS,
            
            track,
            items = {},
        }
        
        table.insert(areaMap, areaData)
      end
    end
  else --if not 2 items selected
    local SI = SaveSelItemsByTracks(start_TS, end_TS)
    
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
    
    if #SI == 0 then
      local areaData = {
          areaStart = start_TS,
          areaEnd = end_TS,
          
          track,
          items = {},
      }
      
      table.insert(areaMap, areaData)
    end
  end
  
  return areaMap
end


-----------------------------------
-----------------------------------

function GetTopBottomItemHalf()
local window, segment, details = reaper.BR_GetMouseCursorContext()
local x, y = reaper.GetMousePosition()
--reaper.ShowConsoleMsg("y position "..y.."\n")

local item_under_mouse = reaper.BR_GetMouseCursorContext_Item()

if item_under_mouse then
  local item_h = reaper.GetMediaItemInfo_Value( item_under_mouse, "I_LASTH" )
  local OScoeff = 1
  if reaper.GetOS():match("^Win") == nil then
    OScoeff = -1
  end
  --reaper.ShowConsoleMsg("item_h = "..item_h.."\n")
  
  local test_point = math.floor( y + item_h/2 *OScoeff)
  
  local test_item, take = reaper.GetItemFromPoint( x, test_point, true )
  
  if item_under_mouse ~= test_item then
    return "bottom"
  else
    return "top"
  end
else return "no item" end

end

------------------------------

function SetFade(item, f_type, f_size, shape ) -- returns fadeStartEdge
  if not item then return end

  if f_type == "in" then
    
    local InitOutFade = reaper.GetMediaItemInfo_Value( item, "D_FADEOUTLEN" )
    local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    if InitOutFade ~= 0 then
     local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
     local fEdge = iPos + f_size
      if fEdge > iEnd - InitOutFade then
      reaper.SetMediaItemInfo_Value( item, "D_FADEOUTLEN", iEnd - fEdge )
      end
    end
    
   reaper.SetMediaItemInfo_Value( item, "D_FADEINLEN", f_size )
   return iPos
    
  elseif f_type == "out" then
  
    local InitInFade = reaper.GetMediaItemInfo_Value( item, "D_FADEINLEN" )
    local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
    local fEdge = iEnd - f_size
    if InitInFade ~= 0 then
      if fEdge < iPos + InitInFade then
        reaper.SetMediaItemInfo_Value( item, "D_FADEINLEN", fEdge - iPos )
      end
    end
    
    reaper.SetMediaItemInfo_Value( item, "D_FADEOUTLEN", f_size )
    return fEdge
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

function WhatFade(half, i_pos, i_end, mPos)
  local f_type, f_size
  
  if LRdefine == 1 then --cross define
    if half == "top" then
      if (i_end - mPos) <= (mPos - i_pos) then
        f_type = "out"
        f_size = i_end - mPos
      else
        f_type = "in"
        f_size = mPos - i_pos
      end
    elseif half == "bottom" then
      if (i_end - mPos) > (mPos - i_pos) then
        f_type = "out"
        f_size = i_end - mPos
      else
        f_type = "in"
        f_size = mPos - i_pos
      end
    end
  elseif LRdefine == 2 then
    if half == "top" then
      f_type = "in"
      f_size = mPos - i_pos
    elseif half == "bottom" then
      f_type = "out"
      f_size = i_end - mPos
    end
  end
  return f_type, f_size
end

----------------------------

function FadeToMouse()
  local mPos = reaper.SnapToGrid(0,reaper.BR_GetMouseCursorContext_Position())
  local fadeStartT = {}
  
  local i_pos = reaper.GetMediaItemInfo_Value(item_mouse, "D_POSITION")
  local i_end = i_pos + reaper.GetMediaItemInfo_Value(item_mouse, "D_LENGTH")
  local f_type = "in"
  local half = GetTopBottomItemHalf()
  f_type, f_size = WhatFade(half, i_pos, i_end, mPos)
 
  if reaper.IsMediaItemSelected(item_mouse) == false then
    local fadeStartEdge = SetFade(item_mouse, f_type, f_size) -- item, "in"/"out" f_type, f_size, (shape)
    table.insert(fadeStartT, fadeStartEdge)
  else
    for i=0, reaper.CountSelectedMediaItems(0) - 1 do
      local item = reaper.GetSelectedMediaItem(0,i)
      local fadeStartEdge = SetFade(item, f_type, f_size) -- item, "in"/"out" f_type, f_size, (shape)
      table.insert(fadeStartT, fadeStartEdge)
    end
  end
  
  return fadeStartT
end

------------------------------------------

function MoveEditCursor(timeTable)
  if #timeTable > 0 then
    local fadeStartEdge = math.min(table.unpack(timeTable))
    if moveEditCursor == true then
      reaper.SetEditCurPos2(0, fadeStartEdge - curOffset, false, false)
    end
  end
end

-----------START-----------
if RazorEditSelectionExists() == true then
  reaper.Undo_BeginBlock2( 0 )
  reaper.PreventUIRefresh( 1 )
  sTime = FadeRazorEdits(GetRazorEdits())
  MoveEditCursor(sTime)
  if UndoString then
    reaper.Undo_EndBlock2( 0, UndoString, -1 )
    reaper.UpdateArrange()
  else reaper.defer(function()end) end
else
  start_TS, end_TS = reaper.GetSet_LoopTimeRange2( 0, false, false, 0, 0, 0 )
  if start_TS ~= end_TS then
    reaper.Undo_BeginBlock2( 0 )
    reaper.PreventUIRefresh( 1 )
    sTime = FadeRazorEdits(GetTSandItems(start_TS, end_TS))
    MoveEditCursor(sTime)
    reaper.Undo_EndBlock2( 0, "Fades in Time selection", -1 )
    reaper.UpdateArrange()
  else
    window, segment, details = reaper.BR_GetMouseCursorContext()
    item_mouse = reaper.BR_GetMouseCursorContext_Item()
    
    if item_mouse then
      reaper.Undo_BeginBlock2( 0 )
      reaper.PreventUIRefresh( 1 )
      sTime = FadeToMouse()
      MoveEditCursor(sTime)
      reaper.PreventUIRefresh( -1 )
      reaper.Undo_EndBlock2( 0, "Set fade to mouse", -1 )
      reaper.UpdateArrange()
    else
      reaper.defer(function()end)
    end
  end
end
