-- @description Select all visible synchronous pooled instances of selected automation items across tracks
-- @version 1.0
-- @about
--   # Selects all the pooled duplicates of the selected automation items across all tracks
--   - Automation items must exist in the same kind of envelope

--------------------------------------------------------------------------------------------

local reaper = reaper
local undo_name = "Select all visible synchronous pooled instances of selected automation items across tracks"
local sel_env = reaper.GetSelectedEnvelope( 0 )
-- proceed if there is a selected envelope
if sel_env then
  local _, envchunk = reaper.GetEnvelopeStateChunk( sel_env, "", false )
  local env_name = string.match (envchunk, "[^\n]+")
  local sel_env_track = reaper.Envelope_GetParentTrack( sel_env )
  local ai_cnt = reaper.CountAutomationItems( sel_env )
  local pools = {}
  local positions = {}
  local pool_id, Start, End
  -- get all different pool IDs and the position of selected automation items
  for i = 0, ai_cnt-1 do
    local sel = reaper.GetSetAutomationItemInfo( sel_env, i, "D_UISEL" , 0, false )
    if sel ~= 0 then
      Start = reaper.GetSetAutomationItemInfo( sel_env, i, "D_POSITION" , 0, false )
      End = Start + reaper.GetSetAutomationItemInfo( sel_env, i, "D_LENGTH" , 0, false )
      positions[#positions+1] = {Start = Start, End = End}
      pool_id = reaper.GetSetAutomationItemInfo( sel_env, i, "D_POOL_ID" , 0, false )
      if #pools > 0 then
        for p = 1, #pools do
          if pool_id == pools[p] then
            found = true
          end
        end
        if not found then pools[#pools+1] = pool_id end
      else
        pools[1] = pool_id
      end
    end
  end
  -- search in all equivalent visible envelopes of all tracks to find pooled duplicates in same time
  reaper.PreventUIRefresh( 1 )
  local track_cnt = reaper.CountTracks( 0 )
  for i = 0, track_cnt-1 do
    local track = reaper.GetTrack( 0, i )
    if track ~= sel_env_track then
      local env = reaper.GetTrackEnvelopeByChunkName( track, env_name )
      if env then
        local count = reaper.CountAutomationItems( env )
        for it = 0, count-1 do
          local pool_id = reaper.GetSetAutomationItemInfo( env, it, "D_POOL_ID" , 0, false )
          for p = 1, #pools do
            if pool_id == pools[p] then
              local Start2 = reaper.GetSetAutomationItemInfo( env, it, "D_POSITION" , 0, false )
              local End2 = Start2 + reaper.GetSetAutomationItemInfo( env, it, "D_LENGTH" , 0, false )
              for k = 1, #positions do
                local Start3 = positions[p].Start
                local End3 = positions[p].End
                if (Start2 >= Start3 and Start2 <= End3-0.1)
                or (End2 >= Start+0.1 and End2 <= End3)
                or (Start2 < Start3 and End2 > End3)
                then
                  reaper.GetSetAutomationItemInfo( env, it, "D_UISEL" , 1, true )
                end
              end
            end
          end
        end
      end
    end
  end
  reaper.PreventUIRefresh( -1 )
  reaper.Undo_OnStateChangeEx( undo_name, 1, -1 )
end
reaper.UpdateArrange()
