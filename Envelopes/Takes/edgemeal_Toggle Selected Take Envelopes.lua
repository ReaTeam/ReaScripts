-- @description Toggle Selected Take Envelopes
-- @author Edgemeal
-- @version 1.0
-- @link Forum Thread https://forum.cockos.com/showthread.php?t=215558

if not reaper.APIExists("BR_EnvAlloc") then
  reaper.MB('This script requires the SWS extension.','API check', 0)
  return
end
  
function GetLastInView(take, env_count)
  local retval = -1
  for j = 0, env_count-1 do
    local env = reaper.GetTakeEnvelope(take, j)
    local br_env = reaper.BR_EnvAlloc(env, false)
    local active, visible, armed, inLane, laneHeight, defaultShape, _, _, _, _, faderScaling = reaper.BR_EnvGetProperties(br_env) 
    if visible then
      reaper.BR_EnvSetProperties(br_env, active, false, armed, inLane, laneHeight, defaultShape, faderScaling)
      reaper.BR_EnvFree(br_env, true) -- commit changes and 'free' the BR_Env object
      retval = j
    else
      reaper.BR_EnvFree(br_env, false) -- 'free' the BR_Env object   
    end
  end -- next env
  return retval 
end

local item = reaper.GetSelectedMediaItem(0,0)
if item then
  local take = reaper.GetActiveTake(item)
  if take then
    local env_count = reaper.CountTakeEnvelopes(take)
    if env_count == 0 then reaper.defer(function () end) return end -- exit, nothing to do! 
    reaper.PreventUIRefresh(1)
    local ndx = -1
    if env_count == 1 then 
      ndx=0
    else 
      ndx = GetLastInView(take, env_count)
      if (ndx == -1) or (ndx+1 > env_count-1) then ndx=0 else ndx=ndx+1 end
    end  
    local env = reaper.GetTakeEnvelope(take, ndx)
    local br_env = reaper.BR_EnvAlloc(env, false)
    local active, visible, armed, inLane, laneHeight, defaultShape, _, _, _, _, faderScaling = reaper.BR_EnvGetProperties(br_env) 
    reaper.BR_EnvSetProperties(br_env, active, true, armed, inLane, laneHeight, defaultShape, faderScaling)
    reaper.BR_EnvFree(br_env, true)
    reaper.UpdateArrange()
    reaper.PreventUIRefresh(-1) 
  end 
end

reaper.defer(function () end)
