-- @description Set unity tempo from tempo map (Pro Tools Conductor off)
-- @author RolandMaj7
-- @version 1.0
-- @changelog Went through practical testing. Added user information and logging. Code cleanup for production.
-- @about
--   # Set Unity Tempo from Tempo Map (Pro Tools "Conductor Off")
--
--   ## Purpose
--   This script simulates the **Pro Tools “Conductor Off”** behavior inside REAPER.
--
--   In REAPER, tempo is always governed by **tempo/time signature markers (T/TS markers)**.  
--   When multiple markers have their **“Set tempo”** flag enabled, REAPER treats each one as an independent local tempo.  
--   This prevents the user from adjusting tempo globally, since changes only affect the section between two markers.
--
--   The script provides a way to collapse the tempo map into a **unity tempo** state, while still preserving
--   time signature changes, metronome patterning, and marker positions.
--
--   ## What the script does
--   - Ensures selected items (or whole project if no selection) are prepared to stretch correctly:
--     - Project or item **timebase** is set to *Beats (position, length, rate)* as needed.
--     - Stretch markers are added at tempo change points to keep audio in sync.
--   - Defines the **scope**:
--     - If there is a time selection → scope is the selected range.
--     - Otherwise → scope is the entire project.
--   - Establishes a **master marker** at the start of the scope:
--     - If a marker already exists there, it is forced to carry tempo.
--     - If not, a new one is inserted using the effective tempo and time signature at that position.
--   - All subsequent T/TS markers within the scope have **“Set tempo” disabled** (BPM cleared),
--     so they follow the master marker’s tempo while still contributing signatures and other options.
--
--   ## Why this is needed
--   - By default in REAPER, the **very first tempo marker** (at bar 0) defines the project’s “unity tempo”.
--   - The tempo displayed in the toolbar is **“tempo at edit cursor”**, not a true global tempo.  
--     As soon as you place multiple tempo markers, adjusting tempo globally becomes impossible.
--   - This script mimics the DAW workflows where you can switch off tempo mapping (Pro Tools “Conductor Off”),
--     straighten items, and then freely adjust the **one global tempo**.
--
--   ## Usage
--   1. Perform your **manual tempo mapping** with T/TS markers as usual. (By adding and fine tuning markers)
--   2. Select the **item(s)** you want straightened (or nothing for whole project scope).
--   3. (Optional) Create a **time selection** if you want to restrict changes to a section only, it will take the first marker in selection as a basis, you might want to create it for better result.
--   4. Run the script:
--      - Items are marked and prepared for stretching.
--      - The first marker in scope becomes the master tempo.
--      - All later markers in scope turn into **TS-only markers**.
--   5. Now you can:
--      - Adjust tempo **globally** by changing the master tempo marker.
--      - Still insert local tempo variations later by re-enabling “Set tempo” on specific markers.
--
--   ## Notes
--   - REAPER’s design: there is **always** a tempo marker at bar 0; this script leverages that fact.
--   - If no time selection is active, scope = entire project.
--   - You can revert or try different scopes via **Undo**.
--   - To restore local tempo variations, manually re-enable **“Set tempo”** on the relevant markers.

-- RolandMaj7_Set_Unity_Tempo_From_Tempo_Map_(Pro_Tools_Conductor_Off).lua
-- REAPER v7.45+
-- What this script does (high-level):
--   • Timebase policy (non-intrusive):
--       - If NO items are selected → set Project timebase = Beats (position, length, rate).
--       - If items ARE selected   → set ONLY those items' timebase = Beats (position, length, rate).
--   • Stretch preparedness:
--       - If items are selected → run Action 42377 ("Media item: Add stretch markers at project tempo changes")
--         so selected audio items will stretch when tempo follows a master marker.
--   • Scope determination:
--       - If a Time Selection exists → scope is that time range.
--       - Else → scope is the entire project.
--   • Master marker & following behavior:
--       - Ensure there is a BPM-carrying "master" tempo marker at the start of scope.
--         (Insert one if missing, using the effective tempo & time signature at that time.)
--       - For all later tempo markers **within scope**, turn OFF "Set tempo" (BPM = -1),
--         preserving their position, time-signature, and linear/gradual flag, so they
--         **follow the master** while still providing meter/metronome patterning.
--   • Summary:
--       - Prints a precise summary of what changed.

local r = reaper
local EPS = 1e-9

------------------------------------------------------------
-- Console guide + Continue/Cancel prompt
------------------------------------------------------------
local function log(s) r.ShowConsoleMsg(tostring(s).."\n") end

