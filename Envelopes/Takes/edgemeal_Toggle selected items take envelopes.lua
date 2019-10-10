-- @description Toggle selected items take envelopes
-- @author Edgemeal
-- @version 1.0
-- @about Toggle all selected items take envelopes

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

function Main()
  local takecount = reaper.CountSelectedMediaItems()
  if takecount == 0 then return end
  for i = 0, takecount-1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    if item then
      local take = reaper.GetActiveTake(item)
      if take then
        local env_count = reaper.CountTakeEnvelopes(take)
        if env_count == 0 then return end
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
      end
    end
  end
end

reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.defer(function () end)
