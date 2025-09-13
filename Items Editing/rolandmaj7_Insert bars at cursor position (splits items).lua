-- @description Insert bars at cursor position (splits items)
-- @author RolandMaj7
-- @version 1.0
-- @changelog Added 'selected tracks' scope to control item split condition. Code cleanup for production.
-- @provides . > RolandMaj7_Insert_bars_at_cursor_position
-- @about
--   # Insert Empty Bars at Cursor (Sibelius-style)
--
--   ## Purpose
--   This script simulates how **Avid Sibelius** inserts bars into a score:  
--   everything after the edit cursor is shifted forward by whole bars, and bar numbering is preserved.  
--   Unlike quarter-note math approaches, this script is **bar index–based**, so it works correctly in any local time signature.
--
--   ## What the script does
--   - Prompts the user for **barCount** (integer ≥ 1).
--   - Splits items on **selected tracks** at the edit cursor (so only the right halves move).
--   - Moves everything at or after the cursor forward by `barCount` bars:
--     - **Tempo/Time-Signature markers** are shifted by measure index, preserving BPM, TS, and linear flags.
--     - **Project markers and regions** are shifted; regions spanning the cursor grow by the inserted bars.
--     - **Items on selected tracks** are repositioned by bar index, preserving their musical alignment.
--   - Preserves all musical data: time signatures, marker options, item lengths, and stretch markers.
--
--   ## Why this is needed
--   - In REAPER, “Insert empty space” works in absolute time/beats, not in **musical bars**.
--   - In notation programs like Sibelius, “Insert Bars” respects the local meter so that bar numbers advance consistently.
--   - This script bridges that gap: it ensures that if you are on bar **91** and insert **1 bar**, the next downbeat is **92.1.00**, no matter whether the section is in 4/4, 3/4, 6/8, or a partial measure.
--
--   ## Usage
--   1. Place the **edit cursor** at the exact bar position where the new bars should be inserted.  
--      The cursor’s bar index becomes the anchor: inserted bars start *at that bar*, and everything after shifts forward.
--   2. Select the **tracks/items** you want affected (only items on selected tracks will move).
--   3. Run the script and enter the number of bars to insert.
--   4. The cursor bar is preserved; all later bars are renumbered by the inserted amount.
--
--   ## Notes
--   - Items are always **split at the cursor** first; left portions remain fixed, right portions move.
--   - Project markers/regions at or after the cursor are shifted by bar index; spanning regions grow.
--   - Undo is supported: the whole operation is wrapped in a single undo point.
--   - To affect all tracks, select them all before running.

-- RolandMaj7_Insert_Bars_At_Cursor_Position_By_Measure.lua
-- REAPER v7.45+
-- Inserts N empty bars at the edit cursor, using MEASURE/BEAT remapping
-- (not QN math) so the next bar number becomes current_bar+N regardless
-- of local time signatures or partial measures.
--
-- Behavior
--   • Prompts for barCount (integer ≥ 1)
--   • Splits items on SELECTED TRACKS at the cursor (only right halves move)
--   • Moves:
--       - Tempo/TS markers at/after cursor by +barCount measures
--       - Project markers/regions at/after cursor by +barCount measures
--         * Regions spanning the cursor: end moves, start stays → region length grows
--       - Items on SELECTED TRACKS with start ≥ cursor by +barCount measures
--   • Preserves: BPM, TS (num/den), linear flag, marker names/colors, item lengths
--   • One undo point, clear summary

local r = reaper
local EPS = 1e-9
local function log(s) r.ShowConsoleMsg(tostring(s).."\n") end

-- ---- Input ----
local ok, sval = r.GetUserInputs("Insert empty bars at cursor", 1, "Number of bars (integer ≥ 1)", "1")
if not ok then return end
local barCount = tonumber(sval or "")
if not barCount or barCount < 1 or math.floor(barCount) ~= barCount then
  r.MB("Please enter an integer ≥ 1.","Invalid input",0); return
end

-- ---- Helpers (measure/beat mapping) ----
-- Time -> (measures, beat_in_measure, cml, cdenom)
local function time_to_measbeat(t)
  local beat_in_measure, measures, cml, fullbeats, cdenom = r.TimeMap2_timeToBeats(0, t)
  return measures, beat_in_measure, cml, cdenom
end

-- (measures, beat_in_measure) -> time
local function measbeat_to_time(measures, beat_in_measure)
  return r.TimeMap2_beatsToTime(0, beat_in_measure, measures)
end

local function get_cursor() return r.GetCursorPosition() end

-- ---- Capture + shift: Tempo/TS markers ----
local function capture_tempo_from(t0)
  local list = {}
  local n = r.CountTempoTimeSigMarkers(0)
  for i=0, n-1 do
    local ok, t, meas, beat, bpm, tsn, tsd, linear = r.GetTempoTimeSigMarker(0, i)
    if ok and t >= t0 - EPS then
      -- Derive precise measure/beat at *current* t via TimeMap2 (robust to partial measures)
      local M, B = time_to_measbeat(t)
      list[#list+1] = {
        idx=i, t=t, M=M, B=B,
        bpm=bpm, tsn=tsn, tsd=tsd, linear=linear
      }
    end
  end
  return list
end

