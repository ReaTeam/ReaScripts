-- @noindex


function SetTimeSelection()
  values = reaper.GetExtState("Fanciest","MarkerLoop")
  local t = {}
  for str in string.gmatch(values, "([^:]+)") do
    table.insert(t, str)
  end
  ms = {}
  for i=1, reaper.GetNumRegionsOrMarkers(0) do
    table.insert(ms, reaper.GetRegionOrMarkerInfo_Value(0, reaper.GetRegionOrMarker(0, i-1,""), "I_NUMBER"))
  end


  if t[1] == "home" then
    first = 0
  elseif t[1] == "end" then
    first = reaper.GetProjectLength(0)
  else
    wip = tonumber(t[1])
    for i, n in ipairs(ms) do
      if n == wip then
        wip = reaper.GetRegionOrMarker(0, i-1,'')
      end
    end
    first = reaper.GetRegionOrMarkerInfo_Value(0, wip, "D_STARTPOS")
  end
  if t[2] == "home" then
    second = 0
  elseif t[2] == "end" then
    second = reaper.GetProjectLength(0)
  else
    wip = tonumber(t[2])
    for i, n in ipairs(ms) do
      if n == wip then
        wip = reaper.GetRegionOrMarker(0, i-1,'')
      end
    end
    second = reaper.GetRegionOrMarkerInfo_Value(0, wip, "D_STARTPOS")
  end
  reaper.GetSet_LoopTimeRange(1, 0, first, second, true)

end

SetTimeSelection()
