-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path;

local param   = select(2, reaper.get_action_context()):match("%- ([^%s]*)%.lua$");

local engine_lib = require "talagan_OneSmallStep/talagan_OneSmallStep Engine lib";

local mode = engine_lib.InputMode[param];
if mode then
  engine_lib.setInputMode(mode)
end
