-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
scaleChordAction(4)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)