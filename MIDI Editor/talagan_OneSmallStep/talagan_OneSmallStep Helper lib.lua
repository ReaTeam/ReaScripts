-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

-- Largely inspired by tenfour's version
-- However, I prefer using an extensive list of JS params
-- To avoid having REAPER creating undo points when polling for notes
-- This allow the undo command to work properly
local jsfx                      = {}

jsfx.name                       = "One Small Step Helper"

jsfx.paramIndex_PedalActivity   = 0
jsfx.paramIndex_NotesInBuffer   = 1
jsfx.paramIndex_NoteStart       = 2

-- Add the given fx to the given track.
local function getOrAddInputFx(track, fx)

  local idx = reaper.TrackFX_AddByName(track, fx.name, true, 1)

  if idx == -1 or idx == nil then
    return -1
  end

  -- Use 0x1000000 as flag for input fx chain
  idx = idx|0x1000000

  return idx
end

-- Remove the given fx from the given track
local function removeInputFx(track, fx)
  -- Only lookup, do not instantiate
  local idx = reaper.TrackFX_AddByName(track, fx.name, true, 0);

  if idx == -1 or idx == nil then
    return
  end

  -- Use 0x1000000 as flag for input fx chain
  idx = idx|0x1000000;

  res = reaper.TrackFX_Delete(track, idx);
end



local function getOrInstallHelperFx(track)
  return getOrAddInputFx(track, jsfx)
end
local function removeHelperFx(track)
  return removeInputFx(track, jsfx);
end


-- Cleanup helper function
local function cleanupAllTrackFXs()
  local tc = reaper.CountTracks(0);

  local ti = 0
  while(ti < tc) do
    local track = reaper.GetTrack(0, ti);
    removeHelperFx(track);
    ti = ti + 1;
  end
end


-- Poll the JSFX state from a track
local function oneSmallStepState(track)

  local recarmed = reaper.GetMediaTrackInfo_Value(track, "I_RECARM");

  -- Security when recording
  if not (recarmed == 1) then
    return {
      pitches       = {},
      pedalActivity = 0
    }
  end

  -- Make sure helper is installed
  local iHelper       = getOrAddInputFx(track, jsfx, true)

  local pitches = {}
  local pedalActivity = reaper.TrackFX_GetParam(track, iHelper, jsfx.paramIndex_PedalActivity);
  local heldNoteCount = reaper.TrackFX_GetParam(track, iHelper, jsfx.paramIndex_NotesInBuffer);

  for i = 1, heldNoteCount, 1 do
    -- now the plugin updates its sliders to give us the values for this index.
    local evt = {
      note        = reaper.TrackFX_GetParam(track, iHelper, jsfx.paramIndex_NoteStart + 4*(i-1) + 0),
      chan        = reaper.TrackFX_GetParam(track, iHelper, jsfx.paramIndex_NoteStart + 4*(i-1) + 1),
      velocity    = reaper.TrackFX_GetParam(track, iHelper, jsfx.paramIndex_NoteStart + 4*(i-1) + 2),
      timestamp   = reaper.TrackFX_GetParam(track, iHelper, jsfx.paramIndex_NoteStart + 4*(i-1) + 3)
    }

    pitches[#pitches+1] = evt;
  end

  return {
    pitches       = pitches,
    pedalActivity = pedalActivity
  }
end

local function resetPedalActivity(track)
  local iHelper       = getOrAddInputFx(track, jsfx, true)
  reaper.TrackFX_SetParam(track, iHelper, jsfx.paramIndex_PedalActivity, 0);
end

return {
  getOrInstallHelperFx  = getOrInstallHelperFx,
  removeHelperFx        = removeHelperFx,
  cleanupAllTrackFXs    = cleanupAllTrackFXs,
  oneSmallStepState     = oneSmallStepState,
  resetPedalActivity    = resetPedalActivity
};
