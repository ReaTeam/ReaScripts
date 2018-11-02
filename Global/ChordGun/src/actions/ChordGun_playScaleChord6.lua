-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
playScaleChordAction(6)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)