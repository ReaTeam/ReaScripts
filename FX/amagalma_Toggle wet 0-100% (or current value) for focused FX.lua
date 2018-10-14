-- @description amagalma_Toggle wet 0-100% (or current value) for focused FX
-- @author amagalma
-- @version 1.0
-- @about
--   # Toggles wet from 0% to current value (or 100%) for the FX in focus

local reaper, math = reaper, math

local focus, track, item, fx = reaper.GetFocusedFX()

function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    if num >= 0 then return math.floor(num * mult + 0.5) / mult
    else return math.ceil(num * mult - 0.5) / mult end
end


if focus == 1 then --------------- TRACK FX ---------------

  if track == 0 then
    track = reaper.GetMasterTrack(0)
  else
    track = reaper.GetTrack(0, track-1)
  end
  
  -- check if it is really visible
  local hwnd = reaper.TrackFX_GetFloatingWindow( track, fx )
  local chain_vis = reaper.TrackFX_GetChainVisible( track )
  if hwnd or chain_vis > -1 then
    
    local parm_cnt = reaper.TrackFX_GetNumParams( track, fx )
    local val = reaper.TrackFX_GetParam( track, fx, parm_cnt-1 )
    local fxguid = reaper.TrackFX_GetFXGUID( track, fx )
    local _, name = reaper.TrackFX_GetFXName( track, fx, "" )
    
    if val > 0 then -- store value and set wet to 0%
      reaper.SetExtState( "ToggleWet", fxguid, val, false )
      reaper.TrackFX_SetParam( track, fx, parm_cnt-1, 0 )
      reaper.Undo_OnStateChangeEx( "Set " .. name .. " to 0% wet", 2, -1 )
    else -- set to previous value if exists or 100%
      if reaper.HasExtState( "ToggleWet" , fxguid ) then
        val = tonumber(reaper.GetExtState( "ToggleWet", fxguid ))
      else
        val = 1
      end
      reaper.TrackFX_SetParam( track, fx, parm_cnt-1, val )
      reaper.DeleteExtState( "ToggleWet", fxguid, false )
      val = round (val * 100)
      reaper.Undo_OnStateChangeEx( "Set " .. name .. " to " .. val .. "% wet", 2, -1 )
    end    
  
  else
  
    reaper.defer(function () end)
    
  end
  
elseif focus == 2 then --------------- TAKE FX ---------------

  item = reaper.GetMediaItem(0, item)
  track = reaper.GetMediaItemTrack(item)
  local take = reaper.GetMediaItemTake(item, fx >> 16)
  -- check if it is really visible
  local hwnd = reaper.TakeFX_GetFloatingWindow( take, fx )
  local chain_vis = reaper.TakeFX_GetChainVisible( take )
  if hwnd or chain_vis > -1 then
  
    local parm_cnt = reaper.TakeFX_GetNumParams( take, fx )
    local val = reaper.TakeFX_GetParam( take, fx, parm_cnt-1 )
    local fxguid = reaper.TakeFX_GetFXGUID( take, fx )
    local _, name = reaper.TakeFX_GetFXName( take, fx, "" )
    
    if val > 0 then -- store value and set wet to 0%
      reaper.SetExtState( "ToggleWet", fxguid, val, false )
      reaper.TakeFX_SetParam( take, fx, parm_cnt-1, 0 )
      reaper.Undo_OnStateChangeEx( "Set " .. name .. " to 0% wet", 4, -1 )
    else -- set to previous value if exists or 100%
      if reaper.HasExtState( "ToggleWet" , fxguid ) then
        val = tonumber(reaper.GetExtState( "ToggleWet", fxguid ))
      else
        val = 1
      end
      reaper.TakeFX_SetParam( take, fx, parm_cnt-1, val )
      reaper.DeleteExtState( "ToggleWet", fxguid, false )
      val = round (val * 100)
      reaper.Undo_OnStateChangeEx( "Set " .. name .. " to " .. val .. "% wet", 4, -1 )
    end
  
  else
  
  reaper.defer(function () end)
  
  end
  
elseif focus == 0 then

  reaper.defer(function () end)
  
end
