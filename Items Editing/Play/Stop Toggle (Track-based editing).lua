-- @description Play/Stop Toggle (Track-based editing)
-- @author Triode
-- @version 0.7
-- @link http://www.outoftheboxsounds.com/
-- @donation If you like this script please support https://www.paypal.com/paypalme/outoftheboxsounds
-- @about
--   Download the other track based scripts to get item selection, item range selection (shift-click), toggle selection, item split (select right or left) across items on tracks in folders on in track groups.
--
--   The item select and split scripts require SWS exclusive toggles B1 to B4 on the toolbar which correspond to the following item selection modes:
--
--   B1: Folder-based item selection
--   B2: Item selection across all tracks
--   B3: Individual item selection
--   B4: Track group based item selection
--
--   This script is a play stop toggle that is compatible with the item range selection and toggle selection scripts when used to come out of record.  
--
--   There are also a script for unselecting all items.
--
--   None of these scripts run anything in the background.
--   No undo point is created by the item selection scripts (unless you specifically set item select undo in reaper's preferences)



transport_state = reaper.GetPlayState()

TS, TE = reaper.GetSet_LoopTimeRange( false, false, 0, 0, false )  --- store initial time selection

 
 function SaveTimeSelectionClick() -- Replaces SWS Save to Time Selection Slot 4
   local ClickStart, ClickEnd = reaper.GetSet_LoopTimeRange(false, false, tostring(0), tostring(0), false) -- Get current time selection
   reaper.SetProjExtState( 0, "TrackBasedItems", "ClickStart", ('%.14f'):format(ClickStart) ) -- Save VisibleStart
   reaper.SetProjExtState( 0, "TrackBasedItems", "ClickEnd", ('%.14f'):format(ClickEnd) ) -- Save VisibleEnd
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
    --reaper.ShowMessageBox("" .. s, "Item GUIDS SET", 0) -- just to test     
    reaper.SetProjExtState( 0, "TrackBasedItems", "SelectionSet",("".. s))
  end
 end --for function


if transport_state == 0 then  -- if stopped
  reaper.Main_OnCommand(1007, 0) -- play
end  

if transport_state == 5 then  -- if in record
  reaper.Main_OnCommand(1016, 0) -- stop
  StoreSelectionSet()
  cursor = reaper.GetCursorPosition()   -- get cursor position
  
  reaper.Main_OnCommand(40290, 0) -- set time selection to items (that have just been recorded) 
  SaveTimeSelectionClick()
  reaper.GetSet_LoopTimeRange(true, false, TS, TE, false) -- restore initial time selection
  reaper.SetEditCurPos( cursor, false, false )
end

if transport_state == 1 then -- if in play
 reaper.Main_OnCommand(1016, 0) -- stop
end

