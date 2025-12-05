-- @description Fade Shape Cycle (MIDI CC relative-mousewheel)
-- @author Grayson Solis
-- @version 1.0
-- @about
--   -- cycles through fade shapes when hovering over fade curves
--   -- works for both wheel up and down
--
--   -- works on:
--
--   - tempo envelopes
--   - crossfades
--   - take / item fades
--   - automation items
--   - envelopes

function get_wheel_direction()
    local wheel_dir = 0
    local is_new, name, midi_val = reaper.MIDI_GetRecentInputEvent(0)
    
    if is_new then
        if midi_val == 1 then wheel_dir = 1
        elseif midi_val == 127 then wheel_dir = -1 end
    end
    
    if wheel_dir == 0 then
        local is_new, name, sectionID, cmdID, mode, resolution, val = reaper.get_action_context()
        if val > 0 then wheel_dir = 1
        elseif val < 0 then wheel_dir = -1 end
    end
    
    return wheel_dir
end

function get_project_time_at_mouse(mouse_x)
    local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0)
    local arrange_left, arrange_width = 0, 1000
    local hwnd = reaper.GetMainHwnd()
    local arrange_hwnd = reaper.JS_Window_FindChildByID(hwnd, 1000)
    
    if arrange_hwnd then
        local retval, left, top, right, bottom = reaper.JS_Window_GetRect(arrange_hwnd)
        arrange_width = right - left
        arrange_left = left
    end
    
    local relative_x = mouse_x - arrange_left
    local time_per_pixel = (end_time - start_time) / arrange_width
    local project_time = start_time + (relative_x * time_per_pixel)
    
    return project_time, time_per_pixel
end

function cycle_shape(current_shape, direction, max_shape)
    local new_shape = current_shape + direction
    if new_shape > max_shape then new_shape = 0 end
    if new_shape < 0 then new_shape = max_shape end
    return new_shape
end

function handle_envelope(mouse_x, mouse_y, wheel_dir)
    if not reaper.BR_GetMouseCursorContext_Envelope then return false end
    
    local envelope = reaper.BR_GetMouseCursorContext_Envelope()
    
    -- Check for tempo map if no envelope detected
    if not envelope then
        local tempo_env = reaper.GetTrackEnvelopeByName(reaper.GetMasterTrack(0), "Tempo map")
        if tempo_env then
            local retval, chunk = reaper.GetEnvelopeStateChunk(tempo_env, "", false)
            if retval and chunk:match("VIS 1") then
                local master_track = reaper.GetMasterTrack(0)
                local test_track = reaper.GetTrackFromPoint(mouse_x, mouse_y)
                if test_track == master_track then
                    envelope = tempo_env
                end
            end
        end
    end
    
    if not envelope then return false end
    
    local project_time = get_project_time_at_mouse(mouse_x)
    
    -- Check automation items first
    local ai_count = reaper.CountAutomationItems(envelope)
    if ai_count > 0 then
        for k = 0, ai_count - 1 do
            local ai_pos = reaper.GetSetAutomationItemInfo(envelope, k, "D_POSITION", 0, false)
            local ai_len = reaper.GetSetAutomationItemInfo(envelope, k, "D_LENGTH", 0, false)
            if project_time >= ai_pos and project_time < ai_pos + ai_len then
                local ai_point_count = reaper.CountEnvelopePointsEx(envelope, k)
                
                for j = 0, ai_point_count - 2 do
                    local retval1, time1, value1, shape1, tension1, selected1 = reaper.GetEnvelopePointEx(envelope, k, j)
                    local retval2, time2 = reaper.GetEnvelopePointEx(envelope, k, j + 1)
                    if retval1 and retval2 then
                        if project_time >= time1 and project_time < time2 then
                            local new_shape = cycle_shape(shape1, wheel_dir, 5)
                            
                            reaper.Undo_BeginBlock()
                            reaper.SetEnvelopePointEx(envelope, k, j, time1, value1, new_shape, tension1, selected1, true)
                            reaper.Envelope_SortPointsEx(envelope, k)
                            reaper.UpdateArrange()
                            reaper.Undo_EndBlock("Change automation item point shape", -1)
                            return true
                        end
                    end
                end
            end
        end
    end
    
    -- Check regular envelope points
    local point_count = reaper.CountEnvelopePoints(envelope)
    if point_count >= 2 then
        for j = 0, point_count - 2 do
            local retval1, time1, value1, shape1, tension1, selected1 = reaper.GetEnvelopePoint(envelope, j)
            local retval2, time2 = reaper.GetEnvelopePoint(envelope, j + 1)
            if retval1 and retval2 and project_time >= time1 and project_time < time2 then
                local new_shape = cycle_shape(shape1, wheel_dir, 5)
                
                reaper.Undo_BeginBlock()
                reaper.SetEnvelopePoint(envelope, j, time1, value1, new_shape, tension1, selected1, true)
                reaper.Envelope_SortPoints(envelope)
                reaper.UpdateArrange()
                reaper.Undo_EndBlock("Change envelope point shape", -1)
                return true
            end
        end
    end
    
    return false
