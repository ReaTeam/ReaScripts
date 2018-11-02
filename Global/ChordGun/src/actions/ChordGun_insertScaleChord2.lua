-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
insertScaleChordAction(2)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)