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
jsfx.paramIndex_Pedal65Activity    = 1
jsfx.paramIndex_Pedal66Activity    = 2
jsfx.paramIndex_Pedal67Activity    = 3
jsfx.paramIndex_Pedal68Activity    = 4
jsfx.paramIndex_Pedal69Activity    = 5

jsfx.paramIndex_NotesInBuffer   = 6
jsfx.paramIndex_NoteStart       = 7

-- Add the given fx to the given track.
local function getOrAddInputFx(track, fx)

  -- Check first.
  local idx = reaper.TrackFX_AddByName(track, fx.name, true, 0);

  if idx == -1 or idx == nil then
    reaper.Undo_BeginBlock();

    local _, tname  = reaper.GetTrackName(track);
    -- Try to add it.
    idx             = reaper.TrackFX_AddByName(track, fx.name, true, 1);

    if idx == -1 or idx == nil then
      reaper.Undo_EndBlock("One Small Step : Add companion JSFX on track " .. tname,-1);
      return -1;
    else
      -- It worked, hide it in case the option to pop up new added FXs is checked
      reaper.TrackFX_SetOpen(track, idx|0x1000000, false);
      reaper.Undo_EndBlock("One Small Step : Add companion JSFX on track " .. tname,-1);
    end
  end

  -- Use 0x1000000 as flag for input fx chain
  return idx|0x1000000
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

  return reaper.TrackFX_Delete(track, idx);
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
      pitches         = {},
      pedalActivity   = 0,
      pedalActivity65 = 0,
      pedalActivity66 = 0,
      pedalActivity67 = 0,
      pedalActivity68 = 0,
      pedalActivity69 = 0,
    }
  end

  -- Make sure helper is installed
  local iHelper       = getOrAddInputFx(track, jsfx)

  local pitches = {}
  local pedalActivity = reaper.TrackFX_GetParam(track, iHelper, jsfx.paramIndex_PedalActivity);
  local heldNoteCount = reaper.TrackFX_GetParam(track, iHelper, jsfx.paramIndex_NotesInBuffer);

  local pedalActivity65 = reaper.TrackFX_GetParam(track, iHelper, jsfx.paramIndex_Pedal65Activity);
  local pedalActivity66 = reaper.TrackFX_GetParam(track, iHelper, jsfx.paramIndex_Pedal66Activity);
  local pedalActivity67 = reaper.TrackFX_GetParam(track, iHelper, jsfx.paramIndex_Pedal67Activity);
  local pedalActivity68 = reaper.TrackFX_GetParam(track, iHelper, jsfx.paramIndex_Pedal68Activity);
  local pedalActivity69 = reaper.TrackFX_GetParam(track, iHelper, jsfx.paramIndex_Pedal69Activity);

  for i = 1, heldNoteCount, 1 do
    -- now the plugin updates its sliders to give us the values for this index.
    local evt = {
      pitch       = reaper.TrackFX_GetParam(track, iHelper, jsfx.paramIndex_NoteStart + 4*(i-1) + 0),
      chan        = reaper.TrackFX_GetParam(track, iHelper, jsfx.paramIndex_NoteStart + 4*(i-1) + 1),
      vel         = reaper.TrackFX_GetParam(track, iHelper, jsfx.paramIndex_NoteStart + 4*(i-1) + 2),
      timestamp   = reaper.TrackFX_GetParam(track, iHelper, jsfx.paramIndex_NoteStart + 4*(i-1) + 3)
    }

    pitches[#pitches+1] = evt;
  end

  return {
    pitches         = pitches,
    pedalActivity   = pedalActivity,

    pedalActivity65 = pedalActivity65,
    pedalActivity66 = pedalActivity66,
    pedalActivity67 = pedalActivity67,
    pedalActivity68 = pedalActivity68,
    pedalActivity69 = pedalActivity69,
  }
end

local function lastPressedPitch(oss_state)
  if oss_state == nil or #oss_state.pitches == 0 then
    return -1
  end

  local pitch = oss_state.pitches[1].pitch
  local ts    = oss_state.pitches[1].timestamp

  for i = 1, #oss_state.pitches, 1 do
    if oss_state.pitches[i].timestamp > ts then
      ts = oss_state.pitches[i].timestamp
      pitch = oss_state.pitches[i].pitch
    end
  end

  return pitch
end

local function isModifierPedalDown(oss_state, pedal_num)
  return (oss_state['pedalActivity' .. pedal_num] or 0) > 0
end

return {
  getOrInstallHelperFx  = getOrInstallHelperFx,
  removeHelperFx        = removeHelperFx,
  cleanupAllTrackFXs    = cleanupAllTrackFXs,
  oneSmallStepState     = oneSmallStepState,
  lastPressedPitch      = lastPressedPitch,
  isModifierPedalDown   = isModifierPedalDown
}
