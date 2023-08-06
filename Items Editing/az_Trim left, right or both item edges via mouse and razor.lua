-- @description Trim left, right or both item edges via mouse and razor
-- @author AZ
-- @version 1.1
-- @changelog -bug fix: treat several selected items
-- @link Autor's page https://forum.cockos.com/member.php?u=135221
-- @about
--   #Trim left, right or both item edges via mouse and razor
--
--   Use vertical mouse position to trim left or right (top/bottom item half)
--   Use razor to trim items at both sides.
--
--   Look at options in user area of the code. (just this simplest way for a while)

----------------------------
--------USER OPTIONS--------

RespectGrouping = true
razorRespectGrouping = false
Select_Items_After_Razor_trim = false
-----------------------
-----------------------

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
    local itemTop, itemBottom
    
    for k = 0, itemCount - 1 do 
        local item = reaper.GetTrackMediaItem(track, k)
        local lock = reaper.GetMediaItemInfo_Value(item, "C_LOCK")
        
        if lock ~= 1 then
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
        end -- if lock
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
            
            local TRareaTable
            if NeedPerLane == true then
              --msg(#TRstr)
              local AreaParsed = ParseAreaPerLane(TRstr, testItemH)
              --msg(#AreaParsed)
              TRareaTable = AreaParsed
            else TRareaTable = TRstr end
        
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
                    if #items > 0 then AnythingForSplit = true end
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
                    if #items > 0 then AnythingForSplit = true end
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

function TrimRazorEdits(razorEdits)
    local areaItems = {}
    local tracks = {}
    local SplitsT = {}
    local GrState = reaper.GetToggleCommandState(1156) --Options: Toggle item grouping override
    
    if AnythingForSplit == true then
      reaper.Undo_BeginBlock2( 0 )
      reaper.PreventUIRefresh(1)
      
      reaper.SelectAllMediaItems(0, false)
      
      for i = 1, #razorEdits do
        local areaData = razorEdits[i]
        if not areaData.isEnvelope then
            local items = areaData.items
            
            for j = 1, #items do
              local item = items[j]
              reaper.SetMediaItemSelected(item, true)
            end
            
            if razorRespectGrouping == true and GrState == 1 then
              reaper.Main_OnCommandEx(40034,0,0) --Item grouping: Select all items in groups
            end
            
            trim_sel_items('right', areaData.areaEnd)
            trim_sel_items('left', areaData.areaStart)
            
            for i=1, reaper.CountSelectedMediaItems(0) do
              table.insert(areaItems, reaper.GetSelectedMediaItem(0, i-1))
            end
            table.insert(SplitsT, areaData.areaStart)
         end
      end
              
    --reaper.SetEditCurPos(cur_pos, false, false)
    reaper.PreventUIRefresh(-1)
  end --if AnythingForSplit
    
    return areaItems, SplitsT
end

-----------------------------------

function trim_byRE_andSel()
  SaveSelItems()
  local selections = GetRazorEdits()
  local items, SplitsT = TrimRazorEdits(selections)
  
  if #items > 0 then
    reaper.PreventUIRefresh( 1 )
    if Select_Items_After_Razor_trim == true then
      for i = 1, #items do
        local item = items[i]
        reaper.SetMediaItemSelected(item, true)
        reaper.Main_OnCommandEx(42406, 0, 0) --clear RE area
      end
    else
      reaper.Main_OnCommandEx(42406, 0, 0) --clear RE area
      RestoreSelItems()
    end
    
    reaper.PreventUIRefresh( -1 )
    reaper.Undo_EndBlock2( 0, "Trim at razor edit", -1 )
  else
    reaper.defer(function()end)
  end

end


-----------------------------------
-----------------------------------

--------------------------------
---------------------------------

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

function GetDefFades()
  local iniPath = reaper.get_ini_file()
  local fadeLen
  local fadeShape
  
  for line in io.lines(iniPath) do 
    if line:match('deffadelen') then 
      fadeLen = tonumber(line:gsub('deffadelen=',''):format("%.5f"))
    end
    
    if line:match('deffadeshape') then 
      fadeShape = tonumber(line:gsub('deffadeshape=',''):format("%.5f"))
    end
    
    if fadeLen and fadeShape then return fadeLen, fadeShape end
  end
end


-----------------------------------------
--------------------------------------------


function trim_sel_items(side, trimTime)
local undoDesc
local iCount = reaper.CountSelectedMediaItems(0)

local defFlen, defFshape = GetDefFades()

for i=0, iCount-1 do
  local item = reaper.GetSelectedMediaItem(0,i)
  
  local iPos = reaper.GetMediaItemInfo_Value(item,'D_POSITION')
  local iEnd = iPos + reaper.GetMediaItemInfo_Value(item,'D_LENGTH')
  local fIn = reaper.GetMediaItemInfo_Value(item,'D_FADEINLEN')
  local fOut = reaper.GetMediaItemInfo_Value(item,'D_FADEOUTLEN')
  local fInShape = reaper.GetMediaItemInfo_Value(item,'C_FADEINSHAPE')
  local fOutShape = reaper.GetMediaItemInfo_Value(item,'C_FADEOUTSHAPE')
  local fInCurv = reaper.GetMediaItemInfo_Value(item,'D_FADEINDIR')
  local fOutCurv = reaper.GetMediaItemInfo_Value(item,'D_FADEOUTDIR')
  
  if iPos < trimTime and trimTime < iEnd then
  
    if side == 'left' then
      reaper.BR_SetItemEdges(item, trimTime, iEnd)
      undoDesc = 'left'
      
      if trimTime < iPos+fIn then
        reaper.SetMediaItemInfo_Value(item,'D_FADEINLEN', fIn-(trimTime-iPos))
        reaper.SetMediaItemInfo_Value(item,'C_FADEINSHAPE', fInShape)
        reaper.SetMediaItemInfo_Value(item,'D_FADEINDIR', fInCurv)
      else
        if reaper.GetToggleCommandState(41194) == 1 then fIn = defFlen else fIn = 0 end
        --^^--Item: Toggle enable/disable default fadein/fadeout
        reaper.SetMediaItemInfo_Value(item,'D_FADEINLEN', fIn)
        reaper.SetMediaItemInfo_Value(item,'C_FADEINSHAPE', defFshape)
        --reaper.SetMediaItemInfo_Value(item,'D_FADEINDIR', defFshape)
      end
      
    elseif side == 'right' then
      reaper.BR_SetItemEdges(item, iPos, trimTime)
      undoDesc = 'right'
      
      if trimTime > iEnd-fOut then
        reaper.SetMediaItemInfo_Value(item,'D_FADEOUTLEN', fOut-(iEnd-trimTime))
        reaper.SetMediaItemInfo_Value(item,'C_FADEOUTSHAPE', fOutShape)
        reaper.SetMediaItemInfo_Value(item,'D_FADEOUTDIR', fOutCurv)
      else
        if reaper.GetToggleCommandState(41194) == 1 then fOut = defFlen else fOut = 0 end
        --^^--Item: Toggle enable/disable default fadein/fadeout
        reaper.SetMediaItemInfo_Value(item,'D_FADEOUTLEN', fOut)
        reaper.SetMediaItemInfo_Value(item,'C_FADEOUTSHAPE', defFshape)
        --reaper.SetMediaItemInfo_Value(item,'D_FADEOUTDIR', defFshape)
      end
    end --left/right
    
  end --if cur_pos
end --for

return undoDesc
end


-----------------------------------------
--------------------------------------------

function MouseTrim()
 
  local item, half = GetTopBottomItemHalf()
  
  if half == "header" or not item then  --if mouse cursor not on the item
    reaper.defer(function() end)
  end
  
  if item and half ~= "header" then
    reaper.Undo_BeginBlock2( 0 )
    reaper.PreventUIRefresh( 1 )
    
    _, _, _ = reaper.BR_GetMouseCursorContext()
    local trimTime = reaper.SnapToGrid(0,reaper.BR_GetMouseCursorContext_Position())
    GroupEnabled = reaper.GetToggleCommandState(1156) --Options: Toggle item grouping override
    
    SaveSelItems()
    
    if reaper.IsMediaItemSelected(item) == false then
      reaper.SelectAllMediaItems( 0, false )
      reaper.SetMediaItemSelected(item, true)
    end
    
    if RespectGrouping == true and GroupEnabled == 1 then
      reaper.Main_OnCommandEx(40034,0,0) --Item grouping: Select all items in groups
    end
    
    local side
    if half == 'top' then side = 'left' elseif half == 'bottom' then side = 'right' end
    
    undoType = trim_sel_items(side, trimTime)
    
    RestoreSelItems()
    reaper.PreventUIRefresh( -1 )
    reaper.Undo_EndBlock2( 0, "Trim "..undoType.." edge of items under mouse", -1 )
 
  end
end

-----------------------------------------------

------Start-------
if RazorEditSelectionExists() == true then
  trim_byRE_andSel()
else
  MouseTrim()
end
