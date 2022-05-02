-- @description Toggle last touched take FX envelope
-- @author Edgemeal
-- @version 1.00
-- @donation Donate https://www.paypal.me/Edgemeal
-- @about If envelope for last touched Take FX parameter does not exist, it will be created and shown.

if not reaper.APIExists('BR_EnvAlloc') then
  reaper.MB('SWS extension is required for this script!', 'Missing API', 0)
  return
end

local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
if retval then
  if (tracknumber >> 16) ~= 0 then -- Item FX
    local show = false
    local track = reaper.CSurf_TrackFromID((tracknumber & 0xFFFF), false)
    local takenumber = (fxnumber >> 16)
    fxnumber = (fxnumber & 0xFFFF)
    local item_index = (tracknumber >> 16)-1
    local item = reaper.GetTrackMediaItem(track, item_index)
    local take = reaper.GetTake(item, takenumber)
    local env = reaper.TakeFX_GetEnvelope(take, fxnumber, paramnumber, false)
    if env == nil then show = true env = reaper.TakeFX_GetEnvelope(take, fxnumber, paramnumber, true) end
    local br_env = reaper.BR_EnvAlloc(env, false)
    local active, visible, armed, inLane, laneHeight, defaultShape, _, _, _, _, faderScaling = reaper.BR_EnvGetProperties(br_env)
    reaper.BR_EnvSetProperties(br_env, active, not visible or show, armed, inLane, laneHeight, defaultShape, faderScaling)
    reaper.BR_EnvFree(br_env, true)
    reaper.UpdateArrange()
  end
end
