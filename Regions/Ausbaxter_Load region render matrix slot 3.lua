--[[
 * ReaScript Name: Load region render matrix slot n
 * Description: Allows quick storage and recall of reaper render matrix.
 * Instructions: Make track selections in region matrix, use the "complementary Save region render matrix slot n" to save the setup. 
      Use the 'load' scripts to recall.
 * Author: Ausbaxter
 * Author URI: https://forum.cockos.com/member.php?u=107072
 * Repository: GitHub > Ausbaxter
 * Repository URL: https://github.com/ausbaxter/Reascripts
 * File URI: https://github.com/ausbaxter/Reascripts/Region Render Matrix/Load region render matrix slot 3
 * Licence: GPL v3
 * REAPER: 5.xx
 * Extensions: SWS Extension
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2018-01-09)
  + Initial Release
--]]
--------------------User Area---------------------------------------------------------------------------
--To create more save slots duplicate this script and change the slot number variable

slot_number = 3 --only use integers


--------------------------------------------------------------------------------------------------------
function Msg(msg) --debug
    --reaper.ShowConsoleMsg("")
    reaper.ShowConsoleMsg(msg .. "\n")
end

function TableCopy(table)--returns a copy of a table, enables passing by value behavior
    local new_table = {}
    for i, k in pairs(table) do
        new_table[i] = k
    end
    return new_table  
end

function GetTrackString(track)
    local t_string = string.match(tostring(track), "%d%w*")
    return t_string
end

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

function DeserializeData(data)--converts region matrix string to table
    local data_table = {}
    local tr_table = {}
    for matrix in data:gmatch("%d+[(][{%w-}+,]*[)]") do
        for region in matrix:gmatch("%d+[(]") do
            r_idx = tonumber(region:match("%d*"))
            for tracks in matrix:gmatch("[(][{%w-},]+") do
                for track in tracks:gmatch("{[%w+-]+}") do
                    if track == "{master}" then track = reaper.GetTrackGUID(reaper.GetMasterTrack(0)) end
                    table.insert(tr_table, track)
                end
            end
            data_table[r_idx] = TableCopy(tr_table)
            tr_table = {}
        end
    end
    return data_table
end

function RestoreRenderMatrix(table)
    
    for r_idx, r_tracks in pairs(table) do
        for j, track_GUID in pairs(r_tracks) do           
            m_track = reaper.GetMasterTrack(0)
            m_track_GUID = reaper.GetTrackGUID(m_track)
            
            --If track is master then deal with it properly
            --for some reason master tk GUID > mediatrack doesn't work
            if track_GUID == m_track_GUID then
                reaper.SetRegionRenderMatrix(0, r_idx, m_track, 1)
            else
                track = reaper.BR_GetMediaTrackByGUID(0, track_GUID )
                reaper.SetRegionRenderMatrix(0, r_idx, track, 1)
            end
        end
    end
end

function ResetRenderMatrix()
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
end


function Main()
    reaper.TrackList_AdjustWindows( false ) --for updating the matrix without mouse over.
    local slot = string.match(slot_number, "%d*")
    retval, matrix_state = reaper.GetProjExtState(0, "RegionRenderMatrixState", "MatrixState" .. slot)
    if matrix_state ~= "" then
        rm_table = DeserializeData(matrix_state)
        ResetRenderMatrix()
        RestoreRenderMatrix(rm_table)
    else
        reaper.ReaScriptError("Region Render Matrix save not found for slot " .. slot)
    end
    reaper.TrackList_AdjustWindows( true )
end

Main()

