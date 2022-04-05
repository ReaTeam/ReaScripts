-- @description Smart split items by mouse cursor
-- @author AZ
-- @version 2.4
-- @changelog
--   Fixed bugs with left/right selection.
--
--   Added in-code options:
--   - to move edit cursor after splitting
--   - to prefer split selected items at edit cursor
--   - respect grouping on razor split
--
--   Added experimental fixed lanes support
-- @link Forum thread https://forum.cockos.com/showthread.php?t=259751
-- @about
--   # Smart split items by mouse cursor
--
--   Forum thread: https://forum.cockos.com/showthread.php?t=259751
--
--   Split items respect grouping, depend on context of mouse cursor, split at razor edit or time selection if exist, split at mouse or edit cursor otherwise.
--
--   There are options in the user area of code:
--   - to switch off time selection
--   - to move edit cursor after splitting
--   - to prefer split selected items at edit cursor
--   (that allows use mouse placement for left/right selecting)
--   - respect grouping on razor split
--
--   Also there is experimental  fixed lanes support
--
--   Thanks BirdBird for razor edit functions.
--   https://forum.cockos.com/showthread.php?t=241604&highlight=razor+edit+scripts


-----------------------------
----------USER AREA----------
use_TS_sel_Items = true -- Could selected items be splitted by TS or not.
use_TS_all = true       -- Use Time selection or not in all cases.

eCurPriority = false     -- Edit cursor have piority against mouse on selected item.

moveEditCursor = true -- moves cursor after splitting if mouse is on item and not recording
curOffset = 1 -- offset between fade and edit cursor in sec
editCurDistance = 4
--^^ If edit cursor placed before the split within the limits of this value it will not moved.

razorRespectGrouping = false -- Allow select by razor only one item of group to split all.
-----------------------------
-----------------------------


--FUNCTIONS--

function msg(value)
  reaper.ShowConsoleMsg(tostring(value)..'\n')
end

-------------------------

function MoveEditCursor(timeTable, EditCurPos)
  if #timeTable > 0 then
    local timepos = math.min(table.unpack(timeTable))
    local recState = reaper.GetToggleCommandState(1013)
    
    if moveEditCursor == true
    and (timepos - EditCurPos > editCurDistance or timepos -0.2 <= EditCurPos)
    --^^here small coeff to avoid extra small distance
    and recState == 0 then
      reaper.SetEditCurPos2(0, timepos - curOffset, false, false)
    end
  end
end

----------------------------------
----------------------------------

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

function SplitRazorEdits(razorEdits)
    local areaItems = {}
    local tracks = {}
    local SplitsT = {}
    local GrState = reaper.GetToggleCommandState(1156) --Options: Toggle item grouping override
    
    if AnythingForSplit == true then
      reaper.Undo_BeginBlock2( 0 )
      reaper.PreventUIRefresh(1)
      for i = 1, #razorEdits do
        local areaData = razorEdits[i]
        if not areaData.isEnvelope then
            local items = areaData.items
            
            --recalculate item data for tracks with previous splits
            --[[
            if tracks[areaData.track] ~= nil then --msg(tracks[areaData.track])
                items = GetItemsInRange(areaData.track, areaData.areaStart, areaData.areaEnd)
            end ]]
            
            for j = 1, #items do 
              local item = items[j]
              --split items
              if razorRespectGrouping == true and GrState == 1 then
                reaper.SelectAllMediaItems(0, false)
                reaper.SetMediaItemSelected(item, true)
                
                reaper.SetEditCurPos(areaData.areaStart, false, false)
                reaper.Main_OnCommandEx( 40759, 0, 0 ) -- split items under edit cursor (select right)
                
                reaper.SetEditCurPos(areaData.areaEnd, false, false)
                reaper.Main_OnCommandEx( 40758, 0, 0 ) -- split items under edit cursor (select left)
                
                for i=0,reaper.CountSelectedMediaItems(0) do
                  local selItem = reaper.GetSelectedMediaItem(0,i)
                  table.insert(areaItems, selItem)
                end
                reaper.SelectAllMediaItems(0, false)
              else
                local newItem = reaper.SplitMediaItem(item, areaData.areaStart)
                if newItem == nil then
                    reaper.SplitMediaItem(item, areaData.areaEnd)
                    table.insert(areaItems, item)
                    table.insert(SplitsT, areaData.areaEnd)
                else
                    reaper.SplitMediaItem(newItem, areaData.areaEnd)
                    table.insert(areaItems, newItem)
                    table.insert(SplitsT, areaData.areaStart)
                end
              end
              
            end --end for
            --tracks[areaData.track] = 1
        end --if not is envelope
    end  --end for
    reaper.SetEditCurPos(cur_pos, false, false)
    reaper.PreventUIRefresh(-1)
  end --AnythingForSplit
    
    return areaItems, SplitsT
end

