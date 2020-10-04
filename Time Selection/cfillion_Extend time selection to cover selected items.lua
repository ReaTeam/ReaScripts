-- @description Extend time selection to cover selected items
-- @author cfillion
-- @version 1.0
-- @link
--   cfillion.ca https://cfillion.ca
--   Request post https://forum.cockos.com/showthread.php?p=2349505
-- @donation https://paypal.me/cfillion

local mint, maxt = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
if mint == maxt then return end

for i = 0, reaper.CountSelectedMediaItems(nil) - 1 do
  local item = reaper.GetSelectedMediaItem(nil, i)
  local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
  local len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')

  mint = math.min(mint, pos)
  maxt = math.max(maxt, pos + len)
end

reaper.GetSet_LoopTimeRange(true, false, mint, maxt, false)
