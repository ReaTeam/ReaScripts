-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


doubleGridSize()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)