-- @noindex

--[[ 
   Smart Grouping with ImGui Key Press + AI Sub-Window (Dockable Version – Vertical Layout)
   Global hotkeys (via JS_ReaScriptAPI), SHIFT‑click multi‑selection, auto-adding new tracks,
   and now a "Group Marker Track" that is automatically created at the top to show the current group.

   NOTES:
   • For global hotkeys (digits) to work even if the GUI isn't focused, you must install
     the "js_ReaScriptAPI" extension. Otherwise, digits only work when the ImGui window is focused.
   • "Show All" is group 10. If group 10 is selected alongside any others, effectively all tracks show.
   • Color is only applied if exactly one group is selected (1–9).
   • SHIFT-click toggles group selection; normal click picks only that group.
   • SHIFT + digit key toggles that group, digit alone sets a single group.
   • A "Refresh Tracks" button re‑scans the project tracks.
   • If exactly one group (1–9) is selected, newly created tracks are auto‑added to that group.
   • Group 10 is off‑limits to the AI prompt (it won’t get modified).
   • A special "Group Marker Track" is automatically created at index 0 whenever exactly one group <10 is selected.
     It’s removed when you select another group or do multi‑selection.
--]]

----------------------------------------
-- Utility: Convert color table <-> string
----------------------------------------
local function colorTableToString(col)
  if not col then return "" end
  return string.format("%.3f,%.3f,%.3f,%.3f", col[1] or 0, col[2] or 0, col[3] or 0, col[4] or 1)
end

