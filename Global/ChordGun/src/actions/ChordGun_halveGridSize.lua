-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/actionFunctions")


halveGridSize()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)