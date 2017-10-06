-- @description amagalma_Select all visible pooled instances of selected automation items in project
-- @version 1.0
-- @about
--   # Selects all the pooled duplicates of the selected automation items across all tracks
--   - Automation items must exist in the same kind of envelope

--------------------------------------------------------------------------------------------

local reaper = reaper
local undo_name = "Select all visible pooled instances of selected automation items in project"
local sel_env = reaper.GetSelectedEnvelope( 0 )
local track_cnt = reaper.CountSelectedTracks( 0 )
-- proceed if there is a selected envelope
if sel_env then
  local _, envchunk = reaper.GetEnvelopeStateChunk( sel_env, "", false )
  local env_name = string.match (envchunk, "[^\n]+")
  local sel_env_track = reaper.Envelope_GetParentTrack( sel_env )
  local ai_cnt = reaper.CountAutomationItems( sel_env )
  local pools = {}
  local pool_id
  -- get all different pool IDs for selected automation items
  for i = 0, ai_cnt-1 do
    local sel = reaper.GetSetAutomationItemInfo( sel_env, i, "D_UISEL" , 0, false )
    if sel ~= 0 then
      pool_id = reaper.GetSetAutomationItemInfo( sel_env, i, "D_POOL_ID" , 0, false )
      if #pools > 0 then
        for p = 1, #pools do
          if pool_id == pools[p] then
            found = true
          end
        end
        if not found then pools[#pool+1] = pool_id end
      else
        pools[1] = pool_id
      end
    end
  end
  -- search in all equivalent visible envelopes of all tracks to find pooled duplicates
  for i = 0, track_cnt-1 do
    local track = reaper.GetSelectedTrack( 0, i )
    local env = reaper.GetTrackEnvelopeByChunkName( track, env_name )
    if env then
      local count = reaper.CountAutomationItems( env )
      for it = 0, count-1 do
        local pool_id = reaper.GetSetAutomationItemInfo( env, it, "D_POOL_ID" , 0, false )
        for p = 1, #pools do
          if pool_id == pools[p] then
            reaper.GetSetAutomationItemInfo( env, it, "D_UISEL" , 1, true )
          end
        end
      end
    end
  end
  reaper.Undo_OnStateChangeEx( undo_name, 1, -1 )
end
reaper.UpdateArrange()
