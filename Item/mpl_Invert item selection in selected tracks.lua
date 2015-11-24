script_title = "Invert item selection in selected tracks"

reaper.Undo_BeginBlock()

itemscount = reaper.CountMediaItems(0)
for i = 1, itemscount do
  item = reaper.GetMediaItem(0, i-1)
  is_selected_item = reaper.GetMediaItemInfo_Value(item, "B_UISEL")
  item_track = reaper.GetMediaItem_Track(item)
  IsTrackSelected = reaper.IsTrackSelected(item_track)
  if IsTrackSelected == true then 
    if is_selected_item == 1 then reaper.SetMediaItemInfo_Value(item, "B_UISEL", 0) end
    if is_selected_item == 0 then reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1) end  
  end
end
reaper.UpdateArrange()

reaper.Undo_EndBlock(script_title, 0)
