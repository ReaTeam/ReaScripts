-- @noindex

--@description Track-based Item Range Selection
--@author: triode
--@version: 0.66
--@requires: SWS Exclusive Toggle B1 to B4 on toolbar
--@donation: https://www.paypal.me/outoftheboxsounds

----------------------

allow_grid = true --- set to false to make this script not sensitive to grid mode
allow_All_Group_time_selection = true   --- set to false to prevent script changing your time selection in "Based on All" mode
folder_boundary = 0.15 -- time in seconds that item edges can exceed time selection before not being considered parallel in folder-based mode
group_boundary = 0.5  -- time in seconds that item edges can exceed time selection before not being considered parallel in track group-based mode

------------------------------------------------------

local math = math  -- Thanks for your threads Amagalma :)
local function equals( a, b ) -- a equals b
  return (math.abs( a - b ) < 0.000001)
end

Based_On_Folder = reaper.GetToggleCommandState(reaper.NamedCommandLookup("_S&M_EXCL_TGL_B1"))
Based_On_Track_Group = reaper.GetToggleCommandState(reaper.NamedCommandLookup("_S&M_EXCL_TGL_B4"))
Based_On_Individual = reaper.GetToggleCommandState(reaper.NamedCommandLookup("_S&M_EXCL_TGL_B3"))
Based_On_All = reaper.GetToggleCommandState(reaper.NamedCommandLookup("_S&M_EXCL_TGL_B2"))

x,y = reaper.GetMousePosition() 
moused = reaper.GetItemFromPoint(x,y,false) -- moused item

ItemGroupState = reaper.GetToggleCommandState(41156)
ItemGroupOverideState = reaper.GetToggleCommandState(1156)

TS, TE = reaper.GetSet_LoopTimeRange( false, false, 0, 0, false )  --- store initial time selectio


if Based_On_Folder + Based_On_Track_Group + Based_On_Individual + Based_On_All == 0 
then  
  ok = reaper.ShowMessageBox( "Folder-Based editing will be selected via SWS Exclusive toggle B1 \n( This script requires Exclusive Toggles B1 to B4 ) \n You'll need to manually put them on your toolbar"  , "Track-based Editing", 1 )
  if ok == 2 then return end
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_EXCL_TGL_B1"),0)
end

 
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

left_b_edge = timesel_start - boundary

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
        chaff = false

        start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        ending = start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        crossfadeout = reaper.GetMediaItemInfo_Value( item, "D_FADEOUTLEN_AUTO"  )
        crossfadein =  reaper.GetMediaItemInfo_Value( item, "D_FADEINLEN_AUTO"  )
        fadeout = reaper.GetMediaItemInfo_Value( item, "D_FADEOUTLEN"  )
        fadein =  reaper.GetMediaItemInfo_Value( item, "D_FADEINLEN"  )
        
        if crossfadeout == 0 then crossfadeout = fadeout end
        if crossfadein == 0 then crossfadein = fadein end
        
        if equals((start + crossfadein), timesel_end) then overlap_by_fade = true end
        if equals((ending - crossfadeout), timesel_start) then overlap_by_fade = true end
        
          if (start + (crossfadein*2) >= timesel_end and length < (2*boundary) ) then
            chaff = true 
          end  
          
          if (start >= left_b_edge and start < timesel_start and length - (crossfadeout*2) < (2*boundary)) then
            chaff = true 
          end 
          
            if chaff == false and overlap_by_fade == false and start >= timesel_start - boundary and ending <= timesel_end + boundary then
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


function SelectAllItems()
outsideTS = false
timesel_start, timesel_end = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
 item_count = reaper.CountMediaItems(0)
  for i = item_count-1, 0, -1 do
    local item = reaper.GetMediaItem(0, i)
    
        overlap_by_fade = false

        start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        ending = start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        crossfadeout = reaper.GetMediaItemInfo_Value( item, "D_FADEOUTLEN_AUTO"  )
        crossfadein =  reaper.GetMediaItemInfo_Value( item, "D_FADEINLEN_AUTO"  )
        fadeout = reaper.GetMediaItemInfo_Value( item, "D_FADEOUTLEN"  )
        fadein =  reaper.GetMediaItemInfo_Value( item, "D_FADEINLEN"  )
        
        if crossfadeout == 0 then crossfadeout = fadeout end
        if crossfadein == 0 then crossfadein = fadein end
      
        if equals((start + crossfadein), timesel_end) then overlap_by_fade = true end
        if equals((ending - crossfadeout), timesel_start) then overlap_by_fade = true end
      
        if overlap_by_fade == false then
          if start <= timesel_start and ending > timesel_start or start < timesel_end and ending >= timesel_end  
          or start >= timesel_start and ending <= timesel_end 
          then
            reaper.SetMediaItemSelected( item, true )
          end 
        end
        
      if overlap_by_fade == false and (start < timesel_start and ending > timesel_start or start < timesel_end and ending > timesel_end) then  
        outsideTS = true
      end  
  end
  return outsideTS
  
