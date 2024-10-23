-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local scriptDir = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]];
local upperDir  = scriptDir:match( "((.*)[\\/](.+)[\\/])(.+)$" );

package.path      = scriptDir .."?.lua;".. package.path

local helper_lib                = require "helper_lib"

local KeyActivityManager        = require "input_managers/KeyActivityManager"
local KeyReleaseActivityManager = require "input_managers/KeyReleaseActivityManager"
local KeyPressActivityManager   = require "input_managers/KeyPressActivityManager"

local S         = require "modules/settings"
local D         = require "modules/defines"
local AT        = require "modules/action_triggers"
local MK        = require "modules/markers"
local T         = require "modules/time"
local SNP       = require "modules/snap"
local N         = require "modules/notes"
local TGT       = require "modules/target"
local F         = require "modules/focus"
local MOD       = require "modules/modifiers"
local ED        = require "modules/edition"
local ART       = require "modules/articulations"

local NAVIGATE  = require "operations/navigate"
local REPITCH   = require "operations/repitch"
local INSERT    = require "operations/insert"
local WRITE     = require "operations/write"
local REPLACE   = require "operations/replace"
local STRETCH   = require "operations/stretch"
local STUFF     = require "operations/stuff"

------------------------------------------
-- Variables

-- Our manager for the Action/Pedal mode (use generic one)
local APActivityManager = KeyActivityManager:new();
-- Our manager for the Key Release input mode
local KRActivityManager = KeyReleaseActivityManager:new();
-- Our manager for the Key Press input mode
local KPActivityManager = KeyPressActivityManager:new();

local function currentKeyEventManager()
  local manager = nil
  local mode    = S.getInputMode();

  -- We have different managers for all modes
  -- But their architecture is identical and compliant
  if mode == D.InputMode.KeyboardPress then
    manager = KPActivityManager;
  elseif mode == D.InputMode.KeyboardRelease then
    manager = KRActivityManager;
  else
    manager = APActivityManager;
  end

  return manager
end

-----------------

-- Commits the currently held notes into the take
local function commit(track, take, notes_to_add, notes_to_extend, triggered_by_key_event)

  local currentop       = ED.ResolveOperationMode(true)

  local writeModeOn     = (currentop.mode == "Write")
  local navigateModeOn  = (currentop.mode == "Navigate")
  local insertModeOn    = (currentop.mode == "Insert")
  local replaceModeOn   = (currentop.mode == "Replace")
  local repitchModeOn   = (currentop.mode == "Repitch")
  local stretchModeOn   = false
  local stuffModeOn     = false

  if insertModeOn and currentop.use_alt then
    insertModeOn = false
    stretchModeOn = true
  end

  if replaceModeOn and currentop.use_alt then
    replaceModeOn = false
    stuffModeOn = true
  end

  if navigateModeOn then
    if (not triggered_by_key_event) or S.AllowKeyEventNavigation() then
      return NAVIGATE.NavigateForward(track)
    else
      -- Triggered by key event and not allowed ... do nothing
      return
    end
  end

  -- Other operations perform changes so go.
  if take == nil then
    take = TGT.CreateItemIfMissing(track);
  end

  if repitchModeOn then
    return REPITCH.Repitch(currentKeyEventManager(), track, take, notes_to_add, notes_to_extend, triggered_by_key_event)
  end

  if insertModeOn then
    return INSERT.Insert(currentKeyEventManager(), track, take, notes_to_add, notes_to_extend, triggered_by_key_event)
  end

  if writeModeOn then
    return WRITE.Write(currentKeyEventManager(), track, take, notes_to_add, notes_to_extend, triggered_by_key_event)
  end

  if replaceModeOn then
    return REPLACE.Replace(currentKeyEventManager(), track, take, notes_to_add, notes_to_extend, triggered_by_key_event)
  end

  if stretchModeOn then
    return STRETCH.Stretch(currentKeyEventManager(), track, take, notes_to_add, notes_to_extend, triggered_by_key_event)
  end

  if stuffModeOn then
    return STUFF.Stuff(currentKeyEventManager(), track, take, notes_to_add, notes_to_extend, triggered_by_key_event)
  end
end

