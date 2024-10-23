-- @noindex

local index, guidz = 0, {}

-- Special Thanks to Justin, https://forum.cockos.com/showpost.php?p=2714766&postcount=17
function BuildFXTree_item(tr, fxid, scale)
  index=index+1 guidz[index] = { track = tr, fxid = fxid, guid = reaper.TrackFX_GetFXGUID(tr, fxid) }
  local c_ok, c_count = reaper.TrackFX_GetNamedConfigParm(tr, fxid, 'container_count')
  if c_ok then
    c_count = tonumber(c_count)
    for child = 1, c_count do BuildFXTree_item(tr, fxid + scale * child, (scale*(c_count+1))) end
  end
end

function BuildFXTree(tr)
  local cnt = reaper.TrackFX_GetCount(tr)
  for i = 1, cnt do BuildFXTree_item(tr, 0x2000000+i, cnt+1) end
end

function ShowFx(guid)
  for j = 1, #guidz do
    if guidz[j].guid == guid then
      local hwnd = reaper.TrackFX_GetFloatingWindow(guidz[j].track, guidz[j].fxid)
      if hwnd == nil then
        reaper.TrackFX_Show(guidz[j].track, guidz[j].fxid, 3) -- show floating window
      else
        reaper.TrackFX_Show(guidz[j].track, guidz[j].fxid, 2) -- hide floating window
      end
    end
  end
end

function Main()
  local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
  local slot = tonumber(name:match(" slot (%d+)"))
  if slot == nil then reaper.MB("Error reading slot # from filename","ERROR",0) return end
  BuildFXTree(reaper.GetMasterTrack())
  local track_count = reaper.CountTracks(0)
  for i = 0, track_count-1 do BuildFXTree(reaper.GetTrack(0, i)) end
  local guids = reaper.GetExtState("Edgemeal_fx_float", tostring(slot))
  for guid in guids:gmatch("[^,]+") do ShowFx(guid) end
end

Main()
reaper.defer(function() end)
