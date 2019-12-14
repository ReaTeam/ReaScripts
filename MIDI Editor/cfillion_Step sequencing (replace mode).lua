-- @description Step sequencing (replace mode)
-- @author cfillion
-- @version 1.0alpha
-- @provides [effect] cfillion_Step sequencing (replace mode).jsfx
-- @screenshot https://i.imgur.com/4azf7CN.gif
-- @donation https://paypal.me/cfillion
-- @about
--   ## Step sequencing (replace mode)
--
--   This script is an alternative to the native step recording feature. Existing notes under the edit cursor are replaced (lowest first). The MIDI editor's active note row is automatically updated as new notes are played.
--
--   Note that this script automatically inserts and removes an helper JSFX in the active track's input FX chain in order to receive live MIDI input.

local MB_OK = 0
local MIDI_EDITOR_SECTION = 32060
local NATIVE_STEP_RECORD  = 40481
local NOTE_BUFFER_START = 1

local jsfx
local jsfxName = 'ReaTeam Scripts/MIDI Editor/cfillion_Step sequencing (replace mode).jsfx'
local scriptName = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local scriptSection = ({reaper.get_action_context()})[3]
local scriptId = ({reaper.get_action_context()})[4]
local debug = false

local function printf(...)
  if debug then
    reaper.ShowConsoleMsg(string.format(...))
  end
end

local function getActiveTake()
  local me = reaper.MIDIEditor_GetActive()

  if me then
    return reaper.MIDIEditor_GetTake(me), me
  end
end

local function findFXByGUID(track, targetGUID, recFX)
  local i, offset = 0, recFX and 0x1000000 or 0
  local guid = reaper.TrackFX_GetFXGUID(track, offset + i)

  while guid do
    if guid == targetGUID then
      return i
    end

    i = i + 1
    guid = reaper.TrackFX_GetFXGUID(track, offset + i)
  end
end

local function findNotesAtTime(take, ppqTime)
  local notes = {}

  for ni = 0, reaper.MIDI_CountEvts(take) - 1 do
    local note = {reaper.MIDI_GetNote(take, ni)}
    note[1] = ni

    if note[4] <= ppqTime and note[5] > ppqTime then
      table.insert(notes, note)
    end
  end

  -- sort notes by ascending pitch
  table.sort(notes, function(a, b) return a[7] < b[7] end)

  return notes
end

local function teardownJSFX()
  if not jsfx then return end

  local index = findFXByGUID(jsfx.track, jsfx.guid, true)
  if index then
    reaper.TrackFX_Delete(jsfx.track, index | 0x1000000)
  end

  jsfx = nil
end

local function installJSFX(take)
  local track = reaper.GetMediaItemTake_Track(take)
  if jsfx and track == jsfx.track then return true end

  teardownJSFX()

  local index = reaper.TrackFX_AddByName(track, jsfxName, true, 1)
  jsfx = {
    guid  = reaper.TrackFX_GetFXGUID(track, index | 0x1000000),
    track = track,
  }
  reaper.gmem_write(0, NOTE_BUFFER_START)

  return index >= 0
end

local function readNoteBuffer()
  local chords = {}

  local bi = NOTE_BUFFER_START
  local be = reaper.gmem_read(0) - 1
  local function nextIndex()
    local i = bi
    bi = bi + 1
    return i
  end

  while bi < be do
    local noteSize  = 4
    local noteCount = reaper.gmem_read(nextIndex()) / noteSize
    printf("received chord\tnotes=%d\n", noteCount)

    local notes = {}
    for ni = 1, noteCount do
      local note = {
        chan   = reaper.gmem_read(nextIndex()),
        pitch  = reaper.gmem_read(nextIndex()),
        vel    = reaper.gmem_read(nextIndex()),
        isDown = reaper.gmem_read(nextIndex()), -- unused
      }

      printf(">\tnote %d\tchan=%d vel=%d\n", note.pitch, note.chan, note.vel)
      table.insert(notes, note)
    end

    table.sort(notes, function(a, b) return a.pitch < b.pitch end)
    table.insert(chords, notes)
  end

  reaper.gmem_write(0, NOTE_BUFFER_START)

  return chords
end

local function insertReplaceNotes(take, newNotes)
  local updated = false
  local qnGrid = reaper.MIDI_GetGrid(take)
  local curPos = reaper.GetCursorPosition()
  local ppqTime = reaper.MIDI_GetPPQPosFromProjTime(take, curPos)
  local ppqNextTime = ppqTime
  local notesUnderCursor = findNotesAtTime(take, ppqTime)

  -- replace existing notes (lowest first)
  for ni = 1, math.min(#newNotes, #notesUnderCursor) do
    local note = notesUnderCursor[ni]
    ppqNextTime = math.max(ppqNextTime, note[5])
    note[6] = newNotes[ni].chan
    note[7] = newNotes[ni].pitch
    note[8] = newNotes[ni].vel
    table.insert(note, 1, take)
    table.insert(note, true) -- noSort
    reaper.MIDI_SetNote(table.unpack(note))
    updated = true
  end

  -- add any remaining notes
  for ni = #notesUnderCursor + 1, #newNotes do
    local note = newNotes[ni]
    local qnTime = reaper.MIDI_GetProjQNFromPPQPos(take, ppqTime)
    local ppqEnd = reaper.MIDI_GetPPQPosFromProjQN(take, qnTime + qnGrid)
    reaper.MIDI_InsertNote(take, true, false, ppqTime, ppqEnd,
      note.chan, note.pitch, note.vel, true)
    ppqNextTime = math.max(ppqNextTime, ppqEnd)
    updated = true
  end

  if updated then
    reaper.MIDI_Sort(take)
  end

  if ppqNextTime > ppqTime then
    local nextTime = reaper.MIDI_GetProjTimeFromPPQPos(take, ppqNextTime)
    reaper.SetEditCurPos(nextTime, false, false)
  end
end

local function loop()
  local take, me = getActiveTake()
  if not take then
    reaper.defer(loop)
    teardownJSFX()
    return
  end

  if not installJSFX(take) then
    reaper.MB('Fatal error: Failed to install helper effect in the input chain.',
      scriptName, MB_OK)
    return
  end

  if 0 < reaper.GetToggleCommandStateEx(MIDI_EDITOR_SECTION, NATIVE_STEP_RECORD) then
    return -- terminate the script
  end

  local chords, lastNote = readNoteBuffer()
  for _, newNotes in ipairs(chords) do
    insertReplaceNotes(take, newNotes)
    lastNote  = newNotes[1]
  end

  if lastNote then
    reaper.MIDIEditor_SetSetting_int(me, 'active_note_row', lastNote.pitch)
  end

  reaper.defer(loop)
end

if reaper.GetToggleCommandStateEx(scriptSection, scriptId) > 0 then
  return
end

if 0 < reaper.GetToggleCommandStateEx(MIDI_EDITOR_SECTION, NATIVE_STEP_RECORD) then
  reaper.MIDIEditor_LastFocused_OnCommand(NATIVE_STEP_RECORD, false)
end

reaper.gmem_attach('cfillion_stepRecordReplace')
reaper.SetToggleCommandState(scriptSection, scriptId, 1)
reaper.RefreshToolbar2(scriptSection, scriptId)
reaper.atexit(function()
  reaper.SetToggleCommandState(scriptSection, scriptId, 0)
  reaper.RefreshToolbar2(scriptSection, scriptId)

  teardownJSFX()

  reaper.gmem_write(0, 0) -- disable the global note buffer
end)

loop()
