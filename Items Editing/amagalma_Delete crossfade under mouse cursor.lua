-- @description Delete crossfade under mouse cursor
-- @author amagalma
-- @version 2.00
-- @changelog
--   - Complete re-write
--   - Support for items in lanes
--   - SWS dependency
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Deletes the crossfade (if any) under the mouse cursor
--   - creates undo only if a crossfade was deleted
--   - does not work for multiple selected or grouped items atm
--   - requires SWS


local ok = false
local x, y = reaper.GetMousePosition()
local time = reaper.BR_PositionAtMouseCursor( false )
local item = {ptr = reaper.GetItemFromPoint(x, y, true)}
if item.ptr and time ~= -1 then
  reaper.PreventUIRefresh(1)
  local tolerance = 7/reaper.GetHZoomLevel()
  tolerance = tolerance > 0.02 and 0.02 or tolerance
  item.pos = reaper.GetMediaItemInfo_Value(item.ptr, "D_POSITION")
  item.len = reaper.GetMediaItemInfo_Value(item.ptr, "D_LENGTH")
  item.en = item.pos + item.len
  item.fadein_len = reaper.GetMediaItemInfo_Value( item.ptr, "D_FADEINLEN_AUTO" )
  item.fadeout_len = reaper.GetMediaItemInfo_Value( item.ptr, "D_FADEOUTLEN_AUTO" )
  item.lane = reaper.GetMediaItemInfo_Value( item.ptr, "I_FIXEDLANE" )
  item.track = reaper.GetMediaItemTrack( item.ptr )
  item.id = reaper.GetMediaItemInfo_Value( item.ptr, "IP_ITEMNUMBER" )
  if item.fadein_len > 0 and time >= item.pos and time <= item.pos + item.fadein_len + tolerance then
    for i = item.id-1 , 0, -1 do
      local itm = reaper.GetTrackMediaItem( item.track, i )
      local lane = reaper.GetMediaItemInfo_Value( itm, "I_FIXEDLANE" )
      if lane == item.lane then
        local fadeout_len = reaper.GetMediaItemInfo_Value( itm, "D_FADEOUTLEN_AUTO" )
        if math.abs(fadeout_len - item.fadein_len) < 0.00001 then
          reaper.SetMediaItemInfo_Value( item.ptr, "D_FADEINLEN_AUTO", 0 )
          reaper.SetMediaItemInfo_Value( item.ptr, "D_FADEINLEN", 0 )
          reaper.SetMediaItemInfo_Value( itm, "D_FADEOUTLEN_AUTO", 0 )
          reaper.SetMediaItemInfo_Value( itm, "D_FADEOUTLEN", 0 )
          ok = true
        end
        break
      end
    end
  elseif item.fadeout_len > 0 and time <= item.en and time >= item.en - item.fadeout_len - tolerance then
    for i = item.id+1, reaper.CountTrackMediaItems( item.track)-1 do
      local itm = reaper.GetTrackMediaItem( item.track, i )
      local lane = reaper.GetMediaItemInfo_Value( itm, "I_FIXEDLANE" )
      if lane == item.lane then
        local fadein_len = reaper.GetMediaItemInfo_Value( itm, "D_FADEINLEN_AUTO" )
        if math.abs(fadein_len - item.fadeout_len) < 0.00001 then
          reaper.SetMediaItemInfo_Value( itm, "D_FADEINLEN_AUTO", 0 )
          reaper.SetMediaItemInfo_Value( itm, "D_FADEINLEN", 0 )
          reaper.SetMediaItemInfo_Value( item.ptr, "D_FADEOUTLEN_AUTO", 0 )
          reaper.SetMediaItemInfo_Value( item.ptr, "D_FADEOUTLEN", 0 )
          ok = true
        end
        break
      end
    end
  end
  reaper.PreventUIRefresh(-1)
end

-- Undo point creation -------------------------------------------------------------------

if ok then
  reaper.UpdateArrange()
  reaper.Undo_OnStateChange2( 0, "Delete crossfade under mouse cursor" )
else
  reaper.defer(function() end)
end
