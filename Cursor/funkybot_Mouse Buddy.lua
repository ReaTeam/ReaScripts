-- @description Mouse Buddy
-- @author Funkybot
-- @version 3.0.2
-- @about
--   Mouse Buddy
--Description: Displays the current mouse context and shows only the mouse modifier sections
--             from an HTML file that match the current context/details. Supports two modes:
--             "Live Mode" (auto-detect) and "Manual Mode" (user selects the context group and
--             mouse behavior filter). In Live Mode you can now press the F key to freeze/unfreeze
--             the displayed content.
--             
--    How to Use:
--             1. In Reaper’s Action List, run Help: Mouse modifier keys and action shortcuts.
--             2. This will create a file called ReaperKeyboardShortcuts.html.
--             3. Navigate to the folder on your PC where this file is saved and copy/paste the HTML 
--                to a non-temporary folder on your computer so you won’t have to repeat this process.
--             4. Launch the Mouse Buddy script from the Action List.
--             5. At the top of the window, click Browse and point Mouse Buddy to the ReaperKeyboardShortcuts.html file.
--             6. In Live Mode, the display updates in real time; press the F key to freeze/unfreeze the view.
--             7. In Manual Mode, you can select the context you want to see modifiers for.
--
--             This version uses a mapping table to convert the (Window,Segment,Details) values
--             into one or more modifier prefix groups for filtering the HTML file.
--
--             The mapping table is defined as follows (all comparisons are done case-insensitively):
--
--             -------------------------------------------------------------------------------
--             Window       Segment       Details              Modifier Groups
--             -------------------------------------------------------------------------------
--             unknown      (wildcard)    (wildcard)           { [show last valid context] }
--             ruler        (wildcard)    (wildcard)           { "Mouse: Ruler" }
--             marker_lane  (none)        (wildcard)           { "Mouse: Project marker/region lane" }
--             tempo_lane   (none)        (wildcard)           { "Mouse: Project tempo/time signature" }
--             timeline     (none)        (wildcard)           { "Mouse: Ruler" }
--             transport    (none)        (wildcard)           { [show last valid context] }
--             tcp          track         (wildcard)           { "Mouse: Track control panel" }
--             envelope     (none)        (wildcard)           { "Mouse: Envelope lane" }
--             envelope     (none)        env_point            { "Mouse: Envelope point", "Mouse: Envelope segment" }
--             envelope     (none)        env_segment          { "Mouse: Envelope segment", "Mouse: Envelope point" }
--             empty        (none)        (wildcard)           { [show last valid context] }
--             mcp          track         (wildcard)           { "Mouse: Mixer control panel " }
--             arrange      track         empty                { "Mouse: Arrange view" }
--             arrange      track         item                 { "Mouse: Media item" }
--             arrange      track         item_stretch_marker  { "Mouse: Media item stretch marker" }
--             arrange      track         env_point            { "Mouse: Envelope point" }
--             arrange      track         env_segment          { "Mouse: Envelope segment" }
--             -------------------------------------------------------------------------------
--             -- MIDI Editor rows (window = "midi_editor")
--             midi_editor  unknown       piano                { "Mouse: MIDI piano roll" }
--             midi_editor  unknown       ruler                { "Mouse: MIDI ruler" }
--             midi_editor  unknown       notes                { "Mouse: MIDI note", "Mouse: MIDI editor" }
--             midi_editor  cc_lane       cc_lane              { "Mouse: MIDI CC lane", "Mouse: MIDI CC segment" }
--             midi_editor  cc_lane       cc_selector          { "Mouse: MIDI CC lane", "Mouse: MIDI CC segment" }
--             midi_editor  cc_segment    cc_segment           { "Mouse: MIDI CC segment", "Mouse: MIDI CC lane" }
--             midi_editor  cc_event      cc_event             { "Mouse: MIDI CC segment", "Mouse: MIDI CC lane" }
--             midi_editor  unknown       (wildcard)           { "Mouse: MIDI piano roll", "Mouse: MIDI editor" }
--             -------------------------------------------------------------------------------
--             cc_lane      cc_selector   (wildcard)           { "Mouse: MIDI CC lane", "Mouse: MIDI CC segment" }
--             cc_lane      cc_lane       (wildcard)           { "Mouse: MIDI CC lane", "Mouse: MIDI CC segment" }
--             -------------------------------------------------------------------------------
--             
--Author: Touristkiller, Funkybot (via ChatGPT)
--Version: 3.0.2
--Requirements: SWS Extensions, ReaImGui
--]]

