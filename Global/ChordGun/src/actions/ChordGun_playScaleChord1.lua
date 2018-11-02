-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
playScaleChordAction(1)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)