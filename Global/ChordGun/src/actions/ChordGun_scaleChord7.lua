-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
scaleChordAction(7)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)