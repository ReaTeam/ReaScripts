-- @description Fade tool (work on context of mouse, razor or time selection)
-- @author AZ
-- @version 1.0
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
--   Also you can set both fades for item by selection it's middle.
--
--   Script warns if non-midi items have too short source for creating crossfade and offer to loop source.

------USER AREA-------
moveEditCursor = true -- moves cursor after fade set
curOffset = 1 -- offset between fade and edit cursor in sec
LRdefine = 2 -- 1 = cross define, based on close and far edge, 2 = top item half - fadein, bottom = fadeout
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
          --reaper.ShowConsoleMsg("area: "..tostring(areaTop).." "..tostring(areaBottom).."\n".."item: "..itemTop.." "..itemBottom.."\n\n")
        end

        --check if item is in area bounds
        if itemEndPos > areaStart and pos < areaEnd then
        
          if itemTop then
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

function GetRazorEdits()
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
        
            --FILL AREA DATA
            local i = 1
            
            local prev_areaStart = nil
            local prev_areaEnd = nil
            local prev_GUID = nil
            local prev_areaTop = nil
            local prev_areaBottom = nil
            
            while i <= #TRstr do
                --area data
                local areaStart = tonumber(TRstr[i][1])
                local areaEnd = tonumber(TRstr[i][2])
                local GUID = TRstr[i][3]
                local areaTop = tonumber(TRstr[i][4])
                local areaBottom = tonumber(TRstr[i][5])
                local isEnvelope = GUID ~= '""'
                
                if areaStart == prev_areaEnd and
                ( prev_areaBottom > areaTop >= prev_areaTop or prev_areaTop < areaBottom <= prev_areaBottom ) then
                  TRstr[i-1][2] = areaEnd
                  break
                end

                --get item/envelope data
                local items = {}
                local envelopeName, envelope
                local envelopePoints
                
                if not isEnvelope then
                --reaper.ShowConsoleMsg(areaTop.." "..areaBottom.."\n\n")
                    items, Litem, Ritem = GetItemsInRange(track, areaStart, areaEnd, areaTop, areaBottom)
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
                    items, Litem, Ritem = GetItemsInRange(track, areaStart, areaEnd)
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

-----------------------

function FadeRazorEdits(razorEdits) --get table
    local areaItems = {}
    local tracks = {}  --it seems no matter
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
            
           --[[ --recalculate item data for tracks with previous splits
            if tracks[areaData.track] ~= nil then
            msg("recalc")
              if areaData.areaTop then
                items= GetItemsInRange(areaData.track, areaData.areaStart, areaData.areaEnd, areaData.areaTop, areaData.areaBottom)
              else
                items= GetItemsInRange(areaData.track, areaData.areaStart, areaData.areaEnd)
              end
            end]]
            
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
                --create crossfade
                table.insert(fadeStartT, areaData.areaStart)
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
                    --local timesig_num, timesig_denom, tempo = reaper.TimeMap_GetTimeSigAtTime( 0, LiPos - tOffs )
                    --srcEnd = LiPos - tOffs + 60/tempo *srcLength
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
                if LiNewEnd and RiNewStart and LiNewEnd < RiNewStart then
                  local SourceMsg =
                  "There is items pair with don't crossing sources.\n\nDo you want to loop their source?"
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
                
                ---------Create fades for midi items cause they have no auto crossfades--------
                if reaper.TakeIsMIDI( Ltake ) == true then
                  SetFade(Litem, "out", LiNewEnd - RiNewStart )
                end
                if reaper.TakeIsMIDI( Rtake ) == true then
                  SetFade(Ritem, "in", LiNewEnd - RiNewStart)
                end
                
                reaper.Main_OnCommandEx(42406, 0, 0)  --Clear RE area
            end
            -------End of the 1st case-----------
            
            -------Other 3 cases-----------
            if #items == 1 then
              if Ritem and Litem == nil then  --fade IN
                local item = items[1]
                local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
                SetFade(item, "in", areaData.areaEnd - iPos)
                table.insert(fadeStartT, iPos)
                reaper.Main_OnCommandEx(42406, 0, 0)  --Clear RE area
              elseif Litem and Ritem == nil then -- fade OUT
                local item = items[1]
                local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
                local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
                SetFade(item, "out", iEnd - areaData.areaStart)
                table.insert(fadeStartT, areaData.areaStart)
                reaper.Main_OnCommandEx(42406, 0, 0)  --Clear RE area
              elseif Litem == nil and Ritem == nil then -- fades on the rests
                local item = items[1]
                local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
                local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
                SetFade(item, "in", areaData.areaStart - iPos)
                SetFade(item, "out", iEnd - areaData.areaEnd)
                table.insert(fadeStartT, iPos)
                reaper.Main_OnCommandEx(42406, 0, 0)  --Clear RE area
              end
            end

           -- tracks[areaData.track] = 1
        end
    end
    
    if state == 0 then
      reaper.Main_OnCommandEx(40041,0,0)  --Options: Toggle auto-crossfade on/off
    end
    reaper.PreventUIRefresh(-1)
    
    return fadeStartT
    --return areaItems
end

-----------------------------------

function GetTSandItems(start_TS, end_TS)
  local areaMap = {}
  local items = {}
  
  for i=0, reaper.CountSelectedMediaItems(0) -1 do
    table.insert(items, reaper.GetSelectedMediaItem(0,i))
  end
  
  local areaData = {
      areaStart = start_TS,
      areaEnd = end_TS,
      
      --track = track,
      items = items,
      
  }
  table.insert(areaMap, areaData)
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
  --local iCount = reaper.CountMediaItems(0)
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
  reaper.Undo_EndBlock2( 0, "Fades in RE area", -1 )
  reaper.UpdateArrange()
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
