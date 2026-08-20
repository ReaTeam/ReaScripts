-- @noindex

--[[
 * @noindex

  CustomShortcuts_Create.lua

  "Create mode" -- the editor. Bind a separate REAPER shortcut to THIS
  action. Lets you browse every action in a chosen section, see REAPER's
  own native shortcut (read-only, reference only), and define/edit a
  custom shortcut per action.

  WORKFLOW: pressing Enter on a successful commit (including clearing a
  shortcut) automatically advances to the NEXT row and starts editing it,
  so you can assign shortcuts down the list quickly without re-clicking
  each one. Typing a letter with no modifier tap first (which is what
  starting a search looks like) automatically backs out of row-editing
  and hands that letter to the search box instead.

  To clear a shortcut: click its cell, backspace the text away (if any),
  and press Enter with nothing typed.

  Custom shortcut entry uses the same "tap a modifier, then type a word"
  capture as Activate mode. The full stored shortcut is
  "<modifiers>+<word>" (e.g. "Cmd+Ctrl+punch"), combined at commit time
  from editCapture.heldModifierAtTap and editCapture.text.

  Saving is explicit -- nothing touches the data file until you click Save.

  NO SEPARATE SHORTCUT NEEDED: this script no longer needs its own bound
  REAPER shortcut. It's normally reached via the "Edit Shortcuts..."
  button inside Activate mode, which auto-registers this script as an
  action on first use if it isn't already. Every path that closes this
  window (Save, Discard, plain Escape/close) relaunches Activate as its
  last step, so you land right back in a fresh Activate window ready to
  run whatever you just assigned.

  Auto-seed: a blank custom-shortcut cell is seeded once from REAPER's own
  native shortcut if it's a simple modifier(s)+single-character combo
  (e.g. Cmd+M seeds "Cmd+m"). This only happens for rows that don't
  already have a saved custom value -- if you ever see a wrong auto-seeded
  value, delete CustomShortcuts_data.lua to force everything to reseed
  from scratch.

  Requires: ReaImGui, js_ReaScriptAPI (both via ReaPack -- see README).
--]]

if not reaper.ImGui_GetBuiltinPath or not reaper.JS_VKeys_GetState then
  reaper.ShowMessageBox(
    "This script requires ReaImGui and js_ReaScriptAPI.\nInstall both via Extensions > ReaPack > Browse packages.",
    "Missing dependency", 0)
  return
end

local info = debug.getinfo(1, "S")
local scriptDir = info.source:match("^@(.*[/\\])")
package.path = scriptDir .. "?.lua;" .. package.path

local core    = require("CustomShortcuts_core")
local capture = require("CustomShortcuts_capture")

package.path = reaper.ImGui_GetBuiltinPath() .. "/?.lua;" .. package.path
local ImGui = require("imgui")("0.9")

reaper.set_action_options(1)
core.ShutDownSiblingIfRunning(core.ACTIVATE_SCRIPT, 0)

local data = core.LoadData()

local WINDOW_NAME = "Custom Shortcuts - Create##Create"

local sectionRows = {}
local sectionReverseIdx = {}
local dirtyCount = 0

-- NOTE: single-char native-shortcut parsing and per-section auto-seeding
-- now live in core.lua (core.TryParseSingleCharShortcut / AutoSeedSection)
-- so Activate can use the exact same logic instead of a second, drifting
-- copy. Kept here only for the two sections Activate's own
-- SnapshotActiveSection() can never select on its own -- Media Explorer
-- and MIDI Event List Editor -- so it structurally can't seed them; this
-- file still owns persisting those.

local function buildReverseIndex(sectionId)
  local idx = {}
  for i, row in ipairs(sectionRows[sectionId]) do
    if row.customText ~= "" then idx[row.customText] = i end
  end
  sectionReverseIdx[sectionId] = idx
end

