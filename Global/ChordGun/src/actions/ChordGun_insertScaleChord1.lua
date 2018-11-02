-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
insertScaleChordAction(1)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)