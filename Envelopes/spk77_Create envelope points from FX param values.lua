--[[
  * ReaScript Name: Create envelope points from FX parameter values
  * Description: - Creates envelope points from currently open and focused FX
  *              - Envelope points are added to the edit cursor
  *              - Can be used for "morphing" between FX presets
  *
  * Instructions: - Open an FX window
  *               - Run action: "Global automation override: Bypass all automation"
  *                 (There's also a "Global automation override" button in the transport bar)
  *               - Move the edit cursor to desired position
  *               - Select a preset
  *               - Run the script
  *               - Move the edit cursor to another position
  *               - Select another preset (or just tweak the current values)
  *               - Run the script etc.
  *               - Run action: "Global automation override: No override (set automation modes per track)" 
  *                
  * Screenshot: 
  * Notes: 
  * Category: 
  * Author: spk77
  * Author URI: http://forum.cockos.com/member.php?u=49553
  * Licence: GPL v3
  * Forum Thread: 
  * Forum Thread URL:
  * Version: 0.1
  * REAPER:
  * Extensions:
]]
 

--[[
 Changelog:
 * v0.1 (2016-06-19)
    + Initial Release
]]

function msg(m)
  return reaper.ShowConsoleMsg(tostring(m) .. "\n")
end

function create_env_points_from_FX_param_values()
  local retval, track_number, item_number, fx_number = reaper.GetFocusedFX()
  if retval == 1 and item_number == -1 then -- currently only track FXs are supported
    local track = reaper.CSurf_TrackFromID(track_number, false)
    local is_open = reaper.TrackFX_GetOpen(track, fx_number) 
    if not is_open then
      return
    end
    reaper.PreventUIRefresh(1)
    local cursor_pos = reaper.GetCursorPosition()
    for i=1, reaper.TrackFX_GetNumParams(track, fx_number) do
      local ret, param_name = reaper.TrackFX_GetParamName(track, fx_number, i-1, "")
      local param_val, min_val, max_val = reaper.TrackFX_GetParam(track, fx_number, i-1)
      --msg(param_name)
      local fx_env = reaper.GetFXEnvelope(track, fx_number, i-1, true)
      if fx_env ~= nil then
        reaper.InsertEnvelopePoint(fx_env, cursor_pos, param_val, 0, 0, false, true)
      end
      reaper.Envelope_SortPoints(fx_env)
    end
    reaper.PreventUIRefresh(-1)
    reaper.TrackList_AdjustWindows(false)
  end
  reaper.Undo_OnStateChangeEx("Create envelope points from FX parameter values", -1, -1)
end

reaper.defer(create_env_points_from_FX_param_values)

