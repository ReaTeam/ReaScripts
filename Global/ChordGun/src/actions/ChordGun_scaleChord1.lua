-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
scaleChordAction(1)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)