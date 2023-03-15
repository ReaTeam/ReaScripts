-- @description Float centered exclusively the next FX for the current track
-- @author amagalma
-- @version 1.1
-- @changelog skip offline FX
-- @donation https://www.paypal.me/amagalma
-- @about
--   Closes all open floating FX and FX chains and floats centered in the screen the next FX for the current track (first selected or last touched)
--
--   - works similarly to "SWS/S&M: Float next FX (and close others) for selected tracks" but centers correctly the Master FX and works with last touched track too
--   - FX that are offline are skipped
--   - requires JS_ReaScriptAPI


if not reaper.APIExists( "JS_Window_Find" ) then
  reaper.MB( "Please, right-click and install 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "You need to install the JS_ReaScriptAPI", 0 )
  local ok, err = reaper.ReaPack_AddSetRepository( "ReaTeam Extensions", "https://github.com/ReaTeam/Extensions/raw/master/index.xml", true, 1 )
  if ok then reaper.ReaPack_BrowsePackages( "js_ReaScriptAPI" )
  else reaper.MB( err, "Something went wrong...", 0)
  end
  return reaper.defer(function() end)
end


-- Make sure there is a track
local track = reaper.GetSelectedTrack( 0, 0 ) or reaper.GetLastTouchedTrack()
if not track then return end


function close_tr_fx(tr) -- me2beats function
  local fx = reaper.TrackFX_GetCount(tr)
  for i = 0,fx-1 do
    if reaper.TrackFX_GetOpen(tr, i) then
      reaper.TrackFX_SetOpen(tr, i, 0)
    end
    if reaper.TrackFX_GetChainVisible(tr)~=-1 then
      reaper.TrackFX_Show(tr, 0, 0)
    end
  end
  local rec_fx, i_rec = reaper.TrackFX_GetRecCount(tr)
  for i = 0,rec_fx-1 do
    i_rec = i+16777216
    if reaper.TrackFX_GetOpen(tr, i_rec) then
      reaper.TrackFX_SetOpen(tr, i_rec, 0)
    end
    if reaper.TrackFX_GetRecChainVisible(tr)~=-1 then
      reaper.TrackFX_Show(tr, i_rec, 0)
    end
  end
end

function close_tk_fx(tk) -- me2beats function
  if not tk then return end
  local fx = reaper.TakeFX_GetCount(tk)
  for i = 0,fx-1 do
    if reaper.TakeFX_GetOpen(tk, i) then
      reaper.TakeFX_SetOpen(tk, i, 0)
    end
    if reaper.TakeFX_GetChainVisible(tk)~=-1 then
      reaper.TakeFX_Show(tk, 0, 0)
    end
  end
end

function next_fx(tr)
  local fx_cnt = reaper.TrackFX_GetCount(tr)
  local current = -1
  for i = 0, fx_cnt-1 do
    if reaper.TrackFX_GetOpen(tr, i) then
      reaper.TrackFX_SetOpen(tr, i, 0)
      current = i
    end
  end
  current = current == fx_cnt-1 and 0 or current + 1
  local times = 0
  while reaper.TrackFX_GetOffline( tr, current ) do
    times = times + 1
    current = current == fx_cnt-1 and 0 or current + 1
    if times == fx_cnt then
      current = -1
      break
    end
  end
  if current == -1 then
    reaper.TrackFX_Show( tr, 0, 1 )
    return false
  else
    reaper.TrackFX_Show( tr, current, 3 )
    return true
  end
end


------- MAIN FUNCTION ---------

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh( 1 )
local fx_cnt = reaper.TrackFX_GetCount( track )
local success
if fx_cnt > 0 then -- Do the thing
  local tracks = reaper.CountTracks()
  for i = 0, tracks do
    local tr =  reaper.CSurf_TrackFromID( i, false )
    if tr ~= track then
      close_tr_fx(tr)
    else
      success = next_fx(tr)
    end
    local tr_items = reaper.CountTrackMediaItems(tr)
    for j = 0, tr_items-1 do
      local tr_item = reaper.GetTrackMediaItem(tr, j)
      local takes = reaper.GetMediaItemNumTakes(tr_item)
      for k = 0, takes-1 do
        close_tk_fx(reaper.GetTake(tr_item,k))
      end
    end
  end
  -- Center floating FX
  local hwnd
  if not success then
    if track == reaper.GetMasterTrack( 0 ) then
      hwnd = reaper.JS_Window_Find( "FX: Master Track", true )
    else
      hwnd = reaper.JS_Window_Find( "FX: Track " ..  reaper.CSurf_TrackToID( track, false ), true )
    end
  else
    if track == reaper.GetMasterTrack( 0 ) then
      hwnd = reaper.JS_Window_Find( " - Master Track [", false )
    else
      for i = 0, fx_cnt-1 do
        hwnd = reaper.TrackFX_GetFloatingWindow( track, i )
        if hwnd then break end
      end
    end
  end
  local _, width, height = reaper.JS_Window_GetClientSize( hwnd ) -- Get floating FX size
  local _, _, scrw, scrh = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, 0) -- Get screen size
  reaper.JS_Window_Move( hwnd, math.floor((scrw-width)/2), math.floor((scrh-height)/2) )
  if not success then
    reaper.MB( "All FX are offline for this track.", "Cannot navigate to next FX!", 0 )
  end
else -- open FX Chain to add FX
  reaper.Main_OnCommand(40291, 0) -- Track: View FX chain for current/last touched track
end
reaper.PreventUIRefresh( -1 )
reaper.Undo_EndBlock("Float centered exclusively the next FX for current track", 2)
