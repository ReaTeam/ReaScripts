-- @description Toggle visible envelopes inlane for selected track
-- @author Edgemeal
-- @version 1.0

function NextVisibleEnvInLane(tr)
  local env_count = reaper.CountTrackEnvelopes(tr)
  if env_count == 0 then return end
  local nextlane = 0
  local index = 0
  local active_envs = {}
  reaper.PreventUIRefresh(1)
  
  for j = 0, env_count-1 do
    local env = reaper.GetTrackEnvelope(tr, j)
    local br_env = reaper.BR_EnvAlloc(env, false)
    local active, visible, armed, inLane, laneHeight, defaultShape, _, _, _, _, faderScaling = reaper.BR_EnvGetProperties(br_env)
    if visible then
      index = index +1
      if inLane then nextlane = index end
      active_envs[index] = env
    end
    if inLane then -- remove from lane
      reaper.BR_EnvSetProperties(br_env, active, visible, armed, false, laneHeight, defaultShape, faderScaling)
      reaper.BR_EnvFree(br_env, true) -- commit changes and 'free' the BR_Env object
    else
      reaper.BR_EnvFree(br_env, false) -- 'free' the BR_Env object
    end
  end -- next env

  -- show next active env in lane
  if #active_envs > 0 then
    nextlane = nextlane + 1
    if nextlane > #active_envs then nextlane = 1 end
    local br_env = reaper.BR_EnvAlloc(active_envs[nextlane], false)
    local active, visible, armed, inLane, laneHeight, defaultShape, _, _, _, _, faderScaling = reaper.BR_EnvGetProperties(br_env)
    reaper.BR_EnvSetProperties(br_env, active, true, armed, true, laneHeight, defaultShape, faderScaling)
    reaper.BR_EnvFree(br_env, true) -- commit changes and 'free' the BR_Env object
    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()
  end
  reaper.PreventUIRefresh(-1)
end

local track = reaper.GetSelectedTrack2(0, 0, true) --< Master track support.
if track then NextVisibleEnvInLane(track) end
reaper.defer(function () end)