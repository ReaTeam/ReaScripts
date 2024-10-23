-- @description Deselect odd-numbered items from selected items
-- @author KKKANTEN
-- @version 1.0
-- @about
--   タイトルの通り、複数選択したアイテムの奇数番目の選択を解除するスクリプトです。
--   アイテムを複数選択し、実行してください。
--
--   As the title suggests, this script deselects the odd-numbered items of multiple selected items.
--   Please select multiple items and execute. (machine translate)

local UNDO_STATE_ITEMS = 4

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
for i = reaper.CountSelectedMediaItems(nil) - 1 & ~1, 0, -2 do
  local item = reaper.GetSelectedMediaItem(nil, i)
  reaper.SetMediaItemSelected(item, false)
end
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('Deselect odd-numbered items from selected items', UNDO_STATE_ITEMS)
