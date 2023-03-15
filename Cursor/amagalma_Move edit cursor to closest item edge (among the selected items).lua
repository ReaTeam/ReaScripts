-- @description Move edit cursor to closest item edge (among the selected items)
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma


local item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt > 0 then
  local cur_pos = reaper.GetCursorPosition()
  local closest_val, closest_time = 3600000

  for i = 0, item_cnt-1 do
    local item = reaper.GetSelectedMediaItem ( 0, i )
    local item_pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    local item_end = item_pos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
    local diff = math.abs(item_pos - cur_pos)
    if diff < closest_val then
      closest_time = item_pos
      closest_val = diff
    end
    diff = math.abs(item_end - cur_pos)
    if diff < closest_val then
      closest_time = item_end
      closest_val = diff
    end
  end
  reaper.SetEditCurPos( closest_time, false, false )
end
reaper.defer(function() end)
