-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local scriptDir = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]];
local upperDir  = scriptDir:match( "((.*)[\\/](.+)[\\/])(.+)$" );

package.path      = scriptDir .."?.lua;".. package.path

local helper_lib                = require "helper_lib";

local KeyActivityManager        = require "KeyActivityManager";
local KeyReleaseActivityManager = require "KeyReleaseActivityManager";
local KeyPressActivityManager   = require "KeyPressActivityManager";

local launchTime                = reaper.time_precise();

-------------
-- Defines

local NoteLenDefs = {
  { id = "1",    next = "1",    prec = "1_2",   qn = 4      },
  { id = "1_2",  next = "1",    prec = "1_4",   qn = 2      },
  { id = "1_4",  next = "1_2",  prec = "1_8",   qn = 1      },
  { id = "1_8",  next = "1_4",  prec = "1_16",  qn = 0.5    },
  { id = "1_16", next = "1_8",  prec = "1_32",  qn = 0.25   },
  { id = "1_32", next = "1_16", prec = "1_64",  qn = 0.125  },
  { id = "1_64", next = "1_32", prec = "1_64",  qn = 0.0625 }
};
local AugmentedDiminishedDefs = {
  { id = '1/2', mod = 1 / 2.0 },
  { id = '1/3', mod = 1 / 3.0 },
  { id = '2/3', mod = 2 / 3.0 },
  { id = '1/4', mod = 1 / 4.0 },
  { id = '3/4', mod = 3 / 4.0 },
  { id = '1/5', mod = 1 / 5.0 },
  { id = '2/5', mod = 2 / 5.0 },
  { id = '3/5', mod = 3 / 5.0 },
  { id = '4/5', mod = 4 / 5.0 },
  { id = '1/6', mod = 1 / 6.0 },
  { id = '5/6', mod = 5 / 6.0 },
  { id = '1/7', mod = 1 / 7.0 },
  { id = '2/7', mod = 2 / 7.0 },
  { id = '3/7', mod = 3 / 7.0 },
  { id = '4/7', mod = 4 / 7.0 },
  { id = '5/7', mod = 5 / 7.0 },
  { id = '6/7', mod = 6 / 7.0 },
  { id = '1/8', mod = 1 / 8.0 },
  { id = '3/8', mod = 3 / 8.0 },
  { id = '5/8', mod = 5 / 8.0 },
  { id = '7/8', mod = 7 / 8.0 },
  { id = '1/9', mod = 1 / 9.0 },
  { id = '2/9', mod = 2 / 9.0 },
  { id = '4/9', mod = 4 / 9.0 },
  { id = '5/9', mod = 5 / 9.0 },
  { id = '7/9', mod = 7 / 9.0 },
  { id = '8/9', mod = 8 / 9.0 }
};

local MacOSModifierKeys = {
  { vkey = 16, name = 'Shift' },
  { vkey = 17, name = 'Cmd' },
  { vkey = 18, name = 'Opt' },
  { vkey = 91, name = 'Ctrl' }
};

local OtherOSModifierKeys = {
  { vkey = 16, name = 'Shift' },
  { vkey = 17, name = 'Ctrl' },
  { vkey = 18, name = 'Alt' }
};

local IsMacos         = (reaper.GetOS():find('OSX') ~= nil);
local ModifierKeys    = IsMacos and MacOSModifierKeys or OtherOSModifierKeys;

local NoteLenLookup = {};
for i,v in ipairs(NoteLenDefs) do
  NoteLenLookup[v.id] = v;
end

local AugmentedDiminishedLookup = {};
for i,v in ipairs(AugmentedDiminishedDefs) do
  AugmentedDiminishedLookup[v.id] = v;
end

local ModifierKeyLookup = {};
for i,v in ipairs(ModifierKeys) do
  ModifierKeyLookup[v.vkey] = v;
end


local NoteLenParamSource = {
  OSS           = 0,
  ProjectGrid   = 1,
  ItemConf      = 2
}

local InputMode = {
  None              = 0,
  Punch             = 1,
  KeyboardRelease   = 2,
  Action            = 3, -- Removed, merged with pedal
  KeyboardPress     = 4
}

local NoteLenModifier = {
  Straight  = 0,
  Dotted    = 1,
  Triplet   = 2,
  Tuplet    = 3,
  Modified  = 4
}
-------------
-- Settings

local SettingDefs = {
  PlaybackMeasureCount                                      = { type = "int",     default = -1 }, -- -1 is marker mode
  Mode                                                      = { type = "int",     default = InputMode.KeyboardRelease },
  NoteLenParamSource                                        = { type = "int",     default = NoteLenParamSource.OSS },
  NoteLenADSign                                             = { type = "string",  default = "+" },
  NoteADFactor                                              = { type = "string",  default = "1/2" },
  TupletDivision                                            = { type = "int",     default = 4 },
  NoteLen                                                   = { type = "string",  default = "1_4"},
  NoteLenModifier                                           = { type = "int",     default = NoteLenModifier.Straight },
  ------
  AllowTargetingFocusedMidiEditors                          = { type = "bool",    default = true },
  AllowTargetingNonSelectedItemsUnderCursor                 = { type = "bool",    default = false },
  AllowCreateItem                                           = { type = "bool",    default = false },
  AllowErasingWhenNoteEndDoesNotMatchCursor                 = { type = "bool",    default = true },
  PlaybackMarkerPolicyWhenClosed                            = { type = "string",  default = "Keep visible" },
  StepBackSustainPedalModifierKey                           = { type = "int",     default = 16 },
  InsertModeSustainPedalModifierKey                         = { type = "int",     default = 17 },
  PreventAddingNotesIfModifierKeyIsPressed                  = { type = "bool",    default = true},
  CleanupJsfxAtClosing                                      = { type = "bool",    default = true},
  SelectInputNotes                                          = { type = "bool",    default = true},
  ------
  KeyPressModeAggregationTime                               = { type = "double",  default = 0.05, min = 0,   max = 0.1 },
  KeyPressModeInertiaTime                                   = { type = "double",  default = 0.5,  min = 0.2, max = 1.0 },
  KeyPressModeInertiaEnabled                                = { type = "bool",    default = true},

  KeyReleaseModeForgetTime                                  = { type = "double",  default = 0.200, min = 0.05, max = 0.4},

  PedalRepeatEnabled                                        = { type = "bool" ,   default = true },
  PedalRepeatTime                                           = { type = "double",  default = 0.200, min = 0.05, max = 0.5 },
  PedalRepeatFirstHitMultiplier                             = { type = "int",     default = 4, min = 1, max = 10 }
};

