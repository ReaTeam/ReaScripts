-- @noindex

local index, guidz = 0, {}

-- Special Thanks to Justin, https://forum.cockos.com/showpost.php?p=2714766&postcount=17
function BuildFXTree_item(tr, fxid, scale)
  local hwnd = reaper.TrackFX_GetFloatingWindow(tr, fxid)
  if hwnd ~= nil then index=index+1 guidz[index] = reaper.TrackFX_GetFXGUID(tr, fxid) end
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

function Main()
  local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
  local slot = tonumber(name:match(" slot (%d+)"))
  if slot == nil then reaper.MB("Error reading slot # from filename","ERROR",0) return end
  local stc = reaper.CountSelectedTracks2(0, true)
  for i = 0, stc-1 do BuildFXTree(reaper.GetSelectedTrack2(0, i, true)) end
  reaper.SetExtState("Edgemeal_fx_float", tostring(slot), table.concat(guidz, ","), false)
end

Main()
reaper.defer(function() end)
