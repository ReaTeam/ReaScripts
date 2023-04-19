-- @noindex

local offset = 0x1000000
local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local slot = tonumber(name:match(" slot (%d+)"))
if slot ~= nil then
  local guid = ""
  local sel_tracks_count = reaper.CountSelectedTracks2(0, true)
  for i = 0, sel_tracks_count-1 do
    local track = reaper.GetSelectedTrack2(0, i, true)
    local track_fx_count = reaper.TrackFX_GetRecCount(track)
    for j = 0, track_fx_count-1  do
      local hwnd = reaper.TrackFX_GetFloatingWindow(track, j+offset)
      if hwnd ~= nil then
        local fx_GUID = reaper.TrackFX_GetFXGUID(track, j+offset)
        guid = guid .. fx_GUID .. ','
      end
    end
  end
  reaper.SetExtState("Edgemeal_infx_float", tostring(slot), guid, false)
end
reaper.defer(function() end)
