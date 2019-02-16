-- @description amagalma_Fit vertically all tracks into view (if possible)
-- @author amagalma
-- @version 1.0
-- @about
--  # Zooms vertically to fit all tracks into view (if possible)
--  # No undo point creation

local reaper = reaper

-- Save non selected tracks
local unsel_tr = {}
local c = 0
local tr_cnt = reaper.CSurf_NumTracks( false )
for i = 0, tr_cnt do
  local track = reaper.CSurf_TrackFromID( i, false )
  if not reaper.IsTrackSelected( track ) then
    c = c + 1
    unsel_tr[c] = track
  end
end
reaper.PreventUIRefresh( 1 )
-- select all tracks (unselected ones)
for i = 1, #unsel_tr do
  reaper.SetTrackSelected( unsel_tr[i], true )
end
-- SWS: Vertical zoom to selected tracks
reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_VZOOMFIT'), 0)
-- Restore initial track selection
for i = 1, #unsel_tr do
  reaper.SetTrackSelected( unsel_tr[i], false )
end
reaper.PreventUIRefresh( -1 )
reaper.defer(function() end)
