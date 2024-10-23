-- @description Unselect items not within time selection
-- @author Edgemeal
-- @version 1.0
-- @link Forum https://forum.cockos.com/showthread.php?t=223042
-- @about Only a part of an item needs to be within the time selection

local s_time, e_time = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
if s_time == e_time then return end

function ItemInTime(item)
  local s = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
  local e = s + reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
  if e > s_time and e_time >= e then return true end
  if e > e_time and s < e_time then return true end
  return false
end

reaper.Undo_BeginBlock(0)
local item_count = reaper.CountSelectedMediaItems(0)
for i = item_count-1, 0, -1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  reaper.SetMediaItemSelected(item, ItemInTime(item))
end
reaper.Undo_EndBlock('Unselect items not within time selection', -1)
reaper.UpdateArrange()