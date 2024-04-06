-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

package.path      = debug.getinfo(1,"S").source:match[[^@?(.*[\/])actions[\/][^\/]-$]] .. "classes/" .. "?.lua;".. package.path;
local S           = require "modules/settings";
local param       = select(2, reaper.get_action_context()):match("%- ([^%s]*)%.lua$");

S.setSetting("EditMode", param)
