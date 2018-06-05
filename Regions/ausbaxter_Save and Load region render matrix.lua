--@description Save and Load region render matrix (9 actions)
--@version 1.0
--@author ausbaxter
--@about
--    # Save and load region render matrix to project
--
--    This package provides actions to save, load and reset Reaper's region
--    render matrix.
--@provides
--    [main] . > ausbaxter_Load region render matrix (slot 1).lua
--    [main] . > ausbaxter_Load region render matrix (slot 2).lua
--    [main] . > ausbaxter_Load region render matrix (slot 3).lua
--    [main] . > ausbaxter_Load region render matrix (slot 4).lua
--    [main] . > ausbaxter_Reset region render matrix.lua
--    [main] . > ausbaxter_Save region render matrix (slot 1).lua
--    [main] . > ausbaxter_Save region render matrix (slot 2).lua
--    [main] . > ausbaxter_Save region render matrix (slot 3).lua
--    [main] . > ausbaxter_Save region render matrix (slot 4).lua
--@changelog
--  + Initial release

local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local slot = tonumber(script_name:match("slot (%d+)"))  

--------------------------------------------------------------------------------------------------------

function TableCopy(table)--returns a copy of a table, enables passing by value behavior
    local new_table = {}
    for i, k in pairs(table) do
        new_table[i] = k
    end
    return new_table  
end

function StringCopy(string)--returns a copy of a string, enables passing by value behavior
    local new_string = ""
    new_string = string
    return new_string 
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

-------------------------------------------Load---------------------------------------------------------

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

function Load()
    reaper.Undo_BeginBlock()
    reaper.TrackList_AdjustWindows( false ) --for updating the matrix without mouse over.
    local slot = string.match(slot, "%d*")
    retval, matrix_state = reaper.GetProjExtState(0, "RegionRenderMatrixState", "MatrixState" .. slot)
    if matrix_state ~= "" then
        rm_table = DeserializeData(matrix_state)
        ResetRenderMatrix()
        RestoreRenderMatrix(rm_table)
    else
        reaper.ReaScriptError("Region Render Matrix save not found for slot " .. slot)
    end
    reaper.TrackList_AdjustWindows( true )
    reaper.Undo_EndBlock("Recall region render matrix",1)
end

-----------------------------------------Save------------------------------------------------------------

function GetRegionRenderMatrix()--returns a table of region indexes and tracks enabled for rendering
    t_regions = GetRegions()
    local track = true
     tr_table, rr_table = {}, {}
    for i, region_idx in ipairs(t_regions) do
        local t = 0
        while reaper.EnumRegionRenderMatrix(0, region_idx, t) do
            track_ud = reaper.GetTrackGUID(reaper.EnumRegionRenderMatrix(0, region_idx, t)) --stores GUID of track (persistent)
            
            --makes sure master is recallable after session is closed and reopened
            if reaper.GetTrackGUID(reaper.GetMasterTrack(0)) == track_ud then
                track_ud = "{master}"
            end
            
            table.insert(tr_table, track_ud)
            t = t + 1
        end
        if t ~= 0 then
            rr_table[region_idx] = TableCopy(tr_table)
            tr_table = {}
        end
    end
    return rr_table
end

function SerializeData(table)--formats region table into string to enable storing to reaper project ext state
    local track_format = ""
    local region_format = ""
    local iter = 1
    for i, region in pairs(table) do
           local track_id = nil
           for j, track in ipairs(region) do
               if j == 1 then track_format = track
               else track_format = track_format .. "," .. track end
           end
           region_format = region_format .. i .. "(" .. StringCopy(track_format) ..  ")"
           track_format = ""
           iter = iter + 1
       end
    return region_format
end

function Save()
    reaper.Undo_BeginBlock()
    local slot = string.match(slot, "%d*")
    local matrix_state = SerializeData(GetRegionRenderMatrix())
    reaper.SetProjExtState(0, "RegionRenderMatrixState", "MatrixState" .. slot, matrix_state)
    reaper.Undo_EndBlock("Save region render matrix",1)
end

--------------------------------------------------------------------------------------------------------

function Main()
    if script_name:match("Load") then
        Load()
    elseif script_name:match("Save") then
        Save()
    elseif script_name:match("Reset") then
        ResetRenderMatrix()
    end
end

Main()