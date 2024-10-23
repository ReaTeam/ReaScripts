-- @description Create Razor Edit on selected tracks within Region bounds under mouse or edit cursor (clear other RE areas)
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showthread.php?t=262254
-- @donation https://www.paypal.me/amagalma
-- @about
--   Creates a Razor edits on the selected tracks within the Region that is under the mouse cursor or the edit cursor.
--   Clears all other razor edits.


local position = reaper.BR_PositionAtMouseCursor(true)
if position == -1 then position = reaper.GetCursorPosition() end
local _, regionidx = reaper.GetLastMarkerAndCurRegion( 0, position )
local track_cnt = reaper.CountSelectedTracks( 0 )
if regionidx == -1 or track_cnt == 0 then return reaper.defer(function() end) end

reaper.Undo_BeginBlock()

local _, _, rgnpos, rgnend = reaper.EnumProjectMarkers( regionidx )
reaper.PreventUIRefresh( 1 )
reaper.Main_OnCommand(42406, 0) -- Clear all areas

for tr = 0, track_cnt-1 do
  local track = reaper.GetSelectedTrack( 0, tr )
  local t, t_cnt = {[1] = string.format('%f %f ""', rgnpos, rgnend )}, 1
  for en = 0, reaper.CountTrackEnvelopes( track )-1 do
    local envelope = reaper.GetTrackEnvelope( track, en )
    local _, chunk = reaper.GetEnvelopeStateChunk( envelope, "", false )
    if chunk:match("VIS (1)") == "1" then -- env visible
       local _, guid = reaper.GetSetEnvelopeInfo_String( envelope, "GUID", "", false )
        t_cnt = t_cnt + 1
        t[t_cnt] = string.format('%f %f "%s"', rgnpos, rgnend, guid )
      end
  end
  reaper.GetSetMediaTrackInfo_String( track, "P_RAZOREDITS", table.concat(t, " "), true )
end
reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()

reaper.Undo_EndBlock( "Create Region Razor edits on selected tracks", 1 )
