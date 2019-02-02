-- @description Move edit cursor to previous visible grid line
-- @author amagalma
-- @version 1.02
-- @about
--   # Moves the edit cursor to the previous grid line that is visible

--[[
 * Changelog:
 * v1.02 (2018-05-28)
  + fix Reaper crash when no visible grid at the start of the project
--]]

function NoUndoPoint() end 
reaper.Main_OnCommand(40755, 0) -- Snapping: Save snap state
reaper.Main_OnCommand(40754, 0) -- Snapping: Enable snap
local cursorpos = reaper.GetCursorPosition()
if cursorpos > 0 then
  local grid = cursorpos
  while (grid >= cursorpos) do
      cursorpos = cursorpos - 0.05
      if cursorpos >= 0.05 then
        grid = reaper.SnapToGrid(0, cursorpos)
      else
        grid = 0
      end
  end
  reaper.SetEditCurPos(grid,1,1)
end  
reaper.Main_OnCommand(40756, 0) -- Snapping: Restore snap state
reaper.defer(NoUndoPoint)
