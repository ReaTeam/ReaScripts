-- @description amagalma_Smart contextual zoom
-- @author amagalma
-- @version 1.0
-- @about
--  # Toggles zoom to objects under mouse or to selected objects if more than one are selected
--  # Can zoom to tracks, items, envelopes, regions or time selection
--  # Mode is stored in projext state so zooming out can be resumed even after loading a saved project
--  # Does not create unecessary undo points
--  # Undo points are created only when (un)hiding Master Track, which is unavoidable

--------------------------------------------------------------------------------

local reaper = reaper
local defheightenv = {} -- stored here are envelope lanes with default height (height = 0)
local defaultheight = 24 + 12*reaper.SNM_GetIntConfigVar("defvzoom", -1)
local trackview = reaper.JS_Window_FindChildByID( reaper.GetMainHwnd(), 1000)
local _, left, top, right, bottom = reaper.JS_Window_GetClientRect( trackview )
local arrange_height = bottom - top
local arrange_width = right - left
local master = reaper.GetMasterTrack( 0 )
-- Get details for what is under mouse cursor
local window, segment, details = reaper.BR_GetMouseCursorContext()
local mouseTrack = reaper.BR_GetMouseCursorContext_Track()
local mouseItem = reaper.BR_GetMouseCursorContext_Item()
local mousePos = reaper.BR_GetMouseCursorContext_Position()
--local mouseEnvelope = reaper.BR_GetMouseCursorContext_Envelope()
local debug = 0
--[[ Get time selection and if mouse is inside
local overTimeSel
local tStart, tEnd = reaper.GetSet_LoopTimeRange2( 0, 0, 0, 0, 0, 0 )
if tStart ~= tEnd then
  overTimeSel = (mousePos >= tStart and mousePos <= tEnd)
end--]]

----------------

local function msg(str)
  if debug == 1 then
    reaper.ClearConsole()
    reaper.ShowConsoleMsg("\n" .. tostring(str) .. "\n")
    local context = reaper.GetCursorContext2( true )
    local w = reaper.JS_Window_Find( "ReaScript console output", true )
    if w then
      reaper.JS_Window_SetForeground( w )
      reaper.SetCursorContext( context, nil )
    end
  end
end

----------------

local function ok(str)
  -- return false if string non-existent
  if str == "" or not str then
    return false
  else
    return true
  end
end

local function boolTOnr(value)
  return value and 1 or 0
end

----------------

local function GetStates()
  local _, savedTCPView = reaper.GetProjExtState( 0, "Smart Zoom", "SavedTCPView" )
  local _, v_scroll = reaper.GetProjExtState( 0, "Smart Zoom", "V_Scroll" )
  local _, arrange = reaper.GetProjExtState( 0, "Smart Zoom", "SavedArrangeView" )
  local _, hType = reaper.GetProjExtState( 0, "Smart Zoom", "hType" )
  local _, vType = reaper.GetProjExtState( 0, "Smart Zoom", "vType" )
  return hType, vType, arrange, savedTCPView, v_scroll
end

----------------

local function GetSelectedTracksinTCP()
  local t = {}
  local seltracks_cnt = reaper.CountSelectedTracks2( 0, true )
  if seltracks_cnt > 0 then
    for i = 0, seltracks_cnt-1 do
      local track = reaper.GetSelectedTrack2(0, i, true)
      local guid = reaper.GetTrackGUID( track )
      t[guid] = track
    end
    t.cnt = seltracks_cnt
  else
    local track, context = reaper.BR_TrackAtMouseCursor()
    if reaper.ValidatePtr2( 0, track, "MediaTrack*" ) and context == 0 then
      local guid = reaper.GetTrackGUID( track )
      t[guid] = track
      reaper.SetTrackSelected( track, true )
      t.cnt = 1
    end
  end
  return t
end

----------------

