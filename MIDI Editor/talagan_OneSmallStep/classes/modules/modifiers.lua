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

--[[
local OtherOSModifierKeys = {
{ vkey = 16, name = 'Shift' },
{ vkey = 17, name = 'Ctrl' },
{ vkey = 18, name = 'Alt' }
};

local MacOSModifierKeys = {
{ vkey = 16, name = 'Shift' },
{ vkey = 17, name = 'Cmd' },
{ vkey = 18, name = 'Opt' },
{ vkey = 91, name = 'Ctrl' }
};
]]

-- Shift key : (1 << 3) == 8
local function IsShiftDown(jss)
  return ( (jss & (1<<3)) ~= 0)
end

-- Control (Windows) or Command (macOS) key (1 << 2) == 4
local function IsWinControlMacCmdDown(jss)
  return ( (jss & (1<<2)) ~= 0)
end

-- Alt (Windows) or Option (macOS) key (1 << 4) == 16
local function IsWinAltMacOptionDown(jss)
  return ( (jss & (1<<4)) ~= 0)
end

-- Windows (Windows) or Control (macOS) key : (1 << 5) == 32
local function IsWinWindowsMacControlDown(jss)
  return ( (jss & (1<<5)) ~= 0)
end

local function IsModifierKeyPressed(jss, id)

  if id == 16 then return IsShiftDown(jss) end
  if id == 17 then return IsWinControlMacCmdDown(jss) end
  if id == 18 then return IsWinAltMacOptionDown(jss) end
  if id == 91 then return IsWinWindowsMacControlDown(jss) end

  return false
end

-- Returns the state of the modifier key linked to the function "function_name"
local function IsModifierKeyCombinationPressed(id)
  validateModifierKeyCombination(id)

  if id == "none" then
    return false
  end

  local jss = reaper.JS_Mouse_GetState(0xFF)

  local combi = D.ModifierKeyCombinationLookup[id]

  for k, v in ipairs(combi.vkeys) do
    if not IsModifierKeyPressed(jss, v) then
      return false
    end
  end

  return true
end

local function IsStepBackModifierKeyPressed()
  local jss = reaper.JS_Mouse_GetState(0xFF)
  local key = tonumber(S.getSetting("StepBackModifierKey"))

  return IsModifierKeyPressed(jss, key)
end

return {
  IsStepBackModifierKeyPressed    = IsStepBackModifierKeyPressed,
  IsModifierKeyCombinationPressed = IsModifierKeyCombinationPressed
}
