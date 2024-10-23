-- @description Close gaps (remove space) between all items of selected tracks
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about - Removes the space between consecutive items of all the items on the selected tracks. Leaves the first item of each track at its original position.


local track_cnt = reaper.CountSelectedTracks( 0 )
if track_cnt == 0 then return reaper.defer(function() end) end
local undo = false

for tr = 0, track_cnt-1 do
  local track = reaper.GetSelectedTrack( 0, tr )
  local item_cnt = reaper.CountTrackMediaItems( track )
  if item_cnt > 1 then
    local position
    for it = 0, item_cnt-1 do
      local item = reaper.GetTrackMediaItem( track, it )
      if position then
        reaper.SetMediaItemPosition( item, position, false )
        undo = true
      end
      position = reaper.GetMediaItemInfo_Value( item, "D_POSITION" ) +
      reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
    end
  end
end

if undo then
  reaper.UpdateArrange()
  reaper.Undo_OnStateChange( "Close gaps between items for selected tracks" )
else
  reaper.defer(function() end)
end
