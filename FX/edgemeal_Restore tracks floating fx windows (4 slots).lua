-- @description Restore tracks floating fx windows (4 slots)
-- @author Edgemeal
-- @version 1.00
-- @link Forum https://forum.cockos.com/showpost.php?p=2349852&postcount=2196
-- @donation Donate https://www.paypal.me/Edgemeal
-- @metapackage
-- @provides
--   [main] . > edgemeal_Restore tracks floating fx windows from slot 1.lua
--   [main] . > edgemeal_Restore tracks floating fx windows from slot 2.lua
--   [main] . > edgemeal_Restore tracks floating fx windows from slot 3.lua
--   [main] . > edgemeal_Restore tracks floating fx windows from slot 4.lua

local track_count = reaper.CountTracks(0)

function ShowFx(guid)
  for i = 0, track_count-1 do
    local track = reaper.GetTrack(0, i)
    local track_fx_count = reaper.TrackFX_GetCount(track)
    for j = 0, track_fx_count-1 do
      if reaper.TrackFX_GetFXGUID(track, j) == guid then
        reaper.TrackFX_Show(track, j, 3)
        return
      end
    end
  end
end

function Main()
  local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
  local slot = tonumber(name:match(" slot (%d+)"))
  if slot == nil then
    reaper.MB("Error reading slot # from filename","ERROR",0)
    return
  end
  local guids = reaper.GetExtState("Edgemeal_fx_float", tostring(slot))
  for guid in guids:gmatch("[^,]+") do ShowFx(guid) end
end

Main()
reaper.defer(function() end)
