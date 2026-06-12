-- @description Reset gain to +0dB (un-normalize) for all the takes of the selected items
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about Like the native action "Item properties: Reset item take gain to +0dB (un-normalize)" but works for all the takes

local item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt == 0 then return end

reaper.PreventUIRefresh(1)

for i = 0, item_cnt - 1 do
  local item = reaper.GetSelectedMediaItem( 0 , i )
  for tk = 0, reaper.CountTakes( item ) - 1 do
    local take = reaper.GetTake( item, tk )
    reaper.SetMediaItemTakeInfo_Value( take, "D_VOL", 1 )
  end
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_OnStateChange( "Reset all takes to +0dB")
