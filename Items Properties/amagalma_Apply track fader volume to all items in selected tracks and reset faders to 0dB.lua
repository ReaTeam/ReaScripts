-- @description Apply track fader volume to all items in selected tracks and reset faders to 0dB
-- @author amagalma
-- @version 1.0
-- @donation https://www.paypal.me/amagalma

local sel_tracks = reaper.CountSelectedTracks( 0 )

if sel_tracks == 0 then
  reaper.MB("No changes...", "No tracks selected!", 0 )
  reaper.defer(function() end)
end

reaper.PreventUIRefresh( 1 )
reaper.Undo_BeginBlock2( 0 )

for tr = 0, sel_tracks-1 do
  local track = reaper.GetSelectedTrack( 0, tr )
  local tr_vol = reaper.GetMediaTrackInfo_Value( track, "D_VOL" )
  if tr_vol ~= 1 then
    reaper.SetMediaTrackInfo_Value( track, "D_VOL", 1 )
    local item_cnt = reaper.CountTrackMediaItems( track )
    for it = 0, item_cnt-1 do
      local item = reaper.GetTrackMediaItem( track, it )
      local it_vol = reaper.GetMediaItemInfo_Value( item, "D_VOL" )
      reaper.SetMediaItemInfo_Value( item, "D_VOL", it_vol*tr_vol )
    end
  end
end

reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()
reaper.Undo_EndBlock2( 0, "Reset track faders to 0dB", 1|4 )
