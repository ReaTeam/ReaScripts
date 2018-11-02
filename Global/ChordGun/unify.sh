#!/bin/sh

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function removeFile() {

	outputFile=${1##*/}

	rm "./pkg/$outputFile"
}

function insertNoIndexHeader() {
	echo "-- @noindex" >> ./pkg/${1##*/}
}

function insertIntoFile() {

	dependencyFile=$1
	outputFile=${2##*/}

	grep -v -e "^require" -e "^-- @noindex" "${DIR}"/$dependencyFile >> ./pkg/$outputFile
}

function unifyMainProgram() {

	removeFile $1

	insertNoIndexHeader $1

	insertIntoFile src/chords.lua $1
	insertIntoFile src/defaultValues.lua $1
	insertIntoFile src/preferences.lua $1
	insertIntoFile src/util.lua $1
	insertIntoFile src/Timer.lua $1
	insertIntoFile src/globalState.lua $1
	insertIntoFile src/scales.lua $1
	insertIntoFile src/scaleFunctions.lua $1
	insertIntoFile src/scaleDegreeHeaders.lua $1
	insertIntoFile src/midiEditor.lua $1
	insertIntoFile src/midiMessages.lua $1
	insertIntoFile src/chordNotesArray.lua $1
	insertIntoFile src/insertMidiNote.lua $1
	insertIntoFile src/playOrInsertScaleChord.lua $1
	insertIntoFile src/playOrInsertScaleNote.lua $1
	insertIntoFile src/changeSelectedNotes.lua $1
	insertIntoFile src/scaleData.lua $1
	insertIntoFile src/transposeSelectedNotes.lua $1

	insertIntoFile src/actions/actionFunctions.lua $1

	insertIntoFile src/interface/images/drawDropdownIcon.lua $1
	insertIntoFile src/interface/images/drawLeftArrow.lua $1
	insertIntoFile src/interface/images/drawRightArrow.lua $1

	insertIntoFile src/interface/colors.lua $1
	insertIntoFile src/interface/classes/Docker.lua $1
	insertIntoFile src/interface/classes/HitArea.lua $1
	insertIntoFile src/interface/classes/OctaveValueBox.lua $1
	insertIntoFile src/interface/classes/Label.lua $1
	insertIntoFile src/interface/classes/Header.lua $1
	insertIntoFile src/interface/classes/Frame.lua $1
	insertIntoFile src/interface/classes/Dropdown.lua $1
	insertIntoFile src/interface/classes/ChordInversionValueBox.lua $1
	insertIntoFile src/interface/classes/ChordButton.lua $1
	insertIntoFile src/interface/inputCharacters.lua $1
	insertIntoFile src/interface/handleInput.lua $1

	insertIntoFile src/interface/Interface.lua $1
	insertIntoFile src/interface/frames/InterfaceTopFrame.lua $1
	insertIntoFile src/interface/frames/InterfaceBottomFrame.lua $1

	insertIntoFile src/$1 $1
}

function unifyKeyboardShortcut() {

	removeFile $1

	insertNoIndexHeader $1

	insertIntoFile src/chords.lua $1
	insertIntoFile src/defaultValues.lua $1
	insertIntoFile src/preferences.lua $1
	insertIntoFile src/util.lua $1
	insertIntoFile src/Timer.lua $1
	insertIntoFile src/globalState.lua $1
	insertIntoFile src/scales.lua $1
	insertIntoFile src/scaleFunctions.lua $1
	insertIntoFile src/scaleDegreeHeaders.lua $1
	insertIntoFile src/midiEditor.lua $1
	insertIntoFile src/midiMessages.lua $1
	insertIntoFile src/chordNotesArray.lua $1
	insertIntoFile src/insertMidiNote.lua $1
	insertIntoFile src/playOrInsertScaleChord.lua $1
	insertIntoFile src/playOrInsertScaleNote.lua $1
	insertIntoFile src/changeSelectedNotes.lua $1
	insertIntoFile src/scaleData.lua $1
	insertIntoFile src/transposeSelectedNotes.lua $1

	insertIntoFile src/actions/actionFunctions.lua $1
	
	insertIntoFile src/$1 $1
}

unifyMainProgram ChordGun.lua

unifyKeyboardShortcut actions/ChordGun_decrementChordInversion.lua
unifyKeyboardShortcut actions/ChordGun_decrementChordType.lua
unifyKeyboardShortcut actions/ChordGun_decrementOctave.lua
unifyKeyboardShortcut actions/ChordGun_decrementScaleTonicNote.lua
unifyKeyboardShortcut actions/ChordGun_decrementScaleType.lua

unifyKeyboardShortcut actions/ChordGun_incrementChordInversion.lua
unifyKeyboardShortcut actions/ChordGun_incrementChordType.lua
unifyKeyboardShortcut actions/ChordGun_incrementOctave.lua
unifyKeyboardShortcut actions/ChordGun_incrementScaleTonicNote.lua
unifyKeyboardShortcut actions/ChordGun_incrementScaleType.lua

unifyKeyboardShortcut actions/ChordGun_scaleChord1.lua
unifyKeyboardShortcut actions/ChordGun_scaleChord2.lua
unifyKeyboardShortcut actions/ChordGun_scaleChord3.lua
unifyKeyboardShortcut actions/ChordGun_scaleChord4.lua
unifyKeyboardShortcut actions/ChordGun_scaleChord5.lua
unifyKeyboardShortcut actions/ChordGun_scaleChord6.lua
unifyKeyboardShortcut actions/ChordGun_scaleChord7.lua

unifyKeyboardShortcut actions/ChordGun_scaleNote1.lua
unifyKeyboardShortcut actions/ChordGun_scaleNote2.lua
unifyKeyboardShortcut actions/ChordGun_scaleNote3.lua
unifyKeyboardShortcut actions/ChordGun_scaleNote4.lua
unifyKeyboardShortcut actions/ChordGun_scaleNote5.lua
unifyKeyboardShortcut actions/ChordGun_scaleNote6.lua
unifyKeyboardShortcut actions/ChordGun_scaleNote7.lua

unifyKeyboardShortcut actions/ChordGun_lowerScaleNote1.lua
unifyKeyboardShortcut actions/ChordGun_lowerScaleNote2.lua
unifyKeyboardShortcut actions/ChordGun_lowerScaleNote3.lua
unifyKeyboardShortcut actions/ChordGun_lowerScaleNote4.lua
unifyKeyboardShortcut actions/ChordGun_lowerScaleNote5.lua
unifyKeyboardShortcut actions/ChordGun_lowerScaleNote6.lua
unifyKeyboardShortcut actions/ChordGun_lowerScaleNote7.lua

unifyKeyboardShortcut actions/ChordGun_higherScaleNote1.lua
unifyKeyboardShortcut actions/ChordGun_higherScaleNote2.lua
unifyKeyboardShortcut actions/ChordGun_higherScaleNote3.lua
unifyKeyboardShortcut actions/ChordGun_higherScaleNote4.lua
unifyKeyboardShortcut actions/ChordGun_higherScaleNote5.lua
unifyKeyboardShortcut actions/ChordGun_higherScaleNote6.lua
unifyKeyboardShortcut actions/ChordGun_higherScaleNote7.lua

unifyKeyboardShortcut actions/ChordGun_stopAllNotesFromPlaying.lua
unifyKeyboardShortcut actions/ChordGun_doubleGridSize.lua
unifyKeyboardShortcut actions/ChordGun_halveGridSize.lua