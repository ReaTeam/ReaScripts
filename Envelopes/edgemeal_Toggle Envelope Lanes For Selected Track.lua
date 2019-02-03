-- @description Toggle Envelope Lanes For Selected Track
-- @author Edgemeal
-- @version 1.0
-- @link Forum Thread https://forum.cockos.com/showthread.php?t=215558

if not reaper.APIExists("BR_EnvAlloc") then
  reaper.MB('This script requires the SWS extension.','API check', 0)
  return
end

function GetLastInLane(track, env_count)
  local retval = -1
  for j = 0, env_count-1 do
    local env = reaper.GetTrackEnvelope(track, j)
    local br_env = reaper.BR_EnvAlloc(env, false)
    local active, visible, armed, inLane, laneHeight, defaultShape, _, _, _, _, faderScaling = reaper.BR_EnvGetProperties(br_env)
    if inLane then
      reaper.BR_EnvSetProperties(br_env, active, true, armed, false, laneHeight, defaultShape, faderScaling)
	 reaper.BR_EnvFree(br_env, true) -- commit changes and 'free' the BR_Env object
      retval = j
    else
      reaper.BR_EnvFree(br_env, false) -- 'free' the BR_Env object   
    end
  end -- next env
  return retval
end

local track = reaper.GetSelectedTrack2(0, 0, true) --< Master track support.
if track == nil then reaper.defer(function () end) return end
local env_count = reaper.CountTrackEnvelopes(track)
if env_count == 0 then reaper.defer(function () end) return end

reaper.PreventUIRefresh(1)
local ndx = -1
if env_count == 1 then
  ndx = 0
else
  ndx = GetLastInLane(track,env_count)
  if (ndx == -1) or (ndx+1 > env_count-1) then ndx=0 else ndx=ndx+1 end
end
-- show env in lane
local env = reaper.GetTrackEnvelope(track, ndx)
local br_env = reaper.BR_EnvAlloc(env, false)
local active, visible, armed, inLane, laneHeight, defaultShape, _, _, _, _, faderScaling = reaper.BR_EnvGetProperties(br_env)
reaper.BR_EnvSetProperties(br_env, active, true, armed, true, laneHeight, defaultShape, faderScaling)
reaper.BR_EnvFree(br_env, true) -- commit changes and 'free' the BR_Env object
--  fini --
reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.defer(function () end)