local function buildRowsForSection(sectionId)
  if sectionRows[sectionId] then return end

  local seededCount = core.AutoSeedSection(data, sectionId)
  if seededCount > 0 then
    local ok, err = core.SaveData(data)
    if not ok then
      reaper.ShowConsoleMsg("CustomShortcuts: failed to auto-save seeded shortcuts: " .. tostring(err) .. "\n")
    end
  end

  local sec = core.EnsureSection(data, sectionId)
  local byPersistentId = {}
  for phrase, entry in pairs(sec.shortcuts) do
    byPersistentId[entry.id] = phrase
  end

  local actions = core.EnumerateSectionActions(sectionId)
  local rows = {}
  for _, a in ipairs(actions) do
    local persistentId = core.GetPersistentId(a.cmdId)
    local native = core.GetNativeShortcuts(sectionId, a.cmdId)
    rows[#rows + 1] = {
      cmdId = a.cmdId, name = a.name, persistentId = persistentId,
      native = native, customText = byPersistentId[persistentId] or "", dirty = false,
    }
  end
  table.sort(rows, function(x, y) return x.name < y.name end)
  sectionRows[sectionId] = rows
  buildReverseIndex(sectionId)
end

local function saveAll()
  for sectionId, rows in pairs(sectionRows) do
    local sec = core.EnsureSection(data, sectionId)
    sec.shortcuts = {}
    for _, row in ipairs(rows) do
      if row.customText ~= "" then
        sec.shortcuts[row.customText] = { id = row.persistentId, name = row.name }
      end
      row.dirty = false
    end
  end
  dirtyCount = 0
  local ok, err = core.SaveData(data)
  if not ok then
    reaper.ShowMessageBox("Failed to save: " .. tostring(err), "Custom Shortcuts", 0)
  end
end

local ctx = ImGui.CreateContext("Custom Shortcuts - Create")
local FLT_MIN = ImGui.NumericLimits_Float()

local clipper = ImGui.CreateListClipper(ctx)
ImGui.Attach(ctx, clipper)

local sectionTabIdx = 1
local currentSectionId = core.SECTIONS[sectionTabIdx].id
buildRowsForSection(currentSectionId)

local searchText = ""
local editing = nil
local editCapture = nil

local conflictModal = nil
local conflictModalOpened = false
local followupModal = nil
local followupModalOpened = false
local closeConfirm = false
local closeConfirmOpened = false
local shouldClose = false

local wantEscapeConflict = false
local wantEscapeFollowup = false
local wantEscapeCloseConfirm = false
local wantRefocusMainWindow = false

-- Only sets a flag -- consumed at the TOP of the next frame's loop(),
-- before Begin(), via SetNextWindowFocus. Only call this when nothing
-- else is about to open a new popup this same cycle (the Steal path
-- skips it, since it immediately opens a followup modal that needs to
-- own focus instead).
local function closePopupAndRefocus()
  ImGui.CloseCurrentPopup(ctx)
  wantRefocusMainWindow = true
end

-- Closes this window AND relaunches Activate as the very last step, so
-- the user lands right back in a fresh Activate window ready to search
-- for (and immediately run) whatever they just assigned -- no need to
-- remember or press a separate shortcut to get back there. Safe to call
-- even if Activate wasn't the one that launched this session (e.g. Create
-- was opened directly via its own action) -- it just starts a new one.
local function closeAndRelaunchActivate()
  shouldClose = true
  local activateCmdId = core.GetSiblingCommandId(core.ACTIVATE_SCRIPT, 0)
  if activateCmdId and activateCmdId ~= 0 then
    reaper.Main_OnCommand(activateCmdId, 0)
  end
end

local function startEditingRow(rowIdx)
  editing = rowIdx
  editCapture = capture.NewCaptureState()
end

local function cancelEditing()
  editing = nil
  editCapture = nil
end

