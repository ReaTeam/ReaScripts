-- @description Toggle guide line size between full arrange or item height
-- @author amagalma
-- @version 1.00
-- @about
--   # Toggles the guide line size between full arrange height or item height 
--   - To be used along "amagalma_Toggle show editing guide line on item under mouse cursor in Main Window or in MIDI Editor.lua"
--   - Can be used as a toolbar action

local cmdID = ({reaper.get_action_context()})[4]
local state = reaper.GetToggleCommandState( cmdID )
reaper.SetToggleCommandState( 0, cmdID, state ~= 1 and 1 or 0 )
reaper.RefreshToolbar2( 0, cmdID )
reaper.defer(function() end)
