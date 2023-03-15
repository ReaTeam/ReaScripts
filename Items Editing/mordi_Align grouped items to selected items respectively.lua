-- @description Align grouped items to selected items respectively
-- @author Mordi
-- @version 1.0
-- @changelog Initial release.
-- @about # This script will align any items that are in the same group as selected items. Position only.

-- Print function
function print(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end

function get_selected_items_data()
  local t={}
  for i=1, reaper.CountSelectedMediaItems(0) do
    t[i] = {}
    local item = reaper.GetSelectedMediaItem(0, i-1)
    if item ~= nil then
      t[i].item = item
      t[i].pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      t[i].grp = reaper.GetMediaItemInfo_Value(item, "I_GROUPID")
    end
  end
  return t
end

data = get_selected_items_data()
items_num = reaper.CountMediaItems(0)
items_to_move = {}
index = 1
for i=1, #data do
  for n=1, items_num do
    local item = reaper.GetMediaItem(0, n-1)
    local grp = reaper.GetMediaItemInfo_Value(item, "I_GROUPID")
    if item ~= data[i].item and grp == data[i].grp then
      items_to_move[index] = {}
      items_to_move[index].item = item
      items_to_move[index].pos = data[i].pos
      index = index + 1
    end
  end
end

for i=1, #items_to_move do
  reaper.SetMediaItemInfo_Value(items_to_move[i].item, "D_POSITION", items_to_move[i].pos)
end
