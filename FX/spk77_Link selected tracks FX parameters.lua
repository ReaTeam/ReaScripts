-- @description Link selected tracks FX parameters
-- @author spk77
-- @version 1.02
-- @about Link selected tracks FX parameter, if they have the same name. Select tracks. Run. Terminate once it is done.
-- @screenshot: http://stash.reaper.fm/24908/Link%20FX%20params3.gif
-- @Licence: GPL v3
-- @Forum Thread: Scripts: FX Param Values (various)
-- @Forum Thread URI: http://forum.cockos.com/showpost.php?p=1562493&postcount=31
-- @Forum Thread URI: https://forum.cockos.com/showthread.php?t=267771
-- @REAPER: 5.0
-- @changelog
--   v1.0 ( 2015-08-23 )
--   	+ Initial Release
--   v1.01 ( 2022-06-15 )
--   	+ Added toolbar button indicator, thanks to X-Raym, otherwise unchanged.

-- Link FX parameters
-- Lua script by X-Raym, casrya and SPK77 (23-Aug-2015)
-- Tiny addition by X-Raym(template code) & Airon(60 seconds of editing)

-- Set ToolBar Button State, from X-Rayms template at
-- https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Templates/X-Raym_Background%20script.lua

function SetButtonState( set )
  local is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
  reaper.SetToggleCommandState( sec, cmd, set or 0 )
  reaper.RefreshToolbar2( sec, cmd )
end


local last_param_number = -1
local last_val = -10000000
local param_changed = false

---- param_value_change_count = 0 -- for debugging
---- param_change_count = -1 -- for debugging

function Msg(string)
  reaper.ShowConsoleMsg(tostring(string).."\n")
end

-- http://lua-users.org/wiki/SimpleRound
function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function main()
  local ret, track_number, fx_number, param_number = reaper.GetLastTouchedFX()
  if ret then
    local track_id = reaper.CSurf_TrackFromID(track_number, false)
    if track_id ~= nil and reaper.IsTrackSelected(track_id) then
      local val, minvalOut, maxvalOut = reaper.TrackFX_GetParam(track_id, fx_number, param_number)
      local fx_name_ret, fx_name = reaper.TrackFX_GetFXName(track_id, fx_number, "")

      -- convert double to float precision
      val=round(val,7)
      
      -- Check if parameter has changed
      param_changed = param_number ~= last_param_number or last_val~=val
            
      -- Run this code only when parameter value has changed
      if param_changed then
        --Msg("last_val: " .. last_val .. ", val: " .. val .. ", last_param_number: " .. last_param_number .. ", param_number: " .. param_number .. ", fx_number: " .. fx_number)
        last_val = val 
        last_param_number = param_number
        
        for i=1, reaper.CountSelectedTracks(0) do
          local tr = reaper.GetSelectedTrack(0, i-1)
          
          for fx_i=1, reaper.TrackFX_GetCount(tr) do -- loop through FXs on current track
            local dest_fx_name_ret, dest_fx_name = reaper.TrackFX_GetFXName(tr, fx_i-1, "")
            if dest_fx_name == fx_name then
              --Msg("FX number: " .. fx_i ..", Setting last_val: " .. last_val .. ", val: " .. val .. ", param_number: " .. param_number)
              reaper.TrackFX_SetParam(tr, fx_i-1, param_number, val)
            end
          end
        end
        ---- param_value_change_count = param_value_change_count + 1 -- for debugging
      end
    end
  end
  reaper.defer(main)
end

-- RUN
SetButtonState( 1 )
main()
reaper.atexit( SetButtonState )
