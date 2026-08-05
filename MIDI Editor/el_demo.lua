-- @description demo
-- @author el
-- @version 1.0.0
-- @changelog
--   - First release
--   - Generate tracks with chords, log drum, bass, and hi-hat
--   - Auto set project tempo 112 BPM
-- @provides [main=main] .
-- @about
--   # demo
--
--   Generate an Amapiano beta project with:
--   - Tempo 112 BPM
--   - Piano chords (Am7, Dm7, G7, Cmaj7, etc.)
--   - Log drum groove
--   - Sub bass root notes
--   - Hi-hat 16th pattern
--
--   Usage: Run the script, and tracks + MIDI items will be created automatically.

-- Amapiano Beta Project Generator

-- Tempo: 112 BPM, Key: A minor

reaper.Undo_BeginBlock()

-- Set project tempo

reaper.SetCurrentBPM(0, 112, true)

-- Helper: create track

function create_track(name)

  reaper.InsertTrackAtIndex(reaper.CountTracks(0), true)

  local track = reaper.GetTrack(0, reaper.CountTracks(0)-1)

  reaper.GetSetMediaTrackInfo_String(track, "P_NAME", name, true)

  return track

end

-- Helper: insert MIDI item

function insert_midi(track, start_time, end_time)

  local item = reaper.CreateNewMIDIItemInProj(track, start_time, end_time, false)

  local take = reaper.GetActiveTake(item)

  return take

end

-- Helper: add MIDI note

function add_note(take, start_ppq, end_ppq, pitch, vel)

  reaper.MIDI_InsertNote(take, false, false, start_ppq, end_ppq, 0, pitch, vel, false)

end

-- Time helpers

ppq = reaper.MIDI_GetPPQPosFromProjTime(reaper.MIDIEditor_GetActive(), 0)

ppq_per_beat = 480

-- Tracks

track_piano = create_track("Rhodes Piano")

track_log   = create_track("Log Drum")

track_bass  = create_track("Sub Bass")

track_hat   = create_track("Hi-Hat")

-- Chord progression (verse)

chords = {

  {{"A3","C4","E4","G4"}}, -- Am7

  {{"D3","F3","A3","C4"}}, -- Dm7

  {{"G2","B2","D3","F3"}}, -- G7

  {{"C3","E3","G3","B3"}}  -- Cmaj7

}

-- Chorus chords

chorus = {

  {{"F3","A3","C4","E4"}}, -- Fmaj7

  {{"E3","G3","B3","D4"}}, -- Em7

  {{"A3","C4","E4","G4"}}, -- Am7

  {{"D3","F3","A3","C4"}}, -- Dm7

  {{"G2","B2","D3","F3"}}  -- G7

}

-- Note name to MIDI

note_map = {

  A0=21,A1=33,A2=45,A3=57,A4=69,A5=81,A6=93,A7=105,

  B0=23,B1=35,B2=47,B3=59,B4=71,B5=83,B6=95,B7=107,

  C1=24,C2=36,C3=48,C4=60,C5=72,C6=84,C7=96,

  D1=26,D2=38,D3=50,D4=62,D5=74,D6=86,D7=98,

  E1=28,E2=40,E3=52,E4=64,E5=76,E6=88,E7=100,

  F1=29,F2=41,F3=53,F4=65,F5=77,F6=89,F7=101,

  G1=31,G2=43,G3=55,G4=67,G5=79,G6=91,G7=103

}

-- Insert chords

function insert_chords(track, prog, start_measure, measures_each)

  local take = insert_midi(track, start_measure*2, (start_measure+#prog*measures_each)*2)

  local ppq_start = 0

  for i, chord in ipairs(prog) do

    local start = (i-1)*measures_each*ppq_per_beat*4

    local endp  = start + measures_each*ppq_per_beat*4

    for _, note in ipairs(chord[1]) do

      add_note(take, start, endp, note_map[note], 90)

    end

  end

  reaper.MIDI_Sort(take)

end

-- Build arrangement

insert_chords(track_piano, chords, 0, 1)   -- Verse

insert_chords(track_piano, chorus, 4, 1)   -- Chorus

-- Log drum pattern (Amapiano style: syncopated hits)

log_take = insert_midi(track_log, 0, 16)

for i=0,15 do

  local beat = i*ppq_per_beat

  if (i % 2 == 0) then

    add_note(log_take, beat, beat+ppq_per_beat/2, 36, 100)

  end

end

reaper.MIDI_Sort(log_take)

-- Sub bass (roots of chords)

bass_take = insert_midi(track_bass, 0, 16)

roots = {57, 50, 43, 48} -- A, D, G, C

for bar=0,3 do

  local root = roots[bar+1]

  local start = bar*ppq_per_beat*4

  add_note(bass_take, start, start+ppq_per_beat*4, root, 100)

end

reaper.MIDI_Sort(bass_take)

-- Hi-hat (16th notes)

hat_take = insert_midi(track_hat, 0, 16)

for i=0,63 do

  local beat = i*ppq_per_beat/2

  add_note(hat_take, beat, beat+ppq_per_beat/8, 42, 60)

end

reaper.MIDI_Sort(hat_take)

reaper.Undo_EndBlock("Generate Amapiano Beta Project", -1)
