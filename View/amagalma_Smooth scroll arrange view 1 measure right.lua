-- @description Smooth scroll arrange view 1 measure right
-- @author amagalma
-- @version 1.00
-- @provides
--   .
--   [main] . > amagalma_Smooth scroll arrange view 2 measures right.lua
--   [main] . > amagalma_Smooth scroll arrange view 4 measures right.lua
--   [main] . > amagalma_Smooth scroll arrange view 8 measures right.lua
-- @donation https://www.paypal.me/amagalma

reaper.set_action_options( 1|2 )

local Set, floor, log = reaper.GetSet_ArrangeView2, math.floor, math.log
local measures = tonumber((({reaper.get_action_context()})[2]):match(".-(%d+).-$"))

local a0, b0 = Set( 0, 0, 0, 0, 0, 0 )
local qn_current = floor(reaper.TimeMap_timeToQN( a0 ))
local measure_start = reaper.TimeMap_QNToMeasures(0, qn_current )
local measure_time, qn_start, qn_end = reaper.TimeMap_GetMeasureInfo( 0, measure_start-1 )
local first_visible_measure = measure_start
local first_visible_measure_time = measure_time
if measure_time + 0.00001 < a0 then
  first_visible_measure = measure_start + 1
  first_visible_measure_time = reaper.TimeMap_GetMeasureInfo( 0, first_visible_measure-1 )
end
local wanted_time = reaper.TimeMap_GetMeasureInfo( 0, first_visible_measure-1+measures )
local total_shift = wanted_time - a0

local ret = tonumber(reaper.GetExtState("amagalma_Smooth Scroll", "max_duration"))
local max_duration = ret and ret or 400
local max_max_duration = max_duration*1.25
local hzoom = reaper.GetHZoomLevel()
if hzoom > 200 then
  max_duration = max_duration*0.25
else
  max_duration = max_duration * log(hzoom) / 4
end
  if max_duration < 40 then max_duration = 40 end
  if max_duration > max_max_duration then max_duration = max_max_duration end
local total_frames = floor(max_duration / 31 + 0.5)
local delta = total_shift / total_frames

local frame = 0

local function scroll_right()
  frame = frame + 1
  local a = a0 + delta * frame
  local b = b0 + delta * frame
  Set( 0, 1, 0, 0, a, b )

  if frame ~= total_frames then
    reaper.defer(scroll_right)
  else
    return reaper.defer(function() end)
  end
end

scroll_right()
