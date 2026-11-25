-- @description Trim silence from only the beginning and only the end of selected items just like in Mixcraft
-- @author crossfreedom79
-- @version 1.1
-- @provides crossfreedom79_Trim silence from only the beginning and only the end of selected items just like in Mixcraft/Trim silence from only the beginning and only the end of selected items just like in Mixcraft.lua
-- @about
--   # Trim silence from only the beginning and only the end of selected items just like in Mixcraft
--
--   Trims the silence from only the beginning and only the end of a selected item or a selected audio take, just like the ctrl+i shortcut key in Mixcraft. you might need to change the number in the "local threshold_db" section to let the script know what is and isn't considered silence, for example, when i am not talking into the microphone but the microphone is armed, the green/red volume meter thingys next to the tracks volume knob says that their is -24 decibles of background sound in my room, so i input the number "-20" after the "=" sign, so now it reads like this "local threshold_db = -20". This lets the script know that any sound that it detects that is below the number "-20", should be considered silence that it will then trim.
--
--   Key features:
--
--   -Trims silence from only the beginning and only the end of selected items

-- @description Trims the silence from only the beginning and only the end of a selected item or a selected audio take, just like the ctrl+i shortcut key in Mixcraft. you might need to change the number in the "local threshold_db" section to let the script know what is and isn't considered silence, for example, when i am not talking into the microphone but the microphone is armed, the green/red volume meter thingys next to the tracks volume knob says that their is -24 decibles of background sound in my room, so i input the number "-20" after the "=" sign, so now it reads like this "local threshold_db = -20". This lets the script know that any sound that it detects that is below the number "-20", should be considered silence that it will then trim.
-- @version 1.1

-- ======================================================================
-- USER CONFIGURATION
-- ======================================================================
local threshold_db = -20 -- Silence threshold in dB (e.g., -60 to -30)
local padding_sec = 0.05 -- Padding to keep around the audio in seconds (50ms)
-- ======================================================================

local threshold = 10 ^ (threshold_db / 20)
local block_size = 65536 -- Number of samples to process per block 

function get_trim_points(item, take)
    if not take or reaper.TakeIsMIDI(take) then return nil end

    local source = reaper.GetMediaItemTake_Source(take)
    local samplerate = reaper.GetMediaSourceSampleRate(source)
    if samplerate == 0 then return nil end

    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local take_offs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")

    -- Accessors read raw source time, so we must calculate where the item actually starts in the file
    local source_start = take_offs
    local source_len = item_len * playrate
    local source_end = source_start + source_len

    local accessor = reaper.CreateTakeAudioAccessor(take)
    local num_channels = reaper.GetMediaSourceNumChannels(source)
    
    -- Allocate a buffer large enough for a full block of samples
    local buffer = reaper.new_array(block_size * num_channels)

    -- 1. Scan forward to find the start
    local start_offset_source = 0
    local found_start = false
    
    for i = source_start, source_end, block_size / samplerate do
        local len_to_read = (source_end - i) * samplerate
        local num_samples = math.min(block_size, math.ceil(len_to_read))
        if num_samples <= 0 then break end

        local ret = reaper.GetAudioAccessorSamples(accessor, samplerate, num_channels, i, num_samples, buffer)
        
        -- 'ret' safely prevents the nil comparison error
        if ret and ret > 0 then
            for j = 1, num_samples * num_channels do
                if math.abs(buffer[j]) > threshold then
                    local sample_idx = math.floor((j - 1) / num_channels)
                    start_offset_source = i + (sample_idx / samplerate)
                    found_start = true
                    break
                end
            end
        end
        if found_start then break end
    end

    if not found_start then
        reaper.DestroyAudioAccessor(accessor)
        return nil, nil -- The item is completely silent
    end

    -- 2. Scan backward to find the end
    local end_offset_source = source_end
    local found_end = false
    local current_pos = source_end

    while current_pos > start_offset_source do
        local read_pos = math.max(start_offset_source, current_pos - (block_size / samplerate))
        local len_to_read = (current_pos - read_pos) * samplerate
        local num_samples = math.min(block_size, math.ceil(len_to_read))
        if num_samples <= 0 then break end

        local ret = reaper.GetAudioAccessorSamples(accessor, samplerate, num_channels, read_pos, num_samples, buffer)
        
        if ret and ret > 0 then
            for j = num_samples * num_channels, 1, -1 do
                if math.abs(buffer[j]) > threshold then
                    local sample_idx = math.floor((j - 1) / num_channels)
                    end_offset_source = read_pos + (sample_idx / samplerate)
                    found_end = true
                    break
                end
            end
        end
        if found_end then break end
        current_pos = read_pos
    end

    reaper.DestroyAudioAccessor(accessor)

    -- Convert the found source times back to relative item times
    local start_offset_item = (start_offset_source - source_start) / playrate
    local end_offset_item = (end_offset_source - source_start) / playrate

    -- Apply user-defined padding safely
    start_offset_item = math.max(0, start_offset_item - padding_sec)
    end_offset_item = math.min(item_len, end_offset_item + padding_sec)

    return start_offset_item, end_offset_item
end

function main()
    local count = reaper.CountSelectedMediaItems(0)
    if count == 0 then return end

    reaper.Undo_BeginBlock()

    -- Iterate backwards to safely modify items without disrupting indexing
    for i = count - 1, 0, -1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local take = reaper.GetActiveTake(item)

        if take and not reaper.TakeIsMIDI(take) then
            local start_offset, end_offset = get_trim_points(item, take)

            if start_offset and end_offset and start_offset < end_offset then
                local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                local take_offs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
                local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")

                -- Only apply changes if silence was actually found at the edges
                if start_offset > 0 or end_offset < item_len then
                    local new_pos = item_pos + start_offset
                    local new_len = end_offset - start_offset
                    
                    -- Adjusting take offset requires factoring in the playrate 
                    local new_offs = take_offs + (start_offset * playrate)

                    reaper.SetMediaItemInfo_Value(item, "D_POSITION", new_pos)
                    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", new_len)
                    reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", new_offs)
                end
            end
        end
    end

    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Trim edge silence from selected items", -1)
end

main()
