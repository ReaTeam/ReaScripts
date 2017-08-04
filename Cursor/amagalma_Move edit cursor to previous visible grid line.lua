-- @description amagalma_Move edit cursor to previous visible grid line
-- @author amagalma
-- @version 1.0
-- @about
--   # Moves the edit cursor to the previous grid line that is visible

reaper.Main_OnCommand(40755, 0) -- Snapping: Save snap state
reaper.Main_OnCommand(40754, 0) -- Snapping: Enable snap
local cursorpos = reaper.GetCursorPosition()
local grid = cursorpos
while (grid >= cursorpos) do
    cursorpos = cursorpos - 0.05
    grid = reaper.SnapToGrid(0, cursorpos)
end
reaper.SetEditCurPos(grid,1,1)
reaper.Main_OnCommand(40756, 0) -- Snapping: Restore snap state