local r = reaper -- Reaper API alias

-----------------------------------------------------------
-- Toggle State Reporting via set_action_options
-----------------------------------------------------------
r.set_action_options(4)
local function exit() r.set_action_options(8) end
r.atexit(exit)

-----------------------------------------------------------
-- USER CONFIGURABLE DEFAULT MODE
-----------------------------------------------------------
local ManualModeDefault = false
local mode = "live"
if ManualModeDefault then mode = "manual" end

-----------------------------------------------------------
-- Global variables for HTML file path (persistent state)
-----------------------------------------------------------
local EXT_SECTION = "MM_BUDDY"
local EXT_KEY = "HTML_PATH"
local DEFAULT_PATH = " "  -- default if not set

local HTML_PATH = r.GetExtState(EXT_SECTION, EXT_KEY)
if HTML_PATH == "" then
  HTML_PATH = DEFAULT_PATH
  r.SetExtState(EXT_SECTION, EXT_KEY, HTML_PATH, true)
end
local pathInput = HTML_PATH

-----------------------------------------------------------
-- Mode selection variables (for Manual Mode dropdowns)
-----------------------------------------------------------
local selectedManualIndex = 0    -- 0-based index; 0 corresponds to "All"
local selectedBehaviorIndex = 0  -- 0-based index

-----------------------------------------------------------
-- Global variable to store the last valid live context.
-----------------------------------------------------------
local lastValidContext = nil

-----------------------------------------------------------
-- Global variables for freezing the display (including segment)
-----------------------------------------------------------
local freezeDisplay = false    -- when true, the live view will be frozen
local frozenContext = "UNKNOWN"  -- will store the live context (window) when frozen
local frozenSegment = "UNKNOWN"  -- will store the live segment when frozen
local frozenDetails = ""         -- will store the live details when frozen

-----------------------------------------------------------
-- Predefined valid context groups and mouse filter options
-----------------------------------------------------------
local validContextGroups = {
  "Arrange View",
  "Edit Cursor Handle",
  "Envelope Control Panel",
  "Envelope Point",
  "Envelope Segment",
  "Fixed Lane Comp area",
  "MIDI CC Event",
  "MIDI CC Lane",
  "MIDI CC Segment",
  "MIDI Editor",
  "MIDI Note",
  "MIDI Piano Roll",
  "MIDI Ruler",
  "MIDI Source Loop end Marker",
  "Media Item Bottom Half",
  "Media Item",
  "Media Item Edge",
  "Media Item Fade/Autocrossfade",
  "Media Item Stretch Marker",
  "Media Item Take Marker",
  "Mixer Control Panel",
  "Project Tempo/Time Signature Marker",
  "Project marker/region",
  "Razor Edit Area",
  "Razor Edit Edge",
  "Razor Edit Envelope",
  "Ruler"
}

local validMouseFilters = {
  "Left Click",
  "Left Click/Drag",
  "Left Drag",
  "Right Click",
  "Double Click",
  "Right Drag",
  "Middle Click",
  "Middle Drag"
}

-----------------------------------------------------------
-- Backward-compatibility shim: require specific ReaImGui version
-----------------------------------------------------------
if not r.ImGui_GetBuiltinPath then
  return reaper.MB("ReaImGui is not installed or too old.", "Mouse Buddy", 0)
