-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

-- A manager to keep track of key activities
-- When releasing keys
-- With inertia, to avoid losing events for chords
-- (the release events may not be totally synchronized)

KeyReleaseActivityManager = { activity = {} }

function KeyReleaseActivityManager:new()
  local o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.activity = {};
  return o
end

function KeyReleaseActivityManager:inertia()
  return 0.2;
end

--
function KeyReleaseActivityManager:keepTrackOfKeysForTrack(track, pressed_keys)
  local trackid   = reaper.GetTrackGUID(track);
  local t         = reaper.time_precise();

  if self.activity[trackid] == nil then
    self.activity[trackid] = {}
  end

  for _, v in pairs(pressed_keys) do
    local k               = tostring(math.floor(v.chan+0.5)) .. "," .. tostring(math.floor(v.note+0.5))
    local track_activity  = self.activity[trackid];

    track_activity[k] = track_activity[k] or {
      note      = v.note,
      chan      = v.chan,
      velocity  = v.velocity,
      first_ts  = v.timestamp,
      latest_ts = t
    };

    -- Update activity ts
    track_activity[k].latest_ts = t;
  end
end

function KeyReleaseActivityManager:keyActivityForTrack(track)
  local trackid        = reaper.GetTrackGUID(track);
  local track_activity = self.activity[trackid];

  if track_activity == nil then
    return {}
  end

  local ret = {};
  for _, v in pairs(track_activity) do
   ret[#ret+1] = v;
  end

  return ret;
end

function KeyReleaseActivityManager:clearTrackActivityForTrack(track)
  local trackid = reaper.GetTrackGUID(track);
  self.activity[trackid] = {};
end

function KeyReleaseActivityManager:clearOutdatedTrackActivity()
  local t         = reaper.time_precise();

  -- Do some cleanup
  for guid, track_activity in pairs(self.activity) do

    local torem = {};
    for k, note_info in pairs(track_activity) do
      -- If the key is not held anymore, for more than the inertia time, remove it
      if t - note_info.latest_ts > self:inertia() then
        torem[#torem+1] = k;
      end
    end

    for k,v in pairs(torem) do
      track_activity[v] = nil;
    end
  end

end

return KeyReleaseActivityManager;