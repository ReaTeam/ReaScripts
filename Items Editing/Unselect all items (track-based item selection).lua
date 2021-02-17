-- @description Unselect all items (track-based item selection)
-- @author Triode
-- @version 0.7
-- @link http://www.outoftheboxsounds.com/
-- @donation https://www.paypal.com/paypalme/outoftheboxsounds
-- @about
--   The item selection and split scripts require SWS exclusive toggles B1 to B4 on the toolbar which correspond to the following item selection modes:
--
--   B1: Folder-based item selection
--   B2: Item selection across all tracks
--   B3: Individual item selection
--   B4: Track group based item selection
--
--   This script is for unselecting all items compatible with the item range selection and toggle selection scripts.  Download the other track based scripts to get item range selection (shift-click), toggle selection, item split (select right or left) using the same modes.
--
--   There are also scripts for making newly recorded items create selections compatible with the above actions.
--
--   None of these scripts run anything in the background.
--   No undo point is created by the item selection scripts (unless you specifically set item select undo in reaper's preferences)



  reaper.Main_OnCommand(40289,0) -- unselect all items

  --InitializeSelectionSet
    reaper.SetProjExtState( 0, "TrackBasedItems", "SelectionSet","") 
  
  --InitializeTimeSelectionClick
    reaper.SetProjExtState( 0, "TrackBasedItems", "ClickStart", "" ) -- Save ClickStart
    reaper.SetProjExtState( 0, "TrackBasedItems", "ClickEnd", "" ) -- Save ClickEnd
  
  --function InitializeTimeSelectionShiftClick()
    reaper.SetProjExtState( 0, "TrackBasedItems", "ShiftClickStart", "" ) -- Save ShiftClickStart
    reaper.SetProjExtState( 0, "TrackBasedItems", "ShiftClickEnd", "" ) -- Save ShiftClickEnd



