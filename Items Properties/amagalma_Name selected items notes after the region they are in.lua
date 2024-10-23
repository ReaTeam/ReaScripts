-- @description Name selected items' notes after the region they are in
-- @author amagalma
-- @version 1.00

local item_cnt = reaper.CountSelectedMediaItems( 0 )
local _, _, num_regions = reaper.CountProjectMarkers( 0 )
if item_cnt == 0 or num_regions == 0 then return reaper.defer(function() end) end
for i = 0, item_cnt-1 do
  local item = reaper.GetSelectedMediaItem( 0, i )
  local item_pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
  local _, regionidx = reaper.GetLastMarkerAndCurRegion( 0, item_pos )
  local _, _, _, _, name = reaper.EnumProjectMarkers( regionidx )
  if name ~= "" then
    reaper.GetSetMediaItemInfo_String( item, "P_NOTES", name, true )
  end
end
reaper.UpdateArrange()
reaper.Undo_OnStateChange( "Name selected items' notes after the region they are in" )
