-- @description Move edit cursor to previous visible grid line
-- @author amagalma
-- @version 1.09
-- @changelog If grid not visible, then move by 1 pixel
-- @about
--   # Moves the edit cursor to the previous visible grid line or by 1 pixel


if reaper.GetToggleCommandState(40145) == 0 then 
  reaper.Main_OnCommand(40104, 0) -- View: Move cursor left one pixel
  return reaper.defer(function() end)
end
reaper.PreventUIRefresh( 1 )
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

if cursorpos > 0 then
  local snapped, grid = reaper.SnapToGrid(0, cursorpos)
  if snapped < cursorpos then
    grid = snapped
  else
    grid = cursorpos
    while (grid >= cursorpos) do
        cursorpos = cursorpos - grid_duration
        if cursorpos >= grid_duration then
          grid = reaper.SnapToGrid(0, cursorpos)
        else
          grid = 0
        end
    end
  end
  reaper.SetEditCurPos(grid,1,1)
end
reaper.Main_OnCommand(40756, 0) -- Snapping: Restore snap state
reaper.PreventUIRefresh( -1 )
reaper.defer(function() end)
