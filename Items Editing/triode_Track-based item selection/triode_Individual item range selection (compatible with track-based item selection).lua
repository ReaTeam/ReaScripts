-- @noindex

--@description Indivicual Item Range Selection (compatible with track-based item selection)
--@author: triode
--@version: 0.65
--@requires: SWS Exclusive Toggle B1 to B4 on toolbar
--Donations for script: https://www.paypal.me/outoftheboxsounds

----------------------

allow_grid = true --- set to false to make this script not sensitive to grid mode

------------------------------------------------------

local math = math  -- Thanks for your threads Amagalma :)
local function equals( a, b ) -- a equals b
  return (math.abs( a - b ) < 0.000001)
end

x,y = reaper.GetMousePosition() 
moused = reaper.GetItemFromPoint(x,y,false) -- moused item

ItemGroupState = reaper.GetToggleCommandState(41156)
ItemGroupOverideState = reaper.GetToggleCommandState(1156)

TS, TE = reaper.GetSet_LoopTimeRange( false, false, 0, 0, false )  --- store initial time selectio

 
 function SaveTimeSelectionClick() -- Replaces SWS Save to Time Selection Slot 4
   ClickStart, ClickEnd = reaper.GetSet_LoopTimeRange(false, false, tostring(0), tostring(0), false) -- Get current time selection
   reaper.SetProjExtState( 0, "TrackBasedItems", "ClickStart", ('%.16f'):format(ClickStart) ) -- Save ClickStart
   reaper.SetProjExtState( 0, "TrackBasedItems", "ClickEnd", ('%.16f'):format(ClickEnd) ) -- Save ClickEnd
 end
 
 
 function SaveTimeSelectionShiftClick() -- Replaces SWS Save to Time Selection Slot 5
   ShiftClickStart, ShiftClickEnd = reaper.GetSet_LoopTimeRange(false, false, tostring(0), tostring(0), false) -- Get current time selection
   reaper.SetProjExtState( 0, "TrackBasedItems", "ShiftClickStart", ('%.16f'):format(ShiftClickStart) ) -- Save ShiftClickStart
   reaper.SetProjExtState( 0, "TrackBasedItems", "ShiftClickEnd", ('%.16f'):format(ShiftClickEnd) ) -- Save ShiftClickEnd
 end  

 
function StoreSelectionSet()
  local sel_item = {}
  local item_cnt = reaper.CountSelectedMediaItems(0) 
  local s = ""
  
  for i = 0, item_cnt -1 do --- loop through items and make one long string with tabs inbetween each entry  was - 1
    local Item = reaper.GetSelectedMediaItem(0, i)
    local GUID = reaper.BR_GetMediaItemGUID( Item )
    s = s .. tostring(GUID) .. "\t" 
  end
  
  if item_cnt == 0 then
  reaper.SetProjExtState( 0, "TrackBasedItems", "SelectionSet","") --- if no items are selected erase previous selection set
  end
  
  if s:len() > 0 then 
    reaper.SetProjExtState( 0, "TrackBasedItems", "SelectionSet",("".. s))
  end
 end --for function
 

function select_items()   -- thanks to spk77 for the original eel script select whole items within time selection on selected tracks
 selNum = reaper.CountSelectedTracks(0)
 timesel_start, timesel_end = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)

--left_b_edge = timesel_start - boundary

if timesel_end - timesel_start > 0 then
ti = 0 
outsideTS = false
  for i=0, selNum-1 do
  tr = reaper.GetSelectedTrack(0,ti)
    if tr then
    item_count = reaper.CountTrackMediaItems( tr )
    ii = 0
    for j=0, item_count-1 do
    item = reaper.GetTrackMediaItem(tr, ii)
      if ii then
      
        overlap_by_fade = false
        --chaff = false

        start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        ending = start + length
        crossfadeout = reaper.GetMediaItemInfo_Value( item, "D_FADEOUTLEN_AUTO"  )
        crossfadein =  reaper.GetMediaItemInfo_Value( item, "D_FADEINLEN_AUTO"  )
        fadeout = reaper.GetMediaItemInfo_Value( item, "D_FADEOUTLEN"  )
        fadein =  reaper.GetMediaItemInfo_Value( item, "D_FADEINLEN"  )
        
        if crossfadeout == 0 then crossfadeout = fadeout end
        if crossfadein == 0 then crossfadein = fadein end
        
        if equals((start + crossfadein), timesel_end) then overlap_by_fade = true end
        if equals((ending - crossfadeout), timesel_start) then overlap_by_fade = true end
        
         -- if (start + (crossfadein*2) >= timesel_end and length < (2*boundary) ) then
           -- chaff = true 
          --end  
          
          --if (start >= left_b_edge and start < timesel_start and length - (crossfadeout*2) < (2*boundary)) then
          --  chaff = true 
          --end 
          
            if overlap_by_fade == false and start >= timesel_start and ending <= timesel_end then
              reaper.SetMediaItemSelected( item, true ) 
            end
          
        ii = ii+ 1
        end -- for if ii
        end -- for second for loop
        ti = ti+ 1
        end -- for if tr
      end -- for FOR loop
end  --- for if time selection

end --- for function


function combine_click_and_shiftclick_time_selections() 
 local Click, ClickStart = reaper.GetProjExtState( 0, "TrackBasedItems", "ClickStart" )
 local Click, ClickEnd = reaper.GetProjExtState( 0, "TrackBasedItems", "ClickEnd" )
 local ShiftClick, ShiftClickStart = reaper.GetProjExtState( 0, "TrackBasedItems", "ShiftClickStart" )
 local ShiftClick, ShiftClickEnd = reaper.GetProjExtState( 0, "TrackBasedItems", "ShiftClickEnd" )
 
 if Click == 1 then -- in case user makes a shift selection first
 
 if tonumber(ClickStart) <= tonumber(ShiftClickStart) then
   s = ClickStart
 else
   s = ShiftClickStart
 end
 
 if tonumber(ClickEnd) >= tonumber(ShiftClickEnd) then
   e = ClickEnd
 else
   e = ShiftClickEnd
 end
 
 reaper.Main_OnCommand(40635, 0) -- remove time selection
 reaper.GetSet_LoopTimeRange(true, false, s, e, false)
end 
end -- for function



if moused ~= nil then

  if allow_grid == false then reaper.Main_OnCommand(40514, 0) end -- move cursor to mouse
  reaper.SetMediaItemSelected(moused,1) --- Select item under mouse 
  cursor = reaper.GetCursorPosition()   -- get cursor position
  reaper.PreventUIRefresh(1)
  reaper.Main_OnCommand(40290, 0) -- SET TIME SELECTION TO SEL ITEMS
  SaveTimeSelectionShiftClick()
  combine_click_and_shiftclick_time_selections() 
  SaveTimeSelectionClick()
  select_items() 
  reaper.GetSet_LoopTimeRange(true, false, TS, TE, false) -- restore initial time selection
  StoreSelectionSet()
  reaper.Main_OnCommand(reaper.NamedCommandLookup("41110"), 0) -- select track under mouse
  reaper.SetEditCurPos( cursor, false, false )
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  
  if ItemGroupState == 1 and ItemGroupOverideState == 1 then 
    reaper.Main_OnCommand(40034, 0) -- Select all items in reaper's item groups
  end

end -- for if moused

