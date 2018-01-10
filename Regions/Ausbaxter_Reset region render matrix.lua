--[[
 * ReaScript Name: Reset region render matrix
 * Description: Clears all enabled tracks from the region render matrix
 * Instructions: run
 * Author: Ausbaxter
 * Author URI: https://forum.cockos.com/member.php?u=107072
 * Repository: GitHub > Ausbaxter
 * Repository URL: https://github.com/ausbaxter/Reascripts
 * File URI: https://github.com/ausbaxter/Reascripts/Region Render Matrix/Reset region render matrix
 * Licence: GPL v3
 * REAPER: 5.xx
 * Extensions:
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2018-01-09)
  + Initial Release
--]]

function GetRegions()--returns a table of regions in order to get real region indexes
    local marker_count = reaper.CountProjectMarkers(0)
    local region_table = {}
    for i = 0, marker_count do
        local _, isrgn, _, _, _, idx = reaper.EnumProjectMarkers(i)
        if isrgn then
            table.insert(region_table, idx)
        end
    end
    return region_table
end

function Main()
    --resets matrix without requiring mouse over
    reaper.TrackList_AdjustWindows( false ) --thanks x-raym!
    t_regions  = GetRegions()
    for i, region_idx in pairs(t_regions) do
        local t = 0
        local t_temp_tracks = {}
        while reaper.EnumRegionRenderMatrix(0, region_idx, t) do
            t_temp_tracks[t]  = reaper.EnumRegionRenderMatrix(0, region_idx, t)
            t = t + 1
        end
        for i, track in pairs(t_temp_tracks) do
            reaper.SetRegionRenderMatrix(0, region_idx, track, -1)
        end
    end
    reaper.TrackList_AdjustWindows( true )
end

Main()
