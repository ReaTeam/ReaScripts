-- @description amagalma_Toggle Select all tracks, items or envelope points under mouse (smart select all)
-- @author amagalma
-- @version 1.3
-- @changelog
--    - Added tempo envelope
--    - Better undo point naming
--    - Re-written in Lua
-- @link https://forum.cockos.com/showthread.php?t=188418
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Toggle select/unselect all tracks/items/envelope points depending on what is under mouse cursor
--   - Requires SWS extension.

local function Tracks()
  if reaper.CountSelectedTracks(0) == reaper.CountTracks(0) then
    reaper.Main_OnCommand(40297, 0) -- Track: Unselect all tracks
  else
    reaper.Main_OnCommand(40296, 0) -- Track: Select all tracks
  end
end

local function Items()
  if reaper.CountSelectedMediaItems(0) == reaper.CountMediaItems(0) then
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect all items
  else
    reaper.Main_OnCommand(40182, 0) -- Item: Select all items
  end
end

local function Points()
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_SEL_ENV_MOUSE"), 0) -- SWS/BR: Select envelope at mouse cursor
  reaper.Main_OnCommand(41595, 0) -- Envelope: Toggle select/unselect all points
end

local function Main()
  local master = reaper.GetMasterTrack(0)
  
  -- Get details for what is under mouse cursor
  local window, segment, details = reaper.BR_GetMouseCursorContext()

  ---------------- MASTER ------------------------
  if reaper.BR_GetMouseCursorContext_Track() == master then
    local tempo_env = reaper.GetTrackEnvelopeByName( master, "Tempo map" )
    if tempo_env then
      local ok, chunk = reaper.GetEnvelopeStateChunk(tempo_env, "", false)
      if ok and chunk:match("\nVIS (%d)") == "1" then
        reaper.Undo_BeginBlock()
        
        local pnt_cnt = reaper.CountEnvelopePoints( tempo_env )
        local sel_cnt = 0 
        for pt = 0, pnt_cnt-1 do
          _, _, _, _, _, selected = reaper.GetEnvelopePoint( tempo_env, pt )
          if selected then
            sel_cnt = sel_cnt + 1
          else
            reaper.SetEnvelopePoint( tempo_env, pt, nil, nil, nil, nil, true, true )
          end
        end
        if sel_cnt == pnt_cnt then -- unselect
          for pt = 0, pnt_cnt-1 do
            reaper.SetEnvelopePoint( tempo_env, pt, nil, nil, nil, nil, false, true )
            unselect = true
          end
        end
        reaper.Envelope_SortPoints( tempo_env )
        reaper.UpdateArrange()
      
        reaper.Undo_EndBlock( (unselect and "Unselect" or "Select" ) .. " all tempo envelope points", 1 )
      end
    end
  
  ---------------- TRACKS ------------------------
  elseif window == "tcp" and (segment == "track" or segment == "empty") then
    Tracks()
  elseif window == "mcp" and segment == "track" then
    Tracks()

  ---------------- ITEMS ------------------------
  elseif window == "arrange" and ( segment == "empty" or (segment == "track"
  and (details == "item" or details == "empty" or details == "item_stretch_marker"))) then
    Items()

  ---------------- ENVELOPES --------------------
  elseif window == "tcp" and segment == "envelope" then
    Points()
  elseif window == "arrange" and (segment == "track" or segment == "envelope")
    and (details == "env_point" or details == "env_segment") then
    Points()
  elseif window == "ruler" and segment == "tempo_lane" then
    Points()
  end

end

Main()
