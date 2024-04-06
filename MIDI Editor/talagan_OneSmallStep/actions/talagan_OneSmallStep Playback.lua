-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step. Will replay the n last measures.

package.path      = debug.getinfo(1,"S").source:match[[^@?(.*[\/])actions[\/][^\/]-$]] .. "classes/" .. "?.lua;".. package.path

local S           = require "modules/settings"
local MK          = require "modules/markers"

-- Give the possibility to this script to be duplicated and called
-- With a param at the end of the lua file name (it overrides OSS config)
local param       = select(2, reaper.get_action_context()):match("%- ([^%s]*)%.lua$");

if reaper.set_action_options ~= nil then
  reaper.set_action_options(1);
end

-- Reaper must be in stalled state
if not (reaper.GetPlayState() == 0) then
  return;
end

local rewindMeasureCount  = ((param == nil) and S.getPlaybackMeasureCount() or tonumber(param));

local pos                 = reaper.GetCursorPosition()
local posqn               = reaper.TimeMap2_timeToQN(0, pos)
local posm                = reaper.TimeMap_QNToMeasures(0, posqn)

local timeStart           = 0

if rewindMeasureCount == -1 then
  local mkid, mkpos = MK.findPlaybackMarker()

  if mkid == nil then
    rewindMeasureCount = 0
  else
    timeStart = mkpos
  end
end

if rewindMeasureCount >= 0 then
  -- Determine the right measure start
  local _, thisMeasureStart, thisMeasureEnd = reaper.TimeMap_GetMeasureInfo(0, posm - 1);

  if math.abs(thisMeasureStart - posqn) < 0.01 and rewindMeasureCount == 0 then
    -- If the cursor is on the start of one measure, move 1 one more measure backward
    rewindMeasureCount = 1;
  end

  local _, measureStart, measureEnd         = reaper.TimeMap_GetMeasureInfo(0, posm - 1 - rewindMeasureCount);

  timeStart = reaper.TimeMap2_QNToTime(0, measureStart);
end

-- In OSS manual, I encourage users to a tick the option that
-- creates an undo point whenever the Edit cursor is moved
-- This ensures that OSS undo works well (notes are cancelled and the edit cursor moves back to its previous position)
-- Hovever, for the playback action, it may create unwanted undo points

-- That's why, at the end we check if undo points were created during playback and we cancel them.

local SPBA = "OneSmallStep - Start Playback";
local EPBA = "OneSmallStep - End Playback";

local waitEndOfPlayback
local function startPlayback()
  -- Move the cursor back and hit play
  reaper.Undo_BeginBlock();
  reaper.SetEditCurPos(timeStart, true, true);
  reaper.Undo_EndBlock(SPBA,0);
  reaper.OnPlayButton();
  reaper.defer(waitEndOfPlayback);
end

local function onPlaybackEnd()
  reaper.Undo_BeginBlock();
  reaper.SetEditCurPos(pos, false, false);
  reaper.Undo_EndBlock(EPBA,0);

  -- We cannot prevent reaper from creating undo points
  local last_action = reaper.Undo_CanUndo2(0);
  while last_action == SPBA or last_action == EPBA do
    reaper.Undo_DoUndo2(0);
    last_action = reaper.Undo_CanUndo2(0);
  end

end

function waitEndOfPlayback()
  local ps          = reaper.GetPlayState();
  local curtime     = reaper.GetPlayPosition();
  local antiglitch  = 0.1;

  if (curtime < pos - antiglitch) and (ps == 1) then
    reaper.defer(waitEndOfPlayback);
  else
    return;
  end
end

local function stopPlayback()
  reaper.OnStopButton();
  onPlaybackEnd();
end

reaper.defer(startPlayback);
reaper.atexit(stopPlayback);

