-- @noindex

--@description Track-based non-contiguous Item Selection
--@author: triode
--Forum post: https://forum.cockos.com/showthread.php?t=234011
--@version: 0.74
--@requires: SWS Exclusive Toggle B1 to B4 on toolbar
--Donation: https://www.paypal.me/outoftheboxsounds


----------------------

allow_grid = true --- set to false to make this script not sensitive to grid mode
folder_boundary = 0.15 -- time in seconds that item edges can exceed time selection before not being considered parallel
group_boundary = 0.5

------------------------------------------------------
local math = math  -- Thanks for your threads Amagalma :)
local function equals( a, b ) -- a equals b
  return (math.abs( a - b ) < 0.000001)
end


ItemGroupState = reaper.GetToggleCommandState(41156)
ItemGroupOverideState = reaper.GetToggleCommandState(1156)


x,y = reaper.GetMousePosition() -- get x,y of the mouuse
moused = reaper.GetItemFromPoint(x,y,false) -- check if item is under mouse


Based_On_Folder = reaper.GetToggleCommandState(reaper.NamedCommandLookup("_S&M_EXCL_TGL_B1"))
Based_On_Track_Group = reaper.GetToggleCommandState(reaper.NamedCommandLookup("_S&M_EXCL_TGL_B4"))
Based_On_Individual = reaper.GetToggleCommandState(reaper.NamedCommandLookup("_S&M_EXCL_TGL_B3"))  -- doesn't get called but works the absence of others
Based_On_All = reaper.GetToggleCommandState(reaper.NamedCommandLookup("_S&M_EXCL_TGL_B2"))

TS, TE = reaper.GetSet_LoopTimeRange( false, false, 0, 0, false )  --- store initial time selection


if Based_On_Folder + Based_On_Track_Group + Based_On_Individual + Based_On_All == 0 
then  
  ok = reaper.ShowMessageBox( "Folder-Based editing will be selected via SWS Exclusive toggle B1 \n( This script requires Exclusive Toggles B1 to B4 ) \n You'll need to manually put them on your toolbar"  , "Track-based Editing", 1 )
  if ok == 2 then return end
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_EXCL_TGL_B1"),0)
end
 
 function SaveTimeSelectionClick() -- Replaces SWS Save to Time Selection Slot 4
   local ClickStart, ClickEnd = reaper.GetSet_LoopTimeRange(false, false, tostring(0), tostring(0), false) -- Get current time selection
   reaper.SetProjExtState( 0, "TrackBasedItems", "ClickStart", ('%.16f'):format(ClickStart) ) -- Save VisibleStart
   reaper.SetProjExtState( 0, "TrackBasedItems", "ClickEnd", ('%.16f'):format(ClickEnd) ) -- Save VisibleEnd
 end
 
 
-- thanks to spk77 for the original eel script select whole items within time selection on selected tracks
function toggle_selection_of_whole_items_in_time_selection_on_selected_tracks(timesel_start, timesel_end, ti, ii, tr, item, start, ending) 
local selNum = reaper.CountSelectedTracks(0)
local timesel_start, timesel_end = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
local whatever = reaper.IsMediaItemSelected(moused)

if timesel_end - timesel_start > 0 then

