-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step. Will replay the n last measures.

package.path      = debug.getinfo(1,"S").source:match[[^@?(.*[\/])actions[\/][^\/]-$]] .."?.lua;".. package.path;
local engine_lib  = require "classes/engine_lib";

engine_lib.setPlaybackMarkerAtCurrentPos();
