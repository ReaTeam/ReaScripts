-- @description Live Keys Scripts
-- @author Larry Seyer
-- @version 1.0
-- @provides
--   . > Live_Inst_Track_1.lua
--   larryseyer_Live Keys Scripts/Live_Inst_Track_2.lua
--   larryseyer_Live Keys Scripts/New file 4.lua > larryseyer_Live Keys Scripts/Live_Inst_Track_3.lua
--   larryseyer_Live Keys Scripts/New file 5.lua > larryseyer_Live Keys Scripts/Live_Inst_Track_4.lua
--   larryseyer_Live Keys Scripts/New file 6.lua > larryseyer_Live Keys Scripts/Live_Inst_Track_5.lua
--   larryseyer_Live Keys Scripts/New file 7.lua > larryseyer_Live Keys Scripts/Live_Inst_Track_6.lua
--   larryseyer_Live Keys Scripts/New file 8.lua > larryseyer_Live Keys Scripts/Live_Inst_Track_7.lua
--   larryseyer_Live Keys Scripts/New file 9.lua > larryseyer_Live Keys Scripts/Live_Inst_Track_8.lua
--   larryseyer_Live Keys Scripts/New file 10.lua > larryseyer_Live Keys Scripts/Live_Inst_Track_9.lua
--   larryseyer_Live Keys Scripts/New file 11.lua > larryseyer_Live Keys Scripts/Live_Inst_Track_10.lua
--   larryseyer_Live Keys Scripts/New file 12.lua > larryseyer_Live Keys Scripts/Live_Inst_Track_11.lua
--   larryseyer_Live Keys Scripts/New file 13.lua > larryseyer_Live Keys Scripts/Live_Inst_Track_12.lua
--   larryseyer_Live Keys Scripts/New file 14.lua > larryseyer_Live Keys Scripts/Live_Inst_Track_13.lua
--   larryseyer_Live Keys Scripts/New file 15.lua > larryseyer_Live Keys Scripts/Live_Inst_Track_14.lua
--   larryseyer_Live Keys Scripts/New file 16.lua > larryseyer_Live Keys Scripts/Live_Inst_Track_15.lua
--   larryseyer_Live Keys Scripts/New file 17.lua > larryseyer_Live Keys Scripts/Live_Inst_Track_16.lua
--   larryseyer_Live Keys Scripts/New file 18.lua > larryseyer_Live Keys Scripts/Live_Inst_Tracks_Reset.lua
--   larryseyer_Live Keys Scripts/New file 19.lua > larryseyer_Live Keys Scripts/Live_Inst_Misc.lua
-- @link
--   How-To Install Video https://www.youtube.com/watch?v=g506QrJ19-4
--   Author Website https://larryseyer.com/
--   Donation Page https://larryseyer.com/donate/
-- @about
--   Live Keys Scripts (NOW WORKS WITH MAC AND WINDOWS)
--
--   These scripts are designed for those who want to use Reaper for live performance such as a replacement for MainStage.
--
--   Using these scripts saves computing power by turning off ALL tracks and FX (up to 16 tracks) except the desired track allowing for more stable operation for a live performance using Reaper. Tracks that are disabled take no processing power.
--
--   This script differs from other scripts in that it allows for instantaneous switching from one track to another without cutting notes or effects off. In other words, delays, reverbs, and long string patches continue to sound when selecting new tracks.
--
--   In addition, bypassed tracks and FX are hidden out of view and only the selected track is visible (up to 16 tracks). This is done in order to allow for the automatic large track size increase when a track is selected this script performs.
--
--   Install these scripts in your 'Scripts' directory in Reaper.
--
--   The following video explains how to install and use the "Live Keys Scripts" for Reaper script files:
--
--   https://www.youtube.com/watch?v=g506QrJ19-4

--
-- Live_Inst (c) 2021 Larry Seyer All rights reserved
-- http://LarrySeyer.com
--

local this_live_track = 1

function get_script_path()
  if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
    return debug.getinfo(1,'S').source:match("(.*".."\\"..")"):sub(2) .. "\\" -- remove "@"
  end
    return debug.getinfo(1,'S').source:match("(.*".."/"..")"):sub(2) .. "/"
end

local path = string.format('%s/Live_Inst_Misc.lua', get_script_path())

dofile(path)

Live_Inst_Main_Logic(this_live_track)


