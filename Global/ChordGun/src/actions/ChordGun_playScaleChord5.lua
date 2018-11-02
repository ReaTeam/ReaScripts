-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
playScaleChordAction(5)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)