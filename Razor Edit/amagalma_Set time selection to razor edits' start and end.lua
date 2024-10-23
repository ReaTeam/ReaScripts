-- @description Set time selection to razor edits' start and end
-- @author amagalma
-- @version 1.00
-- @about Sets the time selection to begin at the earliest razor edit start and to end at the latest razor edit end.


local ts_st, ts_en = math.huge, -1
for tr = 0, reaper.CountTracks( 0 )-1 do
  local track = reaper.GetTrack(0, tr)
  local _, areas = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
  if areas ~= "" then
    for area_start, area_end in string.gmatch(areas, '(%S+) (%S+) %S+') do
      area_start, area_end = tonumber(area_start), tonumber(area_end)
      if area_start < ts_st then ts_st = area_start end
      if area_end > ts_en then ts_en = area_end end
    end
  end
end

if ts_en ~=-1 then
  reaper.GetSet_LoopTimeRange( true, false, ts_st, ts_en, false )
  reaper.Undo_OnStateChangeEx("Set time selection to razor edits' start and end", 8, -1)
else
  return reaper.defer(function() end)
end
