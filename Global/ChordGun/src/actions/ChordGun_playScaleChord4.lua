-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
playScaleChordAction(4)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)