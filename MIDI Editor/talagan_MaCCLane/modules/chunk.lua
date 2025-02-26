-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local function getItemChunk(item)

  if not reaper.ValidatePtr(item, "MediaItem*") then
    error("Not a valid MediaItem !!")
  end

  local fastStr = reaper.SNM_CreateFastString("")

  local chunkOK = reaper.SNM_GetSetObjectState(item, fastStr, false, false)
  if not chunkOK then
    return nil
  end

  local chunk = reaper.SNM_GetFastString(fastStr)

  reaper.SNM_DeleteFastString(fastStr)

  return chunk
end

return {
  getItemChunk = getItemChunk
}