end
package.path = r.ImGui_GetBuiltinPath() .. "/?.lua"
local ImGui = require 'imgui' '0.9.3'
 
-----------------------------------------------------------
-- Create an ImGui context with docking enabled.
-----------------------------------------------------------
local ctx = ImGui.CreateContext("Mouse Buddy")
 
-----------------------------------------------------------
-- Font creation & attach
----------------------------------------------------------- 
local font = ImGui.CreateFont('Arial', 13)
ImGui.Attach(ctx, font)

-----------------------------------------------------------
-- UI Style Helpers
-----------------------------------------------------------
local function setStyle()
  ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg, 0x323232FF)
  ImGui.PushStyleColor(ctx, ImGui.Col_Text,     0xC8C8C8FF)
  ImGui.PushStyleVar  (ctx, ImGui.StyleVar_WindowRounding, 12)
  ImGui.PushStyleVar  (ctx, ImGui.StyleVar_WindowPadding, 10, 10)
  ImGui.PushStyleVar  (ctx, ImGui.StyleVar_ItemSpacing,  8, 4)
end

local function clearStyle()
  ImGui.PopStyleVar  (ctx, 3)
  ImGui.PopStyleColor(ctx, 2)
end

-----------------------------------------------------------
-- Enhanced Mouse Context Detection using BR_GetMouseCursorContext
-- Returns: window, segment, details
-- For native_ctx 1 (arrange view), we force:
--   window = "arrange", segment = "track"
-- and set details based on known values:
--   "ITEM"              -> "item"
--   "ITEM_STRETCH_MARKER" -> "item_stretch_marker"
--   "ENV_POINT"         -> "env_point"
--   "ENV_SEGMENT"       -> "env_segment"
--   Otherwise          -> "empty"
-----------------------------------------------------------
local function get_mouse_context()
  local window, segment, details = r.BR_GetMouseCursorContext()
  window = type(window) == "string" and string.upper(window) or ""
  segment = type(segment) == "string" and string.upper(segment) or ""
  details = type(details) == "string" and string.upper(details) or ""
  local native_ctx = r.GetCursorContext()
  if native_ctx == 1 then
    segment = "TRACK"
    if details == "ITEM" then
      details = "item"
    elseif details == "ITEM_STRETCH_MARKER" then
      details = "item_stretch_marker"
    elseif details == "ENV_POINT" then
      details = "env_point"
    elseif details == "ENV_SEGMENT" then
      details = "env_segment"
    else
      details = "empty"
    end
    window = "arrange"
  else
    window = string.lower(window)
    segment = string.lower(segment)
    details = string.lower(details)
    if window == "midi_editor" then
      if details == "" and segment ~= "" then
        details = segment
        segment = "unknown"
      elseif segment == "" then
        segment = "unknown"
      end
    end
    -- NEW: If the context is TCP, force the segment to "track" and details to an empty string.
    if window == "tcp" then
      segment = "track"
      details = ""
    end
  end
  return window, segment, details
end

