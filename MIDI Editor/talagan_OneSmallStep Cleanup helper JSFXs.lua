-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path;

local helper_lib = require "talagan_OneSmallStep/talagan_OneSmallStep Helper lib";

reaper.Undo_BeginBlock();
helper_lib.cleanupAllTrackFXs();
reaper.Undo_EndBlock("One Small Step - Cleanup helper JSFXs",-1);