local function commitBack(track, take, notes_to_shorten, triggered_by_key_event)

  local currentop       = ED.ResolveOperationMode(true)

  local writeModeOn     = (currentop.mode == "Write")
  local navigateModeOn  = (currentop.mode == "Navigate")
  local insertModeOn    = (currentop.mode == "Insert")
  local replaceModeOn   = (currentop.mode == "Replace")
  local repitchModeOn   = (currentop.mode == "Repitch")
  local stretchModeOn   = false
  local stuffModeOn     = false

  if insertModeOn and currentop.use_alt then
    insertModeOn  = false
    stretchModeOn = true
  end

  if replaceModeOn and currentop.use_alt then
    replaceModeOn = false
    stuffModeOn = true
  end

  if navigateModeOn or not take then
    if triggered_by_key_event and not S.AllowKeyEventNavigation() then
      -- Do nothing, not allowed
      return
    else
      return NAVIGATE.NavigateBack(track)
    end
  end

  if repitchModeOn then
    return REPITCH.RepitchBack(currentKeyEventManager(), track, take, notes_to_shorten, triggered_by_key_event)
  end

  if insertModeOn then
    return INSERT.InsertBack(currentKeyEventManager(), track, take, notes_to_shorten, triggered_by_key_event)
  end

  if writeModeOn then
    return WRITE.WriteBack(currentKeyEventManager(), track, take, notes_to_shorten, triggered_by_key_event)
  end

  if replaceModeOn then
    return REPLACE.ReplaceBack(currentKeyEventManager(), track, take, notes_to_shorten, triggered_by_key_event)
  end

  if stretchModeOn then
    return STRETCH.StretchBack(currentKeyEventManager(), track, take, notes_to_shorten, triggered_by_key_event)
  end

  if stuffModeOn then
    return STUFF.StuffBack(currentKeyEventManager(), track, take, notes_to_shorten, triggered_by_key_event)
  end
end

local function normalizeVelocities(notes_from_manager)
  if not S.getSetting("VelocityLimiterEnabled") then
    return
  end

  local min   = S.getSetting("VelocityLimiterMin")
  local max   = S.getSetting("VelocityLimiterMax")
  local mode  = S.getSetting("VelocityLimiterMode")

  if min > max then
    min, max = max, min
  end

  for i=1, #notes_from_manager do
    local n = notes_from_manager[i]
    if mode == "Clamp" then
      n.vel = (n.vel < min) and (min) or (n.vel)
      n.vel = (n.vel > max) and (max) or (n.vel)
    elseif mode == "Linear" then
      n.vel = min + (n.vel/127.0) * (max - min)
      n.vel = math.floor(n.vel + 0.5) -- This not be an integer, so round
    end
  end
end

