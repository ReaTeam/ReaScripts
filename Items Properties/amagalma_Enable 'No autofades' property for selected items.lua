-- @description Enable 'No autofades' property for selected items
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showthread.php?t=244523
-- @donation https://www.paypal.me/amagalma
-- @about Checks the "No autofades" property in the Media Item Properties


local item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt == 0 then return end
for i = 0, item_cnt-1 do
  local item = reaper.GetSelectedMediaItem( 0, i )
  local _, chunk = reaper.GetItemStateChunk( item, "", false )
  if not chunk:find("FADEFLAG 1") then
    chunk = chunk:gsub("(MUTE.-\n)", "%1FADEFLAG 1\n")
    reaper.SetItemStateChunk( item, chunk, false )
  end
end
reaper.Undo_OnStateChange( "Enable 'No autofades' property for selected items" )