local function unsafestr(str)
  if str == "" then
    return nil
  end
  return str
end

local function getSetting(setting)
  local spec  = SettingDefs[setting];

  if spec == nil then
    error("Trying to get unknown setting " .. setting);
  end

  local val = unsafestr(reaper.GetExtState("OneSmallStep", setting));

  if val == nil then
    val = spec.default;
  else
    if spec.type == 'bool' then
      val = (val == "true");
    elseif spec.type == 'int' then
      val = tonumber(val);
    elseif spec.type == 'double' then
      val = tonumber(val);
    elseif spec.type == 'string' then
      -- No conversion needed
    end
  end
  return val;
end
local function setSetting(setting, val)
  local spec  = SettingDefs[setting];

  if spec == nil then
    error("Trying to set unknown setting " .. setting);
  end

  if val == nil then
    reaper.DeleteExtState("OneSmallStep", setting, true);
  else
    if spec.type == 'bool' then
      val = (val == true) and "true" or "false";
    elseif spec.type == 'int' then
      val = tostring(val);
    elseif spec.type == 'double' then
      val = tostring(val);
    elseif spec.type == "string" then
      -- No conversion needed
    end
    reaper.SetExtState("OneSmallStep", setting, val, true);
  end
end
local function resetSetting(setting)
  setSetting(setting, SettingDefs[setting].default)
end
local function getSettingSpec(setting)
  return SettingDefs[setting]
end

local function setPlaybackMeasureCount(c)         return setSetting("PlaybackMeasureCount", c)  end
local function getPlaybackMeasureCount()          return getSetting("PlaybackMeasureCount")     end

local function setInputMode(m)                    return setSetting("Mode", m)  end
local function getInputMode()                     return getSetting("Mode")     end

local function setNoteLenParamSource(m)           return setSetting("NoteLenParamSource", m)  end
local function getNoteLenParamSource()            return getSetting("NoteLenParamSource")     end

local function setNoteADSign(plus_or_minus)       return setSetting("NoteLenADSign", plus_or_minus)   end
local function getNoteADSign()                    return getSetting("NoteLenADSign")                  end

local function setNoteADFactor(fraction_string)   return setSetting("NoteADFactor", fraction_string)   end
local function getNoteADFactor()                  return getSetting("NoteADFactor")                    end

local function setTupletDivision(m)               return setSetting("TupletDivision", m)   end
local function getTupletDivision()                return getSetting("TupletDivision")      end

local function setNoteLen(nl)                     return setSetting("NoteLen", nl)  end
local function getNoteLen()                       return getSetting("NoteLen")      end

local function setNoteLenModifier(nl)             return setSetting("NoteLenModifier", nl)  end
local function getNoteLenModifier()               return getSetting("NoteLenModifier")      end


---------------
-- FOCUS TOOLS

local function IsActiveMidiEditorFocused()
  local me  = reaper.MIDIEditor_GetActive()
  local f   = reaper.JS_Window_GetFocus();
  while f do
    if f == me then
      return true
    end
    f = reaper.JS_Window_GetParent(f);
  end
  return false
end

local function IsArrangeViewFocused()
  return (reaper.GetCursorContext() >= 0);
end

local lastKnownFocus = {};
local function TrackFocus()
  if IsActiveMidiEditorFocused() then
    lastKnownFocus = { element = 'MIDIEditor' }
  elseif IsArrangeViewFocused() then
    lastKnownFocus = { element = 'ArrangeView', context = reaper.GetCursorContext() }
  else
    -- Simply ignore, we don't want to give back focus to this
  end
end

local function RestoreFocus()

  local hwnd = reaper.GetMainHwnd();
  reaper.JS_Window_SetFocus(hwnd);

  if lastKnownFocus.element == 'MIDIEditor' then
    reaper.JS_Window_SetFocus(reaper.MIDIEditor_GetActive());
  elseif lastKnownFocus.element == 'ArrangeView' then
    reaper.SetCursorContext(lastKnownFocus.context)
  else
    -- We don't know how to restore focus in a better way
  end
end

-----------------------------------
-- Triggers for external actions

-- The three functions are used to communicate between the independent actions and OSS
local function setActionTrigger(action_name)
  reaper.SetExtState("OneSmallStep", action_name, tostring(reaper.time_precise()), false);
end
local function getActionTrigger(action_name)
  return tonumber(reaper.GetExtState("OneSmallStep", action_name));
end
local function clearActionTrigger(action_name)
  reaper.DeleteExtState("OneSmallStep", action_name, true);
