-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local D = require "modules/defines"
local S = require "modules/settings"

local function validateActionTrigger(action_name)
  if D.ActionTriggers[action_name] == nil then
    error("Trying to use unknown action trigger :" .. action_name)
  end
end

local function setActionTrigger(action_name)
  validateActionTrigger(action_name)
  reaper.SetExtState("OneSmallStep", action_name .. "ActionTrigger", tostring(reaper.time_precise()), false)
end
local function getActionTrigger(action_name)
  validateActionTrigger(action_name)
  return tonumber(reaper.GetExtState("OneSmallStep", action_name .. "ActionTrigger"))
end
local function clearActionTrigger(action_name)
  validateActionTrigger(action_name)
  reaper.DeleteExtState("OneSmallStep", action_name .. "ActionTrigger", true)
end

local function clearAllActionTriggers()
  for k,v in pairs(D.ActionTriggers) do
    clearActionTrigger(k)
  end
end

local function hasActionTrigger(forward)
  local res = false
  for k,v in pairs(D.ActionTriggers) do
    local cond = false
    if forward then
      cond = not v.back
    else
      cond = v.back
    end
    if cond then
      res = (res or (getActionTrigger(k) ~= nil))
    end
  end
  return res
end
local function hasForwardActionTrigger()
  return hasActionTrigger(true)
end
local function hasBackwardActionTrigger()
  return hasActionTrigger(false)
end

return {
  setActionTrigger          = setActionTrigger,
  getActionTrigger          = getActionTrigger,
  clearActionTrigger        = clearActionTrigger,
  clearAllActionTriggers    = clearAllActionTriggers,
  hasActionTrigger          = hasActionTrigger,
  hasForwardActionTrigger   = hasForwardActionTrigger,
  hasBackwardActionTrigger  = hasBackwardActionTrigger
}