local function show_guide_and_confirm()
  r.ClearConsole()
  log("======================================================================================")
  log(" Tempo Master/Follow Utility — Scope, Policy, and Actions (Pro Tools 'Conductor off') ")
  log("======================================================================================")
  log("")
  log("WHAT THIS SCRIPT WILL DO")
  log("  1) TIMEBASE POLICY (non-intrusive):")
  log("     • If NO items are selected → Project timebase = Beats (position, length, rate).")
  log("       This ensures bars, tempo/TS markers, and project markers stay aligned when tempo behavior changes.")
  log("     • If items ARE selected   → ONLY those selected items get timebase = Beats (position, length, rate).")
  log("       This protects your global project setting and focuses changes on what you selected.")
  log("")
  log("  2) STRETCH PREPARATION (Selected Items only):")
  log("     • Runs Action 42377: \"Media item: Add stretch markers at project tempo changes\"")
  log("       so selected audio items will actually conform when the tempo follows the master.")
  log("")
  log("  3) SCOPE (WHERE CHANGES APPLY):")
  log("     • If a Time Selection exists → the scope is that time range.")
  log("     • Else → the scope is the entire project.")
  log("")
  log("  4) MASTER/FOLLOW BEHAVIOR:")
  log("     • Ensures a BPM-carrying \"master\" tempo marker at the START of scope.")
  log("       - If no marker is exactly at scope start, one is inserted using the effective tempo & TS at that time.")
  log("     • For every later tempo/TS marker INSIDE scope, turns OFF \"Set tempo\" (BPM = -1),")
  log("       while preserving its position, time-signature, and 'gradually transition' flag.")
  log("       These markers then FOLLOW the master tempo but keep their meter/metronome patterns.")
  log("")
  log("WHAT THIS SCRIPT WILL NOT DO")
  log("  • It does NOT delete tempo markers.")
  log("  • It does NOT change marker positions or your time signatures.")
  log("  • It does NOT change transport BPM directly; behavior is governed by master tempo markers.")
  log("")
  log("USAGE TIPS")
  log("  • For whole-project behavior: no time selection needed.")
  log("  • For a section-only workflow: make a time selection first, then run the script.")
  log("  • If you want audio items to stretch: select those items before running (so 42377 can be applied).")
  log("")
  log("SAFETY")
  log("  • An Undo point wraps the entire operation; cancel or undo if needed (Ctrl/Cmd+Z).")
  log("")
  log("Click OK to continue, or Cancel to abort without changes.")
  log("=========================================================")

  local btn = r.MB("Proceed with the actions described in the Console guide?\n\nOK = Continue\nCancel = Abort (no changes)", "Tempo Master/Follow — Confirm", 1) -- 1 = OK/Cancel
  -- Return true if OK (1), false otherwise (2 = Cancel)
  return (btn == 1)
end

------------------------------------------------------------
-- Timebase helpers
-- Project "TIMEBASEMODE": 0=Time, 1=Beats(pos only), 2=Beats(pos,len,rate)
-- Item "I_TIMEBASE":      0=Time, 1=Beats(pos only), 2=Beats(pos,len,rate), -1=project default
------------------------------------------------------------
local function apply_timebase_policy()
  local summary = { mode = "", project_prev = nil, project_new = nil, items_changed = 0, items_total = 0 }
  local sel_cnt = r.CountSelectedMediaItems(0)

  if sel_cnt == 0 then
    local prev = r.GetSetProjectInfo(0, "TIMEBASEMODE", 0, false)
    if prev ~= 2 then
      r.GetSetProjectInfo(0, "TIMEBASEMODE", 2, true)
      summary.project_prev = prev
      summary.project_new  = 2
    else
      summary.project_prev = 2
      summary.project_new  = 2
    end
    summary.mode = "project"
  else
    summary.mode = "items"
    summary.items_total = sel_cnt
    for i=0, sel_cnt-1 do
      local it = r.GetSelectedMediaItem(0, i)
      if it then
        local prev = r.GetMediaItemInfo_Value(it, "I_TIMEBASE")
        if prev ~= 2 then
          r.SetMediaItemInfo_Value(it, "I_TIMEBASE", 2)
          summary.items_changed = summary.items_changed + 1
        end
      end
    end
  end

  return summary
end

------------------------------------------------------------
-- Scope helpers (time selection or whole project)
------------------------------------------------------------
local function get_scope_times()
  -- GetSet_LoopTimeRange2 returns startOut, endOut, isSetOut (with isSetOut meaning "time selection exists")
  local ts_start, ts_end, isSet = r.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  if isSet and ts_start and ts_end and (ts_end - ts_start) > EPS then
    return ts_start, ts_end, true
  end
  return 0.0, math.huge, false
end

------------------------------------------------------------
-- Tempo/TS helpers
------------------------------------------------------------
local function count_tempo() return r.CountTempoTimeSigMarkers(0) end

local function get_marker(i)
  local ok, t, meas, beat, bpm, tsn, tsd, linear = r.GetTempoTimeSigMarker(0, i)
  if not ok then return nil end
  return { idx=i, t=t, meas=meas, beat=beat, bpm=bpm, tsn=tsn, tsd=tsd, linear=linear }
end

local function find_marker_exact_at(tpos, tol)
  tol = tol or 1e-6
  local cnt = count_tempo()
  for i=0, cnt-1 do
    local m = get_marker(i)
    if not m then break end
    if math.abs(m.t - tpos) <= tol then return m end
  end
  return nil
end

