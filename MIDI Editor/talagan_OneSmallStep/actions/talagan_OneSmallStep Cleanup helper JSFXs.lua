-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

package.path      = debug.getinfo(1,"S").source:match[[^@?(.*[\/])actions[\/][^\/]-$]] .."?.lua;".. package.path;
local helper_lib  = require "classes/helper_lib";

reaper.Undo_BeginBlock();
helper_lib.cleanupAllTrackFXs();
reaper.Undo_EndBlock("One Small Step - Cleanup helper JSFXs",-1);