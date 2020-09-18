-- @noindex

local activeProjectIndex = 0

function print(arg)
  reaper.ShowConsoleMsg(tostring(arg) .. "\n")
end

function emptyFunctionToPreventAutomaticCreationOfUndoPoint()
end

function startUndoBlock()
	reaper.Undo_BeginBlock()
end

function endUndoBlock()
	local actionDescription = "pandabot_Isolate items by eighth note"
	reaper.Undo_OnStateChange(actionDescription)
	reaper.Undo_EndBlock(actionDescription, -1)
end

function currentBpm()
	local timePosition = 0
	return reaper.TimeMap2_GetDividedBpmAtTime(activeProjectIndex, timePosition)
end

function lengthOfQuarterNote()
	return 60/currentBpm()
end

function lengthOfEighthNote()
	return lengthOfQuarterNote()/2
end

--

function getIndicesOfSelectedTracks()

	local selectedTrackIndices = {}

	local wantMasterTrack = true
	local numberOfSelectedTracks = reaper.CountSelectedTracks2(activeProjectIndex, wantMasterTrack)

	for i = 0, numberOfSelectedTracks - 1 do

		local selectedTrack = reaper.GetSelectedTrack2(activeProjectIndex, i, wantMasterTrack)
		local trackNumber = reaper.GetMediaTrackInfo_Value(selectedTrack, "IP_TRACKNUMBER")

		if trackNumber == -1 then
			selectedTrackIndices[i+1] = 0.0
		else
			selectedTrackIndices[i+1] = trackNumber
		end
	end

	return selectedTrackIndices
end

function unselectMasterTrack()

	local masterTrack = reaper.GetMasterTrack(activeProjectIndex)
	reaper.SetTrackSelected(masterTrack, false)
end

function unselectAllTracks()

	local commandId = 40297
  reaper.Main_OnCommand(commandId, 0)

  unselectMasterTrack()
end

function restoreTrackSelections(selectedTrackIndices)

	for i = 1, #selectedTrackIndices do

		if selectedTrackIndices[i] == 0 then
			local track = reaper.GetMasterTrack(activeProjectIndex)
			reaper.SetTrackSelected(track, true)
		else
			local track = reaper.GetTrack(activeProjectIndex, selectedTrackIndices[i]-1)
			reaper.SetTrackSelected(track, true)
		end
	end
end

--

function volumeEnvelopeIsNotVisible(trackEnvelope)

	local takeEnvelopesUseProjectTime = true
	local trackEnvelopeObject = reaper.BR_EnvAlloc(trackEnvelope, takeEnvelopesUseProjectTime)

	local active, visible, armed, inLane, laneHeight, defaultShape, minValue, maxValue, centerValue, type, faderScaling = reaper.BR_EnvGetProperties(trackEnvelopeObject, true, true, true, true, 0, 0, 0, 0, 0, 0, true)
	
	local commitChanges = false
	reaper.BR_EnvFree(trackEnvelopeObject, commitChanges)
	
	return visible == false
end

function toggleTrackVolumeEnvelopeVisibility()

	local commandId = 40406
  reaper.Main_OnCommand(commandId, 0)
end

function showVolumeEnvelopes()

	local numberOfSelectedItems = reaper.CountSelectedMediaItems(activeProjectIndex)

	for i = 0, numberOfSelectedItems - 1 do

		local selectedItem = reaper.GetSelectedMediaItem(activeProjectIndex, i)
		local trackOfSelectedItem = reaper.GetMediaItem_Track(selectedItem)
		local trackEnvelope = reaper.GetTrackEnvelopeByName(trackOfSelectedItem, "Volume")

		if volumeEnvelopeIsNotVisible(trackEnvelope) then
			reaper.SetTrackSelected(trackOfSelectedItem, true)
		end
	end

	toggleTrackVolumeEnvelopeVisibility()
	unselectAllTracks()
end

--

function getStartPosition(item)
	local itemPosition = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	return itemPosition
end

function getEndPosition(item)
	local itemPosition = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
	return itemPosition + itemLength
end

--

function startingEnvelopePointIsAtCenterValue(trackEnvelope)

	local timePosition = 0
	local envelopePointIndexAtStart = reaper.GetEnvelopePointByTime(trackEnvelope, timePosition)
	local returnValue, time, value, shape, tension, selected = reaper.GetEnvelopePoint(trackEnvelope, envelopePointIndexAtStart)
	return value == 1.0

end

function linearShape() 				return 0 end
function squareShape() 				return 1 end
function slowStartEndShape() 	return 2 end
function fastStartShape() 		return 3 end
function fastEndShape() 			return 4 end
function bezierShape() 				return 5 end

--

function addEnvelopePoints(trackEnvelope, startPosition, endPosition, noteLength)

	local selected = false
	local noSort = true
	local tension = 0.0

	local minValue = 0.0
	local centerValue = 1.0


	if startPosition == 0.0 then

		if not startingEnvelopePointIsAtCenterValue(trackEnvelope) then
			reaper.InsertEnvelopePoint(trackEnvelope, 0.0, centerValue, linearShape(), tension, selected, noSort)
		end
	
	else

		if startPosition-noteLength < 0.0 then
			reaper.InsertEnvelopePoint(trackEnvelope, 0.0, minValue, fastEndShape(), tension, selected, noSort)
		else

			if startingEnvelopePointIsAtCenterValue(trackEnvelope) then
				reaper.InsertEnvelopePoint(trackEnvelope, 0.0, minValue, linearShape(), tension, selected, noSort)
			end

			reaper.InsertEnvelopePoint(trackEnvelope, startPosition-noteLength, minValue, fastEndShape(), tension, selected, noSort)
		end

		reaper.InsertEnvelopePoint(trackEnvelope, startPosition, centerValue, linearShape(), tension, selected, noSort)
	end

	reaper.InsertEnvelopePoint(trackEnvelope, endPosition, centerValue, fastStartShape(), tension, selected, noSort)
	reaper.InsertEnvelopePoint(trackEnvelope, endPosition+noteLength, minValue, linearShape(), tension, selected, noSort)

	reaper.Envelope_SortPoints(trackEnvelope)
end


function isolateItems()

	local numberOfSelectedItems = reaper.CountSelectedMediaItems(activeProjectIndex)

	for i = 0, numberOfSelectedItems - 1 do

		local selectedItem = reaper.GetSelectedMediaItem(activeProjectIndex, i)
		local trackOfSelectedItem = reaper.GetMediaItem_Track(selectedItem)

		local trackEnvelope = reaper.GetTrackEnvelopeByName(trackOfSelectedItem, "Volume")
		local startPosition = getStartPosition(selectedItem)
		local endPosition = getEndPosition(selectedItem)
		local noteLength = lengthOfEighthNote()
		addEnvelopePoints(trackEnvelope, startPosition, endPosition, noteLength)
	end
end

-----

local numberOfSelectedItems = reaper.CountSelectedMediaItems(activeProjectIndex)

if numberOfSelectedItems == 0 then
	reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
	return
end

startUndoBlock()

	local selectedTrackIndices = getIndicesOfSelectedTracks()
	unselectAllTracks()
	showVolumeEnvelopes()
	isolateItems()
	restoreTrackSelections(selectedTrackIndices)
	reaper.UpdateArrange()

endUndoBlock()