local function find_last_marker_at_or_before(tpos)
  local cnt = count_tempo()
  local last = nil
  for i=0, cnt-1 do
    local m = get_marker(i)
    if not m then break end
    if m.t <= tpos + EPS then last = m else break end
  end
  return last
end

local function effective_tempo_and_ts_at(t)
  local qn_bpm = r.TimeMap_GetDividedBpmAtTime(t)  -- effective quarter-note BPM at time t
  local tsn, tsd = r.TimeMap_GetTimeSigAtTime(0, t)
  return qn_bpm, tsn, tsd
end

local function ensure_master_at(start_t)
  -- Ensure there is a BPM-carrying marker exactly at start_t.
  local m = find_marker_exact_at(start_t)
  if m then
    if not m.bpm or m.bpm <= 0 then
      local bpm, tsn, tsd = effective_tempo_and_ts_at(start_t)
      r.SetTempoTimeSigMarker(0, m.idx, m.t, m.meas, m.beat, bpm, tsn, tsd, m.linear or 0)
      m.bpm = bpm
    end
    return m, "existing"
  end

  -- No exact marker → insert one at start_t using effective tempo & TS (prevents jumps)
  local bpm, tsn, tsd = effective_tempo_and_ts_at(start_t)
  local ok = r.SetTempoTimeSigMarker(0, -1, start_t, -1, -1, bpm, tsn, tsd, 0)
  if ok then
    local ins = find_marker_exact_at(start_t)
    return ins, "inserted"
  end

  -- Fallback: promote the last-before to be the master (edge cases)
  local last = find_last_marker_at_or_before(start_t)
  if last and (not last.bpm or last.bpm <= 0) then
    local lbpm, ltsn, ltsd = effective_tempo_and_ts_at(last.t)
    r.SetTempoTimeSigMarker(0, last.idx, last.t, last.meas, last.beat, lbpm, ltsn, ltsd, last.linear or 0)
    last.bpm = lbpm
    return last, "promoted_previous"
  end

  return last, "fallback_previous"
end

local function unset_tempo_between(start_t, end_t)
  local changed = 0
  local cnt = count_tempo()
  for i=0, cnt-1 do
    local m = get_marker(i)
    if not m then break end
    if m.t > start_t + EPS and m.t <= end_t + EPS then
      if m.bpm and m.bpm > 0 then
        local ok = r.SetTempoTimeSigMarker(0, i, m.t, m.meas, m.beat, -1, m.tsn, m.tsd, m.linear or 0)
        if ok then changed = changed + 1 end
      end
    end
  end
  return changed
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------
if not show_guide_and_confirm() then
  -- User canceled: exit cleanly with no changes
  return
end

r.Undo_BeginBlock2(0)
r.PreventUIRefresh(1)

-- Step 0: Apply timebase policy
local tb = apply_timebase_policy()

-- Step 1: If items selected, add stretch markers at tempo changes (42377)
local sel_items = r.CountSelectedMediaItems(0)
if sel_items > 0 then
  r.Main_OnCommand(42377, 0)
end

-- Step 2: Determine scope
local scope_start, scope_end, hasTS = get_scope_times()

-- Step 3: Ensure master at scope start
local master, master_mode = ensure_master_at(scope_start)

-- Step 4: Unset 'Set tempo' (BPM=-1) for subsequent markers inside scope
local unset_count = unset_tempo_between(scope_start, scope_end)

r.UpdateArrange()
r.UpdateTimeline()
r.PreventUIRefresh(-1)
r.Undo_EndBlock2(0, "Timebase policy + SM + master + unset tempo in scope", -1)

------------------------------------------------------------
-- Summary (printed to console)
------------------------------------------------------------
r.ShowConsoleMsg("\n")
log("=========================================================")
log(" Summary — Tempo Master/Follow Utility ")
log("=========================================================")
if tb.mode == "project" then
  log(("Timebase: Project set to Beats (pos,len,rate). (prev=%d → new=%d)")
      :format(tb.project_prev or -1, tb.project_new or -1))
else
  log(("Timebase: %d selected item(s) processed; %d item(s) set to Beats (pos,len,rate).")
      :format(tb.items_total, tb.items_changed))
end

if sel_items > 0 then
  log(("Stretch markers: Action 42377 executed on %d selected item(s)."):format(sel_items))
else
  log("Stretch markers: No items selected → 42377 not executed.")
end

if hasTS then
  log(("Scope: Time Selection [%.6f .. %.6f]"):format(scope_start, scope_end))
else
  log("Scope: Entire project")
end

if master then
  log(("Master marker: t=%.6f | BPM=%s | TS=%d/%d | mode=%s")
      :format(master.t, (master.bpm and master.bpm>0) and string.format("%.3f", master.bpm) or "-", master.tsn or 0, master.tsd or 0, master_mode))
else
  log("Master marker: not found (used previous or none existed)")
end

log(("Unset 'Set tempo' inside scope (after master): %d"):format(unset_count))
log("Note: Positions, TS, and linear/gradual flags were preserved for all markers.")
log("=========================================================")

