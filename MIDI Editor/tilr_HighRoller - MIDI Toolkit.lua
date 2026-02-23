-- @description HighRoller - MIDI Toolkit
-- @author tilr
-- @version 1.0.0
-- @provides
--   [main=main,midi_editor,midi_inlineeditor] .
--   [main=midi_editor,midi_inlineeditor] tilr_HighRoller - MIDI Toolkit/tilr_HighRoller - FlipH.lua
--   [main=midi_editor,midi_inlineeditor] tilr_HighRoller - MIDI Toolkit/tilr_HighRoller - FlipV.lua
--   [main=midi_editor,midi_inlineeditor] tilr_HighRoller - MIDI Toolkit/tilr_HighRoller - Glue.lua
--   [main=midi_editor,midi_inlineeditor] tilr_HighRoller - MIDI Toolkit/tilr_HighRoller - Gluex2.lua
--   [main=midi_editor,midi_inlineeditor] tilr_HighRoller - MIDI Toolkit/tilr_HighRoller - Split.lua
--   [main=midi_editor,midi_inlineeditor] tilr_HighRoller - MIDI Toolkit/tilr_HighRoller - Splitx2.lua
--   [main=midi_editor,midi_inlineeditor] tilr_HighRoller - MIDI Toolkit/tilr_HighRoller - RotateL.lua
--   [main=midi_editor,midi_inlineeditor] tilr_HighRoller - MIDI Toolkit/tilr_HighRoller - RotateR.lua
-- @about
--   # HighRoller - Midi Toolkit
--
--   A set of tools to manipulate midi notes.
--   Useful to create snare or hat rolls for risers or trap beats or manipulate midi in general.
--
--   Comes with scripts to execute the MIDI tools using shortcuts, also works in the inline MIDI editor.
--
--   Requires ReaImGui installed.
--
--   #### Tools:
--
--   * Flip Horizontal - flips selected notes horizontally
--   * Flip Vertical - flips selected notes vertically
--   * Rotate Left - Rotates selected notes left by grid division
--   * Rotate Right - Rotates selected notes right by grid division
--   * Split - Adds a subdivision to notes and spaces splits equally
--   * Glue - Removes a subdivision from consecutive notes
--   * Split x2 - Adds two subdivisions to each note
--   * Glue :2 - Removes two subdivisions from consecutive notes
--   * Gate - Increase or decrease notes length proportionally to their original length
--   * Gate Ramp - Progressively increment or decrement notes length
--   * Warp - Bend notes start time towards the first or last note
--   * Vel Ramp - Progressively increment or decrement notes velocity

local function log(t)
  reaper.ShowConsoleMsg(t .. '\n')
end
local function logtable(table, indent)
  log(tostring(table))
  for index, value in pairs(table) do -- print table
    log('    ' .. tostring(index) .. ' : ' .. tostring(value))
  end
end

local function GetPianoRollTake()
  local editor = reaper.MIDIEditor_GetActive()
  if editor then
    local take = reaper.MIDIEditor_GetTake(editor)
    if take and reaper.TakeIsMIDI(take) then
      return take
    end
  end
  local item = reaper.GetSelectedMediaItem(0, 0)
  if item then
    local take = reaper.GetActiveTake(item)
    if take and reaper.TakeIsMIDI(take) then
      return take
    end
  end
  return nil
end

function GetMidiGridPPQ(take)
    local time = reaper.GetCursorPosition()
    local gridQN = reaper.MIDI_GetGrid(take)
    local qn = reaper.TimeMap2_timeToQN(0, time)
    local ppq1 = reaper.MIDI_GetPPQPosFromProjQN(take, qn)
    local ppq2 = reaper.MIDI_GetPPQPosFromProjQN(take, qn + gridQN)
    return ppq2 - ppq1
end

local function Hash(str)
  local hash = 2166136261
  for i = 1, #str do
    hash = hash ~ string.byte(str, i)
    hash = (hash * 16777619) & 0xffffffff
  end
  return hash   -- return NUMBER, not hex string
end

-- current MIDI selected notes + hash
local selnotes = {}
local selnotescount = 0
local selnoteshash = 0

-- modifications using sliders are applied to the original notes
-- keep track of the original notes before modifications
local backupnotes = {}
local backupnoteshash = 0

