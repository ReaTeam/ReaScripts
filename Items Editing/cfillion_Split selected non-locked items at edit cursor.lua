-- @description Split selected non-locked items at edit cursor
-- @version 1.0
-- @author cfillion
-- @link Forum Thread http://forum.cockos.com/showthread.php?t=189347
-- @donation https://www.paypal.me/cfillion
-- @about
--   This script splits selected non-locked items at edit cursor.
--
--   The logic is inspired by spk77's script "Split all items at edit cursor".

local self = ({reaper.get_action_context()})[2]:match('([^/\\_]+).lua$')
local bucket, cursor = {}, reaper.GetCursorPosition()
local UNDO_STATE_ITEMS = 4

for i = 0, reaper.CountSelectedMediaItems() - 1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  local locked = reaper.GetMediaItemInfo_Value(item, 'C_LOCK') > 0
  local length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
  local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')

  if not locked and pos <= cursor and pos + length >= cursor then
    table.insert(bucket, item)
  end
end

if #bucket == 0 then
  reaper.defer(function() end)
  return
end

reaper.Undo_BeginBlock()

for _, item in pairs(bucket) do
  reaper.SplitMediaItem(item, cursor)
end

reaper.UpdateArrange()
reaper.Undo_EndBlock(self, UNDO_STATE_ITEMS)