local function StoreVertical()
  local _, v_scroll = reaper.JS_Window_GetScrollInfo( trackview, "v" )
  local track_data = {}
  local track_cnt = reaper.GetNumTracks()
  for i = 0, track_cnt do
    local tr = reaper.CSurf_TrackFromID( i, false )
    local guid = reaper.GetTrackGUID( tr )
    local height = reaper.GetMediaTrackInfo_Value( tr, "I_HEIGHTOVERRIDE" )
    local vis = reaper.GetMediaTrackInfo_Value( tr, "B_SHOWINTCP" )
    local env_cnt = reaper.CountTrackEnvelopes( tr )
    local trackinfo = string.format("%sh%dv%de%d", guid, height, vis, env_cnt)
    local envelopes = {}
    if env_cnt > 0 then
      for j = 0, env_cnt-1 do
        local envelope = reaper.GetTrackEnvelope( tr, j )
        local _, name = reaper.GetEnvelopeName( envelope, "" )
        local BR_Envelope = reaper.BR_EnvAlloc( envelope, true )
        local _, visible, _, _, laneHeight = reaper.BR_EnvGetProperties( BR_Envelope )
        reaper.BR_EnvFree( BR_Envelope, false )
        -- Double Dagger ‡ , Alt + 0135 -> envelopes separator
        envelopes[j+1] = string.format("%qh%dv%d‡", name, laneHeight, boolTOnr(visible))
      end
      envelopes = table.concat(envelopes)
    else
      envelopes = "nil"
    end
    -- Broken bar ¦ , Alt + 0166 -> tracks separator
    track_data[i+1] = trackinfo .. envelopes .. "¦"
  end
  track_data = table.concat(track_data)
  -- store data in project
  reaper.SetProjExtState( 0, "Smart Zoom", "SavedTCPView", track_data)
  reaper.SetProjExtState( 0, "Smart Zoom", "V_Scroll", v_scroll)
end

----------------

local function RestoreVertical(SavedTCPView)
  local cnt = 0
  for info in SavedTCPView:gmatch("(.-)¦") do
    cnt = cnt + 1
    local guid, height, visible, envelopes, env_info = info:match("(%b{})h(%d+)v(%d+)e(%d+)(.+)")
    local track = cnt ~= 1 and reaper.BR_GetMediaTrackByGUID( 0, guid ) or master
    if track then
      if track ~= master then
        reaper.SetMediaTrackInfo_Value( track, "B_SHOWINTCP", tonumber(visible) )
      else
        local vis = reaper.GetMasterTrackVisibility()
        if visible == "1" then
          if vis == 0 or vis == 2 then
            vis = vis + 1
            reaper.SetMasterTrackVisibility( vis )
          end
        elseif visible == "0" then
          if vis == 1 or vis == 3 then
            vis = vis -1
            reaper.SetMasterTrackVisibility( vis )
          end
        end
        reaper.SetMasterTrackVisibility( vis )
      end
      reaper.SetMediaTrackInfo_Value( track, "I_HEIGHTOVERRIDE", tonumber(height) )
      if envinfo ~= "nil" then
        for i in env_info:gmatch('(.-)‡') do
          local name, env_h, env_v = i:match('"(.-)"h(%d+)v(%d+)')
          local env = reaper.GetTrackEnvelopeByName( track, name )
          if env then
            local _, chunk = reaper.GetEnvelopeStateChunk( env, "", false )
            chunk = string.gsub(chunk, "VIS (%d+)", "VIS " .. env_v)
            chunk = string.gsub(chunk, "LANEHEIGHT (%d+)", "LANEHEIGHT " .. env_h)
            reaper.SetEnvelopeStateChunk( env, chunk, false )
          end
        end
      end
    end
  end
  reaper.SetProjExtState( 0, "Smart Zoom", "SavedTCPView", "" )
  reaper.SetProjExtState( 0, "Smart Zoom", "V_Scroll", "")
end

----------------

local function StoreHorizontal()
  local arr_start, arr_end = reaper.GetSet_ArrangeView2( 0, 0, 0, 0)
  reaper.SetProjExtState( 0, "Smart Zoom", "SavedArrangeView", arr_start .. "-" .. arr_end )
end

----------------

local function ReStoreHorizontal()
  local ok, size = reaper.GetProjExtState( 0, "Smart Zoom", "SavedArrangeView" )
  if ok == 1 and size ~= "" then
    local arr_start, arr_end = size:match("(.+)-(.+)")
    reaper.GetSet_ArrangeView2( 0, 1, 0, 0, tonumber(arr_start) , tonumber(arr_end))
    reaper.SetProjExtState( 0, "Smart Zoom", "SavedArrangeView", "")
  end
end

----------------

