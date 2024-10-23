-- @description Set last selected point to first selected point value in AI
-- @author Edgemeal
-- @version 1.0
-- @about Used exclusively for automation item(s) on selected envelope.

local env = reaper.GetSelectedTrackEnvelope(0)
if env == nil then return end

local ai_count = reaper.CountAutomationItems(env)
if ai_count < 1 then return end

function GetFirstSelectedPoint()
  for ai = 0, ai_count-1 do
    local points = reaper.CountEnvelopePointsEx(env, ai)-1
    for point = 0, points do 
      local ret, _, value, _, _, selected = reaper.GetEnvelopePointEx(env, ai, point)
      if ret and selected then return ai, point, value end 
    end
  end
  return -1
end

function GetLastSelectedPoint()
  for ai = ai_count-1, 0, -1 do
    local points = reaper.CountEnvelopePointsEx(env, ai)-1
    for point = points, 0, -1 do 
      local ret, _, value, _, _, selected = reaper.GetEnvelopePointEx(env, ai, point)
      if ret and selected then return ai, point, value end 
    end
  end
  return -1
end

local a1,p1,v1 = GetFirstSelectedPoint()
local a2,p2,v2 = GetLastSelectedPoint()
if (a1 ~= -1) and (a2 ~= -1) then
  reaper.Undo_BeginBlock(0)
  reaper.SetEnvelopePointEx(env, a2, p2, _, v1, _, _, true, false)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Set last selected point to first selected point value in AI", -1)
end

