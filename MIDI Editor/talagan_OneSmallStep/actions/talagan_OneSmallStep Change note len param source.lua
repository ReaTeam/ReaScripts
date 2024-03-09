-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

package.path      = debug.getinfo(1,"S").source:match[[^@?(.*[\/])actions[\/][^\/]-$]] .."?.lua;".. package.path;
local engine_lib  = require "classes/engine_lib";
local mode        = select(2, reaper.get_action_context()):match("%- ([^%s]*)%.lua$");

if mode == 'OSS' then
  engine_lib.setNoteLenParamSource(engine_lib.NoteLenParamSource.OSS);
elseif mode == 'ItemConf' then
  engine_lib.setNoteLenParamSource(engine_lib.NoteLenParamSource.ItemConf);
elseif mode == 'ProjectGrid' then
  engine_lib.setNoteLenParamSource(engine_lib.NoteLenParamSource.ProjectGrid);
end
