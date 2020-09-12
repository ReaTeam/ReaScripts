-- @noindex

local activeProjectIndex = 0

function print(arg)
  reaper.ShowConsoleMsg(tostring(arg) .. "\n")
end

function startUndoBlock()
	reaper.Undo_BeginBlock()
end

function endUndoBlock()
	local actionDescription = "pandabot_Extend items by eighth note"
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

startUndoBlock()

	local numberOfSelectedItems = reaper.CountSelectedMediaItems(activeProjectIndex)

	for i = 0, numberOfSelectedItems - 1 do

		local selectedItem = reaper.GetSelectedMediaItem(activeProjectIndex, i)
		local selectedItemPosition = reaper.GetMediaItemInfo_Value(selectedItem, "D_POSITION")
		local selectedItemLength = reaper.GetMediaItemInfo_Value(selectedItem, "D_LENGTH")

		local takeIndex = 0
		local selectedItemTake = reaper.GetTake(selectedItem, takeIndex)
		local selectedItemTakeStartOffset = reaper.GetMediaItemTakeInfo_Value(selectedItemTake, "D_STARTOFFS")

		local noteLength = lengthOfEighthNote()

		if selectedItemPosition < noteLength then

			reaper.SetMediaItemInfo_Value(selectedItem, "D_POSITION", selectedItemPosition-selectedItemPosition)
			reaper.SetMediaItemInfo_Value(selectedItem, "D_LENGTH", selectedItemLength + selectedItemPosition + noteLength)
			reaper.SetMediaItemInfo_Value(selectedItem, "D_SNAPOFFSET", selectedItemPosition)
			reaper.SetMediaItemTakeInfo_Value(selectedItemTake, "D_STARTOFFS", selectedItemTakeStartOffset-selectedItemPosition)
			
			reaper.SetMediaItemInfo_Value(selectedItem, "D_FADEINLEN", selectedItemPosition)
			reaper.SetMediaItemInfo_Value(selectedItem, "D_FADEOUTLEN", noteLength)

		else

			reaper.SetMediaItemInfo_Value(selectedItem, "D_POSITION", selectedItemPosition-noteLength)
			reaper.SetMediaItemInfo_Value(selectedItem, "D_LENGTH", selectedItemLength + 2*noteLength)
			reaper.SetMediaItemInfo_Value(selectedItem, "D_SNAPOFFSET", noteLength)
			reaper.SetMediaItemTakeInfo_Value(selectedItemTake, "D_STARTOFFS", selectedItemTakeStartOffset-noteLength)

			reaper.SetMediaItemInfo_Value(selectedItem, "D_FADEINLEN", noteLength)
			reaper.SetMediaItemInfo_Value(selectedItem, "D_FADEOUTLEN", noteLength)
		end

		local fadeOutShape = 4
		reaper.SetMediaItemInfo_Value(selectedItem, "C_FADEINSHAPE", fadeOutShape)
		reaper.SetMediaItemInfo_Value(selectedItem, "C_FADEOUTSHAPE", fadeOutShape)
	end

endUndoBlock()