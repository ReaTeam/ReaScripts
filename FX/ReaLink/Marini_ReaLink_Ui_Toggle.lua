-- @noindex

local commandID = ({reaper.get_action_context()})[4]
local toggle = reaper.GetToggleCommandState(commandID) == 1

reaper.SetToggleCommandState(0,commandID, toggle and 0 or 1)
reaper.RefreshToolbar(commandID)