ti = 0 

  for i=0, selNum-1 do
    local tr = reaper.GetSelectedTrack(0,ti)
      if tr then
        local item_count = reaper.CountTrackMediaItems( tr )
        local ii = 0
        for j=0, item_count-1 do
        local item = reaper.GetTrackMediaItem(tr, ii)
    
      if ii then
      
      overlap_by_fade = false
      chaff = false
      
      local start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      ending = start + length
      crossfadeout = reaper.GetMediaItemInfo_Value( item, "D_FADEOUTLEN_AUTO"  )
      crossfadein =  reaper.GetMediaItemInfo_Value( item, "D_FADEINLEN_AUTO"  )
      fadeout = reaper.GetMediaItemInfo_Value( item, "D_FADEOUTLEN"  )
      fadein =  reaper.GetMediaItemInfo_Value( item, "D_FADEINLEN"  )
      
      if crossfadeout == 0 then crossfadeout = fadeout end
      if crossfadein == 0 then crossfadein = fadein end
      
      if equals((start + crossfadein), timesel_end) then overlap_by_fade = true end
      if equals((ending - crossfadeout), timesel_start) then overlap_by_fade = true end
      
      if (start + (crossfadein*2) >= timesel_end and length < (2*boundary) ) then chaff = true end
      if (start >= (timesel_start - boundary) and start < timesel_start and length - (crossfadeout*2) < (2*boundary)) then chaff = true end
                                  
        if overlap_by_fade == false and chaff == false and start >= timesel_start - boundary and ending <= timesel_end + boundary then  reaper.SetMediaItemSelected( item, not whatever ) end
                    
        ii = ii+ 1
        end
        end
        ti = ti+ 1
        end
      end
  end
end   --- for function 


 function LoadSelectionSet()
 Loaded, splurge = reaper.GetProjExtState( 0, "TrackBasedItems", "SelectionSet" ) -- get selection set
   if sep == nil then  --retrieve_items_from_set(val, sep)
     sep = "%s"
   end
      
   local t={}
   for str in string.gmatch(splurge, "([^"..sep.."]+)") do
     t[#t+1] = str      
     item = reaper.BR_GetMediaItemByGUID( 0, str )
     reaper.SetMediaItemSelected( item, true )
   end
      reaper.UpdateArrange()
 end -- for function  


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
  cursor = reaper.GetCursorPosition()   -- get cursor position
  reaper.PreventUIRefresh(1)
  reaper.Main_OnCommand(40528, 0) --------select item under mouse (this works even if user has a mouse-drag-item set to the same mouse modifier
  --reaper.SetMediaItemSelected(moused,1)   --- Select item under mouse -- this is preferable as it works even with a click on the crossfade area
  reaper.Main_OnCommand(41110, 0) -- Select Track under Mouse (used early to prevent adding tracks to selection when moving down arrange)
  reaper.Main_OnCommand(40290, 0) -- SET TIME SELECTION TO SEL ITEMS
  SaveTimeSelectionClick()
  reaper.SetMediaItemSelected(moused,0)  --- Unselect item under mouse
  
-------------------------Folder-based non-contiguous Item Selection (V 0.5) ---------------------

if Based_On_Folder == 1 then
  boundary = folder_boundary
  reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_SELPARENTS2'),0) 
  reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_UNSELMASTER'),0) -- Unselect Master Track
  reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_SELCHILDREN2'),0) -- Select Children of Selected folder track
end

  
----------------------Track group-based non-contiguous Item Selection------------------------------

if Based_On_Track_Group == 1 then
  boundary = group_boundary
  select_all_tracks_in_selected_track_groups()
end

--------------------Select All tracks

if Based_On_All == 1 then
  boundary = 0
  reaper.Main_OnCommand(40296, 0) -- select all tracks 
end


------------ Individual Mode-------
if Based_On_Individual == 1 then
  boundary = 0
end

------------------------------- (to conclude all modes)

LoadSelectionSet()
toggle_selection_of_whole_items_in_time_selection_on_selected_tracks()
StoreSelectionSet()
reaper.Main_OnCommand(40290, 0) --  set time selection to sell items in case shift is used next
SaveTimeSelectionClick() -- in case shift is used next
reaper.Main_OnCommand(41110, 0) -- Select Track under Mouse
reaper.GetSet_LoopTimeRange(true, false, TS, TE, false) -- restore initial time selection
reaper.SetEditCurPos( cursor, false, false )

if ItemGroupState == 1 and ItemGroupOverideState == 1 then
reaper.Main_OnCommand(40034, 0) -- Select all items in reaper's item groups
end

reaper.PreventUIRefresh(0)
reaper.UpdateArrange()
end -- for if moused

  
  

  
  