-----------------------------------------------------------
-- Modifier Mapping Table (all fields in lower-case)
-- Order matters: more specific rows come before fallback/wildcard rows.
-----------------------------------------------------------
local modifierMapping = {
  { window = "unknown",     segment = "",            details = "",             groups = {"[LAST]"} },
  { window = "ruler",       segment = "",            details = "",             groups = {"Mouse: Ruler"} },
  { window = "marker_lane", segment = "(none)",      details = "",             groups = {"Mouse: Project marker/region lane"} },
  { window = "tempo_lane",  segment = "(none)",      details = "",             groups = {"Mouse: Project tempo/time signature"} },
  { window = "timeline",    segment = "(none)",      details = "",             groups = {"Mouse: Ruler"} },
  { window = "transport",   segment = "(none)",      details = "",             groups = {"[LAST]"} },
  { window = "tcp",         segment = "track",       details = "",             groups = {"Mouse: Track control panel"} },
  { window = "envelope",    segment = "(none)",      details = "",             groups = {"Mouse: Envelope lane"} },
  { window = "envelope",    segment = "(none)",      details = "env_point",    groups = {"Mouse: Envelope point", "Mouse: Envelope segment"} },
  { window = "envelope",    segment = "(none)",      details = "env_segment",  groups = {"Mouse: Envelope segment", "Mouse: Envelope point"} },
  { window = "empty",       segment = "(none)",      details = "",             groups = {"[LAST]"} },
  { window = "mcp",         segment = "track",       details = "",             groups = {"Mouse: Mixer control panel"} },
  { window = "mcp",         segment = "",            details = "",             groups = {"Mouse: Mixer control panel"} },
  { window = "arrange",     segment = "track",       details = "empty",        groups = {"Mouse: Arrange view"} },
  { window = "arrange",     segment = "track",       details = "item",         groups = {"Mouse: Media item"} },
  { window = "arrange",     segment = "track",       details = "item_stretch_marker", groups = {"Mouse: Media item stretch marker"} },
  { window = "arrange",     segment = "track",       details = "env_point",    groups = {"Mouse: Envelope point"} },
  { window = "arrange",     segment = "track",       details = "env_segment",  groups = {"Mouse: Envelope segment"} },
  -- MIDI Editor rows:                               
  { window = "midi_editor", segment = "unknown",     details = "piano",  groups = {"Mouse: MIDI piano roll"} },
  { window = "midi_editor", segment = "unknown",     details = "ruler",  groups = {"Mouse: MIDI ruler"} },
  { window = "midi_editor", segment = "unknown",     details = "notes",  groups = {"Mouse: MIDI note", "Mouse: MIDI editor"} },
  { window = "midi_editor", segment = "cc_lane",     details = "cc_lane", groups = {"Mouse: MIDI CC lane", "Mouse: MIDI CC segment"} },
  { window = "midi_editor", segment = "cc_lane",     details = "cc_selector", groups = {"Mouse: MIDI CC lane", "Mouse: MIDI CC segment"} },
  { window = "midi_editor", segment = "cc_segment",  details = "cc_segment", groups = {"Mouse: MIDI CC segment", "Mouse: MIDI CC lane"} },
  { window = "midi_editor", segment = "cc_event",    details = "cc_event", groups = {"Mouse: MIDI CC segment", "Mouse: MIDI CC lane"} },
  { window = "midi_editor", segment = "unknown",     details = "", groups = {"Mouse: MIDI piano roll", "Mouse: MIDI editor"} },
  { window = "cc_lane",     segment = "cc_selector", details = "",   groups = {"Mouse: MIDI CC lane", "Mouse: MIDI CC segment"} },
  { window = "cc_lane",     segment = "cc_lane",     details = "",         groups = {"Mouse: MIDI CC lane", "Mouse: MIDI CC segment"} },
}

-----------------------------------------------------------
-- Helper: Returns true if the mapping row matches (w,s,d).
-----------------------------------------------------------
local function matchesMapping(mapping, w, s, d)
  if mapping.window ~= w then return false end
  if mapping.segment ~= "(none)" and mapping.segment ~= "" and mapping.segment ~= s then return false end
  if mapping.details ~= "" and mapping.details ~= d then return false end
  return true
end

-----------------------------------------------------------
-- Return the candidate groups list from the first matching mapping row.
-----------------------------------------------------------
local function get_modifier_keyword_groups(window, segment, details)
  local w = string.lower(window or "")
  local s = string.lower(segment or "")
  local d = string.lower(details or "")
  for _, map in ipairs(modifierMapping) do
    if matchesMapping(map, w, s, d) then
      return map.groups
    end
  end
  return { window or "UNKNOWN" }
end

