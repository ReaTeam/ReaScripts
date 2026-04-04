-- @noindex


function SendProjectList()
  -- send project name
  ProjectName=reaper.GetProjectName(0)
  reaper.SetExtState("Fanciest","CurrentProject",ProjectName,false)
  
  -- send loop points (by marker index)
  local first, second = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)
  count = reaper.GetNumRegionsOrMarkers(0)
  local m, n = {}, {}
  --m[0], n[0] = 0, "home"
  for i=1, count do
    local marker = reaper.GetRegionOrMarker(0, i-1, "")
    local time = reaper.GetRegionOrMarkerInfo_Value(0, marker, "D_STARTPOS")
    local idx = reaper.GetRegionOrMarkerInfo_Value(0, marker, "I_NUMBER")
    m[i] = time
    n[i] = idx
  end
  m[#m+1] = reaper.GetProjectLength(0)
  n[#n+1] = "end"
  m[#m+1] = 0
  n[#n+1] = "home"
  
  for idx, val in ipairs(m) do
    if math.abs(first-val)<0.02 then
      finalfirst = n[idx]
    end
  end
  if finalfirst == nil then
    reaper.GetSet_LoopTimeRange(1, 0, 0, 0, 0)
  end
  
  for idx, val in ipairs(m) do
    if math.abs(second-val)<0.02 then
      finalsecond = n[idx]
    end
  end
  if finalsecond == nil then
    reaper.GetSet_LoopTimeRange(1, 0, 0, 0, 0)
  end
  
  if finalfirst ~= finalsecond and finalfirst ~= nil and finalsecond ~= nil then 
    reaper.SetExtState("Fanciest","SelectDisplay",finalfirst..':'..finalsecond,false)
  else
    reaper.SetExtState("Fanciest","SelectDisplay","none",false)
  end
  
  -- send track arm states
  count = reaper.CountTracks(0)
  local arms = {}
  for i=0, count-1 do
    Track = reaper.GetTrack(0, i)
    if reaper.GetMediaTrackInfo_Value(Track, "I_RECARM") == 0 then
      arms[i+1] = "off"
    elseif reaper.GetMediaTrackInfo_Value(Track, "I_RECINPUT") == 0 then
      arms[i+1] = "chan1"
    elseif reaper.GetMediaTrackInfo_Value(Track, "I_RECINPUT") == 1 then
      arms[i+1] = "chan2"
    else
      reaper.SetMediaTrackInfo_Value(Track, "I_RECARM", 0)
      arms[i+1] = "off" --don't feel like dealing w weird states
    end
  end
  armstring = table.concat(arms,":") --isnt this the guy who landed on the moon
  reaper.SetExtState("Fanciest","ArmDisplay",armstring,false)
end

SendProjectList()
