-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local KeyActivityManager   = require "input_managers/KeyActivityManager";
local S                    = require "modules/settings"

-- Inherit from generic KeyActivityManager
KeyReleaseActivityManager = KeyActivityManager:new();

function KeyReleaseActivityManager:inertia()
  return S.getSetting("KeyReleaseModeForgetTime");
end

-- We need to override the default cleanup because we want to keep track of
-- Non committed but released keys
function KeyReleaseActivityManager:clearOutdatedActivity()
  local t         = reaper.time_precise();

  -- Do some cleanup
  for guid, track_activity in pairs(self.activity) do

    local note_activity   = track_activity.notes;
    local torem = {};

    for k, note_info in pairs(note_activity) do
      -- If the key is not held anymore, for more than the inertia time, remove it
      if t - note_info.latest_ts > self:inertia() then
        torem[#torem+1] = k;
      end
    end

    for k,v in pairs(torem) do
      note_activity[v] = nil;
    end
  end
end

function KeyReleaseActivityManager:tryAdvancedCommitForTrack(track, commit_callback)
  local trackid         = reaper.GetTrackGUID(track);
  local track_activity  = self.activity[trackid];
  local note_activity   = track_activity.notes;

  local unreleased_count = 0;
  for _, v in pairs(note_activity) do
    if (v.committed == nil) and (v.released == nil) then
      unreleased_count = unreleased_count + 1;
    end
  end

  local candidates = {}
  if unreleased_count == 0 then
    -- Check if we have
    for _, v in pairs(note_activity) do
      if v.committed == nil and v.released then
        v.committed = true;
        candidates[#candidates+1] = v
      end
    end
  end

  -- Perform the commit of released keys
  if #candidates > 0 then
    if commit_callback then
      commit_callback(candidates, {})
    end
  end

  return candidates;
end


return KeyReleaseActivityManager;
