-- @noindex

-- fixing script path for correct require calls
local path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = path .. "?.lua"

local AccessiChords = require('timtam_AccessiChords')

local note = AccessiChords.getCurrentPitchCursorNote()
local chordIndex = tonumber(AccessiChords.getValue('last_chord_position', 1))

local chords = AccessiChords.getChordsForNote(note)

if chords[chordIndex] == nil then
  AccessiChords.print('reset chord to 1')
  chordIndex = 1
end

AccessiChords.stopNotes()

AccessiChords.playNotes(table.unpack(chords[chordIndex]))

AccessiChords.insertMidiNotes(table.unpack(chords[chordIndex]))

AccessiChords.stopNotes()