local function shift_tempo_markers_by_measures(captured, deltaMeasures)
  if #captured == 0 then return 0 end
  -- Delete affected markers first (from end) to avoid reindex issues
  local toDel = {}
  for _, m in ipairs(captured) do toDel[m.idx] = true end
  for i = r.CountTempoTimeSigMarkers(0)-1, 0, -1 do
    if toDel[i] then r.DeleteTempoTimeSigMarker(0, i) end
  end
  -- Re-add using MEASURE/BEAT addressing so partial-measure semantics are preserved
  local added = 0
  for _, m in ipairs(captured) do
    local newM = m.M + deltaMeasures
    -- Place by measure/beat (timepos = -1; measurepos/newM, beatpos/m.B)
    local ok = r.SetTempoTimeSigMarker(0, -1, -1, newM, m.B, m.bpm, m.tsn, m.tsd, m.linear or 0)
    if ok then added = added + 1 end
  end
  return added
end

-- ---- Capture + shift: Project markers/regions ----
local function capture_proj_markers_regions(t0)
  local starts, ends = {}, {}
  local nm, nr = r.CountProjectMarkers(0)
  for i=0, nm+nr-1 do
    local ok, isrgn, pos, rgnend, name, idx, color = r.EnumProjectMarkers3(0, i)
    if ok then
      if pos >= t0 - EPS then
        local M, B = time_to_measbeat(pos)
        starts[#starts+1] = { idx=idx, isrgn=isrgn, M=M, B=B, name=name, color=color }
      end
      if isrgn and rgnend >= t0 - EPS then
        local Me, Be = time_to_measbeat(rgnend)
        ends[#ends+1] = { idx=idx, Me=Me, Be=Be }
      end
    end
  end
  return starts, ends
end

local function apply_proj_marker_region_shifts(starts, ends, deltaMeasures)
  local movedS, movedE = 0, 0
  -- Move starts
  for _, s in ipairs(starts) do
    local newStart = measbeat_to_time(s.M + deltaMeasures, s.B)
    local ok
    if s.isrgn then
      local _, _, _, rgnend = r.EnumProjectMarkers3(0, s.idx)
      ok = r.SetProjectMarker3(0, s.idx, true, newStart, rgnend, s.name or "", s.color or 0)
    else
      ok = r.SetProjectMarker3(0, s.idx, false, newStart, 0, s.name or "", s.color or 0)
    end
    if ok then movedS = movedS + 1 end
  end
  -- Move region ends (so regions spanning the cursor grow by the insert)
  for _, e in ipairs(ends) do
    local curOK, _, pos, _, name, idx, color = r.EnumProjectMarkers3(0, e.idx)
    local newEnd = measbeat_to_time(e.Me + deltaMeasures, e.Be)
    local ok = r.SetProjectMarker3(0, e.idx, true, pos, newEnd, name or "", color or 0)
    if ok then movedE = movedE + 1 end
  end
  return movedS, movedE
end

-- ---- Items on selected tracks ----
local function split_selected_track_items_at_cursor()
  -- 40012: Item: Split items at edit cursor
  r.Main_OnCommand(40012, 0)
end

local function capture_items_on_selected_tracks_from(t0)
  local cap = {}
  local trc = r.CountSelectedTracks(0)
  for ti=0, trc-1 do
    local tr = r.GetSelectedTrack(0, ti)
    if tr then
      local n = r.CountTrackMediaItems(tr)
      for i=0, n-1 do
        local it = r.GetTrackMediaItem(tr, i)
        if it then
          local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
          if pos >= t0 - EPS then
            local M, B = time_to_measbeat(pos)
            cap[#cap+1] = { it=it, M=M, B=B }
          end
        end
      end
    end
  end
  return cap
end

local function move_items_by_measures(cap, deltaMeasures)
  local moved = 0
  for _, c in ipairs(cap) do
    if r.ValidatePtr2(0, c.it, "MediaItem*") then
      local newPos = measbeat_to_time(c.M + deltaMeasures, c.B)
      r.SetMediaItemInfo_Value(c.it, "D_POSITION", newPos)
      moved = moved + 1
    end
  end
  return moved
end

-- ---- MAIN ----
r.Undo_BeginBlock2(0)
r.PreventUIRefresh(1)
-- r.ClearConsole()

local tCursor = get_cursor()

-- 1) Split selected-track items at cursor
split_selected_track_items_at_cursor()

-- 2) Snapshot affected things under the *current* map
local tempoCap   = capture_tempo_from(tCursor)
local pmStarts, pmEnds = capture_proj_markers_regions(tCursor)
local itemsCap   = capture_items_on_selected_tracks_from(tCursor)

-- 3) Apply shifts by +barCount MEASURES
local tempoMoved = shift_tempo_markers_by_measures(tempoCap, barCount)
local markMovedS, markMovedE = apply_proj_marker_region_shifts(pmStarts, pmEnds, barCount)
local itemsMoved = move_items_by_measures(itemsCap, barCount)

r.UpdateArrange()
r.UpdateTimeline()
r.PreventUIRefresh(-1)
r.Undo_EndBlock2(0, string.format("Insert %d bar(s) at cursor (by measure)", barCount), -1)

-- ---- Summary ----
r.ShowConsoleMsg("")
log("=== Insert Empty Bars (Measure-accurate) ===")
do
  local Mcur, Bcur = time_to_measbeat(tCursor)
  log(string.format("Cursor: time=%.6f  | measure=%d  | beat-in-measure=%.6f", tCursor, Mcur, Bcur))
end
log(string.format("Bars inserted: %d  (everything at/after cursor moved by +%d measures)", barCount, barCount))
log(string.format("Tempo/TS markers moved: %d", tempoMoved))
log(string.format("Project markers moved (starts): %d, (region ends): %d", markMovedS, markMovedE))
log(string.format("Items moved (selected tracks): %d", itemsMoved))
log("Note: Items were split at the cursor; left parts stayed. BPM/TS/linear flags preserved.")
log("===========================================")

