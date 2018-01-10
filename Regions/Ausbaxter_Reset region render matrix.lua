--@description Recall region render matrix (9 actions)
--@version 1.0
--@author ausbaxter
--@about
--    # Save and load region render matrix to project
--
--    This package provides actions to save, load and reset Reaper's region
--    render matrix.
--@provides
--    [main] . > ausbaxter_Recall region render matrix (slot 1).lua
--    [main] . > ausbaxter_Recall region render matrix (slot 2).lua
--    [main] . > ausbaxter_Recall region render matrix (slot 3).lua
--    [main] . > ausbaxter_Recall region render matrix (slot 4).lua
--    [main] . > ausbaxter_Reset region render matrix.lua
--    [main] . > ausbaxter_Save region render matrix (slot 1).lua
--    [main] . > ausbaxter_Save region render matrix (slot 2).lua
--    [main] . > ausbaxter_Save region render matrix (slot 3).lua
--    [main] . > ausbaxter_Save region render matrix (slot 4).lua
--@changelog
--  + Initial release

--------------------------------------------------------------------------------------------------------

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
    reaper.Undo_BeginBlock()
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
    reaper.Undo_EndBlock("Reset region render matrix",1)
end

Main()