local function GetTotalEnvLaneHeight(tracks)
  local totalheight = 0
  local totalenv_cnt = 0
  for guid, track in pairs(tracks) do
    if guid ~= "cnt" then
      local count = reaper.CountTrackEnvelopes( track )
      totalenv_cnt = totalenv_cnt + count
      if count > 0 then
        for i = 0, count-1 do
          local env = reaper.GetTrackEnvelope( track, i )
          local _, chunk = reaper.GetEnvelopeStateChunk( env, "", false )
          local height = tonumber(string.match(chunk, "LANEHEIGHT (%d+) "))
          if height == 0 then
            if not string.match(chunk, "TEMPOENVEX") then -- do not count Tempo Env
              height = defaultheight -- default track/lane height
              defheightenv[#defheightenv+1] = env
            end
          end 
          totalheight = totalheight + height
        end
      end
      if track == master then totalenv_cnt = totalenv_cnt - 1 end -- do not count Tempo Map
    end
  end
  return totalheight, totalenv_cnt
end

----------------

local function ZoomFitTracksTCP(selectedtracks)
  -- take into account the gap between the master and the normal tracks
  local y = (reaper.GetMasterTrackVisibility() & 1 == 1) and ( arrange_height - 7) or arrange_height
  local totalenvheight, totalenv_cnt = GetTotalEnvLaneHeight(selectedtracks)
  local tr_height = ((y - totalenvheight - totalenv_cnt) / selectedtracks.cnt) - 1
  -- Hide unselected tracks and Fit selected tracks to TCP
  local track_cnt = reaper.CountTracks( 0 )
  for i = 0, track_cnt do
    local track = reaper.CSurf_TrackFromID( i, false )
    local guid = reaper.GetTrackGUID( track )
    if not selectedtracks[guid] then
      if track ~= master then
        reaper.SetMediaTrackInfo_Value( track, "B_SHOWINTCP", 0)
      else
        local vis = reaper.GetMasterTrackVisibility()
        if vis == 1 or vis == 3 then vis = vis - 1 end
        reaper.SetMasterTrackVisibility( vis )
      end
    else
      reaper.SetMediaTrackInfo_Value( track, "I_HEIGHTOVERRIDE", tr_height)
    end
  end
  if #defheightenv > 0 then -- fix envelope lanes with default height
    for i = 1, #defheightenv do
      local env = reaper.BR_EnvAlloc( defheightenv[i], false )
      local act, vis, arm, inL, height, sha, _, _, _, _, fad = reaper.BR_EnvGetProperties( env )
      reaper.BR_EnvSetProperties( env, act, vis, arm, inL, defaultheight, sha, fad )
      reaper.BR_EnvFree( env, true )
    end
  end
end

----------------

local function ZoomFitSelectedItemsTCP(mouseTrack, mouseItem)
  local item_cnt = reaper.CountSelectedMediaItems( 0 )
  local tracks = {}
  local cnt = 0
  local min, max = reaper.GetProjectLength( 0 ), 0
  if item_cnt < 1 then
    local guid = reaper.GetTrackGUID( mouseTrack )
    tracks[guid] = mouseTrack
    tracks.cnt = 1
    min = reaper.GetMediaItemInfo_Value( mouseItem, "D_POSITION" )
    max = reaper.GetMediaItemInfo_Value( mouseItem, "D_LENGTH" ) + min
  else
    for i = 0, item_cnt-1 do
      local item = reaper.GetSelectedMediaItem( 0, i )
      local it_st = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      local it_end = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" ) + it_st
      if it_st < min then min = it_st end
      if it_end > max then max = it_end end
      local track = reaper.GetMediaItem_Track( item )
      local guid = reaper.GetTrackGUID( track )
      if not tracks[guid] then
        tracks[guid] = track
        cnt = cnt + 1
      end
    end
    tracks.cnt = cnt
  end
  local len = max - min
  local scrollbar = 18 * (len / arrange_width )
  reaper.GetSet_ArrangeView2( 0, 1, 0, 0, min - len*0.01 , max + len*0.01 + scrollbar)
  ZoomFitTracksTCP(tracks)
end

----------------

local function ZoomToRegion(region)
  local _, _, rgnstart, rgnend = reaper.EnumProjectMarkers( region )
  local rgnlen = rgnend - rgnstart
  local scrollbar = 18 * (rgnlen / arrange_width )
  reaper.GetSet_ArrangeView2( 0, 1, 0, 0, rgnstart - rgnlen*0.01 , rgnend + rgnlen*0.01 + scrollbar)
end

---------------- TOGGLE ZOOM FUNCTIONS ----------------

local function ToggleZoomFitSelectedItemsTCP(mouseTrack, mouseItem)
  local hType, vType, arrange, savedTCPView, v_scroll = GetStates()
  if not ok(hType) and not ok(vType) then -- no zoom active
    StoreVertical()
    StoreHorizontal()
    ZoomFitSelectedItemsTCP(mouseTrack, mouseItem)
    reaper.SetProjExtState( 0, "Smart Zoom", "hType", "items")
    reaper.SetProjExtState( 0, "Smart Zoom", "vType", "items")
    msg("1 Zoom to selected items from no active zoom")
    return 0
  else
    if hType == vType then -- active zoom to sel items
      RestoreVertical(savedTCPView)
      ReStoreHorizontal()
      reaper.SetProjExtState( 0, "Smart Zoom", "hType", "")
      reaper.SetProjExtState( 0, "Smart Zoom", "vType", "")
      msg("2 Exit from zoom to selected items")
      return v_scroll
    else
      if ok(arrange) then -- horizontal zoom active
        StoreVertical()
      elseif ok(savedTCPView) then -- vertical zoom active
        StoreHorizontal()
      end
      ZoomFitSelectedItemsTCP(mouseTrack, mouseItem)
      reaper.SetProjExtState( 0, "Smart Zoom", "hType", "items")
      reaper.SetProjExtState( 0, "Smart Zoom", "vType", "items")
      msg("3 Zoom to selected items from existing horizontal zoom")
      return 0
    end
  end
end

----------------

local function ToggleZoomFitSelectedTracksTCP()
  local hType, vType, arrange, savedTCPView, v_scroll = GetStates()
  if vType == "tracks" then -- active zoom to tracks
    RestoreVertical(savedTCPView)
    reaper.SetProjExtState( 0, "Smart Zoom", "vType", "")
    msg("4 Exit from zoom to selected tracks")
    return v_scroll
  else
    local selectedtracks = GetSelectedTracksinTCP()
    if vType == "items" then -- active zoom to sel items
      local track_cnt = reaper.CountTracks( 0 )
      local vis_cnt = 0
      for i = 0, track_cnt do
        local track = reaper.CSurf_TrackFromID( 0, false )
        if reaper.IsTrackVisible( track, false ) then
          vis_cnt = vis_cnt + 1
        end
      end
      if vis_cnt == 1 then -- only one track visible, exit from sel item zoom
        RestoreVertical(savedTCPView)
        ReStoreHorizontal()
        reaper.SetProjExtState( 0, "Smart Zoom", "hType", "")
        reaper.SetProjExtState( 0, "Smart Zoom", "vType", "")
        msg("5 Exit from zoom to selected items")
        return v_scroll
      else
        msg("6 Zoom to selected track. Keep mode to zoom to selected items")
        ZoomFitTracksTCP(selectedtracks)
        return 0
      end
    elseif not ok(vType) then -- no active vertical zoom
      StoreVertical()
      ZoomFitTracksTCP(selectedtracks)
      reaper.SetProjExtState( 0, "Smart Zoom", "vType", "tracks")
      msg("7 Zoom to selected tracks from no active vertical zoom mode")
      return 0
    end
  end 
end

----------------

local function ToggleZoomtoRegion()
  local _, region = reaper.GetLastMarkerAndCurRegion(0, mousePos)
  if region then
    local hType, vType, arrange, savedTCPView, v_scroll = GetStates()
    if hType == "region" then -- zoom to region is active
      ReStoreHorizontal()
      reaper.SetProjExtState( 0, "Smart Zoom", "hType", "")
      msg("8 Exit zoom to region")
    elseif not ok(hType) then -- no active horizontal zoom
      StoreHorizontal()
      ZoomToRegion(region)
      reaper.SetProjExtState( 0, "Smart Zoom", "hType", "region")
      msg("9 Zoom to region from no active horizontal zoom")
    elseif hType == "items" then -- active zoom to sel items
      ZoomToRegion(region)
      reaper.SetProjExtState( 0, "Smart Zoom", "hType", "region")
      reaper.SetProjExtState( 0, "Smart Zoom", "vType", "tracks")
      msg("10 Zoom to region from selected items mode. Now: region & tracks")
    elseif hType == "timesel" then -- active zoom to time selection
      ZoomToRegion(region)
      reaper.SetProjExtState( 0, "Smart Zoom", "hType", "region")
      msg("11 Zoom to region from time selection mode")
    end
  end
end

----------------

local function ToggleZoomTimeSelection()
  local hType, vType, arrange, savedTCPView, v_scroll = GetStates()
  if hType == "timesel" then -- zoom to time selection is active
    ReStoreHorizontal()
    reaper.SetProjExtState( 0, "Smart Zoom", "hType", "")
    msg("12 Exit zoom to time selection")
  elseif not ok(hType) then -- no active horizontal zoom
    StoreHorizontal()
    reaper.Main_OnCommand(40031, 0) -- View: Zoom time selection
    reaper.SetProjExtState( 0, "Smart Zoom", "hType", "timesel")
    msg("13 Zoom to time selection from no active horizontal zoom mode")
  elseif hType == "items" then -- active zoom to sel items
    reaper.Main_OnCommand(40031, 0) -- View: Zoom time selection
    reaper.SetProjExtState( 0, "Smart Zoom", "hType", "timesel")
    reaper.SetProjExtState( 0, "Smart Zoom", "vType", "tracks")
    msg("14 Zoom to time selection from items mode. Now timesel & tracks")
  elseif hType == "region" then -- active zoom to region
    reaper.Main_OnCommand(40031, 0) -- View: Zoom time selection
    reaper.SetProjExtState( 0, "Smart Zoom", "hType", "timesel")
    msg("15 Zoom to time selection from region mode")
  end
end

----------------

local function ToggleZoomSelEnvelope(envelope)
   ok, toggle = reaper.GetProjExtState( 0, "Smart Zoom", "Envelope" )
  if ok ~= 1 then
    -- SWS/wol: Set selected envelope height to maximum
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_WOL_SETSELENVHMAX'), 0)
    reaper.SetProjExtState( 0, "Smart Zoom", "Envelope", "1" )
    msg("16 Zoom to selected envelope")
  else
    -- SWS/wol: Set selected envelope height to default
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_WOL_SETSELENVHDEF'), 0)
    reaper.SetProjExtState( 0, "Smart Zoom", "Envelope", "" )
    msg("17 Exit zoom to selected envelope")
  end
end


---------------- MAIN FUNCTION ----------------


-- SMART ZOOM TO CONTEXT

reaper.PreventUIRefresh( 1 )
local v_scroll = false

-- TCP track
if string.match(window, "tcp") and string.match(segment, "track") then
  v_scroll = ToggleZoomFitSelectedTracksTCP()
-- ECP track
elseif string.match(window, "tcp") and string.match(segment, "envelope") then
  -- in order this function to work correctly it should not be inside an active PreventUIRefresh state
  reaper.PreventUIRefresh( -1 )
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_MOUSE_L_CLICK"), 0)
  ToggleZoomSelEnvelope()
  reaper.PreventUIRefresh( 1 )
-- Region, Marker & Tempo lanes
elseif string.match(window, "ruler") and not string.match(segment, "timeline") then
  ToggleZoomtoRegion()
-- Timeline
elseif string.match(window, "ruler") and string.match(segment, "timeline") then
  ToggleZoomTimeSelection()
-- Empty arrange
elseif string.match(window, "arrange") and string.match(segment, "track") and string.match(details, "empty") then
  v_scroll = ToggleZoomFitSelectedTracksTCP()
-- Envelope track in arrange
elseif string.match(window, "arrange") and string.match(segment, "envelope") then
  -- in order this function to work correctly it should not be inside an active PreventUIRefresh state
  reaper.PreventUIRefresh( -1 )
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_MOUSE_L_CLICK"), 0)
  ToggleZoomSelEnvelope()
  reaper.PreventUIRefresh( 1 )
-- Item
elseif string.match(window, "arrange") and string.match(segment, "track") and string.match(details, "item") then
  v_scroll = ToggleZoomFitSelectedItemsTCP(mouseTrack, mouseItem)
end
reaper.PreventUIRefresh( -1 )
if v_scroll then
  reaper.TrackList_AdjustWindows( false )
  reaper.JS_Window_SetScrollPos( trackview, "v", tonumber(v_scroll) )
end
reaper.UpdateTimeline()
reaper.defer(function () end ) -- No Undo point creation
-- Undo points will be created when (un)hiding the Master Track. It is unavoidable
