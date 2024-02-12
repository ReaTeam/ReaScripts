-- @description amagalma_Toggle wet 0-100% (or current value) for focused FX
-- @author amagalma
-- @version 1.12
-- @changelog Added tooltip info
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Toggles wet from 0% to current value (or 100%) for the FX in focus

local v1, v2 = reaper.GetAppVersion():match("(%d+)%.(%d+)")
if tonumber(v1) < 7 or tonumber(v2) < 6 then
  reaper.MB( "Downgrade to a previous version of the script from Reapack.\nThis script version requires Reaper v7.06+", "Unsupported version!", 0 )
  return reaper.defer(function() end)
end

local floor, ceil, integ = math.floor, math.ceil, math.tointeger

local retval, track, item, take, fx, parm = reaper.GetTouchedOrFocusedFX( 1 )
if not retval then return reaper.defer(function () end) end

local function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  if num >= 0 then return floor(num * mult + 0.5) / mult
  else return ceil(num * mult - 0.5) / mult end
end


if item == -1 then --------------- TRACK FX ---------------

  if track == -1 then
    track = reaper.GetMasterTrack(0)
  else
    track = reaper.GetTrack(0, track)
  end

  -- check if it is really visible
  local hwnd = reaper.TrackFX_GetFloatingWindow( track, fx )
  local chain_vis = reaper.TrackFX_GetChainVisible( track )
  if hwnd or chain_vis > -1 then

    local msg
    local wetparam = reaper.TrackFX_GetParamFromIdent( track, fx, ":wet" )
    local val = reaper.TrackFX_GetParam( track, fx, wetparam )
    local fxguid = reaper.TrackFX_GetFXGUID( track, fx )
    local _, name = reaper.TrackFX_GetFXName( track, fx, "" )

    if val > 0 then -- store value and set wet to 0%
      reaper.SetProjExtState( 0, "ToggleWet", fxguid, val )
      reaper.TrackFX_SetParam( track, fx, wetparam, 0 )
      reaper.Undo_OnStateChangeEx( "Set " .. name .. " to 0% wet", 2, -1 )
      msg = ({reaper.GetTrackName(track)})[2] .. "  |  ".. ({reaper.TrackFX_GetFXName(track, fx)})[2] .. "  => 0%"
    else -- set to previous value if exists or 100%
      local hasState, val = reaper.GetProjExtState( 0, "ToggleWet" , fxguid )
      if not hasState == 1 then
        val = 1
      end
      reaper.TrackFX_SetParam( track, fx, wetparam, val )
      reaper.SetProjExtState( 0, "ToggleWet", fxguid, "" )
      val = round (val * 100)
      msg = ({reaper.GetTrackName(track)})[2] .. "  |  ".. ({reaper.TrackFX_GetFXName(track, fx)})[2] .. "  => " .. integ(val) .. "%"
      reaper.Undo_OnStateChangeEx( "Set " .. name .. " to " .. val .. "% wet", 2, -1 )
    end
    local x, y = reaper.GetMousePosition()
    reaper.TrackCtl_SetToolTip(msg, x, y, true)

  else

    reaper.defer(function () end)

  end

else --------------- TAKE FX ---------------

  item = reaper.GetMediaItem(0, item)
  track = reaper.GetMediaItemTrack(item)
  take =  reaper.GetTake( item, take )
  -- check if it is really visible
  local hwnd = reaper.TakeFX_GetFloatingWindow( take, fx )
  local chain_vis = reaper.TakeFX_GetChainVisible( take )
  if hwnd or chain_vis > -1 then

    local msg
    local wetparam = reaper.TakeFX_GetParamFromIdent( take, fx, ":wet" )
    local val = reaper.TakeFX_GetParam( take, fx, wetparam )
    local fxguid = reaper.TakeFX_GetFXGUID( take, fx )
    local _, name = reaper.TakeFX_GetFXName( take, fx, "" )

    if val > 0 then -- store value and set wet to 0%
      reaper.SetProjExtState( 0, "ToggleWet", fxguid, val )
      reaper.TakeFX_SetParam( take, fx, wetparam, 0 )
      reaper.Undo_OnStateChangeEx( "Set " .. name .. " to 0% wet", 4, -1 )
      msg = reaper.GetTakeName( take ) .. "  |  ".. ({reaper.TakeFX_GetFXName(take, fx)})[2] .. "  => 0%"
    else -- set to previous value if exists or 100%
      local hasState, val = reaper.GetProjExtState( 0, "ToggleWet" , fxguid )
      if not hasState == 1 then
        val = 1
      end
      reaper.TakeFX_SetParam( take, fx, wetparam, val )
      reaper.SetProjExtState( 0, "ToggleWet", fxguid, "" )
      val = round (val * 100)
      msg = reaper.GetTakeName( take ) .. "  |  ".. ({reaper.TakeFX_GetFXName(take, fx)})[2] .. "  => " .. integ(val) .. "%"
      reaper.Undo_OnStateChangeEx( "Set " .. name .. " to " .. val .. "% wet", 4, -1 )
    end
    local x, y = reaper.GetMousePosition()
    reaper.TrackCtl_SetToolTip(msg, x, y, true)

  else

  reaper.defer(function () end)

  end

end
