-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local D = require "modules/defines"

local PLAYBACK_MARKER   = "OSS Playback"
local OPERATION_MARKER  = "OSS OP Start"

local function markerColor(marker_name)
  if marker_name == PLAYBACK_MARKER then
    return 0x00C000
  elseif marker_name == OPERATION_MARKER then
    return 0x4080FF
  end

  return 0xFFFFFF
end

local function findMarker(marker_name)
  local mc = reaper.CountProjectMarkers(0);
  for i=0, mc, 1 do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i);
    if name == marker_name then
      return i, pos
    end
  end
  return nil
end

local function setMarkerAtPos(marker_name, pos)
  local id, mpos  = findMarker(marker_name)
  local color     = markerColor(marker_name)

  reaper.Undo_BeginBlock()
  if not (id == nil) then
    reaper.DeleteProjectMarkerByIndex(0, id);
  end

  if (mpos == nil) or math.abs(pos - mpos) > D.TIME_TOLERANCE then
    reaper.AddProjectMarker2(0, false, pos, 0, marker_name, -1, reaper.ColorToNative( (color & 0xFF0000) >> 16, (color & 0x00FF00) >> 8, color & 0xFF)|0x1000000);
  end
  reaper.Undo_EndBlock("One Small Step - Set ".. marker_name .." marker", -1);
end

local function setMarkerAtCurrentPos(marker_name)
  setMarkerAtPos(marker_name, reaper.GetCursorPosition())
end

local function removeMarker(marker_name)
  reaper.Undo_BeginBlock();
  local id, mpos  = findMarker(marker_name)
  if not (id == nil) then
    reaper.DeleteProjectMarkerByIndex(0, id)
  end
  reaper.Undo_EndBlock("One Small Step - Remove " .. marker_name .. " marker", -1);
end

local function findPlaybackMarker()
  return findMarker(PLAYBACK_MARKER)
end

local function setPlaybackMarkerAtPos(pos)
  return setMarkerAtPos(PLAYBACK_MARKER, pos)
end
local function setPlaybackMarkerAtCurrentPos()
  return setMarkerAtCurrentPos(PLAYBACK_MARKER)
end
local function removePlaybackMarker()
  return removeMarker(PLAYBACK_MARKER)
end

local function findOperationMarker()
  return findMarker(OPERATION_MARKER)
end
local function setOperationMarkerAtPos(pos)
  return setMarkerAtPos(OPERATION_MARKER, pos)
end
local function setOperationMarkerAtCurrentPos()
  return setMarkerAtCurrentPos(OPERATION_MARKER)
end
local function removeOperationMarker()
  return removeMarker(OPERATION_MARKER)
end

return {
  PLAYBACK_MARKER                 = PLAYBACK_MARKER,
  OPERATION_MARKER                = OPERATION_MARKER,

  findMarker                      = findMarker,
  setMarkerAtPos                  = setMarkerAtPos,
  removeMarker                    = removeMarker,

  findPlaybackMarker              = findPlaybackMarker,
  setPlaybackMarkerAtPos          = setPlaybackMarkerAtPos,
  setPlaybackMarkerAtCurrentPos   = setPlaybackMarkerAtCurrentPos,
  removePlaybackMarker            = removePlaybackMarker,

  findOperationMarker             = findOperationMarker,
  setOperationMarkerAtPos         = setOperationMarkerAtPos,
  setOperationMarkerAtCurrentPos  = setOperationMarkerAtCurrentPos,
  removeOperationMarker           = removeOperationMarker
}
