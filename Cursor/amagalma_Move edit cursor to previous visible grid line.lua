-- @description amagalma_Move edit cursor to previous visible grid line
-- @author amagalma
-- @version 1.05
-- @changelog
--   - Optimized code
-- @about
--   # Moves the edit cursor to the previous grid line that is visible


reaper.Main_OnCommand(40755, 0) -- Snapping: Save snap state
reaper.Main_OnCommand(40754, 0) -- Snapping: Enable snap
local cursorpos = reaper.GetCursorPosition()
local _, division = reaper.GetSetProjectGrid( 0, 0, 0, 0, 0 )
local tmsgn_cnt = reaper.CountTempoTimeSigMarkers( 0 )
local _, tempo
if tmsgn_cnt == 0 then
  tempo = reaper.Master_GetTempo()
else
  local active_tmsgn = reaper.FindTempoTimeSigMarker( 0, cursorpos )
  _, _, _, _, tempo = reaper.GetTempoTimeSigMarker( 0, active_tmsgn )
end
local grid_duration = 60/tempo * division
if cursorpos > 0 then
  local grid = cursorpos
  while (grid >= cursorpos) do
      cursorpos = cursorpos - grid_duration
      if cursorpos >= grid_duration then
        grid = reaper.SnapToGrid(0, cursorpos)
      else
        grid = 0
      end
  end
  reaper.SetEditCurPos(grid,1,1)
end
reaper.Main_OnCommand(40756, 0) -- Snapping: Restore snap state
reaper.defer(function() end)
