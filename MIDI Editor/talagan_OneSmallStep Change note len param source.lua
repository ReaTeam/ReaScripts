-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path;

local mode   = select(2, reaper.get_action_context()):match("%- ([^%s]*)%.lua$");

local engine_lib = require "talagan_OneSmallStep/talagan_OneSmallStep Engine lib";

if mode == 'OSS' then
  engine_lib.setNoteLenParamSource(engine_lib.NoteLenParamSource.OSS);
elseif mode == 'ItemConf' then
  engine_lib.setNoteLenParamSource(engine_lib.NoteLenParamSource.ItemConf);
elseif mode == 'ProjectGrid' then
  engine_lib.setNoteLenParamSource(engine_lib.NoteLenParamSource.ProjectGrid);
end