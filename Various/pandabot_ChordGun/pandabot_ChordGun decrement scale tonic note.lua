-- @noindex

chords = {
  {
    name = 'major',
    code = 'major',
    display = '',
    pattern = '10001001'
  },
  {
    name = 'minor',
    code = 'minor',
    display = 'm',
    pattern = '10010001'
  },
  {
    name = 'power chord',
    code = 'power',
    display = '5',
    pattern = '10000001'
  },
  {
    name = 'suspended second',
    code = 'sus2',
    display = 'sus2',
    pattern = '10100001'
  },
  {
    name = 'suspended fourth',
    code = 'sus4',
    display = 'sus4',
    pattern = '10000101'
  },
  {
    name = 'diminished',
    code = 'dim',
    display = 'dim',
    pattern = '1001001'
  },  
  {
    name = 'augmented',
    code = 'aug',
    display = 'aug',
    pattern = '100010001'
  },
  {
    name = 'major sixth',
    code = 'maj6',
    display = '6',
    pattern = '1000100101'
  },
  {
    name = 'minor sixth',
    code = 'min6',
    display = 'm6',
    pattern = '1001000101'
  },
  {
    name = 'dominant seventh',
    code = '7',
    display = '7',
    pattern = '10001001001'
  },
  {
    name = 'major seventh',
    code = 'maj7',
    display = 'maj7',
    pattern = '100010010001'
  },
  {
    name = 'minor seventh',
    code = 'min7',
    display = 'm7',
    pattern = '10010001001'
  },
  {
    name = 'flat fifth',
    code = 'flat5',
    display = '5-',
    pattern = '10000010'
  },
}

function mouseIsHoveringOver(element)

	local x = gfx.mouse_x
	local y = gfx.mouse_y

	local isInHorizontalRegion = (x >= element.x and x < element.x+element.width)
	local isInVerticalRegion = (y >= element.y and y < element.y+element.height)
	return isInHorizontalRegion and isInVerticalRegion
end

function setPositionAtMouseCursor()

  gfx.x = gfx.mouse_x
  gfx.y = gfx.mouse_y
end

function leftMouseButtonIsHeldDown()
  return gfx.mouse_cap & 1 == 1
end

function leftMouseButtonIsNotHeldDown()
  return gfx.mouse_cap & 1 ~= 1
end

function rightMouseButtonIsHeldDown()
  return gfx.mouse_cap & 2 == 2
end

function clearConsoleWindow()
  reaper.ShowConsoleMsg("")
end

function print(arg)
  reaper.ShowConsoleMsg(tostring(arg) .. "\n")
end

function getScreenWidth()
	local _, _, screenWidth, _ = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true)
	return screenWidth
end

function getScreenHeight()
	local _, _, _, screenHeight = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true)
	return screenHeight
end

function windowIsDocked()
	return gfx.dock(-1) > 0
end

function windowIsNotDocked()
	return not windowIsDocked()
end

function notesAreSelected()

	local activeMidiEditor = reaper.MIDIEditor_GetActive()
	local activeTake = reaper.MIDIEditor_GetTake(activeMidiEditor)

	local noteIndex = 0
	local noteExists = true
	local noteIsSelected = false

	while noteExists do

		noteExists, noteIsSelected = reaper.MIDI_GetNote(activeTake, noteIndex)

		if noteIsSelected then
			return true
		end
	
		noteIndex = noteIndex + 1
	end

	return false
end

function startUndoBlock()
	reaper.Undo_BeginBlock()
end

function endUndoBlock(actionDescription)
	reaper.Undo_OnStateChange(actionDescription)
	reaper.Undo_EndBlock(actionDescription, -1)
end

function emptyFunctionToPreventAutomaticCreationOfUndoPoint()
end


local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"

defaultScaleTonicNoteValue = 1
defaultScaleTypeValue = 1
defaultScaleNotesTextValue = ""
defaultChordTextValue = ""
defaultSelectedScaleNote = 1
defaultOctave = 3

defaultSelectedChordTypes = {}
for i = 1, 7 do
  table.insert(defaultSelectedChordTypes, 1)
end

defaultInversionStates = {}
for i = 1, 7 do
  table.insert(defaultInversionStates, 0)
end

defaultScaleNoteNames = {'C', 'D', 'E', 'F', 'G', 'A', 'B'}
defaultScaleDegreeHeaders = {'I', 'ii', 'iii', 'IV', 'V', 'vi', 'viio'}

defaultNotesThatArePlaying = {}
defaultDockState = 0x0201
defaultWindowShouldBeDocked = tostring(false)

interfaceWidth = 775
interfaceHeight = 620

function defaultInterfaceXPosition()

  local screenWidth = getScreenWidth()
  return screenWidth/2 - interfaceWidth/2
end

function defaultInterfaceYPosition()

  local screenHeight = getScreenHeight()
  return screenHeight/2 - interfaceHeight/2
end
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"

local activeProjectIndex = 0
local sectionName = "com.pandabot.ChordGun"

local scaleTonicNoteKey = "scaleTonicNote"
local scaleTypeKey = "scaleType"
local scaleNotesTextKey = "scaleNotesText"
local chordTextKey = "chordText"
local chordInversionStatesKey = "chordInversionStates"
local selectedScaleNoteKey = "selectedScaleNote"
local octaveKey = "octave"
local selectedChordTypesKey = "selectedChordTypes"
local scaleNoteNamesKey = "scaleNoteNames"
local scaleDegreeHeadersKey = "scaleDegreeHeaders"
local notesThatArePlayingKey = "notesThatArePlaying"
local dockStateKey = "dockState"
local windowShouldBeDockedKey = "shouldBeDocked"
local interfaceXPositionKey = "interfaceXPosition"
local interfaceYPositionKey = "interfaceYPosition"

--

local function setValue(key, value)
  reaper.SetProjExtState(activeProjectIndex, sectionName, key, value)
end

local function getValue(key, defaultValue)

  local valueExists, value = reaper.GetProjExtState(activeProjectIndex, sectionName, key)

  if valueExists == 0 then
    setValue(key, defaultValue)
    return defaultValue
  end

  return value
end

--