end

function handle_crossfade(mouse_x, mouse_y, wheel_dir)
    local project_time, time_per_pixel = get_project_time_at_mouse(mouse_x)
    local track = reaper.GetTrackFromPoint(mouse_x, mouse_y)
    if not track then return false end
    
    -- Get all items on this track
    local item_count = reaper.CountTrackMediaItems(track)
    
    -- Find all overlapping pairs at mouse position
    local crossfades = {}
    
    for i = 0, item_count - 1 do
        local item1 = reaper.GetTrackMediaItem(track, i)
        local item1_pos = reaper.GetMediaItemInfo_Value(item1, "D_POSITION")
        local item1_len = reaper.GetMediaItemInfo_Value(item1, "D_LENGTH")
        local item1_end = item1_pos + item1_len
        
        for j = 0, item_count - 1 do
            if i ~= j then
                local item2 = reaper.GetTrackMediaItem(track, j)
                local item2_pos = reaper.GetMediaItemInfo_Value(item2, "D_POSITION")
                local item2_len = reaper.GetMediaItemInfo_Value(item2, "D_LENGTH")
                local item2_end = item2_pos + item2_len
                
                -- Check for overlap
                local overlap_start = math.max(item1_pos, item2_pos)
                local overlap_end = math.min(item1_end, item2_end)
                
                if overlap_start < overlap_end then
                    -- There's an overlap - check if mouse is in this zone
                    local pixel_threshold = 5 * time_per_pixel
                    
                    if project_time >= overlap_start - pixel_threshold and 
                       project_time <= overlap_end + pixel_threshold then
                        
                        -- Determine which item is on top (later in the item list = on top)
                        local top_item = i > j and item1 or item2
                        local bottom_item = i > j and item2 or item1
                        local top_item_pos = reaper.GetMediaItemInfo_Value(top_item, "D_POSITION")
                        local bottom_item_pos = reaper.GetMediaItemInfo_Value(bottom_item, "D_POSITION")
                        
                        -- Determine if this is a left-side or right-side crossfade
                        -- Left side = top item starts first (its fade-out crosses bottom item's fade-in)
                        -- Right side = bottom item starts first (its fade-out crosses top item's fade-in)
                        local is_left_xfade = top_item_pos < bottom_item_pos
                        
                        table.insert(crossfades, {
                            overlap_start = overlap_start,
                            overlap_end = overlap_end,
                            top_item = top_item,
                            bottom_item = bottom_item,
                            is_left = is_left_xfade
                        })
                    end
                end
            end
        end
    end
    
    if #crossfades == 0 then return false end
    
    -- Get item under mouse to determine vertical position
    local item_under_mouse = reaper.GetItemFromPoint(mouse_x, mouse_y, false)
    if not item_under_mouse then return false end
    
    -- Find the crossfade that matches our criteria:
    -- Upper half of overlap = edit top item's fade
    -- Lower half of overlap = edit bottom item's fade
    for _, xf in ipairs(crossfades) do
        local xfade_mid = (xf.overlap_start + xf.overlap_end) / 2
        
        -- Determine which item to edit based on mouse position within crossfade
        local target_item, fade_type
        
        if xf.is_left then
            -- Left crossfade: top item fades out, bottom item fades in
            if project_time <= xfade_mid then
                -- Left half: edit bottom item's fade-in
                target_item = xf.bottom_item
                fade_type = "C_FADEINSHAPE"
            else
                -- Right half: edit top item's fade-out
                target_item = xf.top_item
                fade_type = "C_FADEOUTSHAPE"
            end
        else
            -- Right crossfade: bottom item fades out, top item fades in
            if project_time <= xfade_mid then
                -- Left half: edit top item's fade-in
                target_item = xf.top_item
                fade_type = "C_FADEINSHAPE"
            else
                -- Right half: edit bottom item's fade-out
                target_item = xf.bottom_item
                fade_type = "C_FADEOUTSHAPE"
            end
        end
        
        local current_shape = reaper.GetMediaItemInfo_Value(target_item, fade_type)
        local new_shape = cycle_shape(current_shape, wheel_dir, 6)
        
        reaper.Undo_BeginBlock()
        reaper.SetMediaItemInfo_Value(target_item, fade_type, new_shape)
        reaper.UpdateArrange()
        
        local fade_name = fade_type == "C_FADEINSHAPE" and "fade in" or "fade out"
        reaper.Undo_EndBlock("Change crossfade " .. fade_name .. " shape", -1)
        return true
    end
    
    return false
end

function handle_item_fades(mouse_x, mouse_y, wheel_dir)
    local item = reaper.GetItemFromPoint(mouse_x, mouse_y, true)
    if not item then return false end
    
    local project_time, time_per_pixel = get_project_time_at_mouse(mouse_x)
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local item_end = item_pos + item_len
    
    local fadein_len = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
    local fadeout_len = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
    
    -- Tighter detection: 5 pixel threshold
    local pixel_threshold = 5 * time_per_pixel
    
    local is_over_fadein = (project_time >= item_pos - pixel_threshold and 
                           project_time <= item_pos + fadein_len + pixel_threshold and 
                           fadein_len > 0)
    local is_over_fadeout = (project_time >= item_end - fadeout_len - pixel_threshold and 
                            project_time <= item_end + pixel_threshold and 
                            fadeout_len > 0)
    
    if not (is_over_fadein or is_over_fadeout) then return false end
    
    reaper.Undo_BeginBlock()
    
    if is_over_fadein then
        local fadein_shape = reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE")
        local new_shape = cycle_shape(fadein_shape, wheel_dir, 6)
        reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", new_shape)
        reaper.Undo_EndBlock("Change fade in shape", -1)
    elseif is_over_fadeout then
        local fadeout_shape = reaper.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE")
        local new_shape = cycle_shape(fadeout_shape, wheel_dir, 6)
        reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", new_shape)
        reaper.Undo_EndBlock("Change fade out shape", -1)
    end
    
    reaper.UpdateArrange()
    return true
end

function main()
    local mouse_x, mouse_y = reaper.GetMousePosition()
    local wheel_dir = get_wheel_direction()
    
    if wheel_dir == 0 then return end
    
    -- Try in order: envelopes, crossfades, then regular fades
    if handle_envelope(mouse_x, mouse_y, wheel_dir) then return end
    if handle_crossfade(mouse_x, mouse_y, wheel_dir) then return end
    if handle_item_fades(mouse_x, mouse_y, wheel_dir) then return end
end

main()