local function advanceToNextRow(fromIdx)
  local rows = sectionRows[currentSectionId]
  local nextIdx = fromIdx + 1
  if rows[nextIdx] then
    startEditingRow(nextIdx)
  else
    cancelEditing()
  end
end

local function commitEdit()
  local rows = sectionRows[currentSectionId]
  local row = rows[editing]
  local phrase = core.CombinedPhrase(editCapture)
  local idx = sectionReverseIdx[currentSectionId]
  local committedRowIdx = editing

  if phrase == "" then
    if row.customText ~= "" then
      idx[row.customText] = nil
      row.customText = ""
      if not row.dirty then row.dirty = true; dirtyCount = dirtyCount + 1 end
    end
    advanceToNextRow(committedRowIdx)
    return
  end

  local conflictRowIdx = idx[phrase]
  if conflictRowIdx and conflictRowIdx ~= editing then
    conflictModal = { rowIdx = editing, otherRowIdx = conflictRowIdx, phrase = phrase }
    conflictModalOpened = false
    return
  end

  idx[row.customText] = nil
  row.customText = phrase
  if not row.dirty then row.dirty = true; dirtyCount = dirtyCount + 1 end
  idx[phrase] = editing
  advanceToNextRow(committedRowIdx)
end

local function resolveSteal()
  local rows = sectionRows[currentSectionId]
  local idx = sectionReverseIdx[currentSectionId]
  local row = rows[conflictModal.rowIdx]
  local other = rows[conflictModal.otherRowIdx]

  idx[other.customText] = nil
  other.customText = ""
  if not other.dirty then other.dirty = true; dirtyCount = dirtyCount + 1 end

  idx[row.customText] = nil
  row.customText = conflictModal.phrase
  if not row.dirty then row.dirty = true; dirtyCount = dirtyCount + 1 end
  idx[conflictModal.phrase] = conflictModal.rowIdx

  local orphanRowIdx = conflictModal.otherRowIdx
  conflictModal = nil
  cancelEditing()
  followupModal = { orphanRowIdx = orphanRowIdx }
  followupModalOpened = false
end

local function resolveModify()
  -- Leave `editing` pointed at the same row so the user can immediately
  -- retype a shortcut for it. Reset the capture state so the rejected
  -- (conflicting) phrase doesn't linger in the field.
  conflictModal = nil
  if editing then
    editCapture = capture.NewCaptureState()
  end
end

