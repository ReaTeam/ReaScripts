-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
scaleChordAction(6)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)