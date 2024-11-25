-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of Talagan Docking Tools

package.path      = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path

local docking_lib = require "talagan_Docking tools/docking_lib"


local _, sfname = reaper.get_action_context()
local param     = tonumber(sfname.match(sfname,"%((.*)%).lua"))

docking_lib.resizeBottommostDock(param)
