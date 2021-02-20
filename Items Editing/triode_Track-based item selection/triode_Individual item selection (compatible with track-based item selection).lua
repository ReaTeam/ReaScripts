-- @noindex

--@description Individual Item Selection (compatible with track-based item selection)
--@author: triode
--@version: 0.72
--@requires: SWS Exclusive Toggle B1 to B4 on toolbar
--Donations for script: https://www.paypal.me/outoftheboxsounds

----------------------

allow_grid = true --- set to false to make this script not sensitive to grid mode

----------------------

ItemGroupState = reaper.GetToggleCommandState(41156)
ItemGroupOverideState = reaper.GetToggleCommandState(1156)

x,y = reaper.GetMousePosition() 
moused = reaper.GetItemFromPoint(x,y,false) 

TS, TE = reaper.GetSet_LoopTimeRange( false, false, 0, 0, false )  --- store initial time selection


 function SaveTimeSelectionClick() 
   local ClickStart, ClickEnd = reaper.GetSet_LoopTimeRange(false, false, tostring(0), tostring(0), false) -- Get current time selection
   reaper.SetProjExtState( 0, "TrackBasedItems", "ClickStart", ('%.16f'):format(ClickStart) ) -- Save VisibleStart
   reaper.SetProjExtState( 0, "TrackBasedItems", "ClickEnd", ('%.16f'):format(ClickEnd) ) -- Save VisibleEnd
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
 
  
  
if moused ~= nil then

  if allow_grid == false then reaper.Main_OnCommand(40514, 0) end -- move cursor to mouse
  reaper.Main_OnCommand(40289,0) -- unselect all items
  reaper.SetMediaItemSelected(moused,1)   --- Select item under mouse 
  cursor = reaper.GetCursorPosition()   -- get cursor position
  reaper.PreventUIRefresh(1)
  reaper.Main_OnCommand(40290, 0) -- SET TIME SELECTION TO SEL ITEMS
  reaper.Main_OnCommand(41110, 0) -- Select Track under Mouse (used early to prevent adding tracks to selection when moving down arrange)
  SaveTimeSelectionClick()
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

