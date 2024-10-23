-- @description Select next item with take FX
-- @author amagalma
-- @version 1.01
-- @changelog Scroll to item if needed
-- @donation https://www.paypal.me/amagalma


local sel_items = reaper.CountSelectedMediaItems( 0 )
if sel_items == 0 then
  reaper.MB("Please, select one or more items.", "No items selected!", 0)
  return
end

local change = false
local tracks, tracks2 = {}, {}

-- Store last item on each track
for i = 0, sel_items-1 do
  local item = reaper.GetSelectedMediaItem( 0, i )
  local track = reaper.GetMediaItemTrack( item )
  tracks[track] = item
end


-- Find next item with take FX
for track, item in pairs(tracks) do
  local ip = reaper.GetMediaItemInfo_Value( item, "IP_ITEMNUMBER" )
  local track_items_cnt = reaper.CountTrackMediaItems( track )
  for i = ip+1, track_items_cnt-1 do
    local item = reaper.GetTrackMediaItem( track, i )
    local take = reaper.GetActiveTake( item )
    if take and reaper.TakeFX_GetCount( take ) > 0 then
      if not tracks2[track] then
        tracks2[track] = { i, track_items_cnt }
        change = true
      end
    end
  end
end


-- Select only the item with the take FX
if change then
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh( 1 )
  for track, info in pairs(tracks2) do
    for i = 0, info[2]-1 do
      local item = reaper.GetTrackMediaItem( track, i )
      reaper.SetMediaItemSelected( item, i == info[1] )
    end
  end

-- Scroll arrange
  local item = reaper.GetSelectedMediaItem( 0, 0 )
  local ar_st, ar_en = reaper.GetSet_ArrangeView2( 0, false, 0, 0, 0, 0 )
  local it_st = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
  if it_st >= ar_en then
    reaper.GetSet_ArrangeView2( 0, true, 0, 0, it_st, it_st+(ar_en-ar_st) )
  end
  
  reaper.UpdateArrange()
  reaper.PreventUIRefresh( -1 )
  reaper.Undo_EndBlock( "Select next Item with TakeFX", 4 )
end
