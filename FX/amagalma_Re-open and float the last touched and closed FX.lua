-- @description Re-open and float the last touched and closed FX
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showpost.php?p=2332348&postcount=22
-- @donation https://www.paypal.me/amagalma
-- @about
--   Re-opens and floats the last FX that was touched and closed.
--
--   *Note: not the last focused FX but the last touched!


local ok, tracknumber, fxnumber = reaper.GetLastTouchedFX()
local ok2, tracknumber2, _, fxnumber2 = reaper.GetFocusedFX()

if ok and (ok2 == 0 or (tracknumber ~= tracknumber2 and fxnumber ~= fxnumber2)) then
  local track = reaper.CSurf_TrackFromID( tracknumber & 0x0000FFFF, false )
  local item_idx = tracknumber >> 16
  if item_idx == 0 then
    local fxid = fxnumber & 0x0000FFFF
    local record = fxnumber >> 24
    if record > 0 then
      reaper.TrackFX_Show( track, fxid+0x1000000, 3 )
    else
      reaper.TrackFX_Show( track, fxid, 3 )
    end
  else
    local item = reaper.GetTrackMediaItem( track, item_idx - 1 )
    local fxid = fxnumber & 0x0000FFFF
    local take =  reaper.GetMediaItemTake( item, fxnumber >> 16 )
    reaper.TakeFX_Show( take, fxid, 3 )
  end
end
reaper.defer(function() end)
