-- @description Clear all take envelopes for all selected items
-- @author amagalma
-- @version 1.0
-- @link https://forum.cockos.com/showpost.php?p=2468431&postcount=2590
-- @donation https://www.paypal.me/amagalma
-- @about Clears all take envelopes for all takes of every selected item


local item_cnt = reaper.CountSelectedMediaItems(0)
if item_cnt == 0 then return reaper.defer(function() end) end

reaper.PreventUIRefresh( 1 )

for i = 0, item_cnt-1 do
  local item = reaper.GetSelectedMediaItem( 0, i )
  local _, chunk = reaper.GetItemStateChunk( item, "", false )
  local t, c = {}, 0
  local record = true
  local change = false
  for line in chunk:gmatch("[^\n]+") do
    if line:match("^<%u+ENV$") or line:match("^<PARMENV ") then
      record = false
      change = true
    end
    if record then
      c = c +1
      t[c] = line
    end
    if record == false and line == ">" then
      record = true
    end
  end
  if change then
  	reaper.SetItemStateChunk( item, table.concat(t, "\n"), false )
  end
end

reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()
reaper.Undo_OnStateChange("Delete all take envelopes for selected items")
