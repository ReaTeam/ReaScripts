-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
playScaleChordAction(2)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)