-----------------------------------

function split_byRE_andSel()
  local selections = GetRazorEdits()
  local items, SplitsT = SplitRazorEdits(selections)
  
  if #items > 0 then
    --reaper.Undo_BeginBlock2( 0 )
    reaper.PreventUIRefresh( 1 )
    for i = 1, #items do
      local item = items[i]
      reaper.SetMediaItemSelected(item, true)
      reaper.Main_OnCommandEx(42406, 0, 0)
    end
    MoveEditCursor(SplitsT, cur_pos)
    reaper.PreventUIRefresh( -1 )
    reaper.Undo_EndBlock2( 0, "Split at razor edit", -1 )
  else
    reaper.defer(function()end)
  end

end


-----------------------------------
-----------------------------------


function is_item_crossTS ()
local splitTime

if itemend <= start_pos or
itempos >= end_pos or
(itempos >= start_pos and itemend <= end_pos) or
use_TS_sel_Items == false then

else
  crossTS=1
  if itemend > start_pos and itempos < start_pos then splitTime = start_pos end
  if splitTime == nil and itemend > end_pos and itempos < end_pos then splitTime = end_pos end
end

return splitTime
end

            
-----------------------------------------
--------------------------------------------


function split_by_edit_cursor_or_TS()
  local SplitsT = {}
  local splitTime
  
if TSexist==0 then  --if TS doesn't exist
  if mouse_cur_pos <= cur_pos and eCurPriority == true then
    reaper.Main_OnCommandEx( 40758, 0, 0 ) -- split items under edit cursor (select left)
  else
    reaper.Main_OnCommandEx( 40759, 0, 0 ) -- 40758 split items under edit cursor (select right)
  end
  if reaper.CountSelectedMediaItems(0) ~= 0 then
    splitTime = reaper.GetCursorPosition()
  else
    reaper.defer(function()end)
  end
else
  crossTS=0
  
  if itemsNUMB == -1 then --if no one item selected
   reaper.Main_OnCommandEx(  40061, 0, 0 ) -- split at TS
  else
    --if any items selected here is need to check crosses with TS
    
    if item then 
       --item under mouse sec position to decide where is item crossed by TS--
      itempos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      itemlen = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" ) 
      itemend = itempos + itemlen
      splitTime = is_item_crossTS()
    else

      for i= 0, itemsNUMB do
      
        local selItem = reaper.GetSelectedMediaItem( 0, i ) --zero based
        --item sec position to decide where is sel item crossed by TS--
        itempos = reaper.GetMediaItemInfo_Value( selItem, "D_POSITION" )
        itemlen = reaper.GetMediaItemInfo_Value( selItem, "D_LENGTH" ) 
        itemend = itempos + itemlen
        
        splitTime = is_item_crossTS()
        if splitTime then table.insert(SplitsT, splitTime) end
      end
    end
  
    if crossTS==0 then
      if mouse_cur_pos <= cur_pos and eCurPriority == true then
        reaper.Main_OnCommandEx( 40758, 0, 0 ) -- split items under edit cursor (select left)
      else
        reaper.Main_OnCommandEx( 40759, 0, 0 ) -- 40758 split items under edit cursor (select right)
      end

       splitTime = reaper.GetCursorPosition()
    else
      reaper.Undo_BeginBlock2( 0 )
      reaper.PreventUIRefresh( 1 )
      
      reaper.Main_OnCommandEx(  40061, 0, 0 ) -- split at TS
      reaper.Main_OnCommandEx( 40635, 0, 0 )  -- Time selection: Remove time selection
      --MoveEditCursor(SplitsT, cur_pos)
      
      reaper.PreventUIRefresh( -1 )
      reaper.Undo_EndBlock2( 0, "Split items at time selection", -1 )
    end 
  end
end
if splitTime then table.insert(SplitsT, splitTime) end
return SplitsT
end


-----------------------------------------
--------------------------------------------


function split_not_sel_item()

reaper.Main_OnCommandEx( 40289, 0, 0 ) -- unselect all items
reaper.SetMediaItemSelected( item, 1 ) -- select founded item under mouse
reaper.Main_OnCommandEx( 40513, 0, 0 ) -- View: Move edit cursor to mouse cursor

reaper.Main_OnCommandEx(  40759, 0, 0 ) -- CENTRAL FUNCTION split items under edit cursor (select right)

reaper.SetEditCurPos(cur_pos, false, false)
MoveEditCursor({mouse_cur_pos}, cur_pos)

end



-----------------------------------------
--------------------------------------------



function split_sel_item()

local eCurSplit

if eCurPriority == true then
  local selectSide
  for i=0, itemsNUMB do
    local item = reaper.GetSelectedMediaItem(0,itemsNUMB)
    local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
    
    if iPos < cur_pos and cur_pos < iEnd then eCurSplit = true end
  end
end

