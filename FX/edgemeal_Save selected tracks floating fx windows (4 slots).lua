-- @description Save and restore selected tracks floating FX windows
-- @author Edgemeal
-- @version 1.00
-- @metapackage
-- @provides
--   [main] . > edgemeal_Save selected tracks floating fx windows to slot 1.lua
--   [main] . > edgemeal_Save selected tracks floating fx windows to slot 2.lua
--   [main] . > edgemeal_Save selected tracks floating fx windows to slot 3.lua
--   [main] . > edgemeal_Save selected tracks floating fx windows to slot 4.lua
-- @link Forum https://forum.cockos.com/showpost.php?p=2349852&postcount=2196
-- @donation Donate https://www.paypal.me/Edgemeal

function Main()
  local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
  local slot = tonumber(name:match(" slot (%d+)"))
  if slot == nil then
    reaper.MB("Error reading slot # from filename","ERROR",0)
    return
  end
  local guid = ""
  local sel_tracks_count = reaper.CountSelectedTracks(0)
  for i = 0, sel_tracks_count-1 do
    local track = reaper.GetSelectedTrack(0, i)
    local track_fx_count = reaper.TrackFX_GetCount(track)
    for j = 0, track_fx_count-1  do
      local hwnd = reaper.TrackFX_GetFloatingWindow(track, j)
      if hwnd ~= nil then
        local fx_GUID = reaper.TrackFX_GetFXGUID(track, j)
        guid = guid .. fx_GUID .. ','
      end
    end
  end
  reaper.SetExtState("Edgemeal_fx_float", tostring(slot), guid, false)
end

Main()
reaper.defer(function() end)
