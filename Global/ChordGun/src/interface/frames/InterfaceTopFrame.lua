-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/scales")
require(workingDirectory .. "/scaleFunctions")

local windowWidth = 775

scaleNames = {}
for key, scale in ipairs(scales) do
  table.insert(scaleNames, scale['name'])
end

local xMargin = 8
local yMargin = 8
local xPadding = 16
local yPadding = 5

local scaleLabelWidth = nil
local horizontalMargin = 8

local scaleTonicNoteWidth = 50
local scaleTypeWidth = 150

local octaveLabelWidth = nil
local octaveValueBoxWidth = 55

keySelectionFrameHeight = 25
function Interface:addTopFrame()

	self:addFrame(xMargin+dockerXPadding, yMargin, self.width - 2 * xMargin, keySelectionFrameHeight)
	self:addScaleLabel()
	self:addScaleTonicNoteDropdown()
	self:addScaleTypeDropdown()
	self:addScaleNotesTextLabel()
	self:addOctaveLabel()
	self:addOctaveSelectorValueBox()
end

function Interface:addScaleLabel()

	local labelText = "Scale:"
	scaleLabelWidth = gfx.measurestr(labelText)
	local labelXpos = xMargin+xPadding
	local labelYpos = yMargin+yPadding
	local labelHeight = 16
	self:addLabel(labelXpos+dockerXPadding, labelYpos, scaleLabelWidth, labelHeight, function() return labelText end)
end

function Interface:addScaleTonicNoteDropdown()

	local scaleTonicNoteXpos = xMargin+xPadding+scaleLabelWidth+horizontalMargin
	local scaleTonicNoteYpos = yMargin+yPadding+1
	local scaleTonicNoteHeight = 15

	local onScaleTonicNoteSelection = function(i)

		setScaleTonicNote(i)
		setSelectedScaleNote(1)
		setChordText("")
		resetSelectedChordTypes()
		resetChordInversionStates()
		updateScaleData()
		updateScaleDegreeHeaders()
	end

	local scaleTonicNote = getScaleTonicNote()
	self:addDropdown(scaleTonicNoteXpos+dockerXPadding, scaleTonicNoteYpos, scaleTonicNoteWidth, scaleTonicNoteHeight, notes, scaleTonicNote, onScaleTonicNoteSelection)

end

function Interface:addScaleTypeDropdown()

	local scaleTypeXpos = xMargin+xPadding+scaleLabelWidth+scaleTonicNoteWidth+horizontalMargin*1.5
	local scaleTypeYpos = yMargin+yPadding+1
	local scaleTypeHeight = 15

	local onScaleTypeSelection = function(i)

		setScaleType(i)
		setSelectedScaleNote(1)
		setChordText("")
		resetSelectedChordTypes()
		resetChordInversionStates()
		updateScaleData()
		updateScaleDegreeHeaders()
	end
	
	local scaleName = getScaleType()
	self:addDropdown(scaleTypeXpos+dockerXPadding, scaleTypeYpos, scaleTypeWidth, scaleTypeHeight, scaleNames, scaleName, onScaleTypeSelection)
end

function Interface:addScaleNotesTextLabel()

	local getScaleNotesTextCallback = function() return getScaleNotesText() end
	local scaleNotesXpos = xMargin+xPadding+scaleLabelWidth+scaleTonicNoteWidth+scaleTypeWidth+horizontalMargin*2+4
	local scaleNotesYpos = yMargin+yPadding+1
	local scaleNotesWidth = 360
	local scaleNotesHeight = 15
	self:addLabel(scaleNotesXpos+dockerXPadding, scaleNotesYpos, scaleNotesWidth, scaleNotesHeight, getScaleNotesTextCallback)
end

function Interface:addOctaveLabel()

	local labelText = "Octave:"
	octaveLabelWidth = gfx.measurestr(labelText)	
	local labelYpos = yMargin+yPadding+1
	local labelHeight = 15
	local labelXpos = windowWidth - 80 - octaveValueBoxWidth
	self:addLabel(labelXpos+dockerXPadding, labelYpos, octaveLabelWidth, labelHeight, function() return labelText end)
end

function Interface:addOctaveSelectorValueBox()

	local windowWidth = 775
	local valueBoxXPos = windowWidth - octaveValueBoxWidth - xMargin - xPadding + 3
	local valueBoxYPos = yMargin + 6
	local valueBoxHeight = 15
	self:addOctaveValueBox(valueBoxXPos+dockerXPadding, valueBoxYPos, octaveValueBoxWidth, valueBoxHeight)
end