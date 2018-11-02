-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
decrementScaleTypeAction()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)