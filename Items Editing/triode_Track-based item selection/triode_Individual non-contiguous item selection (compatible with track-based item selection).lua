-- @noindex

--@description Individual non-contiguous Item Selection (compatible with track-based item selection)
--@author: triode
--@version: 0.74
--@requires: SWS Exclusive Toggle B1 to B4 on toolbar
--Donation: https://www.paypal.me/outoftheboxsounds


----------------------

allow_grid = true --- set to false to make this script not sensitive to grid mode

------------------------------------------------------

ItemGroupState = reaper.GetToggleCommandState(41156)
ItemGroupOverideState = reaper.GetToggleCommandState(1156)

x,y = reaper.GetMousePosition() -- get x,y of the mouuse
moused = reaper.GetItemFromPoint(x,y,false) -- check if item is under mouse

TS, TE = reaper.GetSet_LoopTimeRange( false, false, 0, 0, false )  --- store initial time selection


 function SaveTimeSelectionClick() -- Replaces SWS Save to Time Selection Slot 4
   local ClickStart, ClickEnd = reaper.GetSet_LoopTimeRange(false, false, tostring(0), tostring(0), false) -- Get current time selection
   reaper.SetProjExtState( 0, "TrackBasedItems", "ClickStart", ('%.16f'):format(ClickStart) ) -- Save VisibleStart
   reaper.SetProjExtState( 0, "TrackBasedItems", "ClickEnd", ('%.16f'):format(ClickEnd) ) -- Save VisibleEnd
 end
 
 
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
  LoadSelectionSet()
  reaper.Main_OnCommand(40530, 0) -- toggle selection of item under mouse
  StoreSelectionSet()
  reaper.Main_OnCommand(40290, 0) --  set time selection to selected items in case shift is used next
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

  
  

  
  
