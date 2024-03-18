-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local KeyActivityManager   = require "input_managers/KeyActivityManager";
local S                    = require "modules/settings"

-- Inherit from generic KeyActivityManager
KeyPressActivityManager = KeyActivityManager:new();

function KeyPressActivityManager:aggregation()
  return S.getSetting("KeyPressModeAggregationTime");
end

function KeyPressActivityManager:inertia()
  return S.getSetting("KeyPressModeInertiaTime");
end

function KeyPressActivityManager:tryAdvancedCommitForTrack(track, commit_callback)

  local trackid         = reaper.GetTrackGUID(track);
  local track_activity  = self.activity[trackid];
  local note_activity   = track_activity.notes;
  local time            = reaper.time_precise();

  local candidates      = {}
  local held_candidates = {}

  local most_recent_ts = nil;
  for _, v in pairs(note_activity) do
    if (v.committed == nil) then
      -- Everything that is not committed yet is a candidate
      -- The second condition
      candidates[#candidates+1] = v;
      if (most_recent_ts == nil) or (most_recent_ts < v.first_ts) then
        most_recent_ts = v.first_ts;
      end
    end

    if S.getSetting("KeyPressModeInertiaEnabled") and (v.committed == true) and (time - v.first_ts > self:inertia()) then
      held_candidates[#held_candidates+1] = v;
    end
  end

  -- No keys pressed recently, we passed the aggregation window, set as committed and return candidates
  if (#candidates > 0) and ((time - most_recent_ts) > self:aggregation()) then
    for i, candidate in ipairs(candidates) do
      candidate.committed = true;
    end

    if commit_callback then
      commit_callback(candidates, held_candidates)
    end

    return candidates;
  end

  return {};
end

-- Overriden to add the 'committed' condition on notes to remove
function KeyPressActivityManager:clearOutdatedActivity()
  for guid, track_activity in pairs(self.activity) do

    local note_activity   = track_activity.notes;
    local torem = {};

    for k, note_info in pairs(note_activity) do
      if note_info.committed and note_info.released then
        torem[#torem+1] = k;
      end
    end

    for i, v in ipairs(torem) do
      note_activity[v] = nil;
    end
  end
end


return KeyPressActivityManager;