-- Listen to events from instrumented tracks that have the JSFX companion effect installed (or install it if not present)
local function listenToEvents()

  -- Reaper should not be in play/pause/rec state
  if (not (reaper.GetPlayState()==0)) then
    return;
  end

  local track = nil;
  local take  = TGT.TakeForEdition();

  if not take then
    if S.getSetting("AllowCreateItem") then
      track = TGT.TrackForEditionIfNoItemFound();
      if not track then
        return
      end
    else
      return
    end
  else
    track = reaper.GetMediaItemTake_Track(take);
  end

  -- If track is not armed for recording, we can't do anything
  local recarmed  = reaper.GetMediaTrackInfo_Value(track, "I_RECARM");
  if not (recarmed == 1) then
    return
  end

  -- Add helper FX if it is missing
  local helper_status = helper_lib.getOrInstallHelperFx(track)
  if helper_status == -1 then
    return -42
  end

  local oss_state = helper_lib.oneSmallStepState(track)

  -- MIDI Editor note highlighting
  if S.getSetting("NoteHiglightingDuringPlay") then
    local pitch = helper_lib.lastPressedPitch(oss_state)
    pitch = (pitch >= 0) and (pitch) or (0)
    local ed = reaper.MIDIEditor_GetActive()
    if ed then
      reaper.MIDIEditor_SetSetting_int(ed, "active_note_row", pitch)
    end
  end

  local mode = S.getInputMode();
  -- Input mode should be engaged
  if mode == D.InputMode.None or S.getSetting("Disarmed") then
    return
  end

  -- Get the manager for the current input mode
  local manager = currentKeyEventManager();

  -- Update manager with new info from the helper JSFX
  manager:updateActivity(track, oss_state);

  local spmod = MOD.IsStepBackModifierKeyPressed();
  local pedal = manager:pullPedalTriggerForTrack(track);

  manager:tryAdvancedCommitForTrack(track,
    function(candidates, held_candidates)

      normalizeVelocities(candidates)
      normalizeVelocities(held_candidates)

      -- The advanced commit is dedicated to key event(s) triggerering
      if not spmod then
        -- Advance
        commit(track, take, candidates, held_candidates, true)
      else
        -- If going back all held notes are candidates for selective removal
        -- So concatenate
        for i=1,#held_candidates do
          candidates[#candidates+1] = held_candidates[i]
        end
        commitBack(track, take, candidates, true)
      end
    end
  );

  -- Allow the use of the action or pedal
  if (pedal and not spmod) or AT.hasForwardActionTrigger() then
    manager:simpleCommit(track, function(commit_candidates, held_candidates)
        normalizeVelocities(commit_candidates)
        normalizeVelocities(held_candidates)

        commit(track, take, commit_candidates, held_candidates, false);
      end
    );
  end

  -- Back action pedal
  if (pedal and spmod) or AT.hasBackwardActionTrigger() then
    manager:simpleCommitBack(track, function(shorten_candidates)
        normalizeVelocities(shorten_candidates)

        commitBack(track, take, shorten_candidates, false)
      end
    );
  end

  manager:clearOutdatedActivity()

  AT.clearAllActionTriggers()

  if S.getSetting("PedalRepeatEnabled") then
    manager:forgetPedalTriggerForTrack(track, S.getSetting("PedalRepeatTime"), S.getSetting("PedalRepeatFirstHitMultiplier"))
  end
end

-- To be called from companion action script
local function reaperAction(action_name)
  AT.setActionTrigger(action_name)
end

local function cleanupCompanionFXs()
  reaper.Undo_BeginBlock()
  helper_lib.cleanupAllTrackFXs();
  reaper.Undo_EndBlock("One Small Step - Cleanup companion JSFXs",-1);
end


local function handleMarkerOnExit(policy_setting_name, marker_name)
  local setting = S.getSetting(policy_setting_name);
  if setting == "Hide/Restore" then
    -- Need to backup the position
    -- Save on master track to be project dependent
    local id, pos     = MK.findMarker(marker_name)
    local masterTrack = reaper.GetMasterTrack(0)
    local str         = "";

    if not (id == nil) then
      str = tostring(pos)
    end

    reaper.GetSetMediaTrackInfo_String(masterTrack, "P_EXT:OneSmallStep:MarkerBackup:" .. marker_name, str, true)
  end

  if (setting == "Hide/Restore") or (setting == "Remove") then
    MK.removeMarker(marker_name)
  end
end

local function mayRestoreMarkerOnStart(policy_setting_name, marker_name)
  local setting = S.getSetting("PlaybackMarkerPolicyWhenClosed");
  if setting == "Hide/Restore" then
    local masterTrack = reaper.GetMasterTrack(0)
    local succ, str = reaper.GetSetMediaTrackInfo_String(masterTrack, "P_EXT:OneSmallStep:MarkerBackup:" .. marker_name, '', false);
    if succ and str ~= "" then
      MK.setMarkerAtPos(marker_name, tonumber(str))
    end
  end
end

local function atStart()
  -- Do some cleanup at engine start
  -- But this adds an undo entry point ...
  -- So rely on the user instead to cleanup the JSFXs using the relevant action
  -- If there's one day a way to prevent reaper from creating Undo points
  -- Then we can uncomment this automatic cleanup
  -- cleanupCompanionFXs();

  AT.clearAllActionTriggers()
  mayRestoreMarkerOnStart("PlaybackMarkerPolicyWhenClosed",   MK.PLAYBACK_MARKER)
  mayRestoreMarkerOnStart("OperationMarkerPolicyWhenClosed",  MK.OPERATION_MARKER)
end

local function atExit()
  -- See comment in atStart

  if S.getSetting("CleanupJsfxAtClosing") then
    cleanupCompanionFXs();
  end

  handleMarkerOnExit("PlaybackMarkerPolicyWhenClosed",  MK.PLAYBACK_MARKER)
  handleMarkerOnExit("OperationMarkerPolicyWhenClosed", MK.OPERATION_MARKER)
end

local function atLoop()
  return listenToEvents();
end

return {
  S                             = S,
  D                             = D,
  AT                            = AT,
  MK                            = MK,
  T                             = T,
  TGT                           = TGT,
  F                             = F,
  MOD                           = MOD,
  ED                            = ED,
  SNP                           = SNP,
  N                             = N,
  ART                           = ART,

  atStart                       = atStart,
  atExit                        = atExit,
  atLoop                        = atLoop,

  reaperAction                  = reaperAction,
}
