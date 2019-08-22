-- @description Enable or disable external timecode synchronization
-- @author cfillion
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > cfillion_Enable external timecode synchronization.lua
--   [main] . > cfillion_Disable external timecode synchronization.lua
-- @about This package provides two actions for enabling or disabling REAPER's external timecode synchronization.

local ACTION = 40620
local modes = {Enable=1, Disable=0}
local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local state = reaper.GetToggleCommandState(ACTION)
local mode = assert(modes[name:match('^%w+')], 'Invalid script filename')

if state ~= mode then
  reaper.Main_OnCommand(ACTION, 0)
end
