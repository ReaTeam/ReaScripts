-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
insertScaleChordAction(3)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)