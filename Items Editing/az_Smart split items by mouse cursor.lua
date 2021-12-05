-- @description Smart split items by mouse cursor
-- @author AZ
-- @version 2.2
-- @changelog
--   Removed dead zone where mouse placed on envelope and no automation item selected.
--   For now it provides as empty arrange zone, and items should splitted at edit cursor or time selection.
-- @link Forum thread https://forum.cockos.com/showthread.php?t=259751
-- @about
--   # Smart split items by mouse cursor
--
--   Split items respect grouping, depend on context of mouse cursor, split at razor edit or time selection if exist, split at mouse or edit cursor otherwise.
--   There is an option in the user area of code to switch off time selection.
--
--   Thanks BirdBird for razor edit functions.
--   https://forum.cockos.com/showthread.php?t=241604&highlight=razor+edit+scripts
--
--   Date: october 2021


-----------------------------
----------USER AREA----------
use_TS_sel_Items = true -- Could selected items be splitted by TS or not.
use_TS_all = true       -- Use Time selection or not in all cases.
-----------------------------
-----------------------------


--FUNCTIONS--

function RazorEditSelectionExists()

    for i=0, reaper.CountTracks(0)-1 do

        local retval, x = reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0,i), "P_RAZOREDITS", "string", false)

        if x ~= "" then return true end

    end--for
    
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

function GetItemsInRange(track, areaStart, areaEnd)
    local items = {}
    local itemCount = reaper.CountTrackMediaItems(track)
    for k = 0, itemCount - 1 do 
        local item = reaper.GetTrackMediaItem(track, k)
        local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local itemEndPos = pos+length

        --check if item is in area bounds
        if (itemEndPos > areaStart and itemEndPos <= areaEnd) or
            (pos >= areaStart and pos < areaEnd) or
            (pos <= areaStart and itemEndPos >= areaEnd) then
                table.insert(items,item)
        end
    end

    return items
end

-----------------------

function GetRazorEdits()
    local trackCount = reaper.CountTracks(0)
    local areaMap = {}
    for i = 0, trackCount - 1 do
        local track = reaper.GetTrack(0, i)
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
        end
    end

    return areaMap
end

-----------------------

function SplitRazorEdits(razorEdits)
    local areaItems = {}
    local tracks = {}
    reaper.PreventUIRefresh(1)
    for i = 1, #razorEdits do
        local areaData = razorEdits[i]
        if not areaData.isEnvelope then
            local items = areaData.items
            
            --recalculate item data for tracks with previous splits
            if tracks[areaData.track] ~= nil then 
                items = GetItemsInRange(areaData.track, areaData.areaStart, areaData.areaEnd)
            end
            
            for j = 1, #items do 
                local item = items[j]
                --split items 
                local newItem = reaper.SplitMediaItem(item, areaData.areaStart)
                if newItem == nil then
                    reaper.SplitMediaItem(item, areaData.areaEnd)
                    table.insert(areaItems, item)
                else
                    reaper.SplitMediaItem(newItem, areaData.areaEnd)
                    table.insert(areaItems, newItem)
                end
            end

            tracks[areaData.track] = 1
        end
    end
    reaper.PreventUIRefresh(-1)
    
    return areaItems
end

-----------------------------------

function split_byRE_andSel()
  local selections = GetRazorEdits()
  local items = SplitRazorEdits(selections)
  for i = 1, #items do
      local item = items[i]
      reaper.SetMediaItemSelected(item, true)
      reaper.Main_OnCommandEx(42406, 0, 0)
  end
end


-----------------------------------
-----------------------------------


function is_item_crossTS ()
if itemend < start_pos or itempos > end_pos or use_TS_sel_Items == false then
crossTS=0
else
  if itemend == start_pos or itempos == end_pos then
  crossTS=0
  else
    if itempos > start_pos and itemend < end_pos then  --inside TS
    crossTS=0
    else
      if itempos == start_pos and itemend == end_pos then  --inside TS
      crossTS=0
      else
        if itempos == start_pos and itemend < end_pos then  --inside TS
        crossTS=0
        else
          if itempos > start_pos and itemend == end_pos then  --inside TS
          crossTS=0
          else
          crossTS=1
          end
        end
      end
    end
  end
end
end

            
-----------------------------------------
--------------------------------------------


