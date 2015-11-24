script_title = "Snap selected items to each other"
reaper.Undo_BeginBlock()

first_item = reaper.GetSelectedMediaItem(0, 0)
if  first_item ~= nil then first_item_track = reaper.GetMediaItem_Track(first_item) end

item_t = {}
item_subt = {}
item_count = reaper.CountSelectedMediaItems(0)
if item_count ~= nil then 
  -- unselect items on other tracks then first sel item track 
  for i = 1, item_count do
    item = reaper.GetSelectedMediaItem(0, i-1)
    item_track = reaper.GetMediaItem_Track(item)    
    if item ~= nil and item_track == first_item_track then 
      reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)   
     else
       reaper.SetMediaItemInfo_Value(item, "B_UISEL", 0) 
    end
  end 
  -- main action
  for i = 2, item_count do
    item = reaper.GetSelectedMediaItem(0, i-1)
    if item ~= nil then
      prev_item = reaper.GetSelectedMediaItem(0, i-2)
      prev_item_pos = reaper.GetMediaItemInfo_Value(prev_item, "D_POSITION")
      prev_item_len = reaper.GetMediaItemInfo_Value(prev_item, "D_LENGTH")
      newpos = prev_item_pos + prev_item_len
      reaper.SetMediaItemInfo_Value(item, "D_POSITION", newpos)
    end  
   end 
end

reaper.UpdateArrange()
reaper.Undo_EndBlock(script_title, 0)

