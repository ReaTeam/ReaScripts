-- @description Smart Rename
-- @author Grayson Solis
-- @version 1.0
-- @about
--   Renames:
--
--   - Automation Items
--   - Regions
--   - Markers
--   - Media Items
--   - Tracks
--   - Lanes
--
--   It CANNOT rename envelopes / envelope lanes. Sorry I wasn't able to figure this one out!
--
--   Based on mouse position for context


local function rename()
  local window, segment = reaper.BR_GetMouseCursorContext()
  local mouse_x, mouse_y = reaper.GetMousePosition()
  
  -- Automation Items
  if window == "arrange" and segment == "envelope" then
    local env = reaper.BR_GetMouseCursorContext_Envelope()
    if env then
      local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0)
      local hwnd = reaper.GetMainHwnd()
      local arrange_hwnd = reaper.JS_Window_FindChildByID(hwnd, 1000)
      local arrange_left, arrange_width = 0, 1000
      
      if arrange_hwnd then
        local retval, left, top, right, bottom = reaper.JS_Window_GetRect(arrange_hwnd)
        arrange_width = right - left
        arrange_left = left
      end
      
      local relative_x = mouse_x - arrange_left
      local time_per_pixel = (end_time - start_time) / arrange_width
      local mouse_time = start_time + (relative_x * time_per_pixel)
      
      local ai_count = reaper.CountAutomationItems(env)
      for i = 0, ai_count - 1 do
        local ai_pos = reaper.GetSetAutomationItemInfo(env, i, "D_POSITION", 0, false)
        local ai_len = reaper.GetSetAutomationItemInfo(env, i, "D_LENGTH", 0, false)
        if mouse_time >= ai_pos and mouse_time < ai_pos + ai_len then
          -- Select this automation item
          reaper.GetSetAutomationItemInfo(env, i, "D_UISEL", 1, true)
          return reaper.Main_OnCommand(42091, 0) -- Envelope: Rename automation item pool
        end
      end
    end
  end
  
  -- Items/Takes (mouse context only)
  local item = reaper.BR_GetMouseCursorContext_Item()
  if item then
    reaper.SetMediaItemSelected(item, true)
    return reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_RENMTAKE"), 0)
  end
  
  -- Tracks (mouse context only)
  if window == "tcp" then
    local track = reaper.BR_GetMouseCursorContext_Track()
    if track then
      reaper.SetOnlyTrackSelected(track)
      return reaper.Main_OnCommand(40696, 0)
    end
  end
  
  -- Markers/Regions (tighter detection)
  if window == "ruler" or (window == "arrange" and segment == "marker_lane") then
    -- Get time at mouse cursor
    local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0)
    local hwnd = reaper.GetMainHwnd()
    local arrange_hwnd = reaper.JS_Window_FindChildByID(hwnd, 1000)
    local arrange_left, arrange_width = 0, 1000
    
    if arrange_hwnd then
      local retval, left, top, right, bottom = reaper.JS_Window_GetRect(arrange_hwnd)
      arrange_width = right - left
      arrange_left = left
    end
    
    local relative_x = mouse_x - arrange_left
    local time_per_pixel = (end_time - start_time) / arrange_width
    local mouse_time = start_time + (relative_x * time_per_pixel)
    
    -- Find closest marker/region within tight range (20 pixels)
    local pixel_threshold = 20
    local time_threshold = pixel_threshold * time_per_pixel
    local closest_idx = -1
    local closest_dist = time_threshold
    local is_region = false
    local found_pos, found_end, found_color
    
    local num_markers, num_regions = reaper.CountProjectMarkers(0)
    for i = 0, num_markers + num_regions - 1 do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i)
      
      if isrgn then
        -- For regions, check if mouse is within region bounds
        if mouse_time >= pos and mouse_time <= rgnend then
          closest_idx = markrgnindexnumber
          is_region = true
          found_pos = pos
          found_end = rgnend
          found_color = color
          break
        end
      else
        -- For markers, check proximity
        local dist = math.abs(mouse_time - pos)
        if dist < closest_dist then
          closest_dist = dist
          closest_idx = markrgnindexnumber
          found_pos = pos
          found_color = color
        end
      end
    end
    
    if closest_idx >= 0 then
      -- Get current name using the index we already found
      local retval, isrgn, pos, rgnend, name = reaper.EnumProjectMarkers3(0, closest_idx)
      local ok, new_name = reaper.GetUserInputs("Rename " .. (is_region and "Region" or "Marker"), 1, "Name:", name)
      
      if ok then
        reaper.SetProjectMarker3(0, closest_idx, is_region, found_pos, found_end or found_pos, new_name, found_color)
        return reaper.Undo_EndBlock("Rename " .. (is_region and "Region" or "Marker"), -1)
      end
    end
  end
  
  -- Tracks in arrange view (lanes)
  if window == "arrange" and segment == "track" then
    local track = reaper.BR_GetMouseCursorContext_Track()
    if track then
      reaper.SetOnlyTrackSelected(track)
      return reaper.Main_OnCommand(42472, 0) -- Track: Rename track from edit cursor or play cursor
    end
  end
end

reaper.Undo_BeginBlock()
rename()
reaper.Undo_EndBlock("Contextual Rename", -1)
