-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

package.path      = debug.getinfo(1,"S").source:match[[^@?(.*[\/])actions[\/][^\/]-$]] .. "classes/" .. "?.lua;".. package.path

local E           = require "engine_lib";
local param       = select(2, reaper.get_action_context()):match("%- ([^%s]*)%.lua$");

if not param or param == "" then
  param = "Commit"
end

E.reaperAction(param)
