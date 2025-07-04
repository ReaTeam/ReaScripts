-- @description Make Renderable Track Regions
-- @author Grayson Solis
-- @version 1.0
-- @about
--   - For each selected track, it creates one or more time regions for rendering
--
--   1) Skip any selected track that is muted or inside a muted folder.
--   2) Delete any old regions named after that track (e.g. “Guitar”, “Guitar_1”, etc.).
--   3) Gather all unmuted items on the track and on its child tracks (e.g. your Drum folder ➔ Kick, Snare).
--   4) Sort those items by their start times and group any that overlap into stacks.
--   5) For each stack, make a new region from the earliest start to the latest end:
--       – Name it “TrackName”, “TrackName_1”, “TrackName_2”…  
--       – Color it to match the track  
--       – Set it so that when you render that region, only this track is output
--
--   - Example:
--     - If you select “Vocal” and it has 3 takes overlapping, you’ll get:
--         Region “Vocal” (first take), then “Vocal_1” (second stack), etc.

function delete_existing_regions_for_track(track_name)
    local i = 0
    while i < reaper.CountProjectMarkers(0) do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
        if isrgn and name:match("^" .. track_name:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1") .. "(_?%d*)$") then
            reaper.DeleteProjectMarker(0, markrgnindexnumber, true)
        else
            i = i + 1
        end
    end
end

local function isActuallyMuted(tr)
    while tr do
        if reaper.GetMediaTrackInfo_Value(tr, "B_MUTE") == 1 then
            return true
        end
        tr = reaper.GetParentTrack(tr)
    end
    return false
end

function process_track(track)
    if isActuallyMuted(track) then
        return
    end

    local retval, parent_name = reaper.GetTrackName(track, "")
    parent_name = parent_name:gsub("<.->", "")  -- removes any <…> substring
    delete_existing_regions_for_track(parent_name)

    local track_color = reaper.GetTrackColor(track)

    local all_items = {}

    for i = 0, reaper.CountTrackMediaItems(track) - 1 do
        local item = reaper.GetTrackMediaItem(track, i)
        if reaper.GetMediaItemInfo_Value(item, "B_MUTE") ~= 1 then
            table.insert(all_items, item)
        end
    end

    local track_idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    for i = track_idx, reaper.CountTracks(0) - 1 do
        local child = reaper.GetTrack(0, i)
        if reaper.GetTrackDepth(child) <= reaper.GetTrackDepth(track) then break end
        if not isActuallyMuted(child) then
            for j = 0, reaper.CountTrackMediaItems(child) - 1 do
                local item = reaper.GetTrackMediaItem(child, j)
                if reaper.GetMediaItemInfo_Value(item, "B_MUTE") ~= 1 then
                    table.insert(all_items, item)
                end
            end
        end
    end

    table.sort(all_items, function(a, b)
        return reaper.GetMediaItemInfo_Value(a, "D_POSITION")
             < reaper.GetMediaItemInfo_Value(b, "D_POSITION")
    end)

    local stacks = {}
    local current_stack = {}
    local current_end = 0

    for _, item in ipairs(all_items) do
        local start_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local end_pos   = start_pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        if start_pos > current_end then
            if #current_stack > 0 then
                table.insert(stacks, current_stack)
                current_stack = {}
            end
            current_end = end_pos
        else
            current_end = math.max(current_end, end_pos)
        end
        table.insert(current_stack, item)
    end
    if #current_stack > 0 then table.insert(stacks, current_stack) end

    local valid_count = 0
    for _, stack in ipairs(stacks) do
        local stack_start = math.huge
        local stack_end   = 0

        for _, item in ipairs(stack) do
            local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            stack_start = math.min(stack_start, pos)
            stack_end   = math.max(stack_end, pos + len)
        end

        if stack_start < stack_end then
            local region_name = parent_name
            if valid_count > 0 then
                region_name = region_name .. "_" .. valid_count
            end
            valid_count = valid_count + 1

            local region_id = reaper.AddProjectMarker(0, true, stack_start, stack_end, region_name, -1)
            reaper.SetProjectMarker3(0, region_id, true, stack_start, stack_end, region_name, track_color)
            reaper.SetRegionRenderMatrix(0, region_id, track, 1)
        end
    end
end

local count_sel = reaper.CountSelectedTracks(0)
for i = 0, count_sel - 1 do
    local tr = reaper.GetSelectedTrack(0, i)
    process_track(tr)
end
