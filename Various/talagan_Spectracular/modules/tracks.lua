-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

-- Tracks helper functions.

ReaTrack = {}
ReaTrack.__index = ReaTrack

-- sample_rate is the sample rate of the signal to anayse
function ReaTrack:new(reaper_track)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(reaper_track)
    return instance
end

function ReaTrack:_initialize(reaper_track)
    self._track = reaper_track
    self.guid   = reaper.GetTrackGUID(reaper_track)
end

function ReaTrack:stillValid()
    return reaper.ValidatePtr(self._track, "MediaTrack*")
end

-----------------

-- From a list of ReaTrack, builds a lookup per GUID
local function BuildTrackListLookup(reatrack_list)
    local track_lookup = {}

    for ti = 1, #reatrack_list do
        local rt = reatrack_list[ti]
        track_lookup[rt.guid] = rt
        ti = ti + 1
    end

    return track_lookup
end

-----------------

local function GetSelectedTracks(proj)
    local selectedTracks = {}
    local ti = 0;
    while ti < reaper.CountSelectedTracks(proj) do
        selectedTracks[#selectedTracks+1] = ReaTrack:new(reaper.GetSelectedTrack(proj,ti))
        ti = ti + 1;
    end
    return selectedTracks
end

local function DeselectAllTracks(proj)
    local tcount = reaper.GetNumTracks()

    local ti = 0
    while ti < tcount do
        local t = reaper.GetTrack(0,ti)
        reaper.SetTrackSelected(t,false)
        ti = ti + 1
    end
end

local function RestoreSelectedTracks(proj, reatracks)
    DeselectAllTracks(proj)
    local ti = 1
    while ti <= #reatracks do
        reaper.SetTrackSelected(reatracks[ti]._track, true)
        ti = ti+1
    end
end

local function CreateTrackAtEnd(proj, want_default_fxs)
    local trackCount = reaper.CountTracks(proj)

    -- Insert neutral track at the end of the project
    reaper.InsertTrackAtIndex(trackCount, want_default_fxs)
    -- Get the track
    local new_track = reaper.GetTrack(0, trackCount)
    return ReaTrack:new(new_track)
end

--- Returns full track list (ReaTrack)
local function GetTracks(proj)
    local ret = {}
    local tcount = reaper.GetNumTracks()

    local ti = 0;
    while ti < tcount do
        ret[#ret+1] = ReaTrack:new(reaper.GetTrack(proj, ti))
        ti = ti + 1
    end
    return ret
end

-- Given an old track list, returns 3 lists for newly, removed, or kept tracks
local function GetDiffTracks(proj, old_track_list)
    local new_track_list      = {}
    local kept_track_list     = {}
    local deleted_track_list  = {}

    -- Build a lookup per GUID to search in the old track list
    local tcount = reaper.GetNumTracks()

    local old_track_lookup = BuildTrackListLookup(old_track_list)

    -- span new tracks and classify new/kept
    local ti = 0
    while ti < tcount do
        local t = ReaTrack:new(reaper.GetTrack(proj, ti))
        if not old_track_lookup[t.guid] then
            new_track_list[#new_track_list+1] = t
        else
            kept_track_list[#kept_track_list+1] = t
        end
        ti = ti + 1
    end

    local new_track_lookup  = BuildTrackListLookup(new_track_list)
    local kept_track_lookup = BuildTrackListLookup(kept_track_list)

    -- Look for deleted tracks
    for ti = 1, #old_track_list do
        local t = old_track_list[ti]
        if not new_track_lookup[t.guid] and not kept_track_lookup[t.guid] then
            deleted_track_list[#deleted_track_list+1] = t
        end
    end

    return new_track_list, deleted_track_list, kept_track_list
end

---------------

return {
    GetTracks               = GetTracks,
    GetSelectedTracks       = GetSelectedTracks,
    DeselectAllTracks       = DeselectAllTracks,
    RestoreSelectedTracks   = RestoreSelectedTracks,
    GetDiffTracks           = GetDiffTracks,
    CreateTrackAtEnd        = CreateTrackAtEnd
}
