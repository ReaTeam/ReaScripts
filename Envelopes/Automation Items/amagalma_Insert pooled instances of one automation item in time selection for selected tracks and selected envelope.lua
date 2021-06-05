-- @description Insert pooled instances of one automation item in time selection for selected tracks and selected envelope
-- @author amagalma
-- @version 1.14
-- @changelog - improved undo creation
-- - updated script info
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Inserts automation items in time selection for the selected tracks and selected envelope
--   - There must be a selected envelope and a time selection set for the script to work
--   - If no other tracks are selected, it inserts an AI in the time selection of the selected envelope
--   - Works with the built-in envelopes only
--   - Smart undo point creation

----------------------------- USER SETTINGS -----------------------------------------------

local removetimesel = 1 -- set to 0 to keep time selection or to 1 to remove it

-------------------------------------------------------------------------------------------

local change, states = "none", 1
local timeStart, timeEnd = reaper.GetSet_LoopTimeRange( false, false, 0, 0, false )
local sel_env = reaper.GetSelectedEnvelope( 0 )
local track_cnt = reaper.CountSelectedTracks( 0 )
-- proceed if time selection exists and there is a selected envelope
if sel_env and timeStart ~= timeEnd then
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh( 1 )
  local _, envchunk = reaper.GetEnvelopeStateChunk( sel_env, "", false )
   env_name = string.match (envchunk, "[^\n]+")
  local sel_env_track = reaper.Envelope_GetParentTrack( sel_env )
  --reaper.Main_OnCommand(40331, 0) -- Envelope: Unselect all points
  reaper.InsertAutomationItem( sel_env, -1, timeStart, timeEnd-timeStart )
  change = "insert"
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
        change = "copy"
      end
    end
  end
  -- Clear time selection
  if removetimesel == 1 then  
    reaper.GetSet_LoopTimeRange( true, false, 0, 0, false )
    states = 1|8
  end
  reaper.PreventUIRefresh( -1 )
  reaper.UpdateArrange()
end

-- Smart undo point creation --------------------------------------------------------------

if change == "insert" then
  reaper.Undo_EndBlock( "Envelope: Insert automation item", states )
elseif change == "copy" then
  reaper.Undo_EndBlock( "AI: Insert pooled instances to selected tracks", states )
else
  reaper.defer(function() end)
end
