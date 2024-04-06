-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

-- A manager to keep track of key activities
-- With pressed/released/commited info

KeyActivityManager = { activity = {} };

function KeyActivityManager:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  self.activity = {};
  return o
end

function KeyActivityManager:dbgNote(v)
  reaper.ShowConsoleMsg("  - " ..  tostring(math.floor(v.chan+0.5)) .. "," .. tostring(math.floor(v.pitch + 0.5)) .. " " ..
    "(vel: " .. v.vel .. ") " ..
    "(committed : " .. ((v.committed == nil) and 'nil' or 'true') .. ") " ..
    "(released : " ..  ((v.released  == nil) and 'nil' or 'true') .. ") " ..
    "(ts : " .. (v.first_ts or 'nil') .. ") " ..
    "\n");
end

function KeyActivityManager:dbgState()
  for tid, track_activity in pairs(self.activity) do
    reaper.ShowConsoleMsg("Track " .. tid .. "\n");
    local note_activity = track_activity.notes;
    for k, v in pairs(note_activity) do
      self:dbgNote(v);
    end
  end
end

function KeyActivityManager:clearTrackActivityForTrack(track)
  local trackid = reaper.GetTrackGUID(track);
  self.activity[trackid] = { notes = {}, pedal = {} };
end

function KeyActivityManager:pullPedalTriggerForTrack(track)
  local trackid             = reaper.GetTrackGUID(track);
  local pedal_activity      = self.activity[trackid].pedal;

  if pedal_activity.first_ts and not pedal_activity.committed then
    pedal_activity.committed    = true
    pedal_activity.last_commit  = reaper.time_precise()
    pedal_activity.commit_count = (pedal_activity.commit_count or 0) + 1
    return true
  end

  return false
end

function KeyActivityManager:keyActivityForTrack(track)
  local trackid = reaper.GetTrackGUID(track);
  return self.activity[trackid];
end

function KeyActivityManager:forgetPedalTriggerForTrack(track, time, first_hit_multiplier)
  local trackid             = reaper.GetTrackGUID(track);
  local pedal_activity      = self.activity[trackid].pedal;

  if not pedal_activity.committed then
    return
  end

  if pedal_activity.commit_count == 1 then
    time = time * first_hit_multiplier -- The first time, take more time
  end

  if (reaper.time_precise() - pedal_activity.last_commit) > time then
    -- reset commit flag. The pedal can be pulled again.
    pedal_activity.committed = nil
  end
end

function KeyActivityManager:lockPedalRepeaterTillNextRelease(track)
  local trackid             = reaper.GetTrackGUID(track);
  local pedal_activity      = self.activity[trackid].pedal;

  if not pedal_activity.committed then
    return
  end

  pedal_activity.last_commit = 1/0 -- inf
end


function KeyActivityManager:updateActivity(track, oss_state)

  local trackid   = reaper.GetTrackGUID(track);
  local t         = reaper.time_precise();

  -- Create activity if needed
  if self.activity[trackid] == nil then
    self:clearTrackActivityForTrack(track);
  end

  -- Update pedal tracking
  if oss_state.pedalActivity > 0 then
    local pedal_activity = self.activity[trackid].pedal;
    pedal_activity.first_ts   = oss_state.pedalActivity;
    pedal_activity.latest_ts  = t;
  else
    self.activity[trackid].pedal = {};
  end

  -- Update note(s) tracking
  local note_activity  = self.activity[trackid].notes;
  for _, v in pairs(oss_state.pitches) do

    if v.timestamp == 0 then
      -- Hack... sometimes we read null events from JSFX, need to investiagate
      goto continue
    end

    local k = tostring(math.floor(v.chan + 0.5)) .. "," .. tostring(math.floor(v.pitch + 0.5))

    note_activity[k] = note_activity[k] or {};

    if note_activity[k].first_ts ~= v.timestamp then
      -- We use the ts (note on date) as ID
      -- Since the timestamp does not match our pending/remaining note
      note_activity[k].committed = nil;
      note_activity[k].released  = nil;
    end

    note_activity[k].pitch       = v.pitch;
    note_activity[k].chan        = v.chan;
    note_activity[k].vel         = v.vel;
    note_activity[k].first_ts    = v.timestamp;
    note_activity[k].latest_ts   = t;

    ::continue::
  end

  -- Update released key states
  for k, vals in pairs(note_activity) do
    if vals.latest_ts ~= t then
      -- The key is released because it was not updated this time
      vals.released = true
    end
  end
end

-- Commit non committed held notes, and propose as simple candidates
-- Propose already committed held notes as extend candidates
function KeyActivityManager:simpleCommit(track, commit_callback)
  local trackid         = reaper.GetTrackGUID(track);
  local track_activity  = self.activity[trackid];
  local note_activity   = track_activity.notes;

  local commit_candidates = {};
  local extend_candidates = {};

  for _, v in pairs(note_activity) do
    if (v.committed == nil) then
      -- Everything that is not committed yet is a candidate
      v.committed = true;
      commit_candidates[#commit_candidates+1] = v;
    elseif (v.released == nil) then
      extend_candidates[#extend_candidates+1] = v;
    end
  end

  commit_callback(commit_candidates, extend_candidates);

  return {};
end

-- Commit all held notes, and propose them as commit candidates
function KeyActivityManager:simpleCommitBack(track, commit_callback)
  local trackid           = reaper.GetTrackGUID(track);
  local track_activity    = self.activity[trackid];
  local note_activity     = track_activity.notes;
  local commit_candidates = {};

  for _, v in pairs(note_activity) do
    if (v.released == nil) then
      v.committed = true;
      commit_candidates[#commit_candidates+1] = v;
    end
  end

  commit_callback(commit_candidates);

  return {};
end


-- The default behaviour for the cleanup is to remove all notes that have been committed and released.
function KeyActivityManager:clearOutdatedActivity()
  for guid, track_activity in pairs(self.activity) do
    local note_activity = track_activity.notes;

    -- Clear outdated keys
    local torem = {};

    for k, note_info in pairs(note_activity) do
      if note_info.released then
        torem[#torem+1] = k;
      end
    end

    for i, v in ipairs(torem) do
      note_activity[v] = nil;
    end
  end
end

function KeyActivityManager:tryAdvancedCommitForTrack(track)
  -- Do nothing by default
end

return KeyActivityManager;