end

local function setCommitActionTrigger()         return setActionTrigger(   "CommitActionTrigger") end
local function getCommitActionTrigger()         return getActionTrigger(   "CommitActionTrigger") end
local function clearCommitActionTrigger()       return clearActionTrigger( "CommitActionTrigger") end

local function setCommitBackActionTrigger()     return setActionTrigger(   "CommitBackActionTrigger") end
local function getCommitBackActionTrigger()     return getActionTrigger(   "CommitBackActionTrigger") end
local function clearCommitBackActionTrigger()   return clearActionTrigger( "CommitBackActionTrigger") end

local function setInsertActionTrigger()         return setActionTrigger(   "InsertActionTrigger") end
local function getInsertActionTrigger()         return getActionTrigger(   "InsertActionTrigger") end
local function clearInsertActionTrigger()       return clearActionTrigger( "InsertActionTrigger") end

local function setInsertBackActionTrigger()     return setActionTrigger(   "InsertBackActionTrigger") end
local function getInsertBackActionTrigger()     return getActionTrigger(   "InsertBackActionTrigger") end
local function clearInsertBackActionTrigger()   return clearActionTrigger( "InsertBackActionTrigger") end

------------

-- Our manager for the Action/Pedal mode (use generic one)
local APActivityManager = KeyActivityManager:new();

-- Our manager for the Key Release input mode
local KRActivityManager = KeyReleaseActivityManager:new();

-- Our manager for the Key Press input mode
local KPActivityManager = KeyPressActivityManager:new();

-------------
-- Playback

function findPlaybackMarker()
  local mc = reaper.CountProjectMarkers(0);
  for i=0, mc, 1 do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i);
    if name == "OSS Playback" then
      return i, pos;
    end
  end
  return nil;
end

function setPlaybackMarkerAtPos(pos)
  local id, mpos  = findPlaybackMarker();

  reaper.Undo_BeginBlock();
  if not (id == nil) then
    reaper.DeleteProjectMarkerByIndex(0, id);
  end

  if (mpos == nil) or math.abs(pos - mpos) > 0.001 then
    reaper.AddProjectMarker2(0, false, pos, 0, "OSS Playback", -1, reaper.ColorToNative(0,200,255)|0x1000000);
  end
  reaper.Undo_EndBlock("One Small Step - Set playback marker", -1);
end

function setPlaybackMarkerAtCurrentPos()
  setPlaybackMarkerAtPos(reaper.GetCursorPosition());
end

function removePlaybackMarker()
  reaper.Undo_BeginBlock();
  local id, mpos  = findPlaybackMarker();
  if not (id == nil) then
    reaper.DeleteProjectMarkerByIndex(0, id);
  end
  reaper.Undo_EndBlock("One Small Step - Remove playback marker", -1);
end

------------------

local function IsSPStepBackModifierKeyPressed()
  -- Avoid inconsistencies and only follow events during the lifetime of the plugin, so use launchTime
  -- This will prevent bugs from a session to another (when for example the plugin crashes)
  local keys = reaper.JS_VKeys_GetState(launchTime);
  local c1 = keys:byte(getSetting("StepBackSustainPedalModifierKey"));
  return (c1 == 1);
end
local function getSPStepBackModifierKey()
  return ModifierKeyLookup[getSetting("StepBackSustainPedalModifierKey")];
end

local function IsSPInsertModifierKeyPressed()
  -- Avoid inconsistencies and only follow events during the lifetime of the plugin, so use launchTime
  -- This will prevent bugs from a session to another (when for example the plugin crashes)
  local keys = reaper.JS_VKeys_GetState(launchTime);
  local c1 = keys:byte(getSetting("InsertModeSustainPedalModifierKey"));
  return (c1 == 1);
end
local function getSPInsertModifierKey()
  return ModifierKeyLookup[getSetting("InsertModeSustainPedalModifierKey")];
end

-----------------

local function getNoteLenModifierFactor()

  local m = getNoteLenModifier();

  if m == NoteLenModifier.Straight then
    return 1.0;
  elseif m == NoteLenModifier.Dotted then
    return 1.5;
  elseif m == NoteLenModifier.Triplet then
    return 2/3.0;
  elseif m == NoteLenModifier.Modified then
    local sign    = getNoteADSign();
    local factor  = AugmentedDiminishedLookup[getNoteADFactor()].mod;

    return 1 + (sign == '+' and 1 or -1) * factor;
  elseif m == NoteLenModifier.Tuplet then
    local div = getTupletDivision();
    return 2.0/div;
  end

  return 1.0;
end

local function increaseNoteLen()
  local l = getNoteLen();
  setNoteLen(NoteLenLookup[l].next);
end

local function decreaseNoteLen()
  local l = getNoteLen();
  setNoteLen(NoteLenLookup[l].prec);
end

local function getNoteLenQN()
  local nl  = getNoteLen();

  return NoteLenLookup[nl].qn;
end

-------------------

local function MediaItemContainsCursor(mediaItem, cusorPos)
  local pos       = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
  local len       = reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")

  local fudge = 0.002;
  local left  = pos - fudge;
  local right = pos + len + fudge;

  -- Only keep items that contain the cursor pos
  return (cusorPos >= left) and (cusorPos <= right);
end


