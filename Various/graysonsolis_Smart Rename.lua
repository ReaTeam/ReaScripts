-- @description Smart Rename
-- @author Grayson Solis
-- @version 1.0
-- @about
--   Smart Rename
--
--   Uses mouse context to rename things in the arrange view. Currently can rename:
--   - Automation Items
--   - Media Items
--   - Takes
--   - Tracks
--   - Markers
--   - Regions (even nested regions)


local function rename()
  local window, segment = reaper.BR_GetMouseCursorContext()
  local mouseX, mouseY = reaper.GetMousePosition()
  
  --Automation Items
  if window == "arrange" and segment == "envelope" then
    local env = reaper.BR_GetMouseCursorContext_Envelope()
    if env then
      local startTime, endTime = reaper.GetSet_ArrangeView2(0, false, 0, 0)
      local hwnd = reaper.GetMainHwnd()
      local arrangeHwnd = reaper.JS_Window_FindChildByID(hwnd, 1000)
      local arrangeLeft, arrangeWidth = 0, 1000
      
      if arrangeHwnd then
        local retval, left, top, right, bottom = reaper.JS_Window_GetRect(arrangeHwnd)
        arrangeWidth = right - left
        arrangeLeft = left
      end
      
      local relativeX = mouseX - arrangeLeft
      local timePerPixel = (endTime - startTime) / arrangeWidth
      local mouseTime = startTime + (relativeX * timePerPixel)
      
      local aiCount = reaper.CountAutomationItems(env)
      for i = 0, aiCount - 1 do
        local aiPos = reaper.GetSetAutomationItemInfo(env, i, "D_POSITION", 0, false)
        local aiLen = reaper.GetSetAutomationItemInfo(env, i, "D_LENGTH", 0, false)
        if mouseTime >= aiPos and mouseTime < aiPos + aiLen then
          reaper.GetSetAutomationItemInfo(env, i, "D_UISEL", 1, true)
          return reaper.Main_OnCommand(42091, 0)
        end
      end
    end
  end
  
  --Items/Takes
  local item = reaper.BR_GetMouseCursorContext_Item()
  if item then
    reaper.SetMediaItemSelected(item, true)
    return reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_RENMTAKE"), 0)
  end
  
  --Tracks (TCP)
  if window == "tcp" then
    local track = reaper.BR_GetMouseCursorContext_Track()
    if track then
      reaper.SetOnlyTrackSelected(track)
      return reaper.Main_OnCommand(40696, 0)
    end
  end
  
  --Markers/Regions
  if window == "ruler" or (window == "arrange" and segment == "marker_lane") then
    local startTime, endTime = reaper.GetSet_ArrangeView2(0, false, 0, 0)
    local hwnd = reaper.GetMainHwnd()
    local arrangeHwnd = reaper.JS_Window_FindChildByID(hwnd, 1000)
    local arrangeLeft, arrangeWidth = 0, 1000
    
    if arrangeHwnd then
      local retval, left, top, right, bottom = reaper.JS_Window_GetRect(arrangeHwnd)
      arrangeWidth = right - left
      arrangeLeft = left
    end
    
    local relativeX = mouseX - arrangeLeft
    local timePerPixel = (endTime - startTime) / arrangeWidth
    local mouseTime = startTime + (relativeX * timePerPixel)
    
    --Collect all regions and markers at this position
    local regionsAtPos = {}
    local markersAtPos = {}
    local numMarkers, numRegions = reaper.CountProjectMarkers(0)
    
    for i = 0, numMarkers + numRegions - 1 do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i)
      
      if isrgn then
        --Check if mouse is within region bounds
        if mouseTime >= pos and mouseTime <= rgnend then
          table.insert(regionsAtPos, {
            idx = markrgnindexnumber,
            pos = pos,
            rgnend = rgnend,
            name = name,
            color = color,
            enumIdx = i,
            length = rgnend - pos
          })
        end
      else
        --Check marker proximity
        local pixelThreshold = 20
        local timeThreshold = pixelThreshold * timePerPixel
        local dist = math.abs(mouseTime - pos)
        if dist < timeThreshold then
          table.insert(markersAtPos, {
            idx = markrgnindexnumber,
            pos = pos,
            name = name,
            color = color,
            dist = dist,
            enumIdx = i
          })
        end
      end
    end
    
    local selectedItem = nil
    
    if #regionsAtPos > 0 then
      --REAPER draws regions in enum order, with later regions appearing "on top"
      --The region with the highest enumIdx is the one visually on top (lowest)
      --We always prefer that one
      
      --Check if we're hovering near the start of any region (name area)
      local nameHoverThreshold = 80
      local nameTimeThreshold = nameHoverThreshold * timePerPixel
      
      local nameHoverCandidates = {}
      for _, region in ipairs(regionsAtPos) do
        local timeFromStart = mouseTime - region.pos
        if timeFromStart >= 0 and timeFromStart <= nameTimeThreshold then
          table.insert(nameHoverCandidates, region)
        end
      end
      
      if #nameHoverCandidates > 0 then
        --We're hovering over region name(s)
        --Pick the one with highest enumIdx (drawn on top)
        table.sort(nameHoverCandidates, function(a, b) return a.enumIdx > b.enumIdx end)
        selectedItem = nameHoverCandidates[1]
      else
        --Not hovering over a name, just pick the topmost region
        --Sort by enumIdx descending and pick first (highest = on top)
        table.sort(regionsAtPos, function(a, b) return a.enumIdx > b.enumIdx end)
        selectedItem = regionsAtPos[1]
      end
      
    elseif #markersAtPos > 0 then
      --Only markers, pick closest
      table.sort(markersAtPos, function(a, b) return a.dist < b.dist end)
      selectedItem = markersAtPos[1]
      selectedItem.isRegion = false
    end
    
    if selectedItem then
      local name = selectedItem.name or ""
      local isRegion = selectedItem.rgnend ~= nil
      
      local ok, newName = reaper.GetUserInputs(
        "Rename " .. (isRegion and "Region" or "Marker"), 
        1, 
        "Name:", 
        name
      )
      
      if ok and newName then
        reaper.SetProjectMarker3(
          0, 
          selectedItem.idx, 
          isRegion, 
          selectedItem.pos, 
          selectedItem.rgnend or selectedItem.pos, 
          newName, 
          selectedItem.color
        )
        return reaper.Undo_EndBlock("Rename " .. (isRegion and "Region" or "Marker"), -1)
      end
    end
  end
  
  --Tracks in arrange view
  if window == "arrange" and segment == "track" then
    local track = reaper.BR_GetMouseCursorContext_Track()
    if track then
      reaper.SetOnlyTrackSelected(track)
      return reaper.Main_OnCommand(42472, 0)
    end
  end
end

reaper.Undo_BeginBlock()
rename()
reaper.Undo_EndBlock("Contextual Rename", -1)
