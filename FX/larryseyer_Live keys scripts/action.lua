-- @noindex

--
-- Live_Inst (c) 2021 Larry Seyer All rights reserved
-- http://LarrySeyer.com
--

local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local this_live_track = tonumber(script_name:match("Track (%d+)")) or -1

function get_script_path()
  if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
    return debug.getinfo(1,'S').source:match("(.*".."\\"..")"):sub(2) .. "\\" -- remove "@"
  end
    return debug.getinfo(1,'S').source:match("(.*".."/"..")"):sub(2) .. "/"
end

local path = string.format('%s/../larryseyer_Live keys scripts.lua', get_script_path())

dofile(path)

Live_Inst_Main_Logic(this_live_track)
