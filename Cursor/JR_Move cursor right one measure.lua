-- @description Move cursor right one measure
-- @author JRTaylorMusic
-- @version 1.0

--[[
 * ReaScript Name: Move cursor right one measure
 * Description: 
 * Instructions: Run
 * Screenshot: 
 * Author: 
 * Author URI: 
 * Repository: 
 * Repository URI: 
 * File URI: 
 * Licence: GPL v3
 * Forum Thread: 
 * Forum Thread URI: 
 * REAPER: 5.0
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2016-01-29)
  + Initial Release
--]]


-- USER CONFIG AREA ---------------------------------------------------------

console = true -- true/false: display debug messages in the console

----------------------------------------------------- END OF USER CONFIG AREA


-- Display a message in the console for debugging
function Msg(value)
  if console then
    reaper.ShowConsoleMsg(tostring(value) .. "\n")
  end
end


-- Main function
function main()
  _,returngrid = reaper.GetSetProjectGrid(0,false)
  reaper.SetProjectGrid(0,1)
  reaper.Main_OnCommand(40647,0) -- move cursor right by grid division
  reaper.SetProjectGrid(0,returngrid)-- revert to prior grid division

end


-- INIT ---------------------------------------------------------------------

-- Here: your conditions to avoid triggering main without reason.

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main()

reaper.Undo_EndBlock("Move cursor right one measure", -1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)
