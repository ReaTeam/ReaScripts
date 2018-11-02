-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
scaleChordAction(3)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)