function split_by_edit_cursor_or_TS()
if TSexist==0 then  --if TS doesn't exist
 reaper.Main_OnCommandEx( 40759, 0, 0 ) -- split items under edit cursor (select right)
else

  if itemsNUMB == -1 then --if no one item selected
   reaper.Main_OnCommandEx(  40061, 0, 0 ) -- split at TS
  else
       --if any items selected it need to check croses with TS
    if item then  
     --item under mouse sec position to decide where is item crossed by TS--
    itempos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    itemlen = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" ) 
    itemend = itempos + itemlen
    is_item_crossTS()
    else
    
    item_not_undermouse = reaper.GetSelectedMediaItem( 0, itemsNUMB ) --zero based -- last sel item
    --item sec position to decide where is last sel item crossed by TS--
    itempos = reaper.GetMediaItemInfo_Value( item_not_undermouse, "D_POSITION" )
    itemlen = reaper.GetMediaItemInfo_Value( item_not_undermouse, "D_LENGTH" ) 
    itemend = itempos + itemlen
    
    crossTS = 0 -- need to start while cycle

      while itemsNUMB > -1 and crossTS == 0 do
      is_item_crossTS()
      itemsNUMB = itemsNUMB-1
      item_not_undermouse = reaper.GetSelectedMediaItem( 0, itemsNUMB ) --zero based
      
        if item_not_undermouse then --to avoid error if no more items founded
        --item sec position to decide where is another item regards TS--
        itempos = reaper.GetMediaItemInfo_Value( item_not_undermouse, "D_POSITION" )
        itemlen = reaper.GetMediaItemInfo_Value( item_not_undermouse, "D_LENGTH" ) 
        itemend = itempos + itemlen
        end
      end
    end  
  
    if crossTS==0 then
      reaper.Main_OnCommandEx( 40759, 0, 0 ) -- split items under edit cursor (select right)
    else
      reaper.Undo_BeginBlock2( 0 )
      reaper.PreventUIRefresh( 1 )
      
      reaper.Main_OnCommandEx(  40061, 0, 0 ) -- split at TS
      reaper.Main_OnCommandEx( 40635, 0, 0 )  -- Time selection: Remove time selection
      
      reaper.PreventUIRefresh( -1 )
      reaper.Undo_EndBlock2( 0, "Split items at time selection", -1 )
    end 
  end
end
end


-----------------------------------------
--------------------------------------------


function split_not_sel_item()

reaper.Main_OnCommandEx( 40289, 0, 0 ) -- unselect all items
reaper.SetMediaItemSelected( item, 1 ) -- select founded item under mouse
reaper.Main_OnCommandEx( 40513, 0, 0 ) -- View: Move edit cursor to mouse cursor

reaper.Main_OnCommandEx(  40759, 0, 0 ) -- CENTRAL FUNCTION split items under edit cursor (select right)

reaper.SetEditCurPos(cur_pos, false, false)

end



-----------------------------------------
--------------------------------------------



function split_sel_item()

reaper.Main_OnCommandEx( 40513, 0, 0 ) -- View: Move edit cursor to mouse cursor
split_by_edit_cursor_or_TS() --CENTRAL FUNCTION
reaper.SetEditCurPos(cur_pos, false, false)

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


-----------------------------------------
--------------------------------------------



--CONTEXT DEFINING CODE--
version = reaper.GetExtState("SmartSplit_AZ", "version")
if version ~= "2.2" then reaper.SetExtState("SmartSplit_AZ", "version", "2.2", true) end
    
window, segment, details = reaper.BR_GetMouseCursorContext()

if RazorEditSelectionExists()==true then
  reaper.Undo_BeginBlock2( 0 )
  reaper.PreventUIRefresh( 1 )
  split_byRE_andSel()
  reaper.PreventUIRefresh( -1 )
  reaper.Undo_EndBlock2( 0, "Split at razor edit", -1 )
else

item =  reaper.BR_GetMouseCursorContext_Item() --what is context item or not
itemsNUMB =  reaper.CountSelectedMediaItems( 0 ) -1 -- -1 to accordance Get Sel Item
start_pos, end_pos = reaper.GetSet_LoopTimeRange2( 0, false, false, 0, 0, 0 )

if start_pos == end_pos or use_TS_all == false then TSexist=0
else
TSexist=1
end

cur_pos=reaper.GetCursorPosition()

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
