-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
scaleChordAction(2)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)