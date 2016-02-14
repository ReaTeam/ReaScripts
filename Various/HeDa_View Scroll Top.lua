--[[
   * ReaScript Name: View Scroll Top
   * Lua script for Cockos REAPER
   * Author: HeDa
   * Author URI: http://forum.cockos.com/member.php?u=47822
   * Licence: GPL v3
   * Version: 1.0
]]

local function Save_Selected_Tracks(table)
	for i=1, reaper.CountTracks(0) do
		table[i]=reaper.IsTrackSelected(reaper.GetTrack(0,i-1))
	end
end
local function Restore_Selected_Tracks(table)
	for k,v in pairs(table) do
		reaper.SetTrackSelected(reaper.GetTrack(0,k-1), v)
	end
end

reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
	tracks = {}
	Save_Selected_Tracks(tracks)
	reaper.SetOnlyTrackSelected(reaper.GetTrack(0,0)) -- select first
	reaper.Main_OnCommand(40913,0) -- scroll into view
	Restore_Selected_Tracks(tracks) 
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock2(0, "Scroll Top", -1)
