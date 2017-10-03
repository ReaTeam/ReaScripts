-- @description amagalma_Insert pooled instances of one automation item in time selection for selected tracks and selected envelope
-- @author amagalma
-- @version 1.01
-- @about
--   # Inserts automation items in time selection for the selected tracks and selected envelope
--   - There must be a selected envelope and a time selection set for the script to work
--   - Creates undo only if succeded

--[[
 * Changelog:
 * v1.01 (2017-10-03)
  + undo point creation improvement
--]]

-------------------------------------------------------------------------------------------

local reaper = reaper
local done = -1

-------------------------------------------------------------------------------------------

local timeStart, timeEnd = reaper.GetSet_LoopTimeRange( false, false, 0, 0, false )
local sel_env = reaper.GetSelectedEnvelope( 0 )
local track_cnt = reaper.CountSelectedTracks( 0 )
-- proceed if time selection exists and there is a selected envelope
if sel_env and timeStart ~= timeEnd then
  local sel_env_track = reaper.Envelope_GetParentTrack( sel_env )
  reaper.InsertAutomationItem( sel_env, -1, timeStart, timeEnd-timeStart )
  done = 0
  local _, env_name = reaper.GetEnvelopeName( sel_env, "" )
  local ai_cnt =  reaper.CountAutomationItems( sel_env )
  local pool_id
  for i = 0, ai_cnt-1 do
    local pos = reaper.GetSetAutomationItemInfo( sel_env, i, "D_POSITION" , 0, false )
    if pos == timeStart then
      pool_id = reaper.GetSetAutomationItemInfo( sel_env, i, "D_POOL_ID" , 0, false )
    break
    end
  end
  for i = 0, track_cnt-1 do
    local track = reaper.GetSelectedTrack( 0, i )
    if track ~= sel_env_track then
      local env = reaper.GetTrackEnvelopeByName( track, env_name )
      if env then
        reaper.InsertAutomationItem( env, pool_id, timeStart, timeEnd-timeStart )
        done = done + 1
      end
    end
  end
end
reaper.UpdateArrange()

-------------------------------------------------------------------------------------------

if done > 0 then
  reaper.GetSet_LoopTimeRange( true, false, 0, 0, false )
  reaper.Undo_OnStateChangeEx2( 0, "Insert pooled instances of one automation item for selected tracks", 1|8 , -1 )
elseif done == 0 then
  reaper.Undo_OnStateChangeEx2( 0, "Insert automation item", 1 , -1 )
end
