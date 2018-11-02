-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
playScaleChordAction(7)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)