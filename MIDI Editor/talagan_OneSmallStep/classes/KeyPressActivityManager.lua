-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

-- A manager to keep track of key activities
-- When releasing keys
-- With inertia, to avoid losing events for chords
-- (the release events may not be totally synchronized)

KeyPressActivityManager = { activity = {} };

function KeyPressActivityManager:new()
  local o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.activity = {};
  return o
end

function KeyPressActivityManager:inertia()
  return 0.050;
end

function KeyPressActivityManager:keepTrackOfKeysForTrack(track, pressed_keys)
  local trackid   = reaper.GetTrackGUID(track);
  local t         = reaper.time_precise();

  if self.activity[trackid] == nil then
    self.activity[trackid] = {}
  end

  local track_activity = self.activity[trackid];

  for _, v in pairs(pressed_keys) do

    if v.timestamp == 0 then
      -- Hack... sometimes we read null events from JSFX, need to investiagate
      goto continue
    end

    local k = tostring(math.floor(v.chan+0.5)) .. "," .. tostring(math.floor(v.note+0.5))

    track_activity[k] = track_activity[k] or {};

    if track_activity[k].first_ts ~= v.timestamp then
      -- We use the ts (note on date) as ID
      -- Since the timestamp does not match our pending/remaining note
      track_activity[k].committed = nil;
      track_activity[k].released  = nil;
    end

    track_activity[k].note        = v.note;
    track_activity[k].chan        = v.chan;
    track_activity[k].velocity    = v.velocity;
    track_activity[k].first_ts    = v.timestamp;
    track_activity[k].latest_ts   = t;

    ::continue::
  end

  -- Update released key states
  for k, vals in pairs(track_activity) do
    if vals.latest_ts ~= t then
      -- The key is released because it was not updated this time
      vals.released = true
    end
  end
end

function KeyPressActivityManager:pullNotesToCommitForTrack(track)
  local trackid        = reaper.GetTrackGUID(track);
  local track_activity = self.activity[trackid];

  if track_activity == nil then
    return {}
  end

  local candidates = {}

  local most_recent_ts = nil;
  for _, v in pairs(track_activity) do
    if (v.committed == nil) then
      -- Everything that is not committed yet is a candidate
      candidates[#candidates+1] = v;
      if (most_recent_ts == nil) or (most_recent_ts < v.first_ts) then
        most_recent_ts = v.first_ts;
      end
    end
  end

  if (#candidates > 0) and ((reaper.time_precise() - most_recent_ts) > self:inertia()) then
    for i, candidate in ipairs(candidates) do
      candidate.committed = true;
    end
    return candidates;
  end

  return {};
end

function KeyPressActivityManager:clearTrackActivityForTrack(track)
  local trackid = reaper.GetTrackGUID(track);
  self.activity[trackid] = {};
end

function KeyPressActivityManager:clearOutdatedTrackActivity()

  for guid, track_activity in pairs(self.activity) do
    -- Clear outdated keys
    local torem = {};

    for k, note_info in pairs(track_activity) do
      if note_info.committed and note_info.released then
        -- Check for the committed flag (we don't want to re-add the event, so be sure it wont reappear)
        torem[#torem+1] = k;
      end
    end

    for i, v in ipairs(torem) do
      track_activity[v] = nil;
    end
  end

end

return KeyPressActivityManager;