-- variables for slider modifications
local sliderGate = 0
local sliderGateInc = 0
local checkGateInv = false
local sliderGateTen = 0
local sliderWarp = 0
local sliderVelInc = 0
local sliderVelTen = 0
local checkVelInv = false

function GetNotesHash(notes)
  local xor_acc = 0
  local sum_acc = 0
  local count = 0

  for _, n in pairs(notes) do
    local h = n.hash
    xor_acc = xor_acc ~ h
    sum_acc = (sum_acc + h) & 0xffffffff
    count = count + 1
  end

  local final = xor_acc ~ ((sum_acc << 1) & 0xffffffff) ~ count
  return final
end

local function GetNotes()
  local notes = {}

  local take = GetPianoRollTake()
  if not take then return notes end
  local _, noteCount = reaper.MIDI_CountEvts(take)

  for i = 0, noteCount-1 do
    local ok, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)

    if sel then
      local hash = Hash(table.concat({
        startppq,
        endppq,
        pitch,
        chan,
        vel,
        muted and 1 or 0
      }, ","))

      notes[hash] = {
        hash=hash,
        idx=i,
        start=startppq,
        finish=endppq,
        pitch=pitch,
        chan=chan,
        vel=vel,
        muted=muted
      }
    end
  end

  return notes
end

local function BackupNotes(src)
  local t = {}
  for k,v in pairs(src) do
    t[k] = {
      hash=v.hash,
      idx=v.idx,
      start=v.start,
      finish=v.finish,
      pitch=v.pitch,
      chan=v.chan,
      vel=v.vel,
      muted=v.muted
    }
  end
  return t
end

-- called every frame to keep track of selected MIDI notes
local function RefreshNotes()
  local currentNotes = GetNotes()
  local currentHash = GetNotesHash(currentNotes)

  if currentHash ~= selnoteshash then
    backupnotes = BackupNotes(currentNotes)
    backupnoteshash = currentHash
    sliderGate = 0
    sliderGateInc = 0
    sliderWarp = 0
    sliderVelInc = 0
  end

  selnotescount = 0
  for k,v in pairs(currentNotes) do
    selnotescount = selnotescount + 1
  end

  selnotes = currentNotes
  selnoteshash = currentHash
end

-- called after then plugin modifies the notes (e.g., gate)
-- avoids backup replacement during RefreshNotes()
local function UpdateNotes()
  selnotes = GetNotes()
  selnoteshash = GetNotesHash(selnotes)
end

function FlipHorizontal()
  local take = GetPianoRollTake()
  if not take then return end

  local _, noteCount = reaper.MIDI_CountEvts(take)

  local minStart, maxEnd = math.huge, -math.huge
  local notes = {}

  -- gather selected notes and bounds
  for i = 0, noteCount-1 do
    local ok, sel, muted, startppq, endppq =
      reaper.MIDI_GetNote(take, i)

    if sel then
      table.insert(notes, {i, startppq, endppq})
      if startppq < minStart then minStart = startppq end
      if endppq   > maxEnd   then maxEnd   = endppq end
    end
  end

  if #notes == 0 then return end

  local span = maxEnd - minStart

  reaper.MIDI_DisableSort(take)

  for _, n in ipairs(notes) do
    local idx, startppq, endppq = table.unpack(n)
    local len = endppq - startppq

    local newStart = minStart + (span - (endppq - minStart))
    local newEnd   = newStart + len

    reaper.MIDI_SetNote(take, idx, nil, nil, newStart, newEnd, nil, nil, nil, true)
  end

  reaper.MIDI_Sort(take)
end

function FlipVertical()
  local take = GetPianoRollTake()
  if not take then return end

  local _, noteCount = reaper.MIDI_CountEvts(take)

  local minPitch, maxPitch = 127, 0
  local notes = {}

  -- gather selected notes + pitch bounds
  for i = 0, noteCount-1 do
    local ok, sel, muted, startppq, endppq, chan, pitch =
      reaper.MIDI_GetNote(take, i)

    if sel then
      table.insert(notes, {i, pitch})
      if pitch < minPitch then minPitch = pitch end
      if pitch > maxPitch then maxPitch = pitch end
    end
  end

  if #notes == 0 then return end

  reaper.MIDI_DisableSort(take)

  for _, n in ipairs(notes) do
    local idx, pitch = table.unpack(n)
    local newPitch = maxPitch - (pitch - minPitch)

    reaper.MIDI_SetNote(take, idx, nil, nil, nil, nil, nil, newPitch, nil, true)
  end

  reaper.MIDI_Sort(take)
