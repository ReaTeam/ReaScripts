-- @description Rename region at edit cursor after the first selected track
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showpost.php?p=2358410&postcount=20
-- @donation https://www.paypal.me/amagalma

local msg = "Please, select a track and place the edit cursor inside the region you want to rename"

local track = reaper.GetSelectedTrack( 0, 0 )
if not track then
  reaper.MB( msg, "No track selected!", 0 )
  return
end

local _, rg_idx = reaper.GetLastMarkerAndCurRegion( 0,  reaper.GetCursorPositionEx( 0 ) )
if rg_idx == -1 then
  reaper.MB( msg, "Edit cursor not inside a region!", 0 )
  return
end

local _, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, rg_idx )
local _, tr_name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
if name == tr_name then return end

local ok = reaper.SetProjectMarker4( 0, markrgnindexnumber, isrgn, pos, rgnend, tr_name, color, tr_name == "" and 1 or 0 )
if ok then
  reaper.Undo_OnStateChangeEx2( 0, "Name region after selected track", 8, -1 )
end
