-- @description amagalma_Insert pooled instances of one automation item in time selection for selected tracks and selected envelope
-- @author amagalma
-- @version 1.12
-- @about
--   # Inserts automation items in time selection for the selected tracks and selected envelope
--   - There must be a selected envelope and a time selection set for the script to work

--[[
 * Changelog:
 * v1.12 (2017-10-06)
  + fixed script bug (deleting selected env points) created by the work-around of a Reaper bug
--]]

----------------------------- USER SETTINGS -----------------------------------------------

local removetimesel = 1 -- set to 0 to keep time selection or to 1 to remove it

-------------------------------------------------------------------------------------------

local reaper = reaper
local timeStart, timeEnd = reaper.GetSet_LoopTimeRange( false, false, 0, 0, false )
local sel_env = reaper.GetSelectedEnvelope( 0 )
local track_cnt = reaper.CountSelectedTracks( 0 )
-- proceed if time selection exists and there is a selected envelope
if sel_env and timeStart ~= timeEnd then
  reaper.Undo_BeginBlock2( 0 )
  local _, envchunk = reaper.GetEnvelopeStateChunk( sel_env, "", false )
  local env_name = string.match (envchunk, "[^\n]+")
  local sel_env_track = reaper.Envelope_GetParentTrack( sel_env )
  reaper.Main_OnCommand(40331, 0) -- Envelope: Unselect all points
  reaper.InsertAutomationItem( sel_env, -1, timeStart, timeEnd-timeStart )
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
      local env = reaper.GetTrackEnvelopeByChunkName( track, env_name )
      if env then
        reaper.InsertAutomationItem( env, pool_id, timeStart, timeEnd-timeStart )
      end
    end
  end
  -- the following commands are needed as a work-around for bug: https://forum.cockos.com/showthread.php?t=196794
  reaper.Main_OnCommand(40915, 0) -- Envelope: Insert new point at current position
  reaper.Main_OnCommand(40333, 0) -- Envelope: Delete all selected points
  -- Clear time selection
  if removetimesel == 1 then  
    reaper.GetSet_LoopTimeRange( true, false, 0, 0, false )
  end
  reaper.Undo_EndBlock2( 0, "Insert pooled instances of one automation item for selected tracks", 1|8 )
end
reaper.UpdateArrange()
