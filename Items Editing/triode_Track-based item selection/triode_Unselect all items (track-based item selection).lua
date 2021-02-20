-- @noindex

--@description: Unselect all items (Track-based item selection)
--@author: triode
--@version: 0.7
--@requires: SWS Exclusive Toggle B1 to B4 on toolbar
--@donation: https://www.paypal.me/outoftheboxsounds


  reaper.Main_OnCommand(40289,0) -- unselect all items

  --InitializeSelectionSet
    reaper.SetProjExtState( 0, "TrackBasedItems", "SelectionSet","") 
  
  --InitializeTimeSelectionClick
    reaper.SetProjExtState( 0, "TrackBasedItems", "ClickStart", "" ) -- Save ClickStart
    reaper.SetProjExtState( 0, "TrackBasedItems", "ClickEnd", "" ) -- Save ClickEnd
  
  --function InitializeTimeSelectionShiftClick()
    reaper.SetProjExtState( 0, "TrackBasedItems", "ShiftClickStart", "" ) -- Save ShiftClickStart
    reaper.SetProjExtState( 0, "TrackBasedItems", "ShiftClickEnd", "" ) -- Save ShiftClickEnd
    

    

