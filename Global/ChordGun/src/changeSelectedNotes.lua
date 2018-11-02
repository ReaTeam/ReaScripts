-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/midiEditor")

local function getNoteStartingPositions()

	local numberOfNotes = getNumberOfNotes()
	local previousNoteStartPositionPPQ = -1
	local noteStartingPositions = {}

	for noteIndex = 0, numberOfNotes-1 do

		local _, noteIsSelected, noteIsMuted, noteStartPositionPPQ, noteEndPositionPPQ = reaper.MIDI_GetNote(activeTake(), noteIndex)
	
		if noteIsSelected then

			if noteStartPositionPPQ ~= previousNoteStartPositionPPQ then
				table.insert(noteStartingPositions, noteStartPositionPPQ)
			end

			previousNoteStartPositionPPQ = noteStartPositionPPQ
		end
	end

	return noteStartingPositions
end

local function deleteSelectedNotes()

	local numberOfNotes = getNumberOfNotes()

	for noteIndex = numberOfNotes-1, 0, -1 do

		local _, noteIsSelected = reaper.MIDI_GetNote(activeTake(), noteIndex)
	
		if noteIsSelected then
			deleteNote(noteIndex)
		end
	end
end

local function setEditCursorTo(arg)

	local cursorPosition = reaper.MIDI_GetProjTimeFromPPQPos(activeTake(), arg)
	setEditCursorPosition(cursorPosition)
end

function changeSelectedNotesToScaleChords(chordNotesArray)

	local noteStartingPositions = getNoteStartingPositions()
	deleteSelectedNotes()
	
	for i = 1, #noteStartingPositions do
		setEditCursorTo(noteStartingPositions[i])
		insertScaleChord(chordNotesArray, true)
	end
end

function changeSelectedNotesToScaleNotes(noteValue)

	local noteStartingPositions = getNoteStartingPositions()
	deleteSelectedNotes()

	for i = 1, #noteStartingPositions do
		setEditCursorTo(noteStartingPositions[i])
		insertScaleNote(noteValue, true)
	end
end