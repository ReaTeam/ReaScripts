-- @description Make renderable track regions
-- @author Grayson Solis
-- @version 1.0
-- @about
--   This script deletes any existing regions matching the track name, then scans a selected
--   track and its child tracks for unmuted items. It groups overlapping items into “stacks”
--   and creates timeline regions covering each stack, naming them after the parent track
--   (with incremental suffixes).
--
--   ----------------------------------------------------------------------------------------
--   USE CASE
--   ----------------------------------------------------------------------------------------
--   Ideal when exporting stems or bouncing layered sound effects: place your parent track
--   (e.g., “SFX_Main”), ensure child layers are beneath it, then run this script to generate
--   region markers for each continuous group of items. Regions will automatically carry the
--   track’s color for quick visual reference.
--
--   ----------------------------------------------------------------------------------------
--   BEHAVIOR
--   ----------------------------------------------------------------------------------------
--   - Deletes existing regions named for each track before processing.
--   - Collects all unmuted items on the parent track and its child tracks.
--   - Sorts items by start time and groups overlapping items into stacks.
--   - Creates project regions for each stack, names them with parent track name + index.
--   - Applies the parent track’s color to each region.
--   - Processes each selected track in turn.


----------------------------------------------------------------------------------------
-- PLACEHOLDER: delete_existing_regions_for_track FUNCTION
----------------------------------------------------------------------------------------
function delete_existing_regions_for_track(track_name)
    -- ... keep existing delete_existing_regions_for_track function unchanged ...
end

----------------------------------------------------------------------------------------
-- PROCESS A SINGLE TRACK (REGION CREATION)
----------------------------------------------------------------------------------------
function process_track(track)
    -- 1. Get track name and delete its existing regions
    local retval, parent_name = reaper.GetTrackName(track, "")
    delete_existing_regions_for_track(parent_name)

    -- 2. Get parent track color for region coloring
    local track_color = reaper.GetTrackColor(track)

    -- 3. COLLECT ALL UNMUTED ITEMS
    local all_items = {}

    -- 3a. Parent track items
    for i = 0, reaper.CountTrackMediaItems(track) - 1 do
        local item = reaper.GetTrackMediaItem(track, i)
        if reaper.GetMediaItemInfo_Value(item, "B_MUTE") ~= 1 then
            table.insert(all_items, item)
        end
    end

    -- 3b. Child track items
    local track_idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    for i = track_idx, reaper.CountTracks(0) - 1 do
        local child = reaper.GetTrack(0, i)
        if reaper.GetTrackDepth(child) <= reaper.GetTrackDepth(track) then break end
        for j = 0, reaper.CountTrackMediaItems(child) - 1 do
            local item = reaper.GetTrackMediaItem(child, j)
            if reaper.GetMediaItemInfo_Value(item, "B_MUTE") ~= 1 then
                table.insert(all_items, item)
            end
        end
    end

    ------------------------------------------------------------------------------------
    -- 4. GROUP ITEMS INTO OVERLAPPING STACKS
    ------------------------------------------------------------------------------------
    -- Sort by start time
    table.sort(all_items, function(a, b)
        return reaper.GetMediaItemInfo_Value(a, "D_POSITION") < reaper.GetMediaItemInfo_Value(b, "D_POSITION")
    end)

    local stacks = {}
    local current_stack = {}
    local current_end = 0

    for _, item in ipairs(all_items) do
        local start_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local end_pos = start_pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

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

    ------------------------------------------------------------------------------------
    -- 5. CREATE REGIONS FROM STACKS
    ------------------------------------------------------------------------------------
    local valid_count = 0
    for _, stack in ipairs(stacks) do
        local stack_start = math.huge
        local stack_end = 0

        -- Determine region bounds
        for _, item in ipairs(stack) do
            local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            stack_start = math.min(stack_start, pos)
            stack_end   = math.max(stack_end, pos + len)
        end

        -- Only create region if valid
        if stack_start < stack_end then
            local region_name = parent_name
            if valid_count > 0 then
                region_name = region_name .. "_" .. valid_count
            end
            valid_count = valid_count + 1

            -- Add and color the region
            local region_id = reaper.AddProjectMarker(0, true, stack_start, stack_end, region_name, -1)
            reaper.SetProjectMarker3(0, region_id, true, stack_start, stack_end, region_name, track_color)
            reaper.SetRegionRenderMatrix(0, region_id, track, 1)
        end
    end
end

----------------------------------------------------------------------------------------
-- MAIN: PROCESS EACH SELECTED TRACK
----------------------------------------------------------------------------------------
local count_sel = reaper.CountSelectedTracks(0)
for i = 0, count_sel - 1 do
    local tr = reaper.GetSelectedTrack(0, i)
    process_track(tr)
end
