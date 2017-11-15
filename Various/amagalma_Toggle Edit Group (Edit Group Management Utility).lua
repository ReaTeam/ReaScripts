-- @noindex

-- to be used with amagalma_Edit Group Management Utility
-- thanks to cfilion for helping me bundle the actions into a package

local groupId = ({reaper.get_action_context()})[2]:match('Toggle Edit Group (%d+)')

reaper.SetExtState( "Edit Groups", "Active group", groupId, false )
reaper.defer(function () end )
