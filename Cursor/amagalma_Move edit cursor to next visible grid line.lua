-- @description amagalma_Move edit cursor to next visible grid line
-- @author amagalma
-- @version 1.04
-- @changelog
--   - Improved behavior with framerate grid and lots of frames/sec
-- @about
--   # Moves the edit cursor to the next grid line that is visible


reaper.Main_OnCommand(40755, 0) -- Snapping: Save snap state
reaper.Main_OnCommand(40754, 0) -- Snapping: Enable snap
local cursorpos = reaper.GetCursorPosition()
local grid_duration
if reaper.GetToggleCommandState( 41885 ) == 1 then -- Toggle framerate grid
  grid_duration = 0.4/reaper.TimeMap_curFrameRate( 0 )
else
  local _, division = reaper.GetSetProjectGrid( 0, 0, 0, 0, 0 )
  local tmsgn_cnt = reaper.CountTempoTimeSigMarkers( 0 )
  local _, tempo
  if tmsgn_cnt == 0 then
    tempo = reaper.Master_GetTempo()
  else
    local active_tmsgn = reaper.FindTempoTimeSigMarker( 0, cursorpos )
    _, _, _, _, tempo = reaper.GetTempoTimeSigMarker( 0, active_tmsgn )
  end
  grid_duration = 60/tempo * division
end

local grid = cursorpos
while (grid <= cursorpos) do
    cursorpos = cursorpos + grid_duration
    grid = reaper.SnapToGrid(0, cursorpos)
end
reaper.SetEditCurPos(grid,1,1)
reaper.Main_OnCommand(40756, 0) -- Snapping: Restore snap state
reaper.defer(function() end)
