-- @noindex

--
-- Live_Inst (c) 2021 Larry Seyer All rights reserved
-- http://LarrySeyer.com
--

local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local this_live_track = tonumber(script_name:match("Track (%d+)")) or -1
local path = debug.getinfo(1, 'S').source:match('^@(.+)[\\//]')

dofile(string.format('%s/larryseyer_Live keys scripts.lua', path))
Live_Inst_Main_Logic(this_live_track)
