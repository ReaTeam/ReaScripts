-- @description Close gaps (remove space) between selected items
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about - Removes the space between consecutive items for all selected items. Works on a track by track basis.

local item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt < 2 then return reaper.defer(function() end) end
local undo = false

local first_item = reaper.GetSelectedMediaItem( 0, 0 )
local position = reaper.GetMediaItemInfo_Value( first_item, "D_POSITION" ) + reaper.GetMediaItemInfo_Value( first_item, "D_LENGTH" )
local track = reaper.GetMediaItemTrack( first_item )

for it = 1, item_cnt-1 do
  local item = reaper.GetSelectedMediaItem( 0, it )
  local tr = reaper.GetMediaItemTrack( item )
  if tr == track then
    reaper.SetMediaItemPosition( item, position, false )
    undo = true
  else
    track = tr
  end
  position = reaper.GetMediaItemInfo_Value( item, "D_POSITION" ) + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
end

if undo then
  reaper.UpdateArrange()
  reaper.Undo_OnStateChange( "Close gaps between selected items" )
else
  reaper.defer(function() end)
end