end -- for function



function combine_click_and_shiftclick_time_selections() 
 local Click, ClickStart = reaper.GetProjExtState( 0, "TrackBasedItems", "ClickStart" )
 local Click, ClickEnd = reaper.GetProjExtState( 0, "TrackBasedItems", "ClickEnd" )
 local ShiftClick, ShiftClickStart = reaper.GetProjExtState( 0, "TrackBasedItems", "ShiftClickStart" )
 local ShiftClick, ShiftClickEnd = reaper.GetProjExtState( 0, "TrackBasedItems", "ShiftClickEnd" )
 
 --reaper.ShowConsoleMsg(string.format("\n".."%.16f",ShiftClickEnd))
 
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


function select_all_tracks_in_selected_track_groups()  --- Thankyou me2beats
local r = reaper; local function nothing() end; local function bla() r.defer(nothing) end

local function Elem_in_tb(elem,tb)
  local found
  for eit = 1, #tb do if tb[eit] == elem then found = 1 break end end
  if found then return 1 end
end

local tracks = r.CountSelectedTracks()
if tracks == 0 then bla() return end

local t = {}
local t_tracks = {}

for i = 0, tracks-1 do
  local tr = r.GetSelectedTrack(0,i)
  t_tracks[#t_tracks+1] = tr
  local _, chunk = r.GetTrackStateChunk(tr, '', 0)
  local group_flags = chunk:match'\nGROUP_FLAGS (.-)\n'
  if group_flags then
    for flag in group_flags:gmatch'%d+' do
      flag = tonumber(flag)
      if not (flag == 0 or Elem_in_tb(flag,t)) then t[#t+1] = flag end
    end
  end
end

if #t ==0 then bla() return end

local all_tracks = r.CountTracks()

local t_to_sel = {}

for i = 0, all_tracks-1 do
  local tr = r.GetTrack(0,i)
  if not Elem_in_tb(tr,t_tracks) then
    local _, chunk = r.GetTrackStateChunk(tr, '', 0)
    local group_flags = chunk:match'\nGROUP_FLAGS (.-)\n'
    if group_flags then
      for flag in group_flags:gmatch'%d+' do
        flag = tonumber(flag)
        if not flag ~= 0 and Elem_in_tb(flag,t) then
          if not r.IsTrackSelected(tr) then
            t_to_sel[#t_to_sel+1] = tr break
          end
        end
      end
    end
  end
end

if #t_to_sel==0 then bla() return end


for i = 1, #t_to_sel do r.SetTrackSelected(t_to_sel[i],1) end

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

---------------------Folder-based Item Range Selection------------------

if Based_On_Folder == 1 then

  boundary = folder_boundary
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELPARENTS2"), 0)
  reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_UNSELMASTER'),0) -- Unselect Master Track
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELCHILDREN2"), 0)   

end


---------------------------Track group-based Item Range Selection

if Based_On_Track_Group == 1 then

  boundary = group_boundary
  select_all_tracks_in_selected_track_groups()

end
--------------------Select All mode----------------------------
  
  if Based_On_All == 1 then
  outside = SelectAllItems()
  
    if outside == false or allow_All_Group_time_selection == false then
      reaper.GetSet_LoopTimeRange(true, false, TS, TE, false) -- restore initial time selection
    end  
    
    if outside == false and allow_All_Group_time_selection == true then  --- if there is nothing outside time selection then remove it
      reaper.GetSet_LoopTimeRange(true, false, 0, 0, false)
    end
    
  end
  
-------------------Individual mode------------------------------
  
  if Based_On_Individual == 1 then
    boundary = 0
  end 

-------------------Except Select All Mode:--------------------------------

if (Based_On_Folder == 1) or (Based_On_Track_Group == 1) or (Based_On_Individual == 1) then

  select_items() 
  reaper.GetSet_LoopTimeRange(true, false, TS, TE, false) -- restore initial time selection
  
end

-------------------- to conclude all modeds
  
  StoreSelectionSet()
  reaper.Main_OnCommand(reaper.NamedCommandLookup("41110"), 0) -- select track under mouse
  reaper.SetEditCurPos( cursor, false, false )
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  
  if ItemGroupState == 1 and ItemGroupOverideState == 1 then 
  reaper.Main_OnCommand(40034, 0) -- Select all items in reaper's item groups
  end

end -- for if moused

