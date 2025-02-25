-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local D           = require "modules/defines"
local S           = require "modules/settings"

local launchTime = reaper.time_precise()

local function validateModifierKeyCombination(id)
  if D.ModifierKeyCombinationLookup[id] == nil then
    error("Trying to use unknown modifier key combination with id " .. id)
  end
end

-- Returns the state of the modifier key linked to the function "function_name"
local function IsModifierKeyCombinationPressed(id)
  validateModifierKeyCombination(id)

  if id == "none" then
    return false
  end

  -- Avoid inconsistencies and only follow events during the lifetime of the plugin, so use launchTime
  -- This will prevent bugs from a session to another (when for example the plugin crashes)
  local keys  = reaper.JS_VKeys_GetState(launchTime);
  local combi = D.ModifierKeyCombinationLookup[id]

  for k, v in ipairs(combi.vkeys) do
    local c1    = keys:byte(v);
    if not (c1 ==1) then
      return false
    end
  end

  return true
end

local function IsStepBackModifierKeyPressed()
  local keys  = reaper.JS_VKeys_GetState(launchTime);
  return (keys:byte(S.getSetting("StepBackModifierKey")) == 1)
end

return {
  IsStepBackModifierKeyPressed    = IsStepBackModifierKeyPressed,
  IsModifierKeyCombinationPressed = IsModifierKeyCombinationPressed
}
