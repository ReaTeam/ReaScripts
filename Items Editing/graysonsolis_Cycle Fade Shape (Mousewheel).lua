-- @description Cycle Fade Shape (Mousewheel)
-- @author Grayson Solis
-- @version 1.0
-- @about
--   -- cycles through fade shapes on an item when hovering over fade curves
--   -- works for both wheel up and down

-- mousewheel fade shape editor
-- cycles through fade shapes when hovering over fade curves
-- works for both wheel up and down

function main()
    -- get mouse position
    local mouse_x, mouse_y = reaper.GetMousePosition()
    
    -- find item under mouse
    local item, take = reaper.GetItemFromPoint(mouse_x, mouse_y, true)
    if not item then return end
    
    -- get item position and length
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local item_end = item_pos + item_len
    
    -- convert mouse X to project time
    local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0)
    local arrange_left = 0
    local arrange_width = 1000
    
    -- get the arrange view dimensions
    local hwnd = reaper.GetMainHwnd()
    local arrange_hwnd = reaper.JS_Window_FindChildByID(hwnd, 1000)
    if arrange_hwnd then
        local retval, left, top, right, bottom = reaper.JS_Window_GetRect(arrange_hwnd)
        arrange_width = right - left
        arrange_left = left
    end
    
    -- calculate time from mouse position
    local relative_x = mouse_x - arrange_left
    local time_per_pixel = (end_time - start_time) / arrange_width
    local project_time = start_time + (relative_x * time_per_pixel)
    
    -- get fade info
    local fadein_len = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
    local fadeout_len = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
    local fadein_shape = reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE")
    local fadeout_shape = reaper.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE")
    
    -- check if over fade areas
    local is_over_fadein = (project_time >= item_pos and project_time <= item_pos + fadein_len and fadein_len > 0)
    local is_over_fadeout = (project_time >= item_end - fadeout_len and project_time <= item_end and fadeout_len > 0)
    
    if not (is_over_fadein or is_over_fadeout) then return end
    
    -- detect wheel direction from recent input
    local wheel_dir = 0
    local is_new, name, midi_val = reaper.MIDI_GetRecentInputEvent(0)
    
    if is_new then
        if midi_val == 1 then -- wheel up
            wheel_dir = 1
        elseif midi_val == 127 then -- wheel down
            wheel_dir = -1
        end
    end
    
    -- alternative method using get_action_context
    if wheel_dir == 0 then
        local is_new, name, sectionID, cmdID, mode, resolution, val = reaper.get_action_context()
        if val > 0 then
            wheel_dir = 1 -- wheel up
        elseif val < 0 then
            wheel_dir = -1 -- wheel down
        end
    end
    
    if wheel_dir == 0 then return end
    
    -- Cycle through shapes
    local function cycle_shape(current_shape, direction)
        local new_shape = current_shape + direction
        if new_shape > 6 then new_shape = 0 end
        if new_shape < 0 then new_shape = 6 end
        return new_shape
    end
    
    reaper.Undo_BeginBlock()
    
    if is_over_fadein then
        local new_shape = cycle_shape(fadein_shape, wheel_dir)
        reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", new_shape)
        reaper.Undo_EndBlock("Change fade in shape", -1)
    elseif is_over_fadeout then
        local new_shape = cycle_shape(fadeout_shape, wheel_dir)
        reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", new_shape)
        reaper.Undo_EndBlock("Change fade out shape", -1)
    end
    
    reaper.UpdateArrange()
end

main()
