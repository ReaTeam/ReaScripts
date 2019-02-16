-- @noindex

function print(arg)
  reaper.ShowConsoleMsg(tostring(arg) .. "\n")
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
----------------------------------------------
-- Pickle.lua
-- A table serialization utility for lua
-- Steve Dekorte, http://www.dekorte.com, Apr 2000
-- Freeware
----------------------------------------------

function pickle(t)
  return Pickle:clone():pickle_(t)
end

Pickle = {
  clone = function (t) local nt={}; for i, v in pairs(t) do nt[i]=v end return nt end 
}

function Pickle:pickle_(root)
  if type(root) ~= "table" then 
    error("can only pickle tables, not ".. type(root).."s")
  end
  self._tableToRef = {}
  self._refToTable = {}
  local savecount = 0
  self:ref_(root)
  local s = ""

  while #self._refToTable > savecount do
    savecount = savecount + 1
    local t = self._refToTable[savecount]
    s = s.."{\n"
    for i, v in pairs(t) do
        s = string.format("%s[%s]=%s,\n", s, self:value_(i), self:value_(v))
    end
    s = s.."},\n"
  end

  return string.format("{%s}", s)
end

function Pickle:value_(v)
  local vtype = type(v)
  if     vtype == "string" then return string.format("%q", v)
  elseif vtype == "number" then return v
  elseif vtype == "boolean" then return tostring(v)
  elseif vtype == "table" then return "{"..self:ref_(v).."}"
  else --error("pickle a "..type(v).." is not supported")
  end  
end

function Pickle:ref_(t)
  local ref = self._tableToRef[t]
  if not ref then 
    if t == self then error("can't pickle the pickle class") end
    table.insert(self._refToTable, t)
    ref = #self._refToTable
    self._tableToRef[t] = ref
  end
  return ref
end

----------------------------------------------
-- unpickle
----------------------------------------------

function unpickle(s)
  if type(s) ~= "string" then
    error("can't unpickle a "..type(s)..", only strings")
  end
  local gentables = load("return "..s)
  local tables = gentables()
  
  for tnum = 1, #tables do
    local t = tables[tnum]
    local tcopy = {}; for i, v in pairs(t) do tcopy[i] = v end
    for i, v in pairs(tcopy) do
      local ni, nv
      if type(i) == "table" then ni = tables[i[1]] else ni = i end
      if type(v) == "table" then nv = tables[v[1]] else nv = v end
      t[i] = nil
      t[ni] = nv
    end
  end
  return tables[1]
end

local activeProjectIndex = 0
local sectionName = "com.pandabot.CopyAndPasteRhythm"

local rhythmNotesKey = "rhythmNotes"
local scriptIsRunningKey = "scriptIsRunning"

--

local function setValue(key, value)
  reaper.SetProjExtState(activeProjectIndex, sectionName, key, value)
end

local function getValue(key)

  local valueExists, value = reaper.GetProjExtState(activeProjectIndex, sectionName, key)

  if valueExists == 0 then
    return nil
  end

  return value
end


--[[ ]]--

function getRhythmNotesFromPreferences()

	local pickledValue = getValue(rhythmNotesKey)

	if pickledValue == nil then
		return nil
	end

  return unpickle(pickledValue)
end

function setRhythmNotesInPreferences(arg)
  setValue(rhythmNotesKey, pickle(arg))
end

function getFirstSelectedTake()

	local activeProjectIndex = 0
	local selectedItemIndex = 0
	local selectedMediaItem = reaper.GetSelectedMediaItem(activeProjectIndex, selectedItemIndex)

	if selectedMediaItem == nil then
		return nil
	end

	return reaper.GetActiveTake(selectedMediaItem)
end

function getNumberOfSelectedItems()
	
	local activeProjectIndex = 0
	return reaper.CountSelectedMediaItems(activeProjectIndex)
end

function getNumberOfNotes(mediaItemTake)

  local _, numberOfNotes = reaper.MIDI_CountEvts(mediaItemTake)
  return numberOfNotes
end

function getCurrentChannel(channelArg)

  if channelArg ~= nil then
    return channelArg
  end

  return 0
end

function getCurrentVelocity(velocityArg)

	if velocityArg ~= nil then
    return velocityArg
  end

  return 96
end

function insertMidiNote(selectedTake, startingPositionArg, endingPositionArg, noteChannelArg, notePitchArg, noteVelocityArg)

	local keepNotesSelected = false
	local noteIsMuted = false

	local channel = getCurrentChannel(noteChannelArg)
	local velocity = getCurrentVelocity(noteVelocityArg)

	local noSort = false

	reaper.MIDI_InsertNote(selectedTake, keepNotesSelected, noteIsMuted, startingPositionArg, endingPositionArg, channel, notePitchArg, velocity, noSort)
end

local function getRhythmNoteIndex(rhythmNotes, startingNotePosition, endingNotePosition)

	for i = 1, #rhythmNotes do

		local rhythmNote = rhythmNotes[i]
		local rhythmNotePositions = rhythmNote[1]

	  if rhythmNotePositions[1] == startingNotePosition and rhythmNotePositions[2] == endingNotePosition then
	  	return i
	  end
	end

  return nil
end


-- rhythmNote
-- {{startPosition, endPosition}, {channels}, {velocities}}
-- if there are more notes on the destination then get the default channel/velocity

local function getRhythmNotes(firstSelectedTake)

	local numberOfNotes = getNumberOfNotes(firstSelectedTake)
	local rhythmNotes = {}

	for noteIndex = 0, numberOfNotes-1 do

		local _, noteIsSelected, noteIsMuted, noteStartPositionPPQ, noteEndPositionPPQ, noteChannel, notePitch, noteVelocity  = reaper.MIDI_GetNote(firstSelectedTake, noteIndex)
	
		if not (noteStartPositionPPQ == 0 and noteEndPositionPPQ == 0) then

			local rhythmNoteIndex = getRhythmNoteIndex(rhythmNotes, noteStartPositionPPQ, noteEndPositionPPQ)

			if rhythmNoteIndex == nil then
				local rhythmNote = {}

				local rhythmNotePositions = {}
				table.insert(rhythmNotePositions, noteStartPositionPPQ)
				table.insert(rhythmNotePositions, noteEndPositionPPQ)

				local rhythmNoteChannels = {}
				table.insert(rhythmNoteChannels, noteChannel)

				local rhythmNoteVelocities = {}
				table.insert(rhythmNoteVelocities, noteVelocity)

				table.insert(rhythmNote, rhythmNotePositions)
				table.insert(rhythmNote, rhythmNoteChannels)
				table.insert(rhythmNote, rhythmNoteVelocities)

				table.insert(rhythmNotes, rhythmNote)
			else

				local rhythmNote = rhythmNotes[rhythmNoteIndex]

				table.insert(rhythmNote[2], noteChannel)
				table.insert(rhythmNote[3], noteVelocity)
				
				table.insert(rhythmNotes[rhythmNoteIndex], rhythmNote)
			end
		end
	end

	return rhythmNotes
end


--

reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

local firstSelectedTake = getFirstSelectedTake()

if firstSelectedTake == nil then
	return
end


local rhythmNotes = getRhythmNotes(firstSelectedTake)

if rhythmNotes == nil then
	return
end

startUndoBlock()

	setRhythmNotesInPreferences(rhythmNotes)
endUndoBlock("copy rhythm")
