-- @noindex

local track_count = reaper.CountTracks(0)

function View(track, guid)
  local track_fx_count = reaper.TrackFX_GetCount(track)
  for j = 0, track_fx_count-1 do
    if reaper.TrackFX_GetFXGUID(track, j) == guid then
      local hwnd = reaper.TrackFX_GetFloatingWindow(track, j)
      if hwnd == nil then
        reaper.TrackFX_Show(track, j, 3) -- show floating window
      else
        reaper.TrackFX_Show(track, j, 2) -- hide floating window
      end
      return
    end
  end
end

function ShowFx(guid)
  View(reaper.GetMasterTrack(0), guid)
  for i = 0, track_count-1 do
    local track = reaper.GetTrack(0, i)
    View(track, guid)
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
