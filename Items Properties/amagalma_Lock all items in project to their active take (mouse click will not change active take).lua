-- @description Lock all items in project to their active take (mouse click will not change active take)
-- @author amagalma
-- @version 1.00


local item_cnt = reaper.CountMediaItems( 0 )
if item_cnt == 0 then return reaper.defer(function() end) end

for i = 0, item_cnt-1 do
  local item = reaper.GetMediaItem( 0, i )
  local lock = reaper.GetMediaItemInfo_Value(item, "C_LOCK")
  if lock & 2 ~= 2 then
    reaper.SetMediaItemInfo_Value(item, "C_LOCK", lock|2)
  end
end

reaper.Undo_OnStateChange("Lock all items in project to their active take (mouse click will not change active take)")
