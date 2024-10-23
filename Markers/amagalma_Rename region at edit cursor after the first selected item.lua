-- @description Rename region at edit cursor after the first selected item
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showpost.php?p=2358410&postcount=20
-- @donation https://www.paypal.me/amagalma

local msg = "Please, select an item and place the edit cursor inside the region you want to rename"

local item = reaper.GetSelectedMediaItem( 0, 0 )
if not item then
  reaper.MB( msg, "No item selected!", 0 )
  return
end

local _, rg_idx = reaper.GetLastMarkerAndCurRegion( 0,  reaper.GetCursorPositionEx( 0 ) )
if rg_idx == -1 then
  reaper.MB( msg, "Edit cursor not inside a region!", 0 )
  return
end

local it_name
local take = reaper.GetActiveTake( item )
if take then
  it_name = reaper.GetTakeName( take )
else
  it_name = ({reaper.GetSetMediaItemInfo_String( item, "P_NOTES", "", false )})[2]
end
local _, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, rg_idx )
if name == it_name then return end

local ok = reaper.SetProjectMarker4( 0, markrgnindexnumber, isrgn, pos, rgnend, it_name, color, it_name == "" and 1 or 0 )
if ok then
  reaper.Undo_OnStateChangeEx2( 0, "Name region after selected item", 8, -1 )
end
