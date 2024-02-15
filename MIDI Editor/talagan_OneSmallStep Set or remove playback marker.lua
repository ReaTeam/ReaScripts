-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step. Will replay the n last measures.

package.path      = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path;
local engine_lib  = require "talagan_OneSmallStep/talagan_OneSmallStep Engine lib";

engine_lib.setPlaybackMarkerAtCurrentPos();
