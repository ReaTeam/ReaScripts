-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


updateScaleData()
incrementChordInversionAction()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)