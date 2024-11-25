-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of Talagan Docking Tools

package.path      = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path

local docking_lib = require "talagan_Docking tools/docking_lib"

if not docking_lib.CheckDependencies() then return end

docking_lib.maximizeMidiDock()
