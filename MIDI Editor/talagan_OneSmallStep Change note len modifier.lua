-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path;

local modifier   = select(2, reaper.get_action_context()):match("%- ([^%s]*)%.lua$");

local engine_lib = require "talagan_OneSmallStep/talagan_OneSmallStep Engine lib";


if modifier == 'Triplet' then
  engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Triplet);
elseif modifier == 'Dotted' then
  engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Dotted);
elseif modifier == 'Straight' then
  engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Straight);
end