-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
insertScaleChordAction(6)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)