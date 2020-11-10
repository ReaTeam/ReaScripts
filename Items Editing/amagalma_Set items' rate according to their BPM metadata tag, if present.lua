-- @description Set items' rate according to their BPM metadata tag, if present
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showpost.php?p=2362937&postcount=6
-- @donation https://www.paypal.me/amagalma


local item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt == 0 then return end

local tempo = reaper.Master_GetTempo()
local undo

reaper.PreventUIRefresh( 1 )

for i = 0, item_cnt-1 do
  local item = reaper.GetSelectedMediaItem( 0, i )
  local take = reaper.GetActiveTake( item )
  if take then
    local src = reaper.GetMediaItemTake_Source( take )
    local src_bpm = tonumber(({reaper.CF_GetMediaSourceMetadata( src, "BPM", "" )})[2]) or
      tonumber(({reaper.CF_GetMediaSourceMetadata( src, "bpm", "" )})[2])
    if src_bpm and tempo ~= src_bpm then
      local diff = tempo/src_bpm
      local len = reaper.GetMediaSourceLength( src )
      local cur_rate = reaper.GetMediaItemTakeInfo_Value( take, "D_PLAYRATE" )
      if cur_rate ~= diff then
        reaper.SetMediaItemInfo_Value( item, "D_LENGTH", len / diff )
        reaper.SetMediaItemTakeInfo_Value( take, "D_PLAYRATE", diff )
        undo = true
      end
    end
  end
end

reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()

if undo then
  reaper.Undo_OnStateChange( "Set items' rate according to bpm metadata tag" )
end