end

function Split(double)
  local take = GetPianoRollTake()
  if not take then return end

  local _, noteCount = reaper.MIDI_CountEvts(take)

  -- group selected notes by pitch/channel
  local groups = {}

  for i = 0, noteCount-1 do
    local ok, sel, muted, startppq, endppq, chan, pitch, vel =
      reaper.MIDI_GetNote(take, i)

    if sel then
      local key = pitch.."_"..chan
      groups[key] = groups[key] or {}
      table.insert(groups[key], {
        idx=i,
        start=startppq,
        finish=endppq,
        pitch=pitch,
        chan=chan,
        vel=vel,
        muted=muted
      })
    end
  end

  reaper.MIDI_DisableSort(take)

  -- collect all notes to delete first
  local notesToDelete = {}

  for _, notes in pairs(groups) do
    table.sort(notes, function(a,b) return a.start < b.start end)

    -- detect runs (touching notes) separately per pitch/channel
    local runs = {}
    local run = {notes[1]}
    for i = 2, #notes do
      local prev = run[#run]
      local cur  = notes[i]
      if cur.start <= prev.finish then
        table.insert(run, cur)
      else
        table.insert(runs, run)
        run = {cur}
      end
    end
    table.insert(runs, run)

    -- mark notes for deletion
    for _, r in ipairs(runs) do
      for _, n in ipairs(r) do
        table.insert(notesToDelete, n.idx)
      end
    end
  end

  -- delete all notes in reverse order of indices
  table.sort(notesToDelete, function(a,b) return a > b end)
  for _, idx in ipairs(notesToDelete) do
    reaper.MIDI_DeleteNote(take, idx)
  end

  -- now rebuild the runs with +1 subdivision
  for _, notes in pairs(groups) do
    table.sort(notes, function(a,b) return a.start < b.start end)

    local runs = {}
    local run = {notes[1]}
    for i = 2, #notes do
      local prev = run[#run]
      local cur  = notes[i]
      if cur.start <= prev.finish then
        table.insert(run, cur)
      else
        table.insert(runs, run)
        run = {cur}
      end
    end
    table.insert(runs, run)

    -- create new subdivided notes
    for _, r in ipairs(runs) do
      local start = r[1].start
      local finish = r[#r].finish
      local span = finish - start
      local slices = #r + 1
      if double then
        slices = #r * 2
      end
      local step = span / slices

      for i = 0, slices-1 do
        local s = start + step*i
        local e = start + step*(i+1)

        reaper.MIDI_InsertNote(
          take, true, r[1].muted,
          s, e,
          r[1].chan,
          r[1].pitch,
          r[1].vel,
          true
        )
      end
    end
  end

  reaper.MIDI_Sort(take)
end

function Rotate(left)
  local take = GetPianoRollTake()
  if not take then return end

  local grid = GetMidiGridPPQ(take)
  if left then grid = -grid end

  local notes = GetNotes()
  if not notes or next(notes) == nil then return end

  -- find global span (start positions only)
  local minStart = math.huge
  local maxStart = -math.huge


  for _, note in pairs(notes) do
    if note.start < minStart then minStart = note.start end
    if note.start > maxStart then maxStart = note.start end
  end

  -- try to recall last used rotation boundaries.
  -- because consecutive rotations should use the same boundaries
  -- and because this function can be called from an Action
  -- the boundaries and notes hash are persisted within the project
  local _, rothash = reaper.GetProjExtState(0, 'highroller', 'rothash')
  if tonumber(rothash) == GetNotesHash(notes) then
    local _, rotminstart = reaper.GetProjExtState(0, 'highroller', 'rotminstart')
    local _, rotmaxstart = reaper.GetProjExtState(0, 'highroller', 'rotmaxstart')
    local nrotminstart = tonumber(rotminstart)
    local nrotmaxstart = tonumber(rotmaxstart)
    if nrotminstart ~= nil and nrotmaxstart ~= nil then
      minStart = nrotminstart
      maxStart = nrotmaxstart
    end
  end

  local span = (maxStart - minStart) + math.abs(grid)

  -- rotate positions
  for _, note in pairs(notes) do
    local duration = note.finish - note.start
    local newStart = note.start + grid

    -- wrap left
    if newStart < minStart then
      newStart = newStart + span
    end

    -- wrap right
    if newStart > maxStart then
      newStart = newStart - span
    end

    note.start  = newStart
    note.finish = newStart + duration
  end

  -- write notes back to take
  reaper.MIDI_DisableSort(take)

  for _, note in pairs(notes) do
    reaper.MIDI_SetNote(
      take,
      note.idx,
      nil,
      nil,
      note.start,
      note.finish,
      nil,
      nil,
      nil,
      false
    )
  end

  reaper.MIDI_Sort(take)
  reaper.UpdateArrange()
  notes = GetNotes()

  -- persist last notes hash such that rotate reuses the rotation boundaries on repeat
  reaper.SetProjExtState(0, "highroller", "rothash", GetNotesHash(notes))
  reaper.SetProjExtState(0, "highroller", "rotminstart", minStart)
  reaper.SetProjExtState(0, "highroller", "rotmaxstart", maxStart)
end

function Glue(halve)
  local take = GetPianoRollTake()
  if not take then return end
  local _, noteCount = reaper.MIDI_CountEvts(take)

  -- group selected notes by pitch/channel
  local groups = {}
  for i = 0, noteCount-1 do
    local ok, sel, muted, startppq, endppq, chan, pitch, vel =
      reaper.MIDI_GetNote(take, i)
    if sel then
      local key = pitch.."_"..chan
      groups[key] = groups[key] or {}
      table.insert(groups[key], {
        idx=i,
        start=startppq,
        finish=endppq,
        pitch=pitch,
        chan=chan,
        vel=vel,
        muted=muted
      })
    end
  end

  reaper.MIDI_DisableSort(take)

  -- 1️⃣ Collect all notes to delete across all runs
  local notesToDelete = {}
  local runsByGroup = {} -- store runs to rebuild after deletion
  for gkey, notes in pairs(groups) do
    table.sort(notes, function(a,b) return a.start < b.start end)

    -- detect consecutive/overlapping runs
    local runs = {}
    local run = {notes[1]}
    for i=2,#notes do
      local prev = run[#run]
      local cur  = notes[i]
      if cur.start <= prev.finish then
        table.insert(run, cur)
      else
        table.insert(runs, run)
        run = {cur}
      end
    end
    table.insert(runs, run)
    runsByGroup[gkey] = runs

    -- mark all notes for deletion
    for _, r in ipairs(runs) do
      for _, n in ipairs(r) do
        table.insert(notesToDelete, n.idx)
      end
    end
  end

  -- 2️⃣ Delete all notes in descending index order (safe!)
  table.sort(notesToDelete, function(a,b) return a > b end)
  for _, idx in ipairs(notesToDelete) do
    reaper.MIDI_DeleteNote(take, idx)
  end

  -- 3️⃣ Rebuild merged notes for each run (stepwise glue)
  for gkey, runs in pairs(runsByGroup) do
    for _, r in ipairs(runs) do
      local start = r[1].start
      local finish = r[#r].finish
      local pitch = r[1].pitch
      local chan  = r[1].chan
      local vel   = r[1].vel
      local muted = r[1].muted

      local numNotes = #r
      local newNum

      if halve then
        newNum = math.max(1, math.floor(numNotes/2))
      else
        newNum = math.max(1, numNotes - 1)
      end

      -- insert numNotes-1 evenly spaced notes
      local step = (finish - start) / newNum
      for i = 0, newNum-1 do
        local s = start + step*i
        local e = start + step*(i+1)
        reaper.MIDI_InsertNote(take, true, muted, s, e, chan, pitch, vel, true)
      end

      ::continue::
    end
  end

  reaper.MIDI_Sort(take)
end

local function MapValue(value, min, max, tension)
  local t = (value - min) / (max - min)
  t = math.max(0, math.min(1, t))
  t = t ^ (2 ^ (tension * 4))
  return t
end

local function ApplyGate(notes)
  if sliderGate == 0 and sliderGateInc == 0 then
    return
  end

  local gateMult = 1 + sliderGate
  if gateMult > 1 then
    gateMult = gateMult * gateMult
  end

  local incMult = sliderGateInc
  if incMult > 0 then
    incMult = incMult * 4
  end

  -- find global span
  local firstStart = math.huge
  local lastFinish = -math.huge

  for _, note in ipairs(notes) do
    firstStart = math.min(firstStart, note.start)
    lastFinish = math.max(lastFinish, note.finish)
  end

  -- apply gate + increment
  local ten = sliderGateTen
  if sliderGateInc > 0 then ten = ten * -1 end
  if checkGateInv then ten = ten * -1 end
  for _, note in ipairs(notes) do
    local duration = note.finish - note.start
    local t_ramp = MapValue(note.finish, firstStart, lastFinish, ten)
    if checkGateInv then
      t_ramp = 1 - t_ramp
    end
    local ramp = 1 + incMult * t_ramp
    duration = duration * gateMult * ramp
    duration = math.max(1, duration)
    note.finish = note.start + duration
  end
end

local function ApplyWarp(notes)
    if sliderWarp == 0 then return end

    local firstStart = math.huge
    local lastFinish = -math.huge
    local lastStart = -math.huge
    for _, note in ipairs(notes) do
        firstStart = math.min(firstStart, note.start)
        lastFinish = math.max(lastFinish, note.finish)
        lastStart = math.max(lastStart, note.start)
    end
    local selLength = lastFinish - firstStart
    if selLength == 0 then return end

    for _, note in ipairs(notes) do
        local posRel, warpedRel, newStart

        if sliderWarp < 0 then
            posRel = (note.start - firstStart) / selLength
            warpedRel = MapValue(posRel, 0, 1, -sliderWarp)
            newStart = firstStart + warpedRel * selLength
        else
            posRel = (lastStart - note.start) / selLength
            warpedRel = MapValue(posRel, 0, 1, sliderWarp)
            newStart = lastStart - warpedRel * selLength
        end

        local duration = note.finish - note.start
        note.start = newStart
        note.finish = note.start + duration
    end
end

local function ApplyVelocity(notes)
  if sliderVelInc == 0 then
    return
  end

  local incMult = sliderVelInc
  if incMult > 0 then
    incMult = incMult * 4
  end

  -- find global span
  local firstStart = math.huge
  local lastStart = -math.huge

  for _, note in ipairs(notes) do
    firstStart = math.min(firstStart, note.start)
    lastStart = math.max(lastStart, note.start)
  end

  -- apply velocity increment
  local ten = sliderVelTen
  if sliderVelInc > 0 then ten = ten * -1 end
  if checkVelInv then ten = ten * -1 end
  for _, note in ipairs(notes) do
    local vel = note.vel / 127
    local t_ramp = MapValue(note.start, firstStart, lastStart, ten)
    if checkVelInv then
      t_ramp = 1 - t_ramp
    end
    local ramp = 1 + incMult * t_ramp
    vel = vel * ramp * 127
    vel = math.min(math.max(vel, 1), 127)
    note.vel = math.floor(vel)
  end
end

local function RemoveOverlaps(notes)
    for i = 1, #notes do
        local current = notes[i]

        for j = i + 1, #notes do
            local nextNote = notes[j]

            if current.pitch ~= nextNote.pitch or current.chan ~= nextNote.chan then
                -- different pitch/channel: continue looking
            else
                if current.finish > nextNote.start then
                    current.finish = nextNote.start
                end
                if current.finish <= nextNote.start then
                    break
                end
            end
        end
    end
end

local function ApplyChanges()
  local take = GetPianoRollTake()
  if not take then return end

  reaper.MIDI_DisableSort(take)

  -- delete all selected notes
  local indices = {}
  for _, note in pairs(selnotes) do
      table.insert(indices, note.idx)
  end
  table.sort(indices, function(a,b) return a > b end)
  for _, idx in ipairs(indices) do
      reaper.MIDI_DeleteNote(take, idx)
  end

  -- prepare notes to be modified from original selected notes
  local notesmap = BackupNotes(backupnotes)
  local notes = {}
  for _, v in pairs(notesmap) do
    table.insert(notes, v)
  end
  table.sort(notes, function(a,b) return a.start < b.start end)

  -- apply changes to original selected notes
  ApplyWarp(notes)
  RemoveOverlaps(notes)
  ApplyGate(notes)
  RemoveOverlaps(notes)
  ApplyVelocity(notes)

  -- re-add modified notes
  for _, note in ipairs(notes) do
    reaper.MIDI_InsertNote(take, true, note.muted, note.start, note.finish, note.chan, note.pitch, note.vel, true)
  end

  reaper.MIDI_Sort(take)
  UpdateNotes()
end

-- UI ----------------------------------

if not reaper.ImGui_GetBuiltinPath then
  return reaper.MB('ReaImGui is not installed or too old. Install via Reapack.', 'HighRoller - MIDI Tool', 0)
end

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.10'
local ctx = ImGui.CreateContext('HighRoller - MIDI Tool')

local function myWindow()
  RefreshNotes()
  ImGui.Text(ctx, "Selected notes: " .. selnotescount)

  ImGui.BeginDisabled(ctx, selnotescount == 0)

    if ImGui.Button(ctx, 'Flip Horizontal', 100) then FlipHorizontal() end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Flip Vertical', 100) then FlipVertical() end

    if ImGui.Button(ctx, 'Rotate Left', 100) then Rotate(true) end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Rotate Right', 100) then Rotate(false) end

    if ImGui.Button(ctx, 'Split', 100) then Split(false) end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Glue', 100) then Glue(false) end

    if ImGui.Button(ctx, 'Split x2', 100) then Split(true) end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Glue :2', 100) then Glue(true) end

    ImGui.Spacing(ctx)
    ImGui.Separator(ctx)
    ImGui.Spacing(ctx)

    ImGui.PushItemWidth(ctx, 210)
    local changed
    changed, sliderGate = ImGui.SliderDouble(ctx, "##Gate", sliderGate, -1, 1, "Gate %.2f")
    if changed then
      ApplyChanges()
    end

    changed, sliderGateInc = ImGui.SliderDouble(ctx, "##Gate Inc", sliderGateInc, -1, 1, "Gate Ramp %.2f")
    if changed then
      ApplyChanges()
    end

    ImGui.SameLine(ctx)
    ImGui.PushItemWidth(ctx, 80)
    changed, sliderGateTen = ImGui.SliderDouble(ctx, "##Gate Tension", sliderGateTen, -1, 1, "Tension %.2f")
    if changed then
      ApplyChanges()
    end
    ImGui.SameLine(ctx)
    changed, checkGateInv = ImGui.Checkbox(ctx, "Inv", checkGateInv)
    if changed then
      ApplyChanges()
    end

    ImGui.PushItemWidth(ctx, 210)
    changed, sliderWarp = ImGui.SliderDouble(ctx, "##Warp", sliderWarp, -1, 1, "Warp %.2f")
    if changed then
      ApplyChanges()
    end

    changed, sliderVelInc = ImGui.SliderDouble(ctx, "##Vel Ramp", sliderVelInc, -1, 1, "Vel Ramp %.2f")
    if changed then
      ApplyChanges()
    end
    ImGui.SameLine(ctx)
    ImGui.PushItemWidth(ctx, 80)
    changed, sliderVelTen = ImGui.SliderDouble(ctx, "##Vel Tension", sliderVelTen, -1, 1, "Tension %.2f")
    if changed then
      ApplyChanges()
    end
    ImGui.SameLine(ctx)
    changed, checkVelInv = ImGui.Checkbox(ctx, "Inv ", checkVelInv)
    if changed then
      ApplyChanges()
    end

  ImGui.EndDisabled(ctx)
end

local function loop()
  ImGui.SetNextWindowSize(ctx, 365, 270, ImGui.Cond_Always)
  local visible, open = ImGui.Begin(ctx, 'HighRoller - MIDI Toolkit', true, ImGui.WindowFlags_NoResize | ImGui.PopupFlags_None)
  if visible then
    myWindow()
    ImGui.End(ctx)
  end

  if ImGui.GetKeyDownDuration(ctx, ImGui.Key_Escape) >= 0 then
    open = false
  end

  if open then
    reaper.defer(loop)
  end
end

if not NO_UI then -- skip_init set from other scripts
  reaper.defer(loop)
end

return {
  Split = Split,
  Glue = Glue,
  FlipHorizontal = FlipHorizontal,
  FlipVertical = FlipVertical,
  Rotate = Rotate
}
