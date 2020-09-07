-- @noindex

-- fixing script path for correct require calls
local path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = path .. "?.lua"

local AccessiChords = require('timtam_AccessiChords')

local note = AccessiChords.getCurrentPitchCursorNote()
local lastNote = tonumber(AccessiChords.getValue('last_pitch_cursor_position', note))
local chordIndex = tonumber(AccessiChords.getValue('last_chord_position', 0))

chordIndex = chordIndex + 1

if note ~= lastNote then
  AccessiChords.setValue('last_pitch_cursor_position', note)
end

local chords = AccessiChords.getChordsForNote(note)
local chordNames = AccessiChords.getChordNamesForNote(note)

if chords[chordIndex] == nil then
  chordIndex = #chords
end

AccessiChords.setValue('last_chord_position', chordIndex)

AccessiChords.stopNotes()

AccessiChords.playNotes(table.unpack(chords[chordIndex]))

AccessiChords.speak(chordNames[chordIndex])

AccessiChords.stopNotes()
