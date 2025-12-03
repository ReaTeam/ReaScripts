-- @description Smooth scroll arrange view left
-- @author amagalma
-- @version 1.01
-- @changelog Auto-terminate and re-run script if shortcut key is held down
-- @donation https://www.paypal.me/amagalma

reaper.set_action_options( 1|2 )

local ret = tonumber(reaper.GetExtState("amagalma_Smooth Scroll", "scroll"))
local scroll = ret and ret or 49
ret = tonumber(reaper.GetExtState("amagalma_Smooth Scroll", "max_duration"))
local max_duration = ret and ret or 400


local Set = reaper.GetSet_ArrangeView2
local total_frames = math.floor(max_duration / 31 + 0.5)
local a0, b0 = Set( 0, 0, 0, 0, 0, 0 )
if a0 == 0 then return end
local total_shift = (b0 - a0) * scroll / 100
local delta = total_shift / total_frames

local frame = 0

local function scroll_left()
  frame = frame + 1
  local a = a0 - delta * frame
  local b = b0 - delta * frame
  Set( 0, 1, 0, 0, a, b )
  reaper.UpdateTimeline()

  if frame ~= total_frames then
    reaper.defer(scroll_left)
  else
    return reaper.defer(function() end)
  end
end

scroll_left()
