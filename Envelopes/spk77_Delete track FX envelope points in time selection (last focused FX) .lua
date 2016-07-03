--[[
  * ReaScript Name: Delete track FX envelope points in time selection (for last focused FX)
  * Description: - Deletes track FX envelope points in time selection
  *              - Track FX has to be focused
  *              - Points are deleted from visible FX envelopes
  *
  * Instructions: - Open an FX window
  *               - Set time selection
  *               - Set FX window focused by clicking the window
  *               - Run this script
  *                
  * Screenshot: 
  * Notes: 
  * Category: 
  * Author: spk77
  * Author URI: http://forum.cockos.com/member.php?u=49553
  * Licence: GPL v3
  * Forum Thread: 
  * Forum Thread URL:
  * Version: 0.2
  * REAPER:
  * Extensions: SWS
]]
 

--[[
 Changelog:
 * v0.2 (2016-07-03)
    + fixed function name
 * v0.1 (2016-07-03)
    + Initial Release
]]

function msg(m)
  return reaper.ShowConsoleMsg(tostring(m) .. "\n")
end

function delete_FX_env_points()
  local time_sel_start, time_sel_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if time_sel_start == time_sel_end then return end
  local retval, track_number, item_number, fx_number = reaper.GetFocusedFX()
  if retval == 1 and item_number == -1 then -- currently only track FXs are supported
    local track = reaper.CSurf_TrackFromID(track_number, false)
    local is_open = reaper.TrackFX_GetOpen(track, fx_number)
    if not is_open then
      return
    end
    reaper.PreventUIRefresh(1)
    for i=1, reaper.TrackFX_GetNumParams(track, fx_number) do
      local ret, param_name = reaper.TrackFX_GetParamName(track, fx_number, i-1, "")
      local fx_env = reaper.GetFXEnvelope(track, fx_number, i-1, false)
          
      if fx_env ~= nil then
        local param_val, min_val, max_val = reaper.TrackFX_GetParam(track, fx_number, i-1)
        local br_env = reaper.BR_EnvAlloc(fx_env, true)
        local active, is_visible = reaper.BR_EnvGetProperties(br_env)
        reaper.BR_EnvFree(br_env, false)
        if is_visible then
          reaper.DeleteEnvelopePointRange(fx_env, time_sel_start, time_sel_end)
        end
        reaper.Envelope_SortPoints(fx_env)
      end
    end
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
  end
  reaper.Undo_OnStateChangeEx("Delete FX envelope points in time selection", -1, -1)
end

reaper.defer(delete_FX_env_points)
