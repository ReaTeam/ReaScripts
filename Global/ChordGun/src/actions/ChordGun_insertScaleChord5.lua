-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
insertScaleChordAction(5)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)