local function TryToGetTakeFromMidiEditor()
  local midiEditor   = reaper.MIDIEditor_GetActive();
  local midiEditorOk = not (reaper.MIDIEditor_GetMode(midiEditor) == -1);

  -- Prioritize the currently focused MIDI editor.
  -- Use the last known focused element (between arrange view / midi editor) as it is more robust
  -- When OSS window is focused for editing parameters
  if midiEditorOk and lastKnownFocus.element == "MIDIEditor" then
    --  -1 if ME not focused
    take = reaper.MIDIEditor_GetTake(midiEditor);
    if take then
      local mediaItem  = reaper.GetMediaItemTake_Item(take);
      if MediaItemContainsCursor(mediaItem, reaper.GetCursorPosition()) then
        return take
      end
    end
  end

  return nil;
end

local function TryToGetTakeFromArrangeViewAmongSelectedItems()
  local mediaItemCount = reaper.CountSelectedMediaItems(0);
  local cursorPos      = reaper.GetCursorPosition();

  local candidates  = {};

  for i = 0, mediaItemCount - 1 do

    local mediaItem = reaper.GetSelectedMediaItem(0, i)
    local track     = reaper.GetMediaItem_Track(mediaItem)

    -- Only keep items that contain the cursor pos
    if MediaItemContainsCursor(mediaItem, cursorPos) then
      local tk = reaper.GetActiveTake(mediaItem);

      candidates[#candidates + 1] = {
        take  = tk,
        tsel  = reaper.IsTrackSelected(track),
        tname = reaper.GetTrackName(track),
        name  = reaper.GetTakeName(tk)
      }
    end
  end

  table.sort(candidates, function(e1,e2)
    -- Priorize items that have their track selected
    local l1 = e1.tsel and 0 or 1;
    local l2 = e2.tsel and 0 or 1;

    return l1 < l2;
  end);

  if (#candidates) > 0 then
    return candidates[1].take;
  end

  return nil
end

local function TryToGetTakeFromArrangeViewAmongSelectedTracks()
  local cursorPos      = reaper.GetCursorPosition();
  local trackCount     = reaper.CountSelectedTracks();

  local candidates  = {};

  for i = 0, trackCount - 1 do
    local track     = reaper.GetSelectedTrack(0, i);
    local itemCount = reaper.CountTrackMediaItems(track);
    for j = 0, itemCount - 1 do
      local mediaItem = reaper.GetTrackMediaItem(track, j);

      if MediaItemContainsCursor(mediaItem, cursorPos) then
        local tk = reaper.GetActiveTake(mediaItem);

        candidates[#candidates + 1] = {
          take  = tk,
          tname = reaper.GetTrackName(track),
          name  = reaper.GetTakeName(tk)
        }
      end
    end
  end

  -- No sorting is possible
  if (#candidates) > 0 then
    return candidates[1].take;
  end

  return nil
end


-- This function returns the take that should be edited.
-- Inspired by tenfour's scripts but modified
-- It uses a strategy based on :
-- - What component has focus (midi editor or arrange window)
-- - What items are selected
-- - What items contain the cursor
-- - What tracks are selected

local function TakeForEdition()
  -- Try to get a take from the MIDI editor
  local take = nil;

  if getSetting("AllowTargetingFocusedMidiEditors") then
    take = TryToGetTakeFromMidiEditor();
    if take then
      return take;
    end
  end

  -- Second heuristic, try to get a take from selected items
  take = TryToGetTakeFromArrangeViewAmongSelectedItems();
  if take then
    return take;
  end

  if getSetting("AllowTargetingNonSelectedItemsUnderCursor") then
    -- Third heuristic (if enabled), try to get a take from selected tracks
    take = TryToGetTakeFromArrangeViewAmongSelectedTracks();
    if take then
      return take;
    end
  end

  return nil;
end

local function TrackForEditionIfNoItemFound()
  local trackCount     = reaper.CountSelectedTracks();
  if trackCount > 0 then
    return reaper.GetSelectedTrack(0, 0);
  end
  return nil;
end

---------------------------

local function resolveNoteLenQN(take)

  local nlm = getNoteLenParamSource();

  if nlm == NoteLenParamSource.OSS then
    return getNoteLenQN() * getNoteLenModifierFactor();
  elseif nlm == NoteLenParamSource.ProjectGrid then

    local _, qn, swing, _ = reaper.GetSetProjectGrid(0, false);

    if swing == 3 then
      -- Project Grid is set to "measure"
      local pos   = reaper.GetCursorPosition();
      local posqn = reaper.TimeMap2_timeToQN(0, pos);
      local posm  = reaper.TimeMap_QNToMeasures(0, posqn);

      local _, measureStart, measureEnd = reaper.TimeMap_GetMeasureInfo(0, posm - 1);
      return measureEnd - measureStart;
    else
      return qn * 4;
    end

  else
    local grid_len, swing, note_len = reaper.MIDI_GetGrid(take);

    if note_len == 0 then
      note_len = grid_len;
    end

    return note_len;
  end
end

-- Commits the currently held notes into the take
local function justStepBack()

  local note_len               = resolveNoteLenQN(nil);
  local cursorTime             = reaper.GetCursorPosition()
  local cursorQN               = reaper.TimeMap2_timeToQN(0, cursorTime)
  local rewindTime             = reaper.TimeMap2_QNToTime(0, cursorQN - note_len)

  reaper.Undo_BeginBlock();
  reaper.SetEditCurPos(rewindTime, false, false);
  reaper.Undo_EndBlock("One Small Step: Stepping back",-1);
end


local function CreateItemIfMissing(track)
  local newitem = reaper.CreateNewMIDIItemInProj(track, reaper.GetCursorPosition(), reaper.GetCursorPosition() + 0.001, false);
  take = reaper.GetMediaItemTake(newitem, 0);
  local _, tname = reaper.GetTrackName(track);
  reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", tname ..os.date(' - %Y%m%d%H%M%S'), true);
  return take;
end


local function GetNote(take, ni)
  local _, selected, muted, startPPQ, endPPQ, chan, pitch, vel = reaper.MIDI_GetNote(take, ni);
  return  {
    selected = selected,
    muted = muted,
    pitch = pitch,
    startPPQ = startPPQ,
    endPPQ = endPPQ,
    chan = chan,
    pitch = pitch,
    vel = vel,
    index = ni
  };
end

local function SetNote(take, n, nosort)
  reaper.MIDI_SetNote(take, n.index, n.selected, n.muted, n.startPPQ, n.endPPQ, n.chan, n.pitch, n.vel, nosort)
end

-- Commits the currently held notes into the take
local function commit(take, notes_to_add, notes_to_extend)

  local insertModeOn              = IsSPInsertModifierKeyPressed() or getInsertActionTrigger();

  local note_len                  = resolveNoteLenQN(take);
  local mediaItem                 = reaper.GetMediaItemTake_Item(take)
  local track                     = reaper.GetMediaItemTake_Track(take)

  local cursorTime                = reaper.GetCursorPosition()
  local cursorQN                  = reaper.TimeMap2_timeToQN(0, cursorTime)
  local advanceQN                 = cursorQN + note_len;
  local advanceTime               = reaper.TimeMap2_QNToTime(0, advanceQN)

  local cursorPPQ                 = reaper.MIDI_GetPPQPosFromProjTime(take, cursorTime)
  local advancePPQ                = reaper.MIDI_GetPPQPosFromProjTime(take, advanceTime)

  local newMaxQN                  = advanceQN

  local extcount = 0;
  local addcount = 0;

  reaper.Undo_BeginBlock();

  -- First, move some notes if insert mode is on
  if insertModeOn then
    local _, notecnt, _, _ = reaper.MIDI_CountEvts(take)
    local ni = 0

    while (ni < notecnt) do
      local n                 = GetNote(take, ni);
      local startsAfterCursor = (cursorPPQ - 1 < n.startPPQ)

      if startsAfterCursor then
        local startQN = reaper.MIDI_GetProjQNFromPPQPos(take, n.startPPQ) + note_len
        local endQN   = reaper.MIDI_GetProjQNFromPPQPos(take, n.endPPQ) + note_len

        reaper.MIDI_SetNote(take, ni, nil, nil,
          reaper.MIDI_GetPPQPosFromProjQN(take, startQN),
          reaper.MIDI_GetPPQPosFromProjQN(take, endQN),
          nil, nil, nil, true)

        -- For updating item extents
        if endQN > newMaxQN then
          newMaxQN = endQN
        end
      end

      ni = ni + 1
    end
  end

  -- Try to extend existing notes
  if #notes_to_extend > 0 then
    local _, notecnt, _, _ = reaper.MIDI_CountEvts(take);

    for _, exnote in pairs(notes_to_extend) do

      -- Search for a note that could be extended (matches all conditions)
      local ni    = 0;
      local found = false;

      while (ni < notecnt) do

        local _, _, _, _, endPPQ, chan, pitch, _ = reaper.MIDI_GetNote(take, ni);

        local endsMatchesCursor = (math.abs(endPPQ - cursorPPQ) < 1.0)

        -- Extend the note if found
        if endsMatchesCursor and chan == exnote.chan and pitch == exnote.note then
          reaper.MIDI_SetNote(take, ni, nil, nil, nil, advancePPQ, nil, nil, nil, true);
          extcount = extcount + 1;
          found = true
        end

        ni = ni + 1;
      end

      if not found then
        -- Could not find a note to extend... create one !
        notes_to_add[#notes_to_add+1] = exnote;
      end

    end
  end

  -- Add new notes
  for k,v in pairs(notes_to_add) do
    reaper.MIDI_InsertNote(take, getSetting("SelectInputNotes"), false, cursorPPQ, advancePPQ, v.chan, v.note, v.velocity)
    addcount = addcount + 1;
  end

  -- Advance and mark dirty
  reaper.MIDI_Sort(take)
  reaper.UpdateItemInProject(mediaItem)
  reaper.SetEditCurPos(advanceTime, false, false);

  -- Grow the midi item if needed
  local itemStartTime = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
  local itemLength    = reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")
  local itemEndTime   = itemStartTime + itemLength;
  local newMaxTime    = reaper.TimeMap2_QNToTime(0, newMaxQN)

  if(itemEndTime >= newMaxTime) then
    -- Cool, the item is big enough
  else
    local itemStartQN = reaper.TimeMap2_timeToQN(0, itemStartTime)
    local itemEndQN   = reaper.TimeMap2_timeToQN(0, newMaxTime)

    reaper.MIDI_SetItemExtents(mediaItem, itemStartQN, itemEndQN)
    reaper.UpdateItemInProject(mediaItem);
  end

  -- Mark item as dirty
  reaper.MarkTrackItemsDirty(track, mediaItem)

  local description = "";

  if extcount == 0 then
    if addcount == 0 then
      description = "Advance/Insert rest"
    else
      description = "Add " .. addcount .. " note(s)"
    end
  else
    if addcount == 0 then
      description = "Extend " .. extcount .. " note(s)"
    else
      description = "Add " .. addcount .. " note(s) and extend " .. extcount .. " note(s)"
    end
  end

  reaper.Undo_EndBlock("One Small Step: " .. description,-1);
end


local function deleteMoveBack(take)
  local mediaItem     = reaper.GetMediaItemTake_Item(take)
  local track         = reaper.GetMediaItemTake_Track(take)

  local note_len      = resolveNoteLenQN(take);

  local cursorTime    = reaper.GetCursorPosition()
  local cursorQN      = reaper.TimeMap2_timeToQN(0, cursorTime)
  local rewindTime    = reaper.TimeMap2_QNToTime(0, cursorQN - note_len)

  local cursorPPQ     = reaper.MIDI_GetPPQPosFromProjTime(take, cursorTime)
  local rewindPPQ     = reaper.MIDI_GetPPQPosFromProjTime(take, rewindTime)

  local shcount = 0
  local remcount = 0
  local mvcount = 0

  reaper.Undo_BeginBlock();

  -- Try to extend existing notes
  local torem   = {}
  local tomove  = {}

  local _, notecnt, _, _ = reaper.MIDI_CountEvts(take);

  local ni = 0;
  while (ni < notecnt) do

    -- Examine each note in item
    local n = GetNote(take, ni);

    local startsBetweenRewindAndCursor  = (rewindPPQ-1 < n.startPPQ) and (n.startPPQ < cursorPPQ+1)
    local endsBetweenRewindAndcursor    = (rewindPPQ-1 < n.endPPQ)   and (n.endPPQ < cursorPPQ+1)
    local endsMatchesCursor             = (math.abs(n.endPPQ - cursorPPQ) < 1.0)
    local shortenable                   = endsBetweenRewindAndcursor or endsMatchesCursor
    local startsAfterCursor             = (cursorPPQ-1 < n.startPPQ)

    if startsBetweenRewindAndCursor then

      if endsBetweenRewindAndcursor then
        torem[#torem+1] = n
      else
        local startQN = reaper.MIDI_GetProjQNFromPPQPos(take, cursorPPQ) - note_len
        local endQN   = reaper.MIDI_GetProjQNFromPPQPos(take, n.endPPQ) - note_len

        n.startPPQ = reaper.MIDI_GetPPQPosFromProjQN(take, startQN)
        n.endPPQ   = reaper.MIDI_GetPPQPosFromProjQN(take, endQN)

        tomove[#tomove+1]   = n
        torem[#torem+1]     = n

        remcount            = remcount + 1
      end

    elseif shortenable then

      if rewindPPQ <= (n.startPPQ + 1.0) then
        torem[#torem+1] = n
        remcount  = remcount + 1
      else
        shcount   = shcount + 1
        n.endPPQ  = rewindPPQ
        SetNote(take, n, true)
      end

    elseif startsAfterCursor then
      -- Has to be moved. When moving multiple notes at once, they should be removed and re-inserted ... (says the doc)
      -- Move back
      local startQN = reaper.MIDI_GetProjQNFromPPQPos(take, n.startPPQ) - note_len
      local endQN   = reaper.MIDI_GetProjQNFromPPQPos(take, n.endPPQ) - note_len

      n.startPPQ = reaper.MIDI_GetPPQPosFromProjQN(take, startQN)
      n.endPPQ   = reaper.MIDI_GetPPQPosFromProjQN(take, endQN)

      tomove[#tomove+1]   = n
      torem[#torem+1]     = n

      remcount = remcount + 1
    end

    ni = ni + 1;
  end

  -- Delete notes that were shorten too much
  -- Do this in reverse order to be sure that indices are descending
  for ri = #torem, 1, -1 do
    reaper.MIDI_DeleteNote(take, torem[ri].index);
  end

  -- Reinsert moved notes
  for ri = 1, #tomove, 1 do
    local n = tomove[ri]
    reaper.MIDI_InsertNote(take, n.selected, n.muted, n.startPPQ, n.endPPQ, n.chan, n.pitch, n.vel, true )
  end

  -- Rewind and mark dirty
  reaper.MIDI_Sort(take);
  reaper.UpdateItemInProject(mediaItem)
  reaper.SetEditCurPos(rewindTime, false, false);
  reaper.MarkTrackItemsDirty(track, mediaItem)

  local description = "";

  if shcount == 0 then
    if remcount == 0 then
      description = "One Small Step: Stepping back"
    else
      description = "One Small Step: Removed " .. remcount .. " notes."
    end
  else
    if remcount == 0 then
      description = "One Small Step: Shortened " .. shcount .. " notes."
    else
      description = "One Small Step: Removed " .. remcount .. " notes, and shortened " .. shcount .. " notes."
    end
  end

  reaper.Undo_EndBlock("One Small Step: " .. description,-1);
end


-- Commits the currently held notes into the take
local function commitBack(take, notes_to_shorten)

  local insertModeOn = IsSPInsertModifierKeyPressed() or getInsertBackActionTrigger();

  if insertModeOn then
    return deleteMoveBack(take)
  end

  local mediaItem     = reaper.GetMediaItemTake_Item(take)
  local track         = reaper.GetMediaItemTake_Track(take)

  local note_len      = resolveNoteLenQN(take);

  local cursorTime    = reaper.GetCursorPosition()
  local cursorQN      = reaper.TimeMap2_timeToQN(0, cursorTime)
  local rewindTime    = reaper.TimeMap2_QNToTime(0, cursorQN - note_len)

  local cursorPPQ     = reaper.MIDI_GetPPQPosFromProjTime(take, cursorTime)
  local rewindPPQ     = reaper.MIDI_GetPPQPosFromProjTime(take, rewindTime)

  local shcount = 0;
  local remcount = 0

  reaper.Undo_BeginBlock();

  -- Try to extend existing notes
  local torem = {}
  if #notes_to_shorten > 0 then
    local _, notecnt, _, _ = reaper.MIDI_CountEvts(take);

    local ni = 0;
    while (ni < notecnt) do

      -- Examine each note in item
      local _, _, _, startPPQ, endPPQ, chan, pitch, _ = reaper.MIDI_GetNote(take, ni);

      -- Compare to what we have in our shorten list
      for _, shnote in pairs(notes_to_shorten) do

        local endsMatchesCursor           = (math.abs(endPPQ - cursorPPQ) < 1.0)
        local endsBetweenRewindAndcursor  = (rewindPPQ < endPPQ) and (endPPQ < cursorPPQ)
        local shortenable = endsMatchesCursor or (getSetting("AllowErasingWhenNoteEndDoesNotMatchCursor") and endsBetweenRewindAndcursor);

        if shortenable and chan == shnote.chan and pitch == shnote.note then
          if rewindPPQ <= (startPPQ + 1.0) then
            torem[#torem+1] = ni;
            remcount = remcount + 1
          else
            shcount = shcount + 1
          end

          reaper.MIDI_SetNote(take, ni, nil, nil, nil, rewindPPQ, nil, nil, nil, true);
        end
      end

      ni = ni + 1;
    end
  end

  -- Delete notes that were shorten too much
  -- Do this in reverse order to be sure that indices are descending
  for ri = #torem, 1, -1 do
    reaper.MIDI_DeleteNote(take, torem[ri]);
  end

  -- Rewind and mark dirty
  reaper.MIDI_Sort(take);
  reaper.UpdateItemInProject(mediaItem)
  reaper.SetEditCurPos(rewindTime, false, false);
  reaper.MarkTrackItemsDirty(track, mediaItem)

  local description = "";

  if shcount == 0 then
    if remcount == 0 then
      description = "One Small Step: Stepping back"
    else
      description = "One Small Step: Removed " .. remcount .. " notes."
    end
  else
    if remcount == 0 then
      description = "One Small Step: Shortened " .. shcount .. " notes."
    else
      description = "One Small Step: Removed " .. remcount .. " notes, and shortened " .. shcount .. " notes."
    end
  end

  reaper.Undo_EndBlock("One Small Step: " .. description,-1);
end


-- Listen to events from instrumented tracks that have the JSFX companion effect installed (or install it if not present)
local function listenToEvents()

  local mode = getInputMode();

  -- Input mode should be engaged
  if mode == InputMode.None then
    return;
  end

  -- Reaper should not be in play/pause/rec state
  if (not (reaper.GetPlayState()==0)) then
    return;
  end

  local track = nil;
  local take  = TakeForEdition();

  if not take then
    if getSetting("AllowCreateItem") then
      track = TrackForEditionIfNoItemFound();
      if not track then
        return
      end
    else
      return
    end
  else
    track = reaper.GetMediaItemTake_Track(take);
  end

  local recarmed  = reaper.GetMediaTrackInfo_Value(track, "I_RECARM");

  -- If track is not armed for recording, ignore everything
  if not (recarmed == 1) then
    return;
  end


  -- Add helper FX if it is missing
  local helper_status = helper_lib.getOrInstallHelperFx(track);

  if helper_status == -1 then
    return -42;
  end

  local oss_state = helper_lib.oneSmallStepState(track);

  -- We have different managers for all modes
  -- But their architecture is identical and compliant
  if mode == InputMode.KeyboardPress then
    manager = KPActivityManager;
  elseif mode == InputMode.KeyboardRelease then
    manager = KRActivityManager;
  else
    manager = APActivityManager;
  end

  -- Update manager with new info from the helper JSFX
  manager:updateActivity(track, oss_state);

  local spmod                   = IsSPStepBackModifierKeyPressed();
  local pedal                   = manager:pullPedalTriggerForTrack(track);
  local preventcommitwhenspmod  = getSetting("PreventAddingNotesIfModifierKeyIsPressed");

  -- Try to commit with advanced behaviours (key press, key release)
  manager:tryAdvancedCommitForTrack(track, function(candidates, held_candidates)
    -- The next condition is used specifically to prevent notes
    -- From being added in KeyboardPress mode when the modifier key is down
    -- This is going to happen when a user wants to step back
    -- and first presses the key of the note to erase ...
    -- Without this condition this would first re-add the note in question
    if (not spmod) or (spmod and not preventcommitwhenspmod) then
        if take == nil and #candidates > 0 then
          take = CreateItemIfMissing(track);
        end
        commit(take, candidates, held_candidates);
      end
    end
  );

  -- Allow the use of the action or pedal
  if (pedal and not spmod) or getCommitActionTrigger() or getInsertActionTrigger() then
    manager:simpleCommit(track, function(commit_candidates, extend_candidates)
        if take == nil then
          -- The condition is very large, because it may be a rest insertion
          take = CreateItemIfMissing(track);
        end
        commit(take, commit_candidates, extend_candidates);
      end
    );

    clearCommitActionTrigger()
    clearInsertActionTrigger()
  end

  if (pedal and spmod) or getCommitBackActionTrigger() or getInsertBackActionTrigger() then
    manager:simpleCommitBack(track, function(shorten_candidates)
        if (take == nil) then
          justStepBack();
        else
          commitBack(take, shorten_candidates)
        end
      end
    );

    clearCommitBackActionTrigger()
    clearInsertBackActionTrigger()
  end
  manager:clearOutdatedActivity()

  -- Clear Insert action triggers

  clearInsertBackActionTrigger()

  if getSetting("PedalRepeatEnabled") then
    manager:forgetPedalTriggerForTrack(track, getSetting("PedalRepeatTime"), getSetting("PedalRepeatFirstHitMultiplier"))
  end
end

-- To be called from companion action script
function reaperActionCommit()
  setCommitActionTrigger();
end
function reaperActionCommitBack()
  setCommitBackActionTrigger()
end
function reaperActionInsert()
  setInsertActionTrigger()
end
function reaperActionInsertBack()
  setInsertBackActionTrigger()
end

function cleanupCompanionFXs()
  reaper.Undo_BeginBlock()
  helper_lib.cleanupAllTrackFXs();
  reaper.Undo_EndBlock("One Small Step - Cleanup companion JSFXs",-1);
end

function handlePlaybackMarkerOnExit()
  local setting = getSetting("PlaybackMarkerPolicyWhenClosed");
  if setting == "Hide/Restore" then
    -- Need to backup the position
    -- Save on master track to be project dependent
    local id, pos     = findPlaybackMarker();
    local masterTrack = reaper.GetMasterTrack();
    local str         = "";

    if not (id == nil) then
      str = tostring(pos)
    end

    reaper.GetSetMediaTrackInfo_String(masterTrack, "P_EXT:OneSmallStep:MarkerBackup", str, true);
  end

  if (setting == "Hide/Restore") or (setting == "Remove") then
    removePlaybackMarker();
  end
end

function mayRestorePlaybackMarkerOnStart()
  local setting = getSetting("PlaybackMarkerPolicyWhenClosed");
  if setting == "Hide/Restore" then
    local masterTrack = reaper.GetMasterTrack();
    local succ, str = reaper.GetSetMediaTrackInfo_String(masterTrack, "P_EXT:OneSmallStep:MarkerBackup", '', false);
    if succ and str ~= "" then
      setPlaybackMarkerAtPos(tonumber(str));
    end
  end
end

function atStart()
  -- Do some cleanup at engine start
  -- But this adds an undo entry point ...
  -- So rely on the user instead to cleanup the JSFXs using the relevant action
  -- If there's one day a way to prevent reaper from creating Undo points
  -- Then we can uncomment this automatic cleanup
  -- cleanupCompanionFXs();

  clearCommitActionTrigger()
  clearInsertActionTrigger()
  clearCommitBackActionTrigger()
  clearInsertBackActionTrigger()

  mayRestorePlaybackMarkerOnStart();
end

function atExit()
  -- See comment in atStart

  if getSetting("CleanupJsfxAtClosing") then
    cleanupCompanionFXs();
  end

  handlePlaybackMarkerOnExit();
end

function atLoop()
  return listenToEvents();
end

EngineLib = {

  IsSPStepBackModifierKeyPressed = IsSPStepBackModifierKeyPressed,
  IsSPInsertModifierKeyPressed   = IsSPInsertModifierKeyPressed,

  -- Enums
  InputMode                     = InputMode,
  NoteLenParamSource            = NoteLenParamSource,
  NoteLenModifier               = NoteLenModifier,

  ModifierKeys                  = ModifierKeys,
  ModifierKeyLookup             = ModifierKeyLookup,
  getSPStepBackModifierKey      = getSPStepBackModifierKey,
  getSPInsertModifierKey        = getSPInsertModifierKey,

  NoteLenDefs                   = NoteLenDefs,
  AugmentedDiminishedDefs       = AugmentedDiminishedDefs,

  --Functions
  setInputMode                  = setInputMode,
  getInputMode                  = getInputMode,

  setNoteLenParamSource         = setNoteLenParamSource,
  getNoteLenParamSource         = getNoteLenParamSource,

  setPlaybackMeasureCount       = setPlaybackMeasureCount,
  getPlaybackMeasureCount       = getPlaybackMeasureCount,

  setTupletDivision             = setTupletDivision,
  getTupletDivision             = getTupletDivision,

  getNoteADFactor               = getNoteADFactor,
  setNoteADFactor               = setNoteADFactor,

  getNoteADSign                 = getNoteADSign,
  setNoteADSign                 = setNoteADSign,

  getNoteLenModifier            = getNoteLenModifier,
  setNoteLenModifier            = setNoteLenModifier,
  getNoteLenModifierFactor      = getNoteLenModifierFactor,

  setNoteLen                    = setNoteLen,
  getNoteLen                    = getNoteLen,
  getNoteLenQN                  = getNoteLenQN,

  increaseNoteLen               = increaseNoteLen,
  decreaseNoteLen               = decreaseNoteLen,

  findPlaybackMarker            = findPlaybackMarker,
  setPlaybackMarkerAtCurrentPos = setPlaybackMarkerAtCurrentPos,

  atStart                       = atStart,
  atExit                        = atExit,
  atLoop                        = atLoop,

  getSetting                    = getSetting,
  setSetting                    = setSetting,
  resetSetting                  = resetSetting,
  getSettingSpec                = getSettingSpec,

  reaperActionCommit            = reaperActionCommit,
  reaperActionCommitBack        = reaperActionCommitBack,
  reaperActionInsert            = reaperActionInsert,
  reaperActionInsertBack        = reaperActionInsertBack,

  TakeForEdition                = TakeForEdition,
  TrackForEditionIfNoItemFound  = TrackForEditionIfNoItemFound,

  TrackFocus                    = TrackFocus,
  RestoreFocus                  = RestoreFocus,
}

return EngineLib;