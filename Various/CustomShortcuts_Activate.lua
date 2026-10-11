-- @description CustomShortcuts - Create keyboard shortcuts with multiple characters, plus find & run any Action quickly.
-- @author axeman2u
-- @version 1.1
-- @provides
--   CustomShortcuts_Activate/CustomShortcuts_capture.lua
--   CustomShortcuts_Activate/CustomShortcuts_core.lua
--   CustomShortcuts_Activate/CustomShortcuts_Create.lua
--   CustomShortcuts_Activate/LICENSE.md
--   CustomShortcuts_Activate/README.md

--[[
 * @description CustomShortcuts
 * @version 1.1
 * @author Glenn Burgos
 * @provides
 *   [nomain] CustomShortcuts_core.lua
 *   [nomain] CustomShortcuts_capture.lua
 *   [nomain] CustomShortcuts_Create.lua
 * @about
 *   # CustomShortcuts
 *
 *   A fast, searchable custom-shortcut system that lives outside
 *   REAPER's own keyboard shortcut list -- only one REAPER shortcut is
 *   ever needed, bound to this script.
 *
 *   Activate mode: tap a modifier to search by your own custom shortcut
 *   phrase, or type to search action names (multi-word matching, like
 *   REAPER's own Action List). Enter or double-click runs a result; the
 *   first 10 results are always numbered, and Tab lets you type a digit
 *   to run one without touching the mouse.
 *
 *   Create mode -- the shortcut editor -- is reached via the
 *   "Edit Shortcuts..." button inside Activate mode, so it never needs
 *   its own bound shortcut.
 *
 *   Requires ReaImGui and js_ReaScriptAPI (both installable via
 *   ReaPack).

  CustomShortcuts_Activate.lua

  "Activate mode" -- the default/everyday entry point. Bind a REAPER
  shortcut to THIS action (Actions List > find it > Add). Opening it:
    - snapshots what context REAPER is in (Main vs. an open MIDI editor)
    - shuts down the Create-mode script if it happens to be open
    - opens a small window with a live search, bypassing REAPER's own
      shortcuts for as long as the window has focus
    - typing a lone modifier (tap, release) switches to shortcut-phrase
      search; typing a letter first searches action names, same as
      REAPER's own Action List
    - Enter runs the top result and closes the window; double-click runs
      whichever row you clicked; Escape closes without running anything
    - pressing the same shortcut again closes the window (toggle)

  An "Edit Shortcuts..." button opens Create mode directly -- Create no
  longer needs its own bound REAPER shortcut at all; this button
  auto-registers it as an action the first time it's used. Create
  relaunches this script automatically when it closes, so you land right
  back here ready to run whatever you just assigned.

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

-- Toggle behavior: pressing this action's shortcut again terminates this
-- running instance instead of starting a second one.
reaper.set_action_options(1)

-- Make sure Create mode isn't left open alongside us.
core.ShutDownSiblingIfRunning(core.CREATE_SCRIPT, 0)

-- Snapshot context BEFORE the window steals focus.
local activeSection = core.SnapshotActiveSection()

local data = core.LoadData()

-- BUG FIX: the data file previously only ever got created/updated by
-- Create.lua -- if someone only ever uses Activate (the common case;
-- Create is opened rarely, just to browse/edit), any native REAPER
-- shortcuts added since Create last happened to run were invisible to
-- shortcut-phrase search here. Activate is the guaranteed entry point
-- (bound to the one REAPER shortcut, and also what every Create close
-- path relaunches into), so auto-seeding now runs here too, right at
-- startup, for the two sections Activate actually searches below --
-- keeping the data file current on every normal launch with no
-- dependency on Create ever having been opened. (Media Explorer and MIDI
-- Event List Editor are seeded by Create instead -- see the note there
-- -- since Activate's own SnapshotActiveSection() can never select
-- them, so it'd have nothing to seed there anyway.)
do
  local seededCount = core.AutoSeedSection(data, core.SECTION_MAIN)
  if activeSection ~= core.SECTION_MAIN and core.IsSectionActive(activeSection) then
    seededCount = seededCount + core.AutoSeedSection(data, activeSection)
  end
  if seededCount > 0 then
    local ok, err = core.SaveData(data)
    if not ok then
      reaper.ShowConsoleMsg("CustomShortcuts: failed to auto-save seeded shortcuts: " .. tostring(err) .. "\n")
    end
  end
end

-- Build the name-search action list: current section (if reachable and
-- not Main) plus Main, per the fallback design.
local nameSearchActions = {}
local seenSections = {}
local function addSectionActions(sectionId)
  if seenSections[sectionId] then return end
  seenSections[sectionId] = true
  local list = core.EnumerateSectionActions(sectionId)
  for _, a in ipairs(list) do
    nameSearchActions[#nameSearchActions + 1] = { cmdId = a.cmdId, name = a.name, sectionId = sectionId }
  end
end
if activeSection ~= core.SECTION_MAIN and core.IsSectionActive(activeSection) then
  addSectionActions(activeSection)
end
addSectionActions(core.SECTION_MAIN)

-- Shortcut-search source: same two sections' worth of saved custom
-- shortcuts, section-specific first, Main as fallback. Also builds a
-- reverse index (sectionId -> persistentId -> phrase) so name-search
-- results can show an action's assigned custom shortcut too, not just
-- shortcut-phrase-search results -- previously only the latter showed it.
local shortcutEntries = {}
local shortcutByPersistentId = {}
local function addSectionShortcuts(sectionId)
  local sec = core.EnsureSection(data, sectionId)
  shortcutByPersistentId[sectionId] = shortcutByPersistentId[sectionId] or {}
  for phrase, entry in pairs(sec.shortcuts) do
    shortcutEntries[#shortcutEntries + 1] = {
      phrase = phrase, id = entry.id, name = entry.name, sectionId = sectionId,
    }
    shortcutByPersistentId[sectionId][entry.id] = phrase
  end
end
if activeSection ~= core.SECTION_MAIN and core.IsSectionActive(activeSection) then
  addSectionShortcuts(activeSection)
end
addSectionShortcuts(core.SECTION_MAIN)

-- ---------------------------------------------------------------------

local ctx = ImGui.CreateContext("Custom Shortcuts")
local captureState = capture.NewCaptureState()
local results = {}
local shouldClose = false
local shouldRun = nil -- a result row, set when Enter/double-click fires

-- Tab enters a mode where the first 10 results are numbered 0-9 (row 1
-- shows "0", row 2 shows "1", ... row 10 shows "9") and typing that digit
-- immediately runs the corresponding row -- lets you go from search
-- straight to running an action without reaching for the mouse. Any
-- other key (besides a matching digit, Tab, or Escape) is ignored while
-- this is active rather than silently falling through to normal typing,
-- so it has to be deliberately exited.
local numberSelectMode = false

-- Literal phrase matching, used for shortcut-phrase search -- exact/
-- prefix/substring, in that priority order, so typing the exact stored
-- phrase (modifiers included) scores highest and becomes the sole/top
-- result.
local function scoreMatch(haystack, needle)
  haystack = haystack:lower()
  needle = needle:lower()
  if haystack == needle then return 3 end
  if haystack:find(needle, 1, true) == 1 then return 2 end
  if haystack:find(needle, 1, true) then return 1 end
  return 0
end

local function recomputeResults()
  results = {}

  if captureState.mode == "shortcut" then
    -- FIX: this used to match on captureState.text alone (the typed
    -- word), completely ignoring which modifier(s) were actually
    -- tapped -- so tapping the wrong modifier but typing the right word
    -- would still match. Using the full combined phrase (modifiers +
    -- word) means the tapped modifiers actually have to correspond to
    -- the stored shortcut, and typing the exact phrase then hitting
    -- Enter reliably runs that exact shortcut.
    local needle = core.CombinedPhrase(captureState)
    if needle == "" then return end
    for _, e in ipairs(shortcutEntries) do
      local s = scoreMatch(e.phrase, needle)
      if s > 0 then
        results[#results + 1] = {
          score = s, display = e.name, sub = core.SectionName(e.sectionId) .. "  ·  " .. e.phrase,
          sectionId = e.sectionId, persistentId = e.id,
        }
      end
    end
  elseif captureState.mode == "search" then
    -- REAPER-Action-List-style matching: every space-separated word in
    -- the typed text must appear somewhere in the action name, any
    -- order (e.g. "track show" matches "Track: Show FX chain").
    local needle = captureState.text:lower()
    if needle == "" then return end
    for _, a in ipairs(nameSearchActions) do
      local s = core.ScoreNameMatch(a.name, needle)
      if s > 0 then
        -- Show the action's assigned custom shortcut here too, if it
        -- has one -- previously only shortcut-phrase-search results
        -- showed this, so a name search never revealed an existing
        -- assignment.
        local sub = core.SectionName(a.sectionId)
        local byId = shortcutByPersistentId[a.sectionId]
        if byId then
          local persistentId = core.GetPersistentId(a.cmdId)
          local assignedPhrase = byId[persistentId]
          if assignedPhrase then
            sub = sub .. "  ·  " .. assignedPhrase
          end
        end
        results[#results + 1] = {
          score = s, display = a.name, sub = sub,
          sectionId = a.sectionId, cmdId = a.cmdId,
        }
      end
    end
  end

  table.sort(results, function(x, y)
    if x.score ~= y.score then return x.score > y.score end
    return x.display < y.display
  end)

  -- Cap so we're not rendering thousands of rows for a broad match.
  while #results > 50 do table.remove(results) end
end

local function runResult(r)
  if not r then return end
  local runtimeId = r.cmdId
  if not runtimeId and r.persistentId then
    runtimeId = core.ResolveRuntimeId(r.persistentId)
    if not runtimeId then
      reaper.ShowMessageBox(
        "Couldn't resolve this action anymore (it may have been uninstalled/renamed): " .. tostring(r.display),
        "Custom Shortcuts", 0)
      return
    end
  end

  local ok = core.RunAction(r.sectionId, runtimeId)
  if ok then
    shouldClose = true
  else
    -- Dispatch failed (e.g. a MIDI Editor / Media Explorer action whose
    -- target window isn't open right now) -- leave the window open
    -- rather than closing as if it worked.
    reaper.ShowConsoleMsg("CustomShortcuts: couldn't run '" .. tostring(r.display) ..
      "' -- its target window may not be open.\n")
  end
end

-- Returns true if the caller should keep deferring (i.e. keep running).
local function frame()
  -- Wider/taller default than before, for the same reason as Create's
  -- window -- action names and the section/shortcut column were getting
  -- truncated. Cond_FirstUseEver means this only applies the very first
  -- time the window is created; a manual resize is remembered after that.
  ImGui.SetNextWindowSize(ctx, 640, 440, ImGui.Cond_FirstUseEver)
  local visible, open = ImGui.Begin(ctx, "Custom Shortcuts##Activate", true)

  if visible then
    if captureState.mode == "shortcut" then
      ImGui.TextColored(ctx, 0x77CCFFFF, (captureState.heldModifierAtTap or "") .. " + " .. captureState.text)
      ImGui.SameLine(ctx)
      ImGui.TextDisabled(ctx, "(searching shortcuts, " .. (18 - #captureState.text) .. " left)")
    elseif captureState.mode == "search" then
      ImGui.Text(ctx, captureState.text)
      ImGui.SameLine(ctx)
      ImGui.TextDisabled(ctx, "(searching action names)")
    else
      ImGui.TextDisabled(ctx, "Tap a modifier for a shortcut, or start typing to search by name...")
    end

    -- Buttons live on their OWN row, never sharing a line with the
    -- variable-length status text above -- sharing a line was exactly
    -- what caused Clear to land on top of Edit Shortcuts: a long
    -- placeholder pushed Clear far enough right to collide with Edit
    -- Shortcuts' fixed position. With nothing variable-length on this
    -- row, plain SameLine is enough; no need for width-based anchoring.
    -- Regular Button (not SmallButton) so it matches Edit Shortcuts'
    -- height -- SmallButton uses tighter padding, which made the two
    -- look mismatched side by side.
    if ImGui.Button(ctx, "Clear##activateclear") then
      capture.Reset(captureState)
      recomputeResults()
      numberSelectMode = false
    end
    ImGui.SameLine(ctx)
    -- Launches Create directly; no REAPER-level shortcut needed for it
    -- anymore, since GetSiblingCommandId auto-registers it as an action
    -- on first use if it isn't already. Closes this window on click, and
    -- Create's own closing paths relaunch Activate automatically, so
    -- there's no separate shortcut to remember for either direction.
    if ImGui.Button(ctx, "Edit Shortcuts...") then
      local createCmdId = core.GetSiblingCommandId(core.CREATE_SCRIPT, 0)
      if createCmdId and createCmdId ~= 0 then
        reaper.Main_OnCommand(createCmdId, 0)
      end
      shouldClose = true
    end

    -- Same row either way, so the layout doesn't shift when toggling:
    -- before Tab is pressed, hint that it's available; after, explain
    -- how to use it.
    if numberSelectMode then
      ImGui.TextColored(ctx, 0x77CCFFFF, "Press 0-9 to run a numbered result (Tab or Escape to cancel)")
    elseif #results > 0 then
      ImGui.TextDisabled(ctx, "Press Tab to select a numbered result")
    end

    ImGui.Separator(ctx)

    if ImGui.BeginTable(ctx, "results", 3, ImGui.TableFlags_RowBg | ImGui.TableFlags_BordersInnerH) then
      ImGui.TableSetupColumn(ctx, "#", ImGui.TableColumnFlags_WidthFixed, 24)
      ImGui.TableSetupColumn(ctx, "Action", ImGui.TableColumnFlags_WidthStretch)
      ImGui.TableSetupColumn(ctx, "Section / Shortcut", ImGui.TableColumnFlags_WidthFixed, 160)
      for i, r in ipairs(results) do
        ImGui.TableNextRow(ctx)

        -- Only the first 10 results get a number (row 1 = "0", ...
        -- row 10 = "9") -- matches the digit that runs it in
        -- numberSelectMode.
        ImGui.TableNextColumn(ctx)
        if i <= 10 then
          local label = tostring(i - 1)
          if numberSelectMode then ImGui.TextColored(ctx, 0xFFD966FF, label)
          else ImGui.TextDisabled(ctx, label) end
        end

        ImGui.TableNextColumn(ctx)

        -- Full-row hit target: an invisible Selectable spanning all
        -- columns, drawn first, so any part of the row can be hovered/
        -- double-clicked -- not just whatever the last-drawn text widget
        -- happened to be.
        ImGui.Selectable(ctx, "##row" .. i, false,
          ImGui.SelectableFlags_SpanAllColumns | ImGui.SelectableFlags_AllowDoubleClick)
        if ImGui.IsItemHovered(ctx) and ImGui.IsMouseDoubleClicked(ctx, ImGui.MouseButton_Left) then
          shouldRun = r
        end
        ImGui.SameLine(ctx)

        local isTop = (i == 1)
        if isTop then ImGui.TextColored(ctx, 0xFFD966FF, r.display) else ImGui.Text(ctx, r.display) end
        ImGui.TableNextColumn(ctx)
        ImGui.TextDisabled(ctx, r.sub)
      end
      ImGui.EndTable(ctx)
    end
  end

  -- Must be queried BEFORE End(), while this window is still "current" on
  -- the ImGui window stack.
  local focused = ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_RootAndChildWindows)

  -- Must always be called, regardless of `visible` -- only the CONTENT
  -- above is meant to be conditional on it.
  ImGui.End(ctx)

  capture.SetFocused(focused)

  if focused then
    local keys = capture.PollKeys()

    if numberSelectMode then
      -- Digits are normally part of TEXT_VKEYS and would otherwise flow
      -- into capture.Update() as search text -- deliberately NOT calling
      -- that here, so a digit press in this mode selects a row instead
      -- of typing.
      local ranSomething = false
      for digit = 0, 9 do
        local vk = 0x30 + digit -- '0'..'9'
        if keys.pressed[vk] then
          if results[digit + 1] then
            shouldRun = results[digit + 1]
          end
          numberSelectMode = false
          ranSomething = true
          break
        end
      end
      if not ranSomething then
        if keys.pressed[capture.VK_ESCAPE] or keys.pressed[capture.VK_TAB] then
          numberSelectMode = false
        end
        -- Any other key is ignored while active -- exit via Escape/Tab
        -- (or a matching digit) rather than falling through to typing.
      end
    else
      local changed = capture.Update(captureState, keys)
      if changed then recomputeResults() end

      if keys.pressed[capture.VK_RETURN] then
        shouldRun = results[1]
      elseif keys.pressed[capture.VK_ESCAPE] then
        shouldClose = true
      elseif keys.pressed[capture.VK_DELETE] then
        -- Same as clicking Clear.
        capture.Reset(captureState)
        recomputeResults()
      elseif keys.pressed[capture.VK_TAB] and #results > 0 then
        numberSelectMode = true
      end
    end
  end

  if shouldRun then
    runResult(shouldRun)
    shouldRun = nil
  end

  return open and not shouldClose
end

local function loop()
  local ok, keepGoing = pcall(frame)
  if not ok then
    reaper.ShowConsoleMsg("CustomShortcuts Activate error: " .. tostring(keepGoing) .. "\n")
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
