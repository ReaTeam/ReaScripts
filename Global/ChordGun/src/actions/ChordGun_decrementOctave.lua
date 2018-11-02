-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
decrementOctaveAction()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)