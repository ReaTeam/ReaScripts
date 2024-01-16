-- @description Deselect odd-numbered items from selected items
-- @author KKKANTEN
-- @version 1.0
-- @about
--   タイトルの通り、複数選択したアイテムの奇数番目の選択を解除するスクリプトです。
--   アイテムを複数選択し、実行してください。
--
--   As the title suggests, this script deselects the odd-numbered items of multiple selected items.
--   Please select multiple items and execute. (machine translate)

selectedItemsNum = reaper.CountSelectedMediaItems(0);
selectedItemsArray = {};

for i = 0, selectedItemsNum, 1 do
  selectedItemsArray[#selectedItemsArray + 1] = reaper.GetSelectedMediaItem(0, i);
end

for i = 1, #selectedItemsArray, 2 do
  if selectedItemsArray[i] == nil then
    break
  end
  reaper.SetMediaItemSelected(selectedItemsArray[i], false);
  reaper.ThemeLayout_RefreshAll();
end