local function getTableFromString(arg)

  local output = {}

  for match in arg:gmatch("([^,%s]+)") do
    output[#output + 1] = match
  end

  return output
end

local function setTableValue(key, value)
  reaper.SetProjExtState(activeProjectIndex, sectionName, key, table.concat(value, ","))
end

local function getTableValue(key, defaultValue)

  local valueExists, value = reaper.GetProjExtState(activeProjectIndex, sectionName, key)

  if valueExists == 0 then
    setTableValue(key, defaultValue)
    return defaultValue
  end

  return getTableFromString(value)
end

--[[ ]]--

function getScaleTonicNote()
  return tonumber(getValue(scaleTonicNoteKey, defaultScaleTonicNoteValue))
end

function setScaleTonicNote(arg)
  setValue(scaleTonicNoteKey, arg)
end

--

function getScaleType()
  return tonumber(getValue(scaleTypeKey, defaultScaleTypeValue))
end

function setScaleType(arg)
  setValue(scaleTypeKey, arg)
end

--

function getScaleNotesText()
  return getValue(scaleNotesTextKey, defaultScaleNotesTextValue)
end

function setScaleNotesText(arg)
  setValue(scaleNotesTextKey, arg)
end

--

function getChordText()
  return getValue(chordTextKey, defaultChordTextValue)
end

function setChordText(arg)
  setValue(chordTextKey, arg)
end

--

function getChordInversionMin()
  return -8
end

--

function getChordInversionMax()
  return 8
end

--

function getSelectedScaleNote()
  return tonumber(getValue(selectedScaleNoteKey, defaultSelectedScaleNote))
end

function setSelectedScaleNote(arg)
  setValue(selectedScaleNoteKey, arg)
end

--

function getOctave()
  return tonumber(getValue(octaveKey, defaultOctave))
end

function setOctave(arg)
  setValue(octaveKey, arg)
end

--

function getOctaveMin()
  return -1
end

--

function getOctaveMax()
  return 8
end

--

function getSelectedChordTypes()

  return getTableValue(selectedChordTypesKey, defaultSelectedChordTypes)
end

function getSelectedChordType(index)

  local temp = getTableValue(selectedChordTypesKey, defaultSelectedChordTypes)
  return tonumber(temp[index])
end

function setSelectedChordType(index, arg)

  local temp = getSelectedChordTypes()
  temp[index] = arg
  setTableValue(selectedChordTypesKey, temp)
end

--

function getScaleNoteNames()
  return getTableValue(scaleNoteNamesKey, defaultScaleNoteNames)
end

function getScaleNoteName(index)
  local temp = getTableValue(scaleNoteNamesKey, defaultScaleNoteNames)
  return temp[index]
end

function setScaleNoteName(index, arg)

  local temp = getScaleNoteNames()
  temp[index] = arg
  setTableValue(scaleNoteNamesKey, temp)
end

--

function getScaleDegreeHeaders()
  return getTableValue(scaleDegreeHeadersKey, defaultScaleDegreeHeaders)
end

function getScaleDegreeHeader(index)
  local temp = getTableValue(scaleDegreeHeadersKey, defaultScaleDegreeHeaders)
  return temp[index]
end

function setScaleDegreeHeader(index, arg)

  local temp = getScaleDegreeHeaders()
  temp[index] = arg
  setTableValue(scaleDegreeHeadersKey, temp)
end

--

function getChordInversionStates()
  return getTableValue(chordInversionStatesKey, defaultInversionStates)
end

function getChordInversionState(index)

  local temp = getTableValue(chordInversionStatesKey, defaultInversionStates)
  return tonumber(temp[index])
end

function setChordInversionState(index, arg)

  local temp = getChordInversionStates()
  temp[index] = arg
  setTableValue(chordInversionStatesKey, temp)
end

--

function resetSelectedChordTypes()

  local numberOfSelectedChordTypes = 7

  for i = 1, numberOfSelectedChordTypes do
    setSelectedChordType(i, 1)
  end
end

function resetChordInversionStates()

  local numberOfChordInversionStates = 7

  for i = 1, numberOfChordInversionStates do
    setChordInversionState(i, 0)
  end
end

--

function getNotesThatArePlaying()
  return getTableValue(notesThatArePlayingKey, defaultNotesThatArePlaying)
end

function setNotesThatArePlaying(arg)
  setTableValue(notesThatArePlayingKey, arg)
end

--

function getDockState()
  return getValue(dockStateKey, defaultDockState)
end

function setDockState(arg)
  setValue(dockStateKey, arg)
end

function windowShouldBeDocked()
  return getValue(windowShouldBeDockedKey, defaultWindowShouldBeDocked) == tostring(true)
end

function setWindowShouldBeDocked(arg)
  setValue(windowShouldBeDockedKey, tostring(arg))
end

function getInterfaceXPosition()
  return getValue(interfaceXPositionKey, defaultInterfaceXPosition())
end

function setInterfaceXPosition(arg)
  setValue(interfaceXPositionKey, arg)
end

function getInterfaceYPosition()
  return getValue(interfaceYPositionKey, defaultInterfaceYPosition())
end

function setInterfaceYPosition(arg)
  setValue(interfaceYPositionKey, arg)
end

Timer = {}
Timer.__index = Timer

function Timer:new(numberOfSeconds)

  local self = {}
  setmetatable(self, Timer)

  self.startingTime = reaper.time_precise()
  self.numberOfSeconds = numberOfSeconds
  self.timerIsStopped = true

  return self
end

function Timer:start()

	self.timerIsStopped = false
	self.startingTime = reaper.time_precise()
end

function Timer:stop()

	self.timerIsStopped = true
end

function Timer:timeHasElapsed()

	local currentTime = reaper.time_precise()

	if self.timerIsStopped then
		return false
	end

	if currentTime - self.startingTime > self.numberOfSeconds then
		return true
	else
		return false
	end
end

function Timer:timeHasNotElapsed()
	return not self:timeHasElapsed()
end
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"

mouseButtonIsNotPressedDown = true

currentWidth = 0

scaleTonicNote = getScaleTonicNote()
scaleType = getScaleType()

guiShouldBeUpdated = false

scales = {
  { name = "Major", pattern = "101011010101" },
  { name = "Natural Minor", pattern = "101101011010" },
  { name = "Harmonic Minor", pattern = "101101011001" },
  { name = "Melodic Minor", pattern = "101101010101" },
  { name = "Pentatonic", pattern = "101010010100" },
  { name = "Ionian", pattern = "101011010101" },
  { name = "Aeolian", pattern = "101101011010" },
  { name = "Dorian", pattern = "101101010110" },
  { name = "Mixolydian", pattern = "101011010110" },
  { name = "Phrygian", pattern = "110101011010" },
  { name = "Lydian", pattern = "101010110101" },
  { name = "Locrian", pattern = "110101101010" }
}
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"

notes = { 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B' };
flatNotes = { 'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B' };

function getScalePattern(scaleTonicNote, scale)

  local scalePatternString = scale['pattern']
  local scalePattern = {false,false,false,false,false,false,false,false,false,false,false}

  for i = 0, #scalePatternString do
    local note = getNotesIndex(scaleTonicNote+i)
    if scalePatternString:sub(i+1, i+1) == '1' then
      scalePattern[note] = true
    end
  end
  return scalePattern
end

function getNotesIndex(note) 
   return ((note - 1) % 12) + 1
end

function getNoteName(note)

  local noteName = getSharpNoteName(note)
  
  if not string.match(getScaleNotesText(), noteName) then
    return getFlatNoteName(note)
  else
    return noteName
  end
end

function getSharpNoteName(note)
  local notesIndex = getNotesIndex(note)
  return notes[notesIndex]
end

function getFlatNoteName(note)
  local notesIndex = getNotesIndex(note)
  return flatNotes[notesIndex]
end

function chordIsNotAlreadyIncluded(scaleChordsForRootNote, chordCode)

  for chordIndex, chord in ipairs(scaleChordsForRootNote) do
  
    if chord.code == chordCode then
      return false
    end
  end
  
  return true
end

function getNumberOfScaleChordsForScaleNoteIndex(scaleNoteIndex)

  local chordCount = 0
  local scaleChordsForRootNote = {}
  
  for chordIndex, chord in ipairs(chords) do
  
    if chordIsInScale(scaleNotes[scaleNoteIndex], chordIndex) then
      chordCount = chordCount + 1
      scaleChordsForRootNote[chordCount] = chord   
    end
  end

  return chordCount
end

function getScaleChordsForRootNote(rootNote)
  
  local chordCount = 0
  local scaleChordsForRootNote = {}
  
  for chordIndex, chord in ipairs(chords) do
  
    if chordIsInScale(rootNote, chordIndex) then
      chordCount = chordCount + 1
      scaleChordsForRootNote[chordCount] = chord   
    end
  end
    
  --[[  
  if preferences.enableModalMixtureCheckbox.value then

    for chordIndex, chord in ipairs(chords) do
             
      if chordIsNotAlreadyIncluded(scaleChordsForRootNote, chord.code) and chordIsInModalMixtureScale(rootNote, chordIndex) then
        chordCount = chordCount + 1
        scaleChordsForRootNote[chordCount] = chord
      end
    end
  end
  ]]--


  -- here is where you color the chord buttons differently
  for chordIndex, chord in ipairs(chords) do
           
    if chordIsNotAlreadyIncluded(scaleChordsForRootNote, chord.code) then
      chordCount = chordCount + 1
      scaleChordsForRootNote[chordCount] = chord
    end
  end
  
  return scaleChordsForRootNote
end

function noteIsInScale(note)
  return scalePattern[getNotesIndex(note)]
end

function noteIsNotInScale(note)
  return not noteIsInScale(note)
end

function chordIsInScale(rootNote, chordIndex)

  local chord = chords[chordIndex]
  local chordPattern = chord['pattern']
  
  for i = 0, #chordPattern do
    local note = getNotesIndex(rootNote+i)
    if chordPattern:sub(i+1, i+1) == '1' and noteIsNotInScale(note) then
      return false
    end
  end
  
  return true
end

function noteIsInModalMixtureScale(note)

  local modalMixtureScaleType = 2
  local modalMixtureScalePattern = getScalePattern(getScaleTonicNote(), scales[modalMixtureScaleType])
  return modalMixtureScalePattern[getNotesIndex(note)]
end

function noteIsNotInModalMixtureScale(note)
  return not noteIsInModalMixtureScale(note)
end

function chordIsInModalMixtureScale(rootNote, chordIndex)

  local chord = chords[chordIndex]
  local chordPattern = chord['pattern']
  
  for i = 0, #chordPattern do
    local note = getNotesIndex(rootNote+i)
        
    if chordPattern:sub(i+1, i+1) == '1' and noteIsNotInModalMixtureScale(note) then
      return false
    end
  end
  
  return true
end
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"

function updateScaleDegreeHeaders()

  local minorSymbols = {'i', 'ii', 'iii', 'iv', 'v', 'vi', 'vii'}
  local majorSymbols = {'I', 'II', 'III', 'IV', 'V', 'VI', 'VII'}
  local diminishedSymbol = 'o'
  local augmentedSymbol = '+'
  local sixthSymbol = '6'
  local seventhSymbol = '7'
  
  local i = 1
  for i = 1, #scaleNotes do
  
    local symbol = ""
   
    local chord = scaleChords[i][1]
    
    if string.match(chord.code, "major") or chord.code == '7' then
      symbol = majorSymbols[i]
    else
      symbol = minorSymbols[i]
    end
    
    if (chord.code == 'aug') then
      symbol = symbol .. augmentedSymbol
    end

    if (chord.code == 'dim') then
      symbol = symbol .. diminishedSymbol
    end

    if string.match(chord.code, "6") then
      symbol = symbol .. sixthSymbol
    end
    
    if string.match(chord.code, "7") then
      symbol = symbol .. seventhSymbol
    end
        
    setScaleDegreeHeader(i, symbol) 
  end
end

--[[

  setDrawColorToRed()
  gfx.setfont(1, "Arial")       <-- default bitmap font does not support Unicode characters
  local degreeSymbolCharacter = 0x00B0  <-- this is the degree symbol for augmented chords,  "°"
  gfx.drawchar(degreeSymbolCharacter)

]]--

local tolerance = 0.000001

function activeMidiEditor()
  return reaper.MIDIEditor_GetActive()
end

function activeTake()
  return reaper.MIDIEditor_GetTake(activeMidiEditor())
end

function activeMediaItem()
  return reaper.GetMediaItemTake_Item(activeTake())
end

function activeTrack()
  return reaper.GetMediaItemTake_Track(activeTake())
end

function mediaItemStartPosition()
  return reaper.GetMediaItemInfo_Value(activeMediaItem(), "D_POSITION")
end

function mediaItemStartPositionPPQ()
  return reaper.MIDI_GetPPQPosFromProjTime(activeTake(), mediaItemStartPosition())
end

function mediaItemStartPositionQN()
  return reaper.MIDI_GetProjQNFromPPQPos(activeTake(), mediaItemStartPositionPPQ())
end

local function mediaItemLength()
  return reaper.GetMediaItemInfo_Value(activeMediaItem(), "D_LENGTH")
end

local function mediaItemEndPosition()
  return mediaItemStartPosition() + mediaItemLength()
end

local function cursorPosition()
  return reaper.GetCursorPosition()
end

local function loopStartPosition()

  local loopStartPosition, _ = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  return loopStartPosition
end

local function loopEndPosition()

  local _, loopEndPosition = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  return loopEndPosition
end

local function noteLengthOld()

  local noteLengthQN = getNoteLengthQN()
  local noteLengthPPQ = reaper.MIDI_GetPPQPosFromProjQN(activeTake(), noteLengthQN)
  return reaper.MIDI_GetProjTimeFromPPQPos(activeTake(), noteLengthPPQ)
end

local function noteLength()

  return gridUnitLength()
end


function notCurrentlyRecording()
  
  local activeProjectIndex = 0
  return reaper.GetPlayStateEx(activeProjectIndex) & 4 ~= 4
end

function setEditCursorPosition(arg)

  local activeProjectIndex = 0
  local moveView = false
  local seekPlay = false
  reaper.SetEditCurPos2(activeProjectIndex, arg, moveView, seekPlay)
end

local function moveEditCursorPosition(arg)

  local moveTimeSelection = false
  reaper.MoveEditCursor(arg, moveTimeSelection)
end

local function repeatIsNotOn()
  return reaper.GetSetRepeat(-1) == 0
end

local function loopIsActive()

  if repeatIsNotOn() then
    return false
  end

  if loopStartPosition() < mediaItemStartPosition() and loopEndPosition() < mediaItemStartPosition() then
    return false
  end

  if loopStartPosition() > mediaItemEndPosition() and loopEndPosition() > mediaItemEndPosition() then
    return false
  end

  if loopStartPosition() == loopEndPosition() then
    return false
  else
    return true
  end
end

function moveCursor(keepNotesSelected, selectedChord)

  if keepNotesSelected then

    local noteEndPositionInProjTime = reaper.MIDI_GetProjTimeFromPPQPos(activeTake(), selectedChord.longestEndPosition)
    local noteLengthOfSelectedNote = noteEndPositionInProjTime-cursorPosition()

    if loopIsActive() and loopEndPosition() < mediaItemEndPosition() then

      if cursorPosition() + noteLengthOfSelectedNote >= loopEndPosition() - tolerance then

        if loopStartPosition() > mediaItemStartPosition() then
          setEditCursorPosition(loopStartPosition())
        else
          setEditCursorPosition(mediaItemStartPosition())
        end

      else
        
        moveEditCursorPosition(noteLengthOfSelectedNote)  
      end

    elseif loopIsActive() and mediaItemEndPosition() <= loopEndPosition() then 

      if cursorPosition() + noteLengthOfSelectedNote >= mediaItemEndPosition() - tolerance then

        if loopStartPosition() > mediaItemStartPosition() then
          setEditCursorPosition(loopStartPosition())
        else
          setEditCursorPosition(mediaItemStartPosition())
        end

      else
      
        moveEditCursorPosition(noteLengthOfSelectedNote)
      end

    elseif cursorPosition() + noteLengthOfSelectedNote >= mediaItemEndPosition() - tolerance then
      setEditCursorPosition(mediaItemStartPosition())
    else

      moveEditCursorPosition(noteLengthOfSelectedNote)
    end

  else

    if loopIsActive() and loopEndPosition() < mediaItemEndPosition() then

      if cursorPosition() + noteLength() >= loopEndPosition() - tolerance then

        if loopStartPosition() > mediaItemStartPosition() then
          setEditCursorPosition(loopStartPosition())
        else
          setEditCursorPosition(mediaItemStartPosition())
        end

      else
        moveEditCursorPosition(noteLength())
      end

    elseif loopIsActive() and mediaItemEndPosition() <= loopEndPosition() then 

      if cursorPosition() + noteLength() >= mediaItemEndPosition() - tolerance then

        if loopStartPosition() > mediaItemStartPosition() then
          setEditCursorPosition(loopStartPosition())
        else
          setEditCursorPosition(mediaItemStartPosition())
        end

      else
        moveEditCursorPosition(noteLength())
      end

    elseif cursorPosition() + noteLength() >= mediaItemEndPosition() - tolerance then
        setEditCursorPosition(mediaItemStartPosition())
    else

      moveEditCursorPosition(noteLength())
    end

  end

end

--

function getCursorPositionPPQ()
  return reaper.MIDI_GetPPQPosFromProjTime(activeTake(), cursorPosition())
end

local function getCursorPositionQN()
  return reaper.MIDI_GetProjQNFromPPQPos(activeTake(), getCursorPositionPPQ())
end

function getNoteLengthQN()

  local gridLength = reaper.MIDI_GetGrid(activeTake())
  return gridLength
end

function gridUnitLength()

  local gridLengthQN = reaper.MIDI_GetGrid(activeTake())
  local mediaItemPlusGridLengthPPQ = reaper.MIDI_GetPPQPosFromProjQN(activeTake(), mediaItemStartPositionQN() + gridLengthQN)
  local mediaItemPlusGridLength = reaper.MIDI_GetProjTimeFromPPQPos(activeTake(), mediaItemPlusGridLengthPPQ)
  return mediaItemPlusGridLength - mediaItemStartPosition()
end

function getMidiEndPositionPPQ()

  local startPosition = reaper.GetCursorPosition()
  local startPositionPPQ = reaper.MIDI_GetPPQPosFromProjTime(activeTake(), startPosition)
  local endPositionPPQ = reaper.MIDI_GetPPQPosFromProjTime(activeTake(), startPosition+gridUnitLength())
  return endPositionPPQ
end

function deselectAllNotes()

  local selectAllNotes = false
  reaper.MIDI_SelectAll(activeTake(), selectAllNotes)
end

function getCurrentNoteChannel(channelArg)

  if channelArg ~= nil then
    return channelArg
  end

  if activeMidiEditor() == nil then
    return 0
  end

  return reaper.MIDIEditor_GetSetting_int(activeMidiEditor(), "default_note_chan")
end

function getCurrentVelocity()

  if activeMidiEditor() == nil then
    return 96
  end

  return reaper.MIDIEditor_GetSetting_int(activeMidiEditor(), "default_note_vel")
end

function getNumberOfNotes()

  local _, numberOfNotes = reaper.MIDI_CountEvts(activeTake())
  return numberOfNotes
end

function deleteNote(noteIndex)

  reaper.MIDI_DeleteNote(activeTake(), noteIndex)
end

function thereAreNotesSelected()

  if activeTake() == nil then
    return false
  end

  local numberOfNotes = getNumberOfNotes()

  for noteIndex = 0, numberOfNotes-1 do

    local _, noteIsSelected = reaper.MIDI_GetNote(activeTake(), noteIndex)

    if noteIsSelected then
      return true
    end
  end

  return false
end

function halveGridSize()

  if activeTake() == nil then
    return
  end

  local gridSize = reaper.MIDI_GetGrid(activeTake())/4

  if gridSize <= 1/1024 then
    return
  end

  local activeProjectIndex = 0
  reaper.SetMIDIEditorGrid(activeProjectIndex, gridSize/2)
end

function doubleGridSize()

  if activeTake() == nil then
    return
  end

  local gridSize = reaper.MIDI_GetGrid(activeTake())/4

  if gridSize >= 1024 then
    return
  end

  local activeProjectIndex = 0
  reaper.SetMIDIEditorGrid(activeProjectIndex, gridSize*2)
end

--

function deleteExistingNotesInNextInsertionTimePeriod(keepNotesSelected, selectedChord)

  local insertionStartTime = cursorPosition()

  local insertionEndTime = nil
  
  if keepNotesSelected then
    insertionEndTime = reaper.MIDI_GetProjTimeFromPPQPos(activeTake(), selectedChord.longestEndPosition)
  else
    insertionEndTime = insertionStartTime + noteLength()
  end

  local numberOfNotes = getNumberOfNotes()

  for noteIndex = numberOfNotes-1, 0, -1 do

    local _, _, _, noteStartPositionPPQ = reaper.MIDI_GetNote(activeTake(), noteIndex)
    local noteStartTime = reaper.MIDI_GetProjTimeFromPPQPos(activeTake(), noteStartPositionPPQ)

    if noteStartTime + tolerance >= insertionStartTime and noteStartTime + tolerance <= insertionEndTime then
      deleteNote(noteIndex)
    end
  end
end
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"

function playMidiNote(midiNote)

  local virtualKeyboardMode = 0
  local channel = getCurrentNoteChannel()
  local noteOnCommand = 0x90 + channel
  local velocity = getCurrentVelocity()

  reaper.StuffMIDIMessage(virtualKeyboardMode, noteOnCommand, midiNote, velocity)
end

function stopAllNotesFromPlaying()

  for midiNote = 0, 127 do

    local virtualKeyboardMode = 0
    local channel = getCurrentNoteChannel()
    local noteOffCommand = 0x80 + channel
    local velocity = 0

    reaper.StuffMIDIMessage(virtualKeyboardMode, noteOffCommand, midiNote, velocity)
  end
end

function stopNoteFromPlaying(midiNote)

  local virtualKeyboardMode = 0
  local channel = getCurrentNoteChannel()
  local noteOffCommand = 0x80 + channel
  local velocity = 0

  reaper.StuffMIDIMessage(virtualKeyboardMode, noteOffCommand, midiNote, velocity)
end

function stopNotesFromPlaying()

  local notesThatArePlaying = getNotesThatArePlaying()

  for noteIndex = 1, #notesThatArePlaying do
    stopNoteFromPlaying(notesThatArePlaying[noteIndex])
  end

  setNotesThatArePlaying({})
end
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"

function applyInversion(chord)
  
  local chordLength = #chord

  local selectedScaleNote = getSelectedScaleNote()
  local chordInversionValue = getChordInversionState(selectedScaleNote)
  local chord_ = chord
  local oct = 0  
  
  if chordInversionValue < 0 then
    oct = math.floor(chordInversionValue / chordLength)
    chordInversionValue = chordInversionValue + (math.abs(oct) * chordLength)
  end
  
  for i = 1, chordInversionValue do
    local r = table.remove(chord_, 1)
    r = r + 12
    table.insert(chord_, #chord_ + 1, r )
  end
    
  for i = 1, #chord_ do
    chord_[i] = chord_[i] + (oct * 12)
  end

  return chord_
end

function getChordNotesArray(root, chord, octave)

  local chordLength = 0
  local chordNotesArray = {}
  local chordPattern = chord["pattern"]
  for n = 0, #chordPattern-1 do
    if chordPattern:sub(n+1, n+1) == '1' then
      chordLength = chordLength + 1
      
      local noteValue = root + n + ((octave+1) * 12) - 1
      table.insert(chordNotesArray, noteValue)
    end
  end
  
  chordNotesArray = applyInversion(chordNotesArray)
  
  return chordNotesArray
end
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"

function insertMidiNote(note, keepNotesSelected, selectedChord, noteIndex)

	local startPosition = getCursorPositionPPQ()

	local endPosition = nil
	local velocity = nil
	local channel = nil
	local muteState = nil
	
	if keepNotesSelected then

		local numberOfSelectedNotes = #selectedChord.selectedNotes

		if noteIndex > numberOfSelectedNotes then
			endPosition = selectedChord.selectedNotes[numberOfSelectedNotes].endPosition
			velocity = selectedChord.selectedNotes[numberOfSelectedNotes].velocity
			channel = selectedChord.selectedNotes[numberOfSelectedNotes].channel
			muteState = selectedChord.selectedNotes[numberOfSelectedNotes].muteState
		else
			endPosition = selectedChord.selectedNotes[noteIndex].endPosition
			velocity = selectedChord.selectedNotes[noteIndex].velocity
			channel = selectedChord.selectedNotes[noteIndex].channel
			muteState = selectedChord.selectedNotes[noteIndex].muteState
		end
		
	else
		endPosition = getMidiEndPositionPPQ()
		velocity = getCurrentVelocity()
		channel = getCurrentNoteChannel()
		muteState = false
	end

	local noSort = false

	reaper.MIDI_InsertNote(activeTake(), keepNotesSelected, muteState, startPosition, endPosition, channel, note, velocity, noSort)
end
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"

local function playScaleChord(chordNotesArray)

  stopNotesFromPlaying()
  
  for noteIndex = 1, #chordNotesArray do
    playMidiNote(chordNotesArray[noteIndex])
  end

  setNotesThatArePlaying(chordNotesArray) 
end

function previewScaleChord()

  local scaleNoteIndex = getSelectedScaleNote()
  local chordTypeIndex = getSelectedChordType(scaleNoteIndex)

  local root = scaleNotes[scaleNoteIndex]
  local chord = scaleChords[scaleNoteIndex][chordTypeIndex]
  local octave = getOctave()

  local chordNotesArray = getChordNotesArray(root, chord, octave)
  playScaleChord(chordNotesArray)
  updateChordText(root, chord, chordNotesArray)
end

function insertScaleChord(chordNotesArray, keepNotesSelected, selectedChord)

  deleteExistingNotesInNextInsertionTimePeriod(keepNotesSelected, selectedChord)

  for noteIndex = 1, #chordNotesArray do
    insertMidiNote(chordNotesArray[noteIndex], keepNotesSelected, selectedChord, noteIndex)
  end

  moveCursor(keepNotesSelected, selectedChord)
end

function playOrInsertScaleChord(actionDescription)

  local scaleNoteIndex = getSelectedScaleNote()
  local chordTypeIndex = getSelectedChordType(scaleNoteIndex)

  local root = scaleNotes[scaleNoteIndex]
  local chord = scaleChords[scaleNoteIndex][chordTypeIndex]
  local octave = getOctave()
  
  local chordNotesArray = getChordNotesArray(root, chord, octave)

  if activeTake() ~= nil and notCurrentlyRecording() then

    startUndoBlock()

      if thereAreNotesSelected() then 
        changeSelectedNotesToScaleChords(chordNotesArray)
      else
        insertScaleChord(chordNotesArray, false)
      end

    endUndoBlock(actionDescription)
  end

  playScaleChord(chordNotesArray)
  updateChordText(root, chord, chordNotesArray)
end
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"


local function playScaleNote(noteValue)

  stopNotesFromPlaying()
  playMidiNote(noteValue)
  setNotesThatArePlaying({noteValue})
  setChordText("")
end


function insertScaleNote(noteValue, keepNotesSelected, selectedChord)

	deleteExistingNotesInNextInsertionTimePeriod(keepNotesSelected, selectedChord)

	local noteIndex = 1
	insertMidiNote(noteValue, keepNotesSelected, selectedChord, noteIndex)
	moveCursor(keepNotesSelected, selectedChord)
end

function previewScaleNote(octaveAdjustment)

  local scaleNoteIndex = getSelectedScaleNote()

  local root = scaleNotes[scaleNoteIndex]
  local octave = getOctave()
  local noteValue = root + ((octave+1+octaveAdjustment) * 12) - 1

  playScaleNote(noteValue)
end

function playOrInsertScaleNote(octaveAdjustment, actionDescription)

	local scaleNoteIndex = getSelectedScaleNote()

  local root = scaleNotes[scaleNoteIndex]
  local octave = getOctave()
  local noteValue = root + ((octave+1+octaveAdjustment) * 12) - 1

  if activeTake() ~= nil and notCurrentlyRecording() then

  	startUndoBlock()

		  if thereAreNotesSelected() then 
		    changeSelectedNotesToScaleNotes(noteValue)
		  else
		    insertScaleNote(noteValue, false)
		  end

		endUndoBlock(actionDescription)
  end

	playScaleNote(noteValue)
end
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"

SelectedNote = {}
SelectedNote.__index = SelectedNote

function SelectedNote:new(endPosition, velocity, channel, muteState, pitch)
  local self = {}
  setmetatable(self, SelectedNote)

  self.endPosition = endPosition
  self.velocity = velocity
  self.channel = channel
  self.muteState = muteState
  self.pitch = pitch

  return self
end

SelectedChord = {}
SelectedChord.__index = SelectedChord

function SelectedChord:new(startPosition, endPosition, velocity, channel, muteState, pitch)
  local self = {}
  setmetatable(self, SelectedChord)

  self.startPosition = startPosition
  self.longestEndPosition = endPosition

  self.selectedNotes = {}
  table.insert(self.selectedNotes, SelectedNote:new(endPosition, velocity, channel, muteState, pitch))

  return self
end



local function noteStartPositionDoesNotExist(selectedChords, startPositionArg)

	for index, selectedChord in pairs(selectedChords) do

		if selectedChord.startPosition == startPositionArg then
			return false
		end
	end

	return true
end

local function updateSelectedChord(selectedChords, startPositionArg, endPositionArg, velocityArg, channelArg, muteStateArg, pitchArg)

	for index, selectedChord in pairs(selectedChords) do

		if selectedChord.startPosition == startPositionArg then

			table.insert(selectedChord.selectedNotes, SelectedNote:new(endPositionArg, velocityArg, channelArg, muteStateArg, pitchArg))

			if endPositionArg > selectedChord.longestEndPosition then
				selectedChord.longestEndPosition = endPositionArg
			end

		end
	end
end

local function getSelectedChords()

	local numberOfNotes = getNumberOfNotes()
	local selectedChords = {}

	for noteIndex = 0, numberOfNotes-1 do

		local _, noteIsSelected, muteState, noteStartPositionPPQ, noteEndPositionPPQ, channel, pitch, velocity = reaper.MIDI_GetNote(activeTake(), noteIndex)

		if noteIsSelected then

			if noteStartPositionDoesNotExist(selectedChords, noteStartPositionPPQ) then
				table.insert(selectedChords, SelectedChord:new(noteStartPositionPPQ, noteEndPositionPPQ, velocity, channel, muteState, pitch))
			else
				updateSelectedChord(selectedChords, noteStartPositionPPQ, noteEndPositionPPQ, velocity, channel, muteState, pitch)
			end
		end
	end

	for selectedChordIndex = 1, #selectedChords do
		table.sort(selectedChords[selectedChordIndex].selectedNotes, function(a,b) return a.pitch < b.pitch end)
	end

	return selectedChords
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

	local selectedChords = getSelectedChords()
	deleteSelectedNotes()
	
	for i = 1, #selectedChords do
		setEditCursorTo(selectedChords[i].startPosition)
		insertScaleChord(chordNotesArray, true, selectedChords[i])
	end
end

function changeSelectedNotesToScaleNotes(noteValue)

	local selectedChords = getSelectedChords()
	deleteSelectedNotes()

	for i = 1, #selectedChords do
		setEditCursorTo(selectedChords[i].startPosition)
		insertScaleNote(noteValue, true, selectedChords[i])
	end
end
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"

scaleNotes = {}
scaleChords = {}

scalePattern = nil

chordButtons = {}

function getNotesString(chordNotesArray)

  local notesString = ''
  for i, note in ipairs(chordNotesArray) do
        
    local noteName = getNoteName(note+1)
    
    if i ~= #chordNotesArray then
      notesString = notesString .. noteName .. ','
    else
      notesString = notesString .. noteName .. ''
    end
  end
  
  return notesString
end

--------------------------------------------------------------------------------

function updateScaleNotes()

  scaleNotes = {}

  local scaleNoteIndex = 1
  for note = getScaleTonicNote(), getScaleTonicNote() + 11 do
  
    if noteIsInScale(note) then
      scaleNotes[scaleNoteIndex] = note
      scaleNoteIndex = scaleNoteIndex + 1
    end
  end
end

function updateScaleChords()

  scaleChords = {}

  local scaleNoteIndex = 1
  for note = getScaleTonicNote(), getScaleTonicNote() + 11 do
  
    if noteIsInScale(note) then
      scaleChords[scaleNoteIndex] = getScaleChordsForRootNote(note)
      scaleNoteIndex = scaleNoteIndex + 1
    end
  end
end

function removeFlatsAndSharps(arg)
  return arg:gsub('b',''):gsub('#','')
end

function aNoteIsRepeated()

  local numberOfScaleNoteNames = 7
  local previousScaleNoteName = getScaleNoteName(numberOfScaleNoteNames)
  local scaleNoteName = nil

  for scaleDegree = 1,  numberOfScaleNoteNames do

    scaleNoteName = getScaleNoteName(scaleDegree)

    if removeFlatsAndSharps(scaleNoteName) == removeFlatsAndSharps(previousScaleNoteName) then
      return true
    end

    previousScaleNoteName = scaleNoteName
  end

  return false
end

function updateScaleNoteNames()
  
  local previousScaleNoteName = getSharpNoteName(getScaleTonicNote() + 11)
  local scaleNoteName = nil
  
  local scaleDegree = 1
  for note = getScaleTonicNote(), getScaleTonicNote() + 11 do
  
    if scalePattern[getNotesIndex(note)] then

      scaleNoteName = getSharpNoteName(note) 
      setScaleNoteName(scaleDegree, scaleNoteName)      
      scaleDegree = scaleDegree + 1
      previousScaleNoteName = scaleNoteName
    end
  end
  
  if aNoteIsRepeated() then
  
    local previousScaleNoteName = getFlatNoteName(getScaleTonicNote() + 11)
    local scaleNoteName = nil
    
    local scaleDegree = 1
    for note = getScaleTonicNote(), getScaleTonicNote() + 11 do
    
      if scalePattern[getNotesIndex(note)] then
            
        scaleNoteName = getFlatNoteName(note)        
        setScaleNoteName(scaleDegree, scaleNoteName)      
        scaleDegree = scaleDegree + 1
        previousScaleNoteName = scaleNoteName
      end
    end
  end
end

function updateScaleNotesText()
  
  local scaleNotesText = ''
  
  for i = 1, #scaleNotes do
    if scaleNotesText ~= '' then 
      scaleNotesText = scaleNotesText .. ', '
    end
    
    scaleNotesText = scaleNotesText .. getScaleNoteName(i)
  end

  setScaleNotesText(scaleNotesText)
end

function getChordInversionText(chordNotesArray)

  local selectedScaleNote = getSelectedScaleNote()
  local inversionValue = getChordInversionState(selectedScaleNote)
  
  if inversionValue == 0 then
    return ''
  end
  
  if math.fmod(inversionValue, #chordNotesArray) == 0 then
    return ''
  end
    
  return '/' .. getNoteName(chordNotesArray[1]+1)
end

function getChordInversionOctaveIndicator(numberOfChordNotes)

  local selectedScaleNote = getSelectedScaleNote()
  local inversionValue = getChordInversionState(selectedScaleNote)

  local octaveIndicator = nil
   
  if inversionValue > 0 then
  
    local offsetValue = math.floor(inversionValue / numberOfChordNotes)
    
    if offsetValue > 0 then
      return '+' .. offsetValue
    else
      return '+'
    end
  
  elseif inversionValue < 0 then
  
    local offsetValue = math.abs(math.ceil(inversionValue / numberOfChordNotes))
    
    if offsetValue > 0 then
      return '-' .. offsetValue
    else  
      return '-'
    end
  else
    return ''
  end  
end

function updateChordText(root, chord, chordNotesArray)
  
  local rootNoteName = getNoteName(root)
  local chordInversionText = getChordInversionText(chordNotesArray)
  local chordInversionOctaveIndicator = getChordInversionOctaveIndicator(#chordNotesArray)
  local chordString = rootNoteName .. chord["display"]
  local notesString = getNotesString(chordNotesArray)

  local chordTextValue = ''
  if string.match(chordInversionOctaveIndicator, "-") then
    chordTextValue = ("%s%12s%s%12s"):format(chordInversionOctaveIndicator, chordString, chordInversionText, notesString)
  elseif string.match(chordInversionOctaveIndicator, "+") then
    chordTextValue = ("%s%12s%s%12s%12s"):format('', chordString, chordInversionText, notesString, chordInversionOctaveIndicator)
  else
    chordTextValue = ("%s%12s%s%12s"):format('', chordString, chordInversionText, notesString)
  end

  setChordText(chordTextValue)
  
  showChordText()
end

function showChordText()

  local chordText = getChordText()
  reaper.Help_Set(chordText, false)
end

function updateScaleData()

  scalePattern = getScalePattern(getScaleTonicNote(), scales[getScaleType()])
  updateScaleNotes()
  updateScaleNoteNames()
  updateScaleNotesText()
  updateScaleChords()
  updateScaleDegreeHeaders()
end

function showScaleStatus()

  local scaleTonicText =  notes[getScaleTonicNote()]
  local scaleTypeText = scales[getScaleType()].name
  local scaleNotesText = getScaleNotesText()
  reaper.Help_Set(("%s %s: %s"):format(scaleTonicText, scaleTypeText, scaleNotesText), false)
end
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"

local function transposeSelectedNotes(numberOfSemitones)

  local numberOfNotes = getNumberOfNotes()

  for noteIndex = numberOfNotes-1, 0, -1 do

    local _, noteIsSelected, muteState, noteStartPositionPPQ, noteEndPositionPPQ, channel, pitch, velocity = reaper.MIDI_GetNote(activeTake(), noteIndex)
  
    if noteIsSelected then
      deleteNote(noteIndex)
      local noSort = false
      reaper.MIDI_InsertNote(activeTake(), noteIsSelected, muteState, noteStartPositionPPQ, noteEndPositionPPQ, channel, pitch+numberOfSemitones, velocity, noSort)
    end
  end
end

function transposeSelectedNotesUpOneOctave()
  transposeSelectedNotes(12)
end

function transposeSelectedNotesDownOneOctave()
  transposeSelectedNotes(-12)
end
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"

local function decrementChordInversion()

	local selectedScaleNote = getSelectedScaleNote()

  local chordInversionMin = getChordInversionMin()
  local chordInversion = getChordInversionState(selectedScaleNote)

  if chordInversion <= chordInversionMin then
    return
  end

  setChordInversionState(selectedScaleNote, chordInversion-1)
end

function decrementChordInversionAction()

	local actionDescription = "decrement chord inversion"
	decrementChordInversion()

	if thereAreNotesSelected() then
		playOrInsertScaleChord(actionDescription)
	else
		previewScaleChord()
	end
end

--

local function incrementChordInversion()

	local selectedScaleNote = getSelectedScaleNote()

  local chordInversionMax = getChordInversionMax()
  local chordInversion = getChordInversionState(selectedScaleNote)

  if chordInversion >= chordInversionMax then
    return
  end


  setChordInversionState(selectedScaleNote, chordInversion+1)
end

function incrementChordInversionAction()

	local actionDescription = "increment chord inversion"
	incrementChordInversion()

	if thereAreNotesSelected() then
		playOrInsertScaleChord(actionDescription)
	else
		previewScaleChord()
	end
end

--

local function decrementChordType()

	local selectedScaleNote = getSelectedScaleNote()
	local selectedChordType = getSelectedChordType(selectedScaleNote)

  if selectedChordType <= 1 then
    return
  end

  setSelectedChordType(selectedScaleNote, selectedChordType-1)
end

function decrementChordTypeAction()

	local actionDescription = "decrement chord type"
	decrementChordType()

	if thereAreNotesSelected() then
		playOrInsertScaleChord(actionDescription)
	else
		previewScaleChord()
	end
end

--

local function incrementChordType()

	local selectedScaleNote = getSelectedScaleNote()
	local selectedChordType = getSelectedChordType(selectedScaleNote)

  if selectedChordType >= #chords then
    return
  end

  setSelectedChordType(selectedScaleNote, selectedChordType+1)
end

function incrementChordTypeAction()

	local actionDescription = "increment chord type"
	incrementChordType()

	if thereAreNotesSelected() then
		playOrInsertScaleChord(actionDescription)
	else
		previewScaleChord()
	end
end

--

function playTonicNote()

  local root = scaleNotes[1]
  local octave = getOctave()
  local noteValue = root + ((octave+1) * 12) - 1

  stopNotesFromPlaying()
  playMidiNote(noteValue)
  setNotesThatArePlaying({noteValue})
end

local function decrementOctave()

  local octave = getOctave()

  if octave <= getOctaveMin() then
    return
  end

  setOctave(octave-1)
end

function decrementOctaveAction()

	decrementOctave()

	if thereAreNotesSelected() then
		startUndoBlock()
		transposeSelectedNotesDownOneOctave()
		endUndoBlock("decrement octave")
	else
		playTonicNote()
	end
end

--

local function incrementOctave()

  local octave = getOctave()

  if octave >= getOctaveMax() then
    return
  end

  setOctave(octave+1)
end

function incrementOctaveAction()

	incrementOctave()

	if thereAreNotesSelected() then
		startUndoBlock()
		transposeSelectedNotesUpOneOctave()
		endUndoBlock("increment octave")
	else
		playTonicNote()
	end
end

--

local function decrementScaleTonicNote()

	local scaleTonicNote = getScaleTonicNote()

	if scaleTonicNote <= 1 then
		return
	end

	setScaleTonicNote(scaleTonicNote-1)
end

function decrementScaleTonicNoteAction()

	decrementScaleTonicNote()

	setSelectedScaleNote(1)
	setChordText("")
	resetSelectedChordTypes()
	resetChordInversionStates()
	updateScaleData()
	updateScaleDegreeHeaders()
	showScaleStatus()
end

--

local function incrementScaleTonicNote()

	local scaleTonicNote = getScaleTonicNote()

	if scaleTonicNote >= #notes then
		return
	end

	setScaleTonicNote(scaleTonicNote+1)
end

function incrementScaleTonicNoteAction()

	incrementScaleTonicNote()

	setSelectedScaleNote(1)
	setChordText("")
	resetSelectedChordTypes()
	resetChordInversionStates()
	updateScaleData()
	updateScaleDegreeHeaders()
	showScaleStatus()
end

--

local function decrementScaleType()

	local scaleType = getScaleType()

	if scaleType <= 1 then
		return
	end

	setScaleType(scaleType-1)
	
end

function decrementScaleTypeAction()

	decrementScaleType()

	setSelectedScaleNote(1)
	setChordText("")
	resetSelectedChordTypes()
	resetChordInversionStates()
	updateScaleData()
	updateScaleDegreeHeaders()
	showScaleStatus()
end

--

local function incrementScaleType()

	local scaleType = getScaleType()

	if scaleType >= #scales then
		return
	end

	setScaleType(scaleType+1)
end

function incrementScaleTypeAction()

	incrementScaleType()

	setSelectedScaleNote(1)
	setChordText("")
	resetSelectedChordTypes()
	resetChordInversionStates()
	updateScaleData()
	updateScaleDegreeHeaders()
	showScaleStatus()
end

----

local function scaleIsPentatonic()

	local scaleType = getScaleType()
	local scaleTypeName = string.lower(scales[scaleType].name)
	return string.match(scaleTypeName, "pentatonic")
end


function scaleChordAction(scaleNoteIndex)

	if scaleIsPentatonic() and scaleNoteIndex > 5 then
		return
	end

	setSelectedScaleNote(scaleNoteIndex)

	local selectedChordType = getSelectedChordType(scaleNoteIndex)
	local chord = scaleChords[scaleNoteIndex][selectedChordType]
	local actionDescription = "scale chord " .. scaleNoteIndex .. "  (" .. chord.code .. ")"

	playOrInsertScaleChord(actionDescription)
end

function previewScaleChordAction(scaleNoteIndex)

	if scaleIsPentatonic() and scaleNoteIndex > 5 then
		return
	end

	setSelectedScaleNote(scaleNoteIndex)
	previewScaleChord()
end

--

function scaleNoteAction(scaleNoteIndex)

	if scaleIsPentatonic() and scaleNoteIndex > 5 then
		return
	end

	setSelectedScaleNote(scaleNoteIndex)
	local actionDescription = "scale note " .. scaleNoteIndex
	playOrInsertScaleNote(0, actionDescription)
end

--

function lowerScaleNoteAction(scaleNoteIndex)

	if scaleIsPentatonic() and scaleNoteIndex > 5 then
		return
	end

  if getOctave() <= getOctaveMin() then
    return
  end

	setSelectedScaleNote(scaleNoteIndex)
	local actionDescription = "lower scale note " .. scaleNoteIndex
	playOrInsertScaleNote(-1, actionDescription)
end

--

function higherScaleNoteAction(scaleNoteIndex)

	if scaleIsPentatonic() and scaleNoteIndex > 5 then
		return
	end

  if getOctave() >= getOctaveMax() then
    return
  end

	setSelectedScaleNote(scaleNoteIndex)
	local actionDescription = "higher scale note " .. scaleNoteIndex
	playOrInsertScaleNote(1, actionDescription)
end


--

function previewScaleNoteAction(scaleNoteIndex)

	if scaleIsPentatonic() and scaleNoteIndex > 5 then
		return
	end

	setSelectedScaleNote(scaleNoteIndex)
	previewScaleNote(0)
end

function previewLowerScaleNoteAction(scaleNoteIndex)

	if scaleIsPentatonic() and scaleNoteIndex > 5 then
		return
	end

	if getOctave() <= getOctaveMin() then
		return
	end

	setSelectedScaleNote(scaleNoteIndex)
	previewScaleNote(-1)
end

function previewHigherScaleNoteAction(scaleNoteIndex)

	if scaleIsPentatonic() and scaleNoteIndex > 5 then
		return
	end

	if getOctave() >= getOctaveMax() then
		return
	end

	setSelectedScaleNote(scaleNoteIndex)
	previewScaleNote(1)
end
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"


updateScaleData()
decrementScaleTonicNoteAction()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