if eCurSplit == true then
   --CENTRAL FUNCTION
  MoveEditCursor(split_by_edit_cursor_or_TS(), cur_pos)
else
  reaper.Main_OnCommandEx( 40513, 0, 0 ) -- View: Move edit cursor to mouse cursor
  local splitpoints = split_by_edit_cursor_or_TS() --CENTRAL FUNCTION
  reaper.SetEditCurPos(cur_pos, false, false)
  MoveEditCursor(splitpoints, cur_pos)
end

end



-----------------------------------------
--------------------------------------------


function split_automation_item()

if TSexist == 1 then
  reaper.SetEditCurPos(start_pos, false, false)
  reaper.Main_OnCommandEx( 42087, 0, 0 ) -- Envelope: Split automation items
  --
  reaper.SetEditCurPos(end_pos, false, false)
  reaper.Main_OnCommandEx( 42087, 0, 0 ) -- Envelope: Split automation items
  
  reaper.SetEditCurPos(cur_pos, false, false)
else
  reaper.Main_OnCommandEx( 40513, 0, 0 ) -- View: Move edit cursor to mouse cursor
  reaper.Main_OnCommandEx( 42087, 0, 0 ) -- Envelope: Split automation items
  reaper.SetEditCurPos(cur_pos, false, false)
end

end



-----------------------------------------
--------------------------------------------



function unsel_automation_Items()
  for t=0, reaper.CountTracks(0)-1 do
    local tr = reaper.GetTrack(0,t)
    for e=0, reaper.CountTrackEnvelopes( tr ) -1 do
      local env = reaper.GetTrackEnvelope( tr, e )
      for AI=0, reaper.CountAutomationItems( env ) -1 do
        reaper.GetSetAutomationItemInfo( env, AI, "D_UISEL", 0, true )
      end
    end
  end
end


-------------------------------------
------------------------------------

function updateMSG()
  local msg = "It seems Smart split script was updated."..'\n\n'..
  "Your settings in the user area of code may have been reset."..'\n\n'..
  "Also there are some new settings."..'\n'..
  "Take a look and have fun!"
  reaper.ShowMessageBox(msg, "Smart Split updated", 0)

end
-----------------------------------------
--------------------------------------------


------------------
-------START------
version = reaper.GetExtState("SmartSplit_AZ", "version")
if version ~= "2.4" then
  updateMSG()
  reaper.SetExtState("SmartSplit_AZ", "version", "2.4", true)
end

cur_pos = reaper.GetCursorPosition()

window, segment, details = reaper.BR_GetMouseCursorContext()
mouse_cur_pos = reaper.BR_GetMouseCursorContext_Position()


if RazorEditSelectionExists()==true then
  split_byRE_andSel()
else

item =  reaper.BR_GetMouseCursorContext_Item() --what is context item or not
itemsNUMB =  reaper.CountSelectedMediaItems( 0 ) -1 -- -1 to accordance Get Sel Item
start_pos, end_pos = reaper.GetSet_LoopTimeRange2( 0, false, false, 0, 0, 0 )

if start_pos == end_pos or use_TS_all == false then TSexist=0
else
TSexist=1
end

autoI = "not"

if window == "arrange" and segment == "envelope" then
 Env_line, takeEnvelope = reaper.BR_GetMouseCursorContext_Envelope()
 
 if Env_line and takeEnvelope == false then
 
   AI_number = reaper.CountAutomationItems( Env_line ) -1
   
   while AI_number > -1 do
     isAIsel = reaper.GetSetAutomationItemInfo( Env_line, AI_number, "D_UISEL", 0, false )
     if isAIsel == 1 then autoI = "selected" end
     AI_number = AI_number - 1
   end
 end
 
end


if autoI == "selected" then
  reaper.Undo_BeginBlock2( 0 )
  reaper.PreventUIRefresh( 1 )
  split_automation_item()
  reaper.PreventUIRefresh( -1 )
  reaper.Undo_EndBlock2( 0, "Split automation item by mouse", -1 )
else

  --If likely there is no intention to split AIs--
  unsel_automation_Items()
  -----------------------------

  if not item then  --if mouse cursor not on the item
  split_by_edit_cursor_or_TS()
  end
  
  if item then
  
    selstate = reaper.IsMediaItemSelected( item )
    
    if selstate==false then
    reaper.Undo_BeginBlock2( 0 )
    reaper.PreventUIRefresh( 1 )
    split_not_sel_item()
    reaper.PreventUIRefresh( -1 )
    reaper.Undo_EndBlock2( 0, "Split items under mouse", -1 )
    else
    reaper.Undo_BeginBlock2( 0 )
    reaper.PreventUIRefresh( 1 )
    split_sel_item()
    reaper.PreventUIRefresh( -1 )
    reaper.Undo_EndBlock2( 0, "Split items under mouse or time selection", -1 )
    end
     
  end
  
end

end
