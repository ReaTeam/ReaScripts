-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local SNP = require "modules/snap"
local T   = require "modules/time"
local S   = require "modules/settings"
local ART = require "modules/articulations"

local function Navigate(track, direction)
  local ns = SNP.nextSnapFromCursor(track, direction)

  reaper.Undo_BeginBlock();
  reaper.SetEditCurPos(ns.time, false, false);
  if S.getSetting("AutoScrollArrangeView") then
    T.KeepEditCursorOnScreen()
  end
  reaper.Undo_EndBlock("One Small Step: " .. ((direction > 0) and ("advanced") or ("stepped back")),-1);
end

local function NavigateForward(track)
  Navigate(track, 1)
end

-- Commits the currently held notes into the take
local function NavigateBack(track)
  Navigate(track, -1)
end

return {
  Navigate        = Navigate,
  NavigateForward = NavigateForward,
  NavigateBack    = NavigateBack
}
