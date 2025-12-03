-- @description Smooth scroll arrange view settings
-- @author amagalma
-- @version 1.01
-- @changelog Do not accept a maximum duration that is less or equal to 31ms (one defer cycle)
-- @donation https://www.paypal.me/amagalma

local ret = reaper.GetExtState("amagalma_Smooth Scroll", "scroll")
local scroll = ret ~= "" and ret or "49"
ret = reaper.GetExtState("amagalma_Smooth Scroll", "max_duration")
local max_duration = ret ~= "" and ret or "400"

::AGAIN::
local ok, retvals = reaper.GetUserInputs("amagalma's Smooth Scroll View", 2, "Scroll view by (%) :, Max scrolling duration (ms) :", scroll.. "," .. max_duration )
if ok then
  local new_scroll, new_max_duration = retvals:match("(.+),(.+)")
  local new_scroll_num = tonumber(new_scroll)
  local new_max_duration_num = tonumber(new_max_duration)
  if new_scroll_num and new_scroll_num > 0 and new_max_duration_num and new_max_duration_num > 31 then
    reaper.SetExtState( "amagalma_Smooth Scroll", "scroll", new_scroll, true )
    reaper.SetExtState( "amagalma_Smooth Scroll", "max_duration", new_max_duration, true )
  else
    goto AGAIN
  end
end

reaper.defer(function() end)
