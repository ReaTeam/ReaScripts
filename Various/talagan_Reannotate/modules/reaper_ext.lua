-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local function IsEnvelopeVisible(envelope)
  local _, env_vis = reaper.GetSetEnvelopeInfo_String(envelope, "VISIBLE", "", false)
  return env_vis == "1"
end

local function IsTrackVisibleInTcp(track, is_master)
  if is_master then
    return (reaper.GetMasterTrackVisibility() & 1 ~= 0)
  end
  return (reaper.IsTrackVisible(track, false))
end

local function IsTrackVisibleInMcp(track, is_master)
  if is_master then
    return (reaper.GetMasterTrackVisibility() & 2 == 0)
  end
  return (reaper.IsTrackVisible(track, true))
end

local function IsTrackPinned(track)
  return reaper.GetMediaTrackInfo_Value(track, "B_TCPPIN") == 1
end

return {
    IsEnvelopeVisible       = IsEnvelopeVisible,
    IsTrackPinned           = IsTrackPinned,
    IsTrackVisibleInTcp     = IsTrackVisibleInTcp,
    IsTrackVisibleInMcp     = IsTrackVisibleInMcp
}
