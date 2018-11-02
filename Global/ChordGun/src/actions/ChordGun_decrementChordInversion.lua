-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
decrementChordInversionAction()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)