-----------------------------------------------------------
-- Read mouse modifiers from the chosen HTML file.
-----------------------------------------------------------
local function readMouseModifiersFromHTML()
  local file = io.open(HTML_PATH, "r")
  if not file then return {} end

  local mouseModifiers = {}
  local currentSection = nil
  local inMouseModifierSection = false

  for _ = 1, 4 do
    if not file:read("*line") then break end
  end

  for line in file:lines() do
    if line:find("<TR><TD COLSPAN=2><FONT SIZE=4><B>Mousewheel modifiers</B></FONT></TD></TR>") then
      inMouseModifierSection = true
      currentSection = "Mousewheel modifiers"
      mouseModifiers[currentSection] = {}
    end
    if line:find("Note: use the Action List") then
      inMouseModifierSection = false
      break
    end

    if inMouseModifierSection then
      local sectionName = line:match("<FONT SIZE=4><B>(.+)</B></FONT>")
      if sectionName then
        currentSection = sectionName
        mouseModifiers[currentSection] = {}
      end

      local modifier, action = line:match("<TD>([^<]+)</TD><TD>([^<]+)</TD>")
      if modifier and action and currentSection then
        if modifier ~= "<BR>" and action ~= "<BR>" then
          mouseModifiers[currentSection][modifier] = action
        end
      end
    end
  end

  file:close()
  return mouseModifiers
end

-----------------------------------------------------------
-- Helper: Extract the context group and behavior from a section header.
-----------------------------------------------------------
local function extractGroupAndBehavior(section)
  local s = section:gsub("Mouse:%s*", "")

  -- handle the three “left drag” variants as one group:
  if s:match("^Project marker/region") or s:match("^Project region") then
    return "Project marker/region", "Left Drag"
  end

  for _, grp in ipairs(validContextGroups) do
    local lowerS = s:lower()
    local lowerGrp = grp:lower()
    if lowerS:sub(1, #lowerGrp) == lowerGrp then
      local remainder = s:sub(#lowerGrp + 1)
      remainder = remainder:gsub("^%s*[-:]*%s*", ""):gsub("%s+$", "")
      return grp, remainder
    end
  end

  return s, ""
end

-----------------------------------------------------------
-- Build the Manual Mode dropdown lists (context groups and behaviors)
-----------------------------------------------------------
local function buildManualModeDropdowns(modifiers)
  local groupsSet = {}
  for section, _ in pairs(modifiers) do
    local grp, _ = extractGroupAndBehavior(section)
    if grp and grp ~= "" then groupsSet[grp] = true end
  end

  local groupsList = { "All" }
  for _, validGrp in ipairs(validContextGroups) do
    if groupsSet[validGrp] then
      table.insert(groupsList, validGrp)
    end
  end
  
  local behaviorsSet = {}
  local currentGroup = groupsList[selectedManualIndex+1] or "All"
  for section, _ in pairs(modifiers) do
    local grp, beh = extractGroupAndBehavior(section)
    if currentGroup == "All" or grp == currentGroup then
      if beh and beh ~= "" then behaviorsSet[beh:lower()] = true end
    end
  end
  local behaviorsList = { "All" }
  for _, filter in ipairs(validMouseFilters) do
    if behaviorsSet[filter:lower()] then
      table.insert(behaviorsList, filter)
    end
  end
  
  return groupsList, behaviorsList
end

-----------------------------------------------------------
-- Filter the modifier sections based on the selected context/behavior.
-----------------------------------------------------------
local function filterModifiers(modifiers, context, behavior, manual, liveContext, liveSegment, liveDetails)
  local filtered = {}
  if not manual then
    local normContext = liveContext:upper()
    local normDetails = liveDetails:upper()
    local normSegment = liveSegment:upper()
    -- Special case for MIDI_EDITOR with CC LANE, CC SEGMENT, or CC EVENT details:
    if normContext == "MIDI_EDITOR" and (normDetails == "CC LANE" or normDetails == "CC SEGMENT" or normDetails == "CC EVENT") then
      for section, mods in pairs(modifiers) do
        local cleaned = section:gsub("Mouse:%s*", "")
        if cleaned:upper():match("^MIDI%s*CC") then
          filtered[section] = mods
        end
      end
    elseif normContext == "CC_LANE" then
      -- Also handle the case when window is cc_lane (from the HTML)
      for section, mods in pairs(modifiers) do
        local cleaned = section:gsub("Mouse:%s*", "")
        if cleaned:upper():match("^MIDI%s*CC") then
          filtered[section] = mods
        end
      end
    else
      -- Normal procedure using the mapping table:
      local candidateGroups = get_modifier_keyword_groups(liveContext, liveSegment, liveDetails)
      -- Merge matches from all candidate groups:
      for _, candidate in ipairs(candidateGroups) do
        local keywordClean = candidate:gsub("^Mouse:%s*", "")
        for section, mods in pairs(modifiers) do
          local cleaned = section:gsub("Mouse:%s*", "")
          if cleaned:upper():sub(1, #keywordClean) == keywordClean:upper() then
            filtered[section] = mods
          end
        end
      end
    end
  else
    for section, mods in pairs(modifiers) do
      local grp, beh = extractGroupAndBehavior(section)
      if context ~= "All" and grp ~= context then goto continue end
      if behavior ~= "All" and beh:lower() ~= behavior:lower() then goto continue end
      filtered[section] = mods
      ::continue::
    end
  end
  return filtered
end

-----------------------------------------------------------
-- Sorting logic for modifier keys (unchanged)
-----------------------------------------------------------
local modifier_order = {
  ["Default action"] = 1,
  ["Shift"] = 2,
  ["Ctrl"] = 3,
  ["Shift+Ctrl"] = 4,
  ["Alt"] = 5,
  ["Shift+Alt"] = 6,
  ["Ctrl+Alt"] = 7,
  ["Shift+Ctrl+Alt"] = 8,
  ["Shift+Win"] = 9,
  ["Ctrl+Win"] = 10,
  ["Shift+Ctrl+Win"] = 11,
  ["Alt+Win"] = 12,
  ["Shift+Alt+Win"] = 13,
  ["Ctrl+Alt+Win"] = 14,
  ["Shift+Ctrl+Alt+Win"] = 15,
}

local function getModifierSortOrder(key)
  local norm = key:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  return modifier_order[norm] or 100
end

local function compareModifiers(a, b)
  return getModifierSortOrder(a) < getModifierSortOrder(b)
end

-----------------------------------------------------------
-- Utility: Get a sorted list of keys from a table.
-----------------------------------------------------------
local function getSortedKeys(tbl, comp)
  local keys = {}
  for k in pairs(tbl) do table.insert(keys, k) end
  table.sort(keys, comp or function(a, b) return a < b end)
  return keys
end

-----------------------------------------------------------
-- Sorting logic for Media Item modifiers
-----------------------------------------------------------
local mediaItemModifierOrder = {
    "Mouse: Media item left click",
    "Mouse: Media item left drag",
    "Mouse: Media item double click",
    "Mouse: Media item bottom half",
    "Mouse: Media item edge",
    "Mouse: Media item fade intersection",
    "Mouse: Media item fade/autocrossfade",
    "Mouse: Media item stretch marker",
    "Mouse: Media item take marker"
}

local mediaItemModifierRank = {}
for rank, name in ipairs(mediaItemModifierOrder) do
    mediaItemModifierRank[name] = rank
end

local mediaItemModifierRankLower = {}
for k, v in pairs(mediaItemModifierRank) do
    mediaItemModifierRankLower[k:lower()] = v
end

local function normalizeMediaItemSection(name)
    local lowerName = name:lower()
    if lowerName == "mouse: media item" then
        return "mouse: media item left click"
    end
    return lowerName
end

local function compareMediaItemModifiers(a, b)
    local a_norm = normalizeMediaItemSection(a)
    local b_norm = normalizeMediaItemSection(b)
    local rankA = mediaItemModifierRankLower[a_norm] or math.huge
    local rankB = mediaItemModifierRankLower[b_norm] or math.huge
    if rankA == rankB then
        return a_norm < b_norm
    else
        return rankA < rankB
    end
end

local function getSectionSortOrder(section)
  local s = section:lower()
  if s:find("left click") then
    return 1
  elseif s:find("left click/drag") then
    return 2
  elseif s:find("left drag") then
    return 3
  elseif s:find("right click") then
    return 4
  elseif s:find("double click") then
    return 5
  elseif s:find("right drag") then
    return 6
  elseif s:find("middle click") then
    return 7
  elseif s:find("middle drag") then
    return 8
  else
    return 100
  end
end

local function compareSections(a, b)
    local a_lower = a:lower()
    local b_lower = b:lower()
    local isAMedia = a_lower:find("^mouse:%s*media item")
    local isBMedia = b_lower:find("^mouse:%s*media item")
    if isAMedia and isBMedia then
        return compareMediaItemModifiers(a, b)
    elseif isAMedia and not isBMedia then
        return true
    elseif isBMedia and not isAMedia then
        return false
    else
        local orderA = getSectionSortOrder(a)
        local orderB = getSectionSortOrder(b)
        if orderA == orderB then
            return a < b
        else
            return orderA < orderB
        end
    end
end

-----------------------------------------------------------
-- Main UI function.
-----------------------------------------------------------
local function Main()
  setStyle()
  ImGui.PushFont(ctx, font)

  ImGui.SetNextWindowSize(ctx, 800, 600, ImGui.Cond_FirstUseEver)
  local visible, open = ImGui.Begin(ctx, "Mouse Buddy 3.0", true, ImGui.WindowFlags_NoCollapse)
  if visible then

    if ImGui.IsKeyPressed(ctx, ImGui.Key_F) then
      freezeDisplay = not freezeDisplay
    end

    if ImGui.IsKeyPressed(ctx, ImGui.Key_M) then
      mode = (mode == "live") and "manual" or "live"
    end

    if ImGui.BeginChild(ctx, "Path", -1, 20) then
      local changed, new_path = ImGui.InputText(ctx, "Path", pathInput)
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, "Browse") then
        local ok, filename = r.GetUserFileNameForRead("", "Select Mouse Modifiers HTML", ".html")
        if ok then
          pathInput = filename
          HTML_PATH = pathInput
          r.SetExtState(EXT_SECTION, EXT_KEY, HTML_PATH, true)
        end
      end
      if changed then
        pathInput = new_path
        HTML_PATH = pathInput
        r.SetExtState(EXT_SECTION, EXT_KEY, HTML_PATH, true)
      end
        ImGui.EndChild(ctx)
    end
  
    r.ImGui_Separator(ctx)
    r.ImGui_Text(ctx, "Mode:")
    r.ImGui_SameLine(ctx)
    if r.ImGui_RadioButton(ctx, "Live Mode", mode == "live") then mode = "live" end
    r.ImGui_SameLine(ctx)
    if r.ImGui_RadioButton(ctx, "Manual Mode", mode == "manual") then mode = "manual" end
  
    local liveContext, liveSegment, liveDetails = "", "", ""
    if mode ~= "manual" then
      if not freezeDisplay then
        local win, seg, det = get_mouse_context()
        if win ~= "unknown" then
          lastValidContext = win
        else
          win = lastValidContext or "unknown"
        end
        -- If segment or details are empty, use the last frozen values
        if seg == "" then seg = frozenSegment or "unknown" end
        if det == "" then det = frozenDetails or "" end
        liveContext = win
        liveSegment = seg
        liveDetails = det
        frozenContext = liveContext
        frozenSegment = liveSegment
        frozenDetails = liveDetails
      else
        liveContext = frozenContext
        liveSegment = frozenSegment
        liveDetails = frozenDetails
      end
      
      liveContext = liveContext or "unknown"
      liveSegment = liveSegment or "unknown"
      liveDetails = liveDetails or ""
      
      r.ImGui_Separator(ctx)
      r.ImGui_Text(ctx, "Context: " .. liveContext)
      r.ImGui_SameLine(ctx, 200)
      r.ImGui_Text(ctx, "Segment: " .. liveSegment)
      r.ImGui_SameLine(ctx, 400)
      r.ImGui_Text(ctx, "Details: " .. liveDetails)
      r.ImGui_Spacing(ctx)
      if freezeDisplay then r.ImGui_Text(ctx, "Display FROZEN") end
      r.ImGui_Separator(ctx)
    end
  
    local modifiers = readMouseModifiersFromHTML()
    local context = ""
    local behavior = ""
    if mode == "manual" then
      r.ImGui_Separator(ctx)
      local manualContextGroups, behaviorOptionsList = buildManualModeDropdowns(modifiers)
      r.ImGui_SetNextItemWidth(ctx, 140)
      local contextsStr = table.concat(manualContextGroups, "\0") .. "\0"
      local changedCtx, idx = r.ImGui_Combo(ctx, "Context Group##manual", selectedManualIndex, contextsStr, #manualContextGroups)
      if changedCtx then
        selectedManualIndex = idx
        selectedBehaviorIndex = 0
        manualContextGroups, behaviorOptionsList = buildManualModeDropdowns(modifiers)
      end
      context = manualContextGroups[selectedManualIndex+1] or "All"
      r.ImGui_SameLine(ctx)
      r.ImGui_SetNextItemWidth(ctx, 150)
      local behStr = table.concat(behaviorOptionsList, "\0") .. "\0"
      local changedBeh, behIdx = r.ImGui_Combo(ctx, "Behavior##manual", selectedBehaviorIndex, behStr, #behaviorOptionsList)
      if changedBeh then selectedBehaviorIndex = behIdx end
      behavior = behaviorOptionsList[selectedBehaviorIndex+1] or "All"
    end
  
    r.ImGui_BeginChild(ctx, "Content", -1, -1)
      if mode == "live" and (liveContext == "tcp" or liveContext == "mcp") and liveDetails == "empty" then
        r.ImGui_Text(ctx, "Double Click to Insert Track")
      else
        local filteredModifiers = nil
        if mode == "live" then
          filteredModifiers = filterModifiers(modifiers, nil, nil, false, liveContext, liveSegment, liveDetails)
        else
          filteredModifiers = filterModifiers(modifiers, context, behavior, true)
        end
        
        local sortedSections = getSortedKeys(filteredModifiers, compareSections)
        local displayed = false
        for _, section in ipairs(sortedSections) do
          if mode == "manual" then
            local grp, beh = extractGroupAndBehavior(section)
            if context ~= "All" and grp ~= context then goto continue_section end
            if behavior ~= "All" and beh:lower() ~= behavior:lower() then goto continue_section end
          end
          local cleanedName = section:gsub("Mouse:%s*", "")
          r.ImGui_Text(ctx, cleanedName)
          local mods = filteredModifiers[section]
          local sortedMods = getSortedKeys(mods, compareModifiers)
          for _, mod in ipairs(sortedMods) do
            local line = "  " .. mod .. " -> " .. mods[mod]
            r.ImGui_Text(ctx, line)
          end
          r.ImGui_Separator(ctx)
          displayed = true
          ::continue_section::
        end
        if not displayed then
          local extra = ""
          if mode == "live" then extra = " (" .. liveDetails .. ")" end
          r.ImGui_Text(ctx, "No mouse modifiers for context: " .. (mode=="live" and liveContext or context) .. extra)
        end
      end
    r.ImGui_EndChild(ctx)
  
    r.ImGui_End(ctx)
  end
  
  r.ImGui_PopFont(ctx)
  clearStyle()
  
  if open then r.defer(Main) end
end
  
r.defer(Main)