-- Returns true if the caller should keep deferring (i.e. keep running).
local function frame()
  -- Consume the refocus request BEFORE Begin(), so it applies to the
  -- window we're about to create this frame -- not the popup that just
  -- closed last frame.
  if wantRefocusMainWindow then
    wantRefocusMainWindow = false
    ImGui.SetNextWindowFocus(ctx)
  end

  -- Wider default than before -- many action names are long, and the
  -- old 720px default truncated most of them, hiding native/custom
  -- shortcuts off to the right. Cond_FirstUseEver means this only
  -- applies the very first time the window is created; once resized by
  -- hand, ReaImGui remembers that size on future launches.
  ImGui.SetNextWindowSize(ctx, 1000, 600, ImGui.Cond_FirstUseEver)
  local visible, open = ImGui.Begin(ctx, WINDOW_NAME, true)

  local focused = ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_RootAndChildWindows)
  local modalOpen = (conflictModal ~= nil) or (followupModal ~= nil) or closeConfirm

  if visible then
    for i, s in ipairs(core.SECTIONS) do
      if i > 1 then ImGui.SameLine(ctx) end
      local isCurrent = (i == sectionTabIdx)
      if isCurrent then ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0x5588BBFF) end
      if ImGui.Button(ctx, s.name .. "##tab" .. i) and not isCurrent then
        sectionTabIdx = i
        currentSectionId = s.id
        buildRowsForSection(currentSectionId)
        cancelEditing()
      end
      if isCurrent then ImGui.PopStyleColor(ctx) end
    end

    -- Save is right-aligned at a position based on WINDOW WIDTH, not on
    -- how much precedes it on a line -- it used to share the search row
    -- with the search text and hint, so a long search string pushed it
    -- out of view. The tabs row's content is fixed-length, so anchoring
    -- here keeps Save visible no matter what's typed into search.
    do
      local saveLabel = dirtyCount > 0 and ("Save (" .. dirtyCount .. " unsaved)") or "Save"
      local saveWidth = 180
      ImGui.SameLine(ctx, ImGui.GetWindowWidth(ctx) - saveWidth)
      local saveDisabled = (dirtyCount == 0)
      if saveDisabled then ImGui.BeginDisabled(ctx) end
      local saveClicked = ImGui.Button(ctx, saveLabel, saveWidth - 16, 0)
      if saveDisabled then ImGui.EndDisabled(ctx) end
      if saveClicked and not saveDisabled then
        local ok, err = pcall(saveAll)
        if not ok then
          reaper.ShowConsoleMsg("CustomShortcuts save error: " .. tostring(err) .. "\n")
        end
      end
    end

    ImGui.Separator(ctx)

    ImGui.Text(ctx, "Search: " .. searchText)
    ImGui.SameLine(ctx)
    if ImGui.SmallButton(ctx, "Clear##searchclear") then
      searchText = ""
    end
    ImGui.SameLine(ctx)
    ImGui.TextDisabled(ctx, "(click a cell to edit; Enter commits + advances; empty + Enter clears; typing a letter with no modifier jumps to search)")

    ImGui.Separator(ctx)

    local rows = sectionRows[currentSectionId]
    local needle = searchText:lower()

    if ImGui.BeginTable(ctx, "actions", 3,
        ImGui.TableFlags_RowBg | ImGui.TableFlags_BordersInnerH | ImGui.TableFlags_ScrollY, 0, -1) then
      ImGui.TableSetupColumn(ctx, "Action", ImGui.TableColumnFlags_WidthStretch)
      ImGui.TableSetupColumn(ctx, "REAPER shortcut", ImGui.TableColumnFlags_WidthFixed, 140)
      ImGui.TableSetupColumn(ctx, "Custom shortcut", ImGui.TableColumnFlags_WidthFixed, 200)
      ImGui.TableSetupScrollFreeze(ctx, 0, 1)
      ImGui.TableHeadersRow(ctx)

      -- Multi-word, REAPER-Action-List-style filtering: every space-
      -- separated word in the search box must appear somewhere in the
      -- action name, in any order (e.g. "track show" matches "Track:
      -- Show FX chain").
      local filtered = {}
      if needle == "" then
        for i = 1, #rows do filtered[#filtered + 1] = i end
      else
        for i, row in ipairs(rows) do
          if core.ScoreNameMatch(row.name, needle) > 0 then filtered[#filtered + 1] = i end
        end
      end

      ImGui.ListClipper_Begin(clipper, #filtered)
      while ImGui.ListClipper_Step(clipper) do
        local first, last = ImGui.ListClipper_GetDisplayRange(clipper)
        for f = first, last - 1 do
          local rowIdx = filtered[f + 1]
          local row = rows[rowIdx]
          ImGui.TableNextRow(ctx)

          ImGui.TableNextColumn(ctx)
          if row.dirty then ImGui.TextColored(ctx, 0xFFD966FF, "*" .. row.name)
          else ImGui.Text(ctx, row.name) end

          ImGui.TableNextColumn(ctx)
          ImGui.TextDisabled(ctx, row.native[1] or "")

          ImGui.TableNextColumn(ctx)
          local isEditing = (editing == rowIdx)
          local isConflictFlagged = false
          local shownText = row.customText
          if isEditing then
            shownText = (editCapture.mode == "shortcut")
                and ((editCapture.heldModifierAtTap or "") .. "+" .. editCapture.text)
                or (editCapture.text == "" and "(tap a modifier, or Enter to clear)" or "(tap a modifier first)")
            if editCapture.mode == "shortcut" and editCapture.text ~= "" then
              local candidatePhrase = core.CombinedPhrase(editCapture)
              local idx = sectionReverseIdx[currentSectionId]
              local conflictOwner = idx[candidatePhrase]
              isConflictFlagged = conflictOwner and conflictOwner ~= rowIdx
            end
          end

          if isConflictFlagged then
            ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xFF6666FF)
          elseif isEditing then
            ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0x77CCFFFF)
          end
          ImGui.Selectable(ctx, (shownText == "" and "(none)" or shownText) .. "##cell" .. rowIdx, isEditing)
          if isConflictFlagged or isEditing then ImGui.PopStyleColor(ctx) end

          if ImGui.IsItemClicked(ctx) and not isEditing then
            startEditingRow(rowIdx)
          end
        end
      end

      ImGui.EndTable(ctx)
    end

    -- Conflict modal
    if conflictModal and not conflictModalOpened then
      conflictModalOpened = true
      ImGui.OpenPopup(ctx, "Shortcut conflict")
    end
    if ImGui.BeginPopupModal(ctx, "Shortcut conflict", nil, ImGui.WindowFlags_AlwaysAutoResize) then
      if wantEscapeConflict then
        wantEscapeConflict = false
        closePopupAndRefocus()
        resolveModify()
      elseif conflictModal then
        local rows2 = sectionRows[currentSectionId]
        local otherName = rows2[conflictModal.otherRowIdx].name
        ImGui.Text(ctx, "'" .. conflictModal.phrase .. "' is already assigned to:")
        ImGui.TextColored(ctx, 0xFFD966FF, otherName)
        ImGui.Spacing(ctx)
        if ImGui.Button(ctx, "Steal it", 120, 0) then
          -- Deliberately NOT closePopupAndRefocus() here: resolveSteal()
          -- immediately opens the followup modal, so requesting a main-
          -- window refocus this cycle would fight with that popup opening
          -- next frame. The followup modal's own buttons request refocus
          -- when THEY close instead.
          ImGui.CloseCurrentPopup(ctx)
          resolveSteal()
        end
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, "Modify mine", 120, 0) then
          closePopupAndRefocus()
          resolveModify()
        end
        ImGui.Spacing(ctx)
        ImGui.TextDisabled(ctx, "(Escape also backs out to keep editing)")
      end
      ImGui.EndPopup(ctx)
    end

    -- Followup modal (after a steal)
    if followupModal and not followupModalOpened then
      followupModalOpened = true
      ImGui.OpenPopup(ctx, "Assign new shortcut?")
    end
    if ImGui.BeginPopupModal(ctx, "Assign new shortcut?", nil, ImGui.WindowFlags_AlwaysAutoResize) then
      if wantEscapeFollowup then
        wantEscapeFollowup = false
        closePopupAndRefocus()
        followupModal = nil
      elseif followupModal then
        local rows2 = sectionRows[currentSectionId]
        local orphanName = rows2[followupModal.orphanRowIdx].name
        ImGui.Text(ctx, "'" .. orphanName .. "' just lost its shortcut.")
        ImGui.Text(ctx, "Give it a new one now?")
        ImGui.Spacing(ctx)
        if ImGui.Button(ctx, "Assign now", 120, 0) then
          local orphanIdx = followupModal.orphanRowIdx
          closePopupAndRefocus()
          followupModal = nil
          startEditingRow(orphanIdx)
        end
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, "Skip for now", 120, 0) then
          closePopupAndRefocus()
          followupModal = nil
        end
        ImGui.Spacing(ctx)
        ImGui.TextDisabled(ctx, "(Escape also skips)")
      end
      ImGui.EndPopup(ctx)
    end

    -- Close-with-unsaved-changes confirm
    if closeConfirm and not closeConfirmOpened then
      closeConfirmOpened = true
      ImGui.OpenPopup(ctx, "Unsaved changes")
    end
    if ImGui.BeginPopupModal(ctx, "Unsaved changes", nil, ImGui.WindowFlags_AlwaysAutoResize) then
      if wantEscapeCloseConfirm then
        wantEscapeCloseConfirm = false
        closePopupAndRefocus()
        closeConfirm = false
        closeConfirmOpened = false
      else
        ImGui.Text(ctx, "You have " .. dirtyCount .. " unsaved change(s).")
        if ImGui.Button(ctx, "Save", 100, 0) then
          pcall(saveAll); closePopupAndRefocus(); closeAndRelaunchActivate()
        end
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, "Discard", 100, 0) then
          closePopupAndRefocus(); closeAndRelaunchActivate()
        end
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, "Cancel", 100, 0) then
          closePopupAndRefocus(); closeConfirm = false; closeConfirmOpened = false
        end
        ImGui.Spacing(ctx)
        ImGui.TextDisabled(ctx, "(Escape also cancels)")
      end
      ImGui.EndPopup(ctx)
    end
  end

  -- Must always be called, regardless of `visible` -- only the CONTENT
  -- above (including the modals) is meant to be conditional on it.
  ImGui.End(ctx)

  capture.SetFocused(focused)

  if focused and not modalOpen then
    local keys = capture.PollKeys()

    if editing then
      capture.Update(editCapture, keys)
      if editCapture.mode == "search" then
        -- A letter arrived with no modifier tap first -- not a valid
        -- shortcut kickoff. Read this as "the user wants to search
        -- instead": back out of row-editing and forward the letter(s)
        -- captured so far into the global search box.
        searchText = searchText .. editCapture.text
        cancelEditing()
      elseif keys.pressed[capture.VK_RETURN] then
        commitEdit()
      elseif keys.pressed[capture.VK_ESCAPE] then
        cancelEditing()
      end
    else
      if keys.pressed[capture.VK_BACK] and #searchText > 0 then
        searchText = searchText:sub(1, -2)
      end
      if keys.pressed[capture.VK_DELETE] then
        -- Same as clicking Clear.
        searchText = ""
      end
      for _, vk in ipairs(capture.TEXT_VKEYS) do
        if keys.pressed[vk] then
          local isShift = keys.down[capture.VK_SHIFT]
          local ch = capture.VkeyToChar(vk, isShift)
          if ch then searchText = searchText .. ch end
        end
      end
      if keys.pressed[capture.VK_ESCAPE] then
        if dirtyCount > 0 then
          closeConfirm = true
        else
          closeAndRelaunchActivate()
        end
      end
    end
  elseif focused and modalOpen then
    local keys = capture.PollKeys()
    if keys.pressed[capture.VK_ESCAPE] then
      if conflictModal then wantEscapeConflict = true
      elseif followupModal then wantEscapeFollowup = true
      elseif closeConfirm then wantEscapeCloseConfirm = true
      end
    end
  end

  if not open and not shouldClose then
    if dirtyCount > 0 then
      closeConfirm = true
    else
      closeAndRelaunchActivate()
    end
  end

  return not shouldClose
end

local function loop()
  local ok, keepGoing = pcall(frame)
  if not ok then
    reaper.ShowConsoleMsg("CustomShortcuts Create error: " .. tostring(keepGoing) .. "\n")
    capture.ReleaseAll() -- release immediately, don't rely solely on atexit
    return
  end
  if keepGoing then
    reaper.defer(loop)
  end
end

reaper.atexit(function()
  capture.ReleaseAll() -- must be first; also the backup net if pcall above didn't fire
end)

-- Must happen before the first real PollKeys() call, i.e. before the
-- defer loop starts -- see capture.lua's PrimeKeyState() note.
capture.PrimeKeyState()

reaper.defer(loop)
