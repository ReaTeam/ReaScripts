--[[
   * ReaScript Name: Set pan for selected tracks
   * Lua script for Cockos REAPER
   * Author: spk77
   * Author URI: http://forum.cockos.com/member.php?u=49553
   * Licence: GPL v3
   * Version: 1.0
]]
  
-- Set pan for selected track(s)
-- Lua script by SPK77 15-Sep-2015
-- Version: 0.2015.9.15
--
-- range: use values from -100 to 100

function dialog(title, def_value)
  local ret, retvals = reaper.GetUserInputs(title, 1, "Set pan for selected track(s)", def_value)
  if ret then
    return retvals
  end
  return ret
end


----------
-- Main --
----------

function main()
  local tr_count = reaper.CountSelectedTracks(0)
  if tr_count == 0 then
    return
  end

  local def_value = 0.0

  if tr_count == 1 then
    -- if only one track is selected -> show current pan value in edit box
    def_value = reaper.GetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, 0), "D_PAN")
  end
  
  local new_pan = tonumber(dialog("Set pan for selected track(s)", def_value*100))
  if not new_pan then
    return
  end
  
  if new_pan > 100 then 
    new_pan = 100
  elseif new_pan < -100 then 
    new_pan = -100
  end
  
  for i = 1, tr_count do
    local tr = reaper.GetSelectedTrack(0, i-1)
    if tr ~= nil then
      reaper.SetMediaTrackInfo_Value(tr, "D_PAN", new_pan/100)
    end
  end
  reaper.Undo_OnStateChangeEx("Set pan for selected track(s)", -1, -1)
end

reaper.defer(main)
