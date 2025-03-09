-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local function getChunk(object, type)
  if not reaper.ValidatePtr(object, type .. "*") then
    error("Not a valid " .. type .. "!!")
  end

  local fastStr = reaper.SNM_CreateFastString("")

  local chunkOK = reaper.SNM_GetSetObjectState(object, fastStr, false, false)
  if not chunkOK then
    return nil
  end

  local chunk = reaper.SNM_GetFastString(fastStr)

  reaper.SNM_DeleteFastString(fastStr)

  return chunk
end

local function getItemChunk(item)
  return getChunk(item, "MediaItem")
end

local function getTrackChunk(track)
  return getChunk(track, "MediaTrack")
end



return {
  getItemChunk  = getItemChunk,
  getTrackChunk = getTrackChunk
}
