-- @noindex

-- to be used with amagalma_Edit Group Management Utility
-- thanks to cfilion for helping me bundle the actions into a package

local cmd = reaper.NamedCommandLookup( "_RS062e32dccb7aa93d26fab14c9eb008a791e51882" )
local state = reaper.GetToggleCommandStateEx( 0, cmd )

if state ~= 1 then
  reaper.Main_OnCommand(cmd, 0) -- open Edit Group Management Utility
  reaper.SetCursorContext( 1 )
end
local groupId = ({reaper.get_action_context()})[2]:match('Toggle Edit Group (%d+)')
reaper.SetExtState( "Edit Groups", "Active group", groupId, false )
reaper.defer(function () end )