local function parseColorString(str)
  local t = {}
  for num in str:gmatch("([%d%.]+)") do
    t[#t+1] = tonumber(num)
  end
  if #t < 4 then t[4] = 1 end
  return t
end

----------------------------------------
-- Check for ReaImGui and JS_API
----------------------------------------
local reaper = reaper
if not reaper.ImGui_CreateContext then
  reaper.ShowMessageBox("ReaImGui is required. Please install via ReaPack.", "Error", 0)
  return
end

-- We only do true global key detection if JS_ReaScriptAPI is present:
local hasJS = reaper.APIExists("JS_VKeys_GetState")

----------------------------------------
-- Create ImGui Context
----------------------------------------
local ctx = reaper.ImGui_CreateContext("Smart Grouping (ImGui Keys) + AI")
reaper.ImGui_SetNextWindowSize(ctx, 800, 500, reaper.ImGui_Cond_FirstUseEver())

----------------------------------------
-- Global Variables & Key Mapping
----------------------------------------
local isGuiVisible     = true
local aiWindowIsOpen   = false
local oldTrackCount    = 0 -- We'll track changes in track count to auto-add
local KEY_SHOW_GUI     = reaper.ImGui_Key_F2()  -- F2 to re‑show GUI

-- When ImGui is focused, we capture these key presses:
local digitKeys = {
  reaper.ImGui_Key_1(),
  reaper.ImGui_Key_2(),
  reaper.ImGui_Key_3(),
  reaper.ImGui_Key_4(),
  reaper.ImGui_Key_5(),
  reaper.ImGui_Key_6(),
  reaper.ImGui_Key_7(),
  reaper.ImGui_Key_8(),
  reaper.ImGui_Key_9(),
  reaper.ImGui_Key_0()
}

----------------------------------------
-- SHIFT detection (for ImGui keys)
----------------------------------------
local function isShiftDown()
  return (reaper.ImGui_GetKeyMods(ctx) & reaper.ImGui_Mod_Shift()) ~= 0
end

----------------------------------------
-- 10 Fixed Groups
----------------------------------------
local groups = {}
for i = 1, 10 do
  if i < 10 then
    groups[i] = {
      name    = "Group" .. i,
      tracks  = {},
      color   = {0.5, 0.5, 0.5, 1},
      colorStr= "0.500,0.500,0.500,1.000"
    }
  else
    groups[i] = { name = "Show All", tracks = {}, color = nil, colorStr = "" }
  end
end

local allTracks = {}  -- { track=reaper.Track, name=string }

-- Multiple selected groups possible
local selectedGroups = { [1] = true }  -- By default, group 1 is selected

----------------------------------------
-- Save/Load Groups (Project ExtState)
----------------------------------------
local function serializeGroups()
  local lines = {}
  for i = 1, 10 do
    local g = groups[i]
    local nm = g.name or ("Group" .. i)
    local mem = table.concat(g.tracks, ",")
    local colStr = g.colorStr or ""
    lines[#lines+1] = string.format("GRP|idx=%d|name=%s|tracks=%s|color=%s", i, nm, mem, colStr)
  end
  return table.concat(lines, "\n")
end

local function deserializeGroups(str)
  local out = {}
  for line in (str or ""):gmatch("[^\r\n]+") do
    if line:find("^GRP|") then
      local idxS   = line:match("idx=(%d+)")
      local nm     = line:match("name=(.-)|tracks")
      local tr     = line:match("tracks=(.-)|color")
      local colStr = line:match("color=(.*)$")
      local idx    = tonumber(idxS) or 1
      local name   = nm or ("Group" .. idx)
      local trackList = {}

      if tr and tr ~= "" then
        for piece in tr:gmatch("([^,]+)") do
          piece = piece:match("^%s*(.-)%s*$")
          trackList[#trackList+1] = piece
        end
      end

      local colorVal = nil
      if colStr and colStr ~= "" then
        colorVal = parseColorString(colStr)
      end
      out[idx] = { name=name, tracks=trackList, color=colorVal, colorStr=(colStr or "") }
    end
  end

  for i = 1, 10 do
    if not out[i] then
      if i < 10 then
        out[i] = {
          name    = "Group" .. i,
          tracks  = {},
          color   = {0.5, 0.5, 0.5, 1},
          colorStr= "0.500,0.500,0.500,1.000"
        }
      else
        out[i] = { name = "Show All", tracks = {}, color = nil, colorStr = "" }
      end
    end
  end
  return out
end

local function autosaveGroups()
  local data = serializeGroups()
  reaper.SetProjExtState(0, "SmartImGuiGroups", "groups", data)
end

local function loadGroups()
  local ret, stored = reaper.GetProjExtState(0, "SmartImGuiGroups", "groups")
  if ret > 0 and stored ~= "" then
    groups = deserializeGroups(stored)
  end
end

----------------------------------------
-- Refresh All Tracks
----------------------------------------
local function refreshAllTracks()
  allTracks = {}
  local cnt = reaper.CountTracks(0)
  for i = 0, cnt - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, nm = reaper.GetTrackName(tr, "")
    if nm == "" then nm = "Track " .. (i+1) end
    allTracks[#allTracks+1] = { track=tr, name=nm }
  end
end

----------------------------------------
-- Group Membership Utilities
----------------------------------------
local function isTrackInGroup(gIndex, trackName)
  for _, tn in ipairs(groups[gIndex].tracks) do
    if tn:lower() == trackName:lower() then
      return true
    end
  end
  return false
end

local function addTrackToGroup(gIndex, trackName)
  if not isTrackInGroup(gIndex, trackName) then
    table.insert(groups[gIndex].tracks, trackName)
    autosaveGroups()
  end
end

local function removeTrackFromGroup(gIndex, trackName)
  for idx = #groups[gIndex].tracks, 1, -1 do
    if groups[gIndex].tracks[idx]:lower() == trackName:lower() then
      table.remove(groups[gIndex].tracks, idx)
      autosaveGroups()
      return
    end
  end
end

----------------------------------------
-- Remove any "Group Marker Track" at top
----------------------------------------
local function removeExistingMarkerTracks()
  local cnt = reaper.CountTracks(0)
  -- We'll search from the bottom up so indexing doesn't shift
  for i = cnt - 1, 0, -1 do
    local tr = reaper.GetTrack(0, i)
    local _, nm = reaper.GetTrackName(tr, "")
    if nm:find("^=== GROUP ") then
      reaper.DeleteTrack(tr)
    end
  end
end

----------------------------------------
-- Create "Group Marker Track" for exactly one group < 10
----------------------------------------
local function createMarkerTrack(gIndex)
  local grp = groups[gIndex]
  reaper.InsertTrackAtIndex(0, false) -- insert at top
  local tr = reaper.GetTrack(0, 0)
  local markerName = "=== GROUP " .. (grp.name or ("#" .. gIndex)) .. " ==="
  reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", markerName, true)

  -- Optionally hide in the mixer if you want:
  -- reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINMIX", 0)

  -- Color it the same as the group's color if you like:
  local clr = grp.color
  if clr then
    local r = math.floor(clr[1] * 255)
    local g = math.floor(clr[2] * 255)
    local b = math.floor(clr[3] * 255)
    local nativeColor = reaper.ColorToNative(r, g, b) + 0x1000000
    reaper.SetMediaTrackInfo_Value(tr, "I_CUSTOMCOLOR", nativeColor)
  end
end

----------------------------------------
-- Show Only The Union of Selected Groups
-- Then optionally create marker track
----------------------------------------
local function showSelectedGroups()
  local selectedSet = {}
  for gIndex, _ in pairs(selectedGroups) do
    if gIndex == 10 then
      -- If group 10 is selected => show all
      selectedSet = nil
      break
    end
  end

  if selectedSet then
    for gIndex, _ in pairs(selectedGroups) do
      for _, tn in ipairs(groups[gIndex].tracks) do
        selectedSet[tn:lower()] = true
      end
    end
  end

  local trackCount = reaper.CountTracks(0)
  for i = 0, trackCount - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, tn = reaper.GetTrackName(tr, "")
    -- skip marker tracks in the matching logic (always show them if they exist, or we'll remove them below)
    local isMarker = tn:find("^=== GROUP ")
    if isMarker then
      -- We'll handle remove or keep separately
    else
      local show = false
      if not selectedSet then
        show = true
      else
        if selectedSet[tn:lower()] then
          show = true
        end
      end
      reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINTCP", show and 1 or 0)
      reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINMIX", show and 1 or 0)
    end
  end

  -- color if exactly one group 1..9 is selected
  local singleGrp, count = nil, 0
  for gIndex, _ in pairs(selectedGroups) do
    count = count + 1
    singleGrp = gIndex
    if count > 1 then break end
  end

  if count == 1 and singleGrp < 10 then
    local clr = groups[singleGrp].color
    if clr then
      local function applyColor(tr)
        local r = math.floor(clr[1] * 255)
        local g = math.floor(clr[2] * 255)
        local b = math.floor(clr[3] * 255)
        local nativeColor = reaper.ColorToNative(r, g, b) + 0x1000000
        reaper.SetMediaTrackInfo_Value(tr, "I_CUSTOMCOLOR", nativeColor)
      end
      for i = 0, trackCount - 1 do
        local tr = reaper.GetTrack(0, i)
        local visibleTCP = reaper.GetMediaTrackInfo_Value(tr, "B_SHOWINTCP")
        if visibleTCP == 1 then
          applyColor(tr)
        end
      end
    end
  end

  -- Always remove existing marker tracks:
  removeExistingMarkerTracks()

  -- Then create a marker track if exactly one group <10 is selected
  if count == 1 and singleGrp < 10 then
    createMarkerTrack(singleGrp)
  end

  reaper.TrackList_AdjustWindows(false)
  reaper.UpdateTimeline()
end

----------------------------------------
-- AI Sub-Window
----------------------------------------
local function parseAIResponse(resp)
  local out = {}
  for block in resp:gmatch("%[(.-)%]") do
    local idxS  = block:match("GroupNumber:%s*(%d+)")
    local nm    = block:match("Name:%s*([^;]+)")
    local colS  = block:match("Color:%s*([^;]+)")
    local tr    = block:match("Tracks:%s*(.-)%s*$")
    if idxS and nm and tr then
      local idx = tonumber(idxS) or 1
      if idx >= 1 and idx <= 10 then
        local trackList = {}
        for piece in tr:gmatch("([^,]+)") do
          piece = piece:match("^%s*(.-)%s*$")
          trackList[#trackList+1] = piece
        end
        local colorVal = colS and parseColorString(colS) or nil
        out[#out+1] = { idx=idx, name=nm, tracks=trackList, colorStr=(colS or ""), color=colorVal }
      end
    end
  end
  return out
end

local function applyAIResponse(resp)
  local arr = parseAIResponse(resp)
  if #arr == 0 then
    reaper.ShowMessageBox(
      "No valid bracket data found.\nFormat:\n[GroupNumber: 1; Name: XYZ; Color: 0.500,0.500,0.500,1.000; Tracks: A,B].",
      "Error", 0
    )
    return
  end
  for _, info in ipairs(arr) do
    if info.idx == 10 then
      goto continue -- skip group 10 modifications
    end
    groups[info.idx].name = info.name
    groups[info.idx].tracks = info.tracks
    if info.colorStr and info.colorStr ~= "" then
      groups[info.idx].colorStr = info.colorStr
      groups[info.idx].color = parseColorString(info.colorStr)
    end
    ::continue::
  end
  autosaveGroups()
  reaper.ShowMessageBox("AI grouping applied.\nCheck main window for changes.", "OK", 0)
end

local AI_Instructions  = ""
local AI_Prompt        = ""
local AI_Response      = ""

local function generateAIPrompt()
  local trackList = {}
  for _, t in ipairs(allTracks) do
    trackList[#trackList+1] = t.name
  end
  local prompt = "Dear AI,\n" .. AI_Instructions .. "\n\n"
  prompt = prompt .. "We have 10 fixed groups (GroupNumber: 1..10) mapped to keys 1..9 and 0.\n"
  prompt = prompt .. "Group 10 is 'Show All'—do NOT change or overwrite it.\n"
  prompt = prompt .. "Each group (except group 10) has a color defined as r,g,b,a.\n"
  prompt = prompt .. "IMPORTANT: Return your grouping in this bracket format, skipping group 10:\n"
  prompt = prompt .. "[GroupNumber: 1; Name: Drums; Color: 0.800,0.200,0.200,1.000; Tracks: Kick,Snare]\n\n"
  prompt = prompt .. "Available track names:\n"
  for _, nm in ipairs(trackList) do
    prompt = prompt .. "- " .. nm .. "\n"
  end
  AI_Prompt = prompt
end

local function DrawAIWindow()
  if aiWindowIsOpen then
    local aiWindowFlags = reaper.ImGui_WindowFlags_NoCollapse()
    reaper.ImGui_SetNextWindowCollapsed(ctx, false, reaper.ImGui_Cond_FirstUseEver())
    local visible, openAI = reaper.ImGui_Begin(ctx, "AI Grouping Window##AI", aiWindowIsOpen, aiWindowFlags)
    if visible then
      reaper.ImGui_Text(ctx, "Enter AI grouping instructions:")
      local ci, newI = reaper.ImGui_InputTextMultiline(ctx, "##AIInstrEdit", AI_Instructions, 700, 80)
      if ci then AI_Instructions = newI end

      if reaper.ImGui_Button(ctx, "Generate Prompt##btnAIGen") then
        generateAIPrompt()
      end
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_Button(ctx, "Copy Prompt##btnAICopy") then
        reaper.CF_SetClipboard(AI_Prompt or "")
        reaper.ShowMessageBox("Prompt copied to clipboard!", "OK", 0)
      end

      reaper.ImGui_Separator(ctx)
      reaper.ImGui_Text(ctx, "Generated Prompt:")
      reaper.ImGui_InputTextMultiline(ctx, "##AIPromptView", AI_Prompt, 700, 80, reaper.ImGui_InputTextFlags_ReadOnly())

      reaper.ImGui_Separator(ctx)
      reaper.ImGui_Text(ctx, "Paste AI bracket data here:")
      local cr, newR = reaper.ImGui_InputTextMultiline(ctx, "##AIRespEdit", AI_Response, 700, 80)
      if cr then AI_Response = newR end

      if reaper.ImGui_Button(ctx, "Apply##btnApplyAI") then
        applyAIResponse(AI_Response or "")
      end
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_Button(ctx, "Close##btnAIClose") then
        aiWindowIsOpen = false
      end
    end
    reaper.ImGui_End(ctx)
    aiWindowIsOpen = openAI
  end
end

----------------------------------------
-- Helpers to see if exactly one group is selected
----------------------------------------
local function getSingleSelectedGroup()
  local singleGrp, count = nil, 0
  for gIndex, _ in pairs(selectedGroups) do
    count = count + 1
    singleGrp = gIndex
    if count > 1 then break end
  end
  return singleGrp, count
end

----------------------------------------
-- Main Window
----------------------------------------
local function isGroupSelected(gIndex)
  return selectedGroups[gIndex] == true
end

local function toggleGroup(gIndex)
  if isGroupSelected(gIndex) then
    selectedGroups[gIndex] = nil
  else
    selectedGroups[gIndex] = true
  end
end

local function setSingleGroup(gIndex)
  selectedGroups = {}
  selectedGroups[gIndex] = true
end

local function DrawMainWindow()
  local mainWindowFlags = reaper.ImGui_WindowFlags_NoCollapse()
  reaper.ImGui_SetNextWindowDockID(ctx, 100, reaper.ImGui_Cond_Once())
  local visible, openMain = reaper.ImGui_Begin(ctx, "Smart Grouping (ImGui Key)##Main", isGuiVisible, mainWindowFlags)
  if visible then
    if reaper.ImGui_Button(ctx, "Open AI Window##btnAI") then
      aiWindowIsOpen = true
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, "Close##btnCloseMain") then
      isGuiVisible = false
    end

    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, "Refresh Tracks##btnRefreshTracks") then
      refreshAllTracks()
      showSelectedGroups()
    end

    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Text(ctx, "Press digit keys 1..9 or 0. SHIFT+digit toggles that group (requires JS_API for global).")
    reaper.ImGui_Text(ctx, "SHIFT-click to multi-select groups. Click w/o SHIFT to select just one.")
    reaper.ImGui_Separator(ctx)

    -- Top Pane: list of groups
    if reaper.ImGui_BeginChild(ctx, "##TopPane", -1.0, 200.0, 0) then
      reaper.ImGui_Text(ctx, "Groups:")
      for i = 1, 10 do
        local g   = groups[i]
        local sel = isGroupSelected(i)
        local label = (g.name ~= "" and g.name) or ("(Group #" .. i .. ")")

        if reaper.ImGui_Selectable(ctx, label .. "##grp" .. i, sel) then
          if isShiftDown() then
            toggleGroup(i)
          else
            setSingleGroup(i)
          end
          showSelectedGroups()
        end
      end
      reaper.ImGui_EndChild(ctx)
    end

    reaper.ImGui_Separator(ctx)

    -- Bottom Pane: details of exactly one group
    local countSel, firstSel = 0, nil
    for i = 1, 10 do
      if selectedGroups[i] then
        countSel = countSel + 1
        if not firstSel then firstSel = i end
        if countSel > 1 then break end
      end
    end

    if reaper.ImGui_BeginChild(ctx, "##BottomPane", -1.0, -1.0, 0) then
      if countSel == 1 and firstSel then
        local grp = groups[firstSel]
        local keyLabel = (firstSel < 10) and tostring(firstSel) or "0"

        reaper.ImGui_Text(ctx, "Selected Group: " .. grp.name .. "  (Key " .. keyLabel .. ")")

        reaper.ImGui_Text(ctx, "Rename:")
        reaper.ImGui_SameLine(ctx)
        local changedName, newName = reaper.ImGui_InputText(ctx, "##grpName", grp.name)
        if changedName then
          grp.name = newName
          autosaveGroups()
          showSelectedGroups()  -- also refresh the marker track name
        end

        if firstSel < 10 then
          reaper.ImGui_Text(ctx, "Color (r,g,b,a):")
          local changedColor, newCStr = reaper.ImGui_InputText(ctx, "##grpColor", grp.colorStr or "", 64)
          if changedColor then
            grp.colorStr = newCStr
            grp.color = parseColorString(newCStr)
            autosaveGroups()
            showSelectedGroups()  -- update color on marker track
          end
        else
          reaper.ImGui_Text(ctx, "Show All group: no color.")
        end

        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Text(ctx, "Tracks in this group:")
        for _, tinfo in ipairs(allTracks) do
          local inGrp = isTrackInGroup(firstSel, tinfo.name)
          local changedChk, newVal = reaper.ImGui_Checkbox(ctx, tinfo.name .. "##" .. tinfo.name, inGrp)
          if changedChk then
            if newVal then
              addTrackToGroup(firstSel, tinfo.name)
            else
              removeTrackFromGroup(firstSel, tinfo.name)
            end
            showSelectedGroups()
          end
        end

        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Text(ctx, "Press key " .. keyLabel .. " to hide all but this group (or SHIFT+key to toggle).")
      else
        reaper.ImGui_Text(ctx, "Multiple groups selected or none selected.\nSelect exactly one group to view/edit details.")
      end
      reaper.ImGui_EndChild(ctx)
    end
  end
  reaper.ImGui_End(ctx)
  isGuiVisible = openMain
end

----------------------------------------
-- Key Checks
----------------------------------------
-- 1) ImGui-based (only if ImGui window has focus):
local function globalKeyCheck_ImGui()
  for i = 1, 10 do
    if reaper.ImGui_IsKeyPressed(ctx, digitKeys[i], false) then
      if isShiftDown() then
        toggleGroup(i)
      else
        setSingleGroup(i)
      end
      showSelectedGroups()
    end
  end
end

-- 2) JS-based global (works if user has js_ReaScriptAPI):
local lastKeyState = {}
local function globalKeyCheck_JS()
  if not hasJS then return end
  local keystate = reaper.JS_VKeys_GetState(0)
  if not keystate then return end

  -- VK codes for top row digits: '1'..'9' = 0x31..0x39, '0' = 0x30
  local digitsMap = {
    [0x31] = 1,  -- '1'
    [0x32] = 2,  
    [0x33] = 3,
    [0x34] = 4,
    [0x35] = 5,
    [0x36] = 6,
    [0x37] = 7,
    [0x38] = 8,
    [0x39] = 9,
    [0x30] = 10, -- '0'
  }

  -- SHIFT: 0x10 = VK_SHIFT, 0xA0/A1 = left/right shift
  local SHIFT_down = (
    keystate:byte(0x10+1) ~= 0 or
    keystate:byte(0xA0+1) ~= 0 or
    keystate:byte(0xA1+1) ~= 0
  )

  for vkCode, groupNum in pairs(digitsMap) do
    local isDown   = (keystate:byte(vkCode) ~= 0)
    local wasDown  = lastKeyState[vkCode] or false

    if isDown and not wasDown then
      if SHIFT_down then
        toggleGroup(groupNum)
      else
        setSingleGroup(groupNum)
      end
      showSelectedGroups()
    end
    lastKeyState[vkCode] = isDown
  end
end

----------------------------------------
-- Main Loop (deferred)
----------------------------------------
local function mainLoop()
  -- If ImGui window is focused, check ImGui-based hotkeys:
  globalKeyCheck_ImGui()

  -- Always check JS-based global hotkeys (if available)
  globalKeyCheck_JS()

  -- Check if new tracks were created
  local newTrackCount = reaper.CountTracks(0)
  if newTrackCount > oldTrackCount then
    refreshAllTracks()
    local singleGrp, countSel = getSingleSelectedGroup()
    if countSel == 1 and singleGrp and singleGrp < 10 then
      -- Add newly created tracks to that group:
      for i = oldTrackCount, newTrackCount - 1 do
        local tr = reaper.GetTrack(0, i)
        local _, nm = reaper.GetTrackName(tr, "")
        addTrackToGroup(singleGrp, nm)
      end
      showSelectedGroups()
    end
  end
  oldTrackCount = newTrackCount

  -- Draw UI
  if isGuiVisible then
    DrawMainWindow()
  end
  if aiWindowIsOpen then
    DrawAIWindow()
  end

  -- If user presses F2 while any ImGui window is focused, show main GUI if hidden
  if reaper.ImGui_IsWindowFocused(ctx, reaper.ImGui_FocusedFlags_AnyWindow()) then
    if reaper.ImGui_IsKeyPressed(ctx, KEY_SHOW_GUI, false) then
      isGuiVisible = true
    end
  end

  reaper.defer(mainLoop)
end

----------------------------------------
-- Script Start
----------------------------------------
local function StartScript()
  oldTrackCount = reaper.CountTracks(0)
  refreshAllTracks()
  loadGroups()
  showSelectedGroups()
  mainLoop()
end

StartScript()
