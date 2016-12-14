-- @description Randomize pan of selected items
-- @version 0.1

selected_item_count = reaper.CountSelectedMediaItems(0)
for i = 0, selected_item_count - 1 do
    item = reaper.GetSelectedMediaItem(0, i)
    item_take = reaper.GetActiveTake(item)
    random_pan = math.random() * 2 - 1
    reaper.SetMediaItemTakeInfo_Value(item_take, 'D_PAN', random_pan)
    reaper.UpdateItemInProject(item)
end
