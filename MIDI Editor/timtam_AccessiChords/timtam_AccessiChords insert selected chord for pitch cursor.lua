-- @noindex

-- fixing script path for correct require calls
local path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = path .. "?.lua"

local AccessiChords = require('timtam_AccessiChords')

local note = AccessiChords.getCurrentPitchCursorNote()
local chordIndex = tonumber(AccessiChords.getValue('last_chord_position', 1))
local chordInversion = tonumber(AccessiChords.getValue('last_chord_inversion', 0))

local chords = AccessiChords.getChordsForNote(note, chordInversion)

if #chords[chordIndex] == 0 then

  local chordNames = AccessiChords.getChordNamesForNote(note, chordInversion)

  AccessiChords.speak(chordNames[chordIndex].." does not exist")

  return

end

AccessiChords.playNotes(table.unpack(chords[chordIndex]))

AccessiChords.insertMidiNotes(table.unpack(chords[chordIndex]))

AccessiChords.stopNotesDeferred(10, table.unpack(chords[chordIndex]))
