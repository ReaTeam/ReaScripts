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
local IsMacos                   = (reaper.GetOS():find('OSX') ~= nil);
-------------
-- Defines

-- Tolerance to detect if events match
local TIME_TOLERANCE  = 0.002
local QN_TOLERANCE    = 0.002
local PPQ_TOLERANCE   = 1

local NoteLenDefs = {
  { id = "1",    next = "1",    prec = "1_2",  frac = "4" ,    qn = 4      },
  { id = "1_2",  next = "1",    prec = "1_4",  frac = "2" ,    qn = 2      },
  { id = "1_4",  next = "1_2",  prec = "1_8",  frac = "1" ,    qn = 1      },
  { id = "1_8",  next = "1_4",  prec = "1_16", frac = "1_2" ,  qn = 0.5    },
  { id = "1_16", next = "1_8",  prec = "1_32", frac = "1_4" ,  qn = 0.25   },
  { id = "1_32", next = "1_16", prec = "1_64", frac = "1_8" ,  qn = 0.125  },
  { id = "1_64", next = "1_32", prec = "1_64", frac = "1_16",  qn = 0.0625 }
};

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

local EditMode = {
  Write     = "Write",
  Navigate  = "Navigate",
  Insert    = "Insert",
  Replace   = "Replace"
}

local ActionTriggers = {
  Commit       = { action = "Commit",       back = false },
  CommitBack   = { action = "Commit",       back = true },

  Write        = { action = "Write",        back = false },
  Navigate     = { action = "Navigate",     back = false },
  Insert       = { action = "Insert",       back = false },
  Replace      = { action = "Replace",      back = false },

  WriteBack    = { action = "Write",        back = true },
  NavigateBack = { action = "Navigate",     back = true },
  InsertBack   = { action = "Insert",       back = true },
  ReplaceBack  = { action = "Replace",      back = true },
}

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

local ModifierKeys    = IsMacos and MacOSModifierKeys or OtherOSModifierKeys;

local NoteLenLookup = {};
for i,v in ipairs(NoteLenDefs) do
  NoteLenLookup[v.id] = v;
end

local ModifierKeyLookup = {};
for i,v in ipairs(ModifierKeys) do
  ModifierKeyLookup[v.vkey] = v;
end

local ModifierKeyCombinations = {{ label = "None", id = "none", vkeys = {} }}
for i=1, #ModifierKeys do
  local m1 = ModifierKeys[i]
  ModifierKeyCombinations[#ModifierKeyCombinations+1] = { label = m1.name, id = "" .. m1.vkey, vkeys = { m1.vkey } }
end
for i=1, #ModifierKeys do
  local m1 = ModifierKeys[i]
  for j=i+1, #ModifierKeys do
    m2 = ModifierKeys[j]
    ModifierKeyCombinations[#ModifierKeyCombinations+1] = { label = m1.name .. "+" .. m2.name, id = "" .. m1.vkey .. "+" .. m2.vkey, vkeys = { m1.vkey, m2.vkey } }
  end
end
local ModifierKeyCombinationLookup = {};
for i,v in ipairs(ModifierKeyCombinations) do
  ModifierKeyCombinationLookup[v.id] = v;
end

-------------
-- Settings

local SettingDefs = {
  StepBackModifierKey                                       = { type = "int",     default = IsMacOs and 16 or 16 },

  WriteModifierKeyCombination                               = { type = "string",  default = "none" },
  InsertModifierKeyCombination                              = { type = "string",  default = IsMacos and "17" or "17" },
  NavigateModifierKeyCombination                            = { type = "string",  default = IsMacos and "18" or "18" },
  ReplaceModifierKeyCombination                             = { type = "string",  default = IsMacos and "17+18" or "17+18" },

  HideEditModeMiniBar                                       = { type = "bool",    default = false },

  Mode                                                      = { type = "int",     default = InputMode.KeyboardRelease },
  EditMode                                                  = { type = "string",  default = EditMode.Write },

  PlaybackMeasureCount                                      = { type = "int",     default = -1 }, -- -1 is marker mode
  NoteLenParamSource                                        = { type = "int",     default = NoteLenParamSource.OSS },
  NoteLenFactorDenominator                                  = { type = "int",     default = 1 },
  NoteLenFactorNumerator                                    = { type = "int",     default = 1 },
  TupletDivision                                            = { type = "int",     default = 4 },
  NoteLen                                                   = { type = "string",  default = "1_4"},
  NoteLenModifier                                           = { type = "int",     default = NoteLenModifier.Straight },
  ------
  PlaybackMarkerPolicyWhenClosed                            = { type = "string",  default = "Keep visible" },

  AllowTargetingFocusedMidiEditors                          = { type = "bool",    default = true },
  AllowTargetingNonSelectedItemsUnderCursor                 = { type = "bool",    default = false },
  AllowCreateItem                                           = { type = "bool",    default = false },

  DoNotRewindOnStepBackIfNothingErased                      = { type = "bool",    default = true},
  CleanupJsfxAtClosing                                      = { type = "bool",    default = true},
  SelectInputNotes                                          = { type = "bool",    default = true},
  ------
  KeyPressModeAggregationTime                               = { type = "double",  default = 0.05, min = 0,   max = 0.1 },
  KeyPressModeInertiaTime                                   = { type = "double",  default = 0.5,  min = 0.2, max = 1.0 },
  KeyPressModeInertiaEnabled                                = { type = "bool",    default = true},

  KeyReleaseModeForgetTime                                  = { type = "double",  default = 0.200, min = 0.05, max = 0.4},

  PedalRepeatEnabled                                        = { type = "bool" ,   default = true },
  PedalRepeatTime                                           = { type = "double",  default = 0.200, min = 0.05, max = 0.5 },
  PedalRepeatFirstHitMultiplier                             = { type = "int",     default = 4, min = 1, max = 10 },

  Snap                                                      = { type = "bool",    default = false },
  SnapNotes                                                 = { type = "bool",    default = true },
  SnapProjectGrid                                           = { type = "bool",    default = true },
  SnapItemGrid                                              = { type = "bool",    default = true },
  SnapItemBounds                                            = { type = "bool",    default = true },

  AutoScrollArrangeView                                     = { type = "bool",    default = true },

  AllowKeyEventNavigation                                   = { type = "bool",    default = false }
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

local function setTupletDivision(m)               return setSetting("TupletDivision", m)   end
local function getTupletDivision()                return getSetting("TupletDivision")      end

local function setNoteLen(nl)                     return setSetting("NoteLen", nl)  end
local function getNoteLen()                       return getSetting("NoteLen")      end

local function setNoteLenModifier(nl)             return setSetting("NoteLenModifier", nl)  end
local function getNoteLenModifier()               return getSetting("NoteLenModifier")      end

local function getNoteLenFactorNumerator()        return getSetting("NoteLenFactorNumerator")      end
local function getNoteLenFactorDenominator()      return getSetting("NoteLenFactorDenominator")    end

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

-- These functions are used to communicate between the independent actions and OSS

local function validateActionTrigger(action_name)
  if ActionTriggers[action_name] == nil then
    error("Trying to use unknown action trigger :" .. action_name)
  end
end

local function setActionTrigger(action_name)
  validateActionTrigger(action_name)
  reaper.SetExtState("OneSmallStep", action_name .. "ActionTrigger", tostring(reaper.time_precise()), false);
end
local function getActionTrigger(action_name)
  validateActionTrigger(action_name)
  return tonumber(reaper.GetExtState("OneSmallStep", action_name .. "ActionTrigger"));
end
local function clearActionTrigger(action_name)
  validateActionTrigger(action_name)
  reaper.DeleteExtState("OneSmallStep", action_name .. "ActionTrigger", true);
end

function clearAllActionTriggers()
  for k,v in pairs(ActionTriggers) do
    clearActionTrigger(k)
  end
end


------------

-- Our manager for the Action/Pedal mode (use generic one)
local APActivityManager = KeyActivityManager:new();
-- Our manager for the Key Release input mode
local KRActivityManager = KeyReleaseActivityManager:new();
-- Our manager for the Key Press input mode
local KPActivityManager = KeyPressActivityManager:new();


local function currentKeyEventManager()
  local manager = nil
  local mode    = getInputMode();

  -- We have different managers for all modes
  -- But their architecture is identical and compliant
  if mode == InputMode.KeyboardPress then
    manager = KPActivityManager;
  elseif mode == InputMode.KeyboardRelease then
    manager = KRActivityManager;
  else
    manager = APActivityManager;
  end

  return manager
end

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

  if (mpos == nil) or math.abs(pos - mpos) > TIME_TOLERANCE then
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

local function validateModifierKeyCombination(id)
  if ModifierKeyCombinationLookup[id] == nil then
    error("Trying to use unknown modifier key combination with id " .. id)
  end
end

-- Returns the state of the modifier key linked to the function "function_name"
local function IsModifierKeyCombinationPressed(id)
  validateModifierKeyCombination(id)

  if id == "none" then
    return false
  end

  -- Avoid inconsistencies and only follow events during the lifetime of the plugin, so use launchTime
  -- This will prevent bugs from a session to another (when for example the plugin crashes)
  local keys  = reaper.JS_VKeys_GetState(launchTime);
  local combi = ModifierKeyCombinationLookup[id]

  for k, v in ipairs(combi.vkeys) do
    local c1    = keys:byte(v);
    if not (c1 ==1) then
      return false
    end
  end

  return true
end

local function IsStepBackModifierKeyPressed()
  local keys  = reaper.JS_VKeys_GetState(launchTime);
  return (keys:byte(getSetting("StepBackModifierKey")) == 1)
end

-----------------

local function precpow2(n)
  local b = 0
  local a = (n >> b)
  while a > 0 do
    b = b + 1
    a = (n >> b)
  end
  return (1 << (b-1))
end

local function tupletFactor(div)
  return precpow2(div)/div
end

local function getNoteLenModifierFactor()

  local m   = getNoteLenModifier()
  local nls = getNoteLenParamSource()

  if m == NoteLenModifier.Straight then
    return 1.0;
  elseif m == NoteLenModifier.Dotted then
    return 1.5;
  elseif m == NoteLenModifier.Triplet then
    return 2/3.0;
  elseif m == NoteLenModifier.Modified then
    return getSetting("NoteLenFactorNumerator") / getSetting("NoteLenFactorDenominator");
  elseif m == NoteLenModifier.Tuplet then
    local div = getTupletDivision();

    if nls == NoteLenParamSource.OSS then
      return tupletFactor(div)
    else
      -- In grid mode, we just return 1/n
      return 1/div
    end
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


--------------------

local function swingNoteLenQN(measureStartQN, posQN, noteLenQN, swing)
  local elapsedDoubleBeats  = (posQN - measureStartQN)/(2*noteLenQN)
  -- Hack, it may happen that the cursor is just before the measure start
  if elapsedDoubleBeats < 0 then
    elapsedDoubleBeats = 0
  end

  local eaten = elapsedDoubleBeats - math.floor(elapsedDoubleBeats)
  if eaten > 1 - QN_TOLERANCE/noteLenQN then
    -- Hack : cursor may be very close to next double beat.
    eaten = 0
  end

  local onbeat              = (1 + swing * 0.5)
  local offbeat             = (1 - swing * 0.5)

  if (2 * eaten) < onbeat - (QN_TOLERANCE / noteLenQN) then
    return (noteLenQN * onbeat)
  else
    return (noteLenQN * offbeat)
  end
end

local function resolveNoteLenQN(take)

  local nlm                             = getNoteLenParamSource()

  local cursorTime                      = reaper.GetCursorPosition()
  local cursorQN                        = reaper.TimeMap2_timeToQN(0, cursorTime)
  local cursorMes                       = reaper.TimeMap_QNToMeasures(0, cursorQN)
  local _, measureStartQN, measureEndQN = reaper.TimeMap_GetMeasureInfo(0, cursorMes - 1)

  if math.abs(cursorQN - measureEndQN) < QN_TOLERANCE then
    -- We're on the measure end, advance 1 measure
    cursorMes = cursorMes + 1
    _, measureStartQN, measureEndQN = reaper.TimeMap_GetMeasureInfo(0, cursorMes - 1)
  end

  if nlm == NoteLenParamSource.OSS then
    return getNoteLenQN() * getNoteLenModifierFactor()
  elseif nlm == NoteLenParamSource.ProjectGrid then

    local _, division, swingmode, swing   = reaper.GetSetProjectGrid(0, false)
    local noteLenQN                       = division * 4
    local multFactor                      = getNoteLenQN()

    local baselen = 1
    if swingmode == 0 then
      -- No swing
      baselen = noteLenQN
    elseif swingmode == 3 then
      -- Project Grid is set to "measure"
      baselen = (measureEndQN - measureStartQN)
    else
      -- Swing
      if multFactor > 1 then
        baselen = noteLenQN
      else
        baselen = swingNoteLenQN(measureStartQN, cursorQN, noteLenQN, swing)
      end
    end

    return baselen * getNoteLenQN() * getNoteLenModifierFactor()

  else
    local gridLenQN, swing, noteLenQN = reaper.MIDI_GetGrid(take);
    local multFactor                      = getNoteLenQN()

    if noteLenQN == 0 then
      noteLenQN = gridLenQN
    end

    local baselen = 1
    if swing == 0 then
      baselen = noteLenQN
    else
      -- Swing
      if multFactor > 1 then
        baselen = noteLenQN
      else
        baselen = swingNoteLenQN(measureStartQN, cursorQN, noteLenQN, swing)
      end
    end

    return baselen * getNoteLenQN() * getNoteLenModifierFactor()
  end
end

local function resolveOperationMode(look_for_action_triggers)
  local bk                  = IsStepBackModifierKeyPressed()
  local mode                = getSetting("EditMode")
  local triggered_by_action = false

  local editModes = {
      { name = "Write",     prio = 4 },
      { name = "Navigate",  prio = 3 },
      { name = "Insert",    prio = 2 },
      { name = "Replace",   prio = 1 },
    }

  local activemodes = {}
  for k, editmode in ipairs(editModes) do
    local setting = getSetting(editmode.name .. "ModifierKeyCombination")
    local combi   = ModifierKeyCombinationLookup[setting]
    local pressed = IsModifierKeyCombinationPressed(combi.id)
    if pressed then
      activemodes[#activemodes + 1] = { mode = editmode.name, combi = combi, prio = editmode.prio  }
    end
  end

  table.sort(activemodes, function(e1,e2)
    -- Priorize items that have their track selected
    local l1 = #e1.combi.vkeys
    local l2 = #e2.combi.vkeys

    if l1 == l2 then
      return e1.prio < e2.prio
    end

    return l1 > l2;
  end)

  if #activemodes > 0 then
    mode = activemodes[1].mode
  end

  if look_for_action_triggers then
    for k, v in pairs(ActionTriggers) do
      local has_triggered = getActionTrigger(k)
      if has_triggered then
        if v.action ~= "Commit" then
          -- If it's a commit, use current mode, else use the mode linked to the trigger
          mode = v.action
        end
        triggered_by_action = true
        break
      end
    end
  end

  return {
    mode = mode,
    back = bk
  }
end

-------------------


local function KeepEditCursorOnScreen()
  local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
  local cursor_time = reaper.GetCursorPosition()
  local diff_time = end_time - start_time
  local bound     = 0.05
  local alpha     = 0.25

  if cursor_time < start_time + bound * diff_time then
    reaper.GetSet_ArrangeView2(0, true, 0, 0, cursor_time - diff_time * alpha, cursor_time + diff_time * (1 - alpha))
  end

  if cursor_time > end_time - bound * diff_time then
    reaper.GetSet_ArrangeView2(0, true, 0, 0, cursor_time - diff_time * (1-alpha), cursor_time + diff_time * alpha)
  end
end


local function MediaItemContainsCursor(mediaItem, CursorPos)
  local pos       = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
  local len       = reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")

  local left  = pos - TIME_TOLERANCE;
  local right = pos + len + TIME_TOLERANCE;

  -- Only keep items that contain the cursor pos
  return (CursorPos >= left) and (CursorPos <= right);
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


local function CreateItemIfMissing(track)
  local newitem = reaper.CreateNewMIDIItemInProj(track, reaper.GetCursorPosition(), reaper.GetCursorPosition() + TIME_TOLERANCE, false);
  take = reaper.GetMediaItemTake(newitem, 0);
  local _, tname = reaper.GetTrackName(track);
  reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", tname ..os.date(' - %Y%m%d%H%M%S'), true);
  return take;
end


local function GetNote(take, ni)
  local _, selected, muted, startPPQ, endPPQ, chan, pitch, vel = reaper.MIDI_GetNote(take, ni);
  return  {
    index     = ni,
    selected  = selected,
    muted     = muted,
    pitch     = pitch,
    chan      = chan,
    vel       = vel,
    startPPQ  = startPPQ,
    startQN   = reaper.MIDI_GetProjQNFromPPQPos(take, startPPQ),
    endPPQ    = endPPQ,
    endQN     = reaper.MIDI_GetProjQNFromPPQPos(take, endPPQ)
  };
end

local function SetNote(take, n, nosort)
  reaper.MIDI_SetNote(take, n.index, n.selected, n.muted, n.startPPQ, n.endPPQ, n.chan, n.pitch, n.vel, nosort)
end

local function bool2sign(b)
  return ((b == true) and (1) or (-1))
end

local function noteStartsAfterPPQ(note, limit, strict)
  return note.startPPQ > limit + bool2sign(strict) * PPQ_TOLERANCE
end
local function noteStartsBeforePPQ(note, limit, strict)
  return note.startPPQ < limit - bool2sign(strict) * PPQ_TOLERANCE
end
local function noteEndsAfterPPQ(note, limit, strict)
  return note.endPPQ > limit + bool2sign(strict) * PPQ_TOLERANCE
end
local function noteEndsBeforePPQ(note, limit, strict)
  return note.endPPQ < limit - bool2sign(strict) * PPQ_TOLERANCE
end

local function noteEndsOnPPQ(note, limit)
  return math.abs(note.endPPQ - limit) < PPQ_TOLERANCE
end

local function noteStartsOnPPQ(note, limit)
  return math.abs(note.startPPQ - limit) < PPQ_TOLERANCE
end

local function setNewNoteBounds(note, take, startPPQ, endPPQ, startOffsetQN, endOffsetQN)
  note.startQN  = reaper.MIDI_GetProjQNFromPPQPos(take, startPPQ) + startOffsetQN
  note.endQN    = reaper.MIDI_GetProjQNFromPPQPos(take, endPPQ) + endOffsetQN
  note.startPPQ = reaper.MIDI_GetPPQPosFromProjQN(take, note.startQN )
  note.endPPQ   = reaper.MIDI_GetPPQPosFromProjQN(take, note.endQN )
end

local function moveComparatorHelper(v, cursor, best, direction, mode)

  local tolerance = TIME_TOLERANCE
  if mode == "PPQ" then
    tolerance = PPQ_TOLERANCE
  end

  if direction > 0 then
    if (v > cursor + tolerance) and ((best == nil) or (v < best)) then
      best = v
    end
  else
    if (v < cursor - tolerance) and ((best == nil) or (v > best)) then
      best = v
    end
  end

  return best
end


local function gridSnapHelper(type, direction, cursorTime, cursorQN, bestJumpTime, take, itemStartTime, itemEndTime)

  local grid_len, swing = nil , nil

  if type == "ITEM" then
    grid_len, swing, _  = reaper.MIDI_GetGrid(take)
  else
    _, grid_len, swingmode, swing = reaper.GetSetProjectGrid(0, false)
    grid_len = grid_len * 4 -- put back in QN
    if swingmode ~= 1 then
      swing = 0
    end
  end

  local cursorBars                      = reaper.TimeMap_QNToMeasures(0, cursorQN) - 1
  local _, measureStartQN, measureEndQN = reaper.TimeMap_GetMeasureInfo(0, cursorBars)

  if cursorBars > 0 and direction < 0 and math.abs(cursorQN - measureStartQN) < QN_TOLERANCE then
    -- Cursor is aligned on the beginning of a measure but we're going back.
    -- Work with the precedent measure.
    cursorBars = cursorBars - 1
    _, measureStartQN, measureEndQN = reaper.TimeMap_GetMeasureInfo(0, cursorBars)
  end

  -- Start with window, and slide

  local parity      = 1

  local oddOffset   = grid_len * (1 + swing * 0.5)
  local evenOffset  = grid_len * (1 - swing * 0.5)

  local prec = measureStartQN
  local next = prec + ((parity == 1) and (oddOffset) or (evenOffset))

  while next < (cursorQN - QN_TOLERANCE) do
    parity = parity ~ 1
    prec = next
    next = prec + ((parity == 1) and (oddOffset) or (evenOffset))
  end

  if math.abs(cursorQN - next) < QN_TOLERANCE then
    parity  = parity ~ 1
    next    = next + ((parity == 1) and (oddOffset) or (evenOffset))
  end

  local precTime = reaper.TimeMap2_QNToTime(0, prec)
  local nextTime = reaper.TimeMap2_QNToTime(0, next)
  local msTime   = reaper.TimeMap2_QNToTime(0, measureStartQN)
  local meTime   = reaper.TimeMap2_QNToTime(0, measureEndQN)

  -- Only add these times if they belong to the item (outside, consider there's no grid)
  if type == "PROJECT" or (precTime >= itemStartTime and precTime <= itemEndTime) then
    bestJumpTime = moveComparatorHelper(precTime, cursorTime, bestJumpTime, direction, "TIME")
  end
  if type == "PROJECT" or (nextTime >= itemStartTime and nextTime <= itemEndTime) then
    bestJumpTime = moveComparatorHelper(nextTime, cursorTime, bestJumpTime, direction, "TIME")
  end
  if type == "PROJECT" or  (msTime >= itemStartTime and msTime <= itemEndTime) then
    bestJumpTime = moveComparatorHelper(msTime,   cursorTime, bestJumpTime, direction, "TIME")
  end
  if type == "PROJECT" or  (meTime >= itemStartTime and meTime <= itemEndTime) then
    bestJumpTime = moveComparatorHelper(meTime,   cursorTime, bestJumpTime, direction, "TIME")
  end

  return bestJumpTime
end


-- Resolves the next snap point.
-- Track can be nil (won't happen)
local function nextSnap(track, direction, reftime, options)

  local cursorTime      = reftime -- I don't want to rename everything ...
  local cursorQN        = reaper.TimeMap2_timeToQN(0, cursorTime)
  local bestJumpTime    = nil
  local maxTime         = 0

  if options.enabled and track then

    local itemCount     = reaper.CountTrackMediaItems(track)
    local ii            = 0

    -- For optimization, we should randomize the order of iteration over the items
    while ii < itemCount do
      local mediaItem        = reaper.GetTrackMediaItem(track, ii)

      local itemStartTime    = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
      local itemEndTime      = itemStartTime + reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")

      if (maxTime ~= nil) or (itemEndTime > maxTime) then
        maxTime = itemEndTime
      end

      -- A few conditions to avoid exploring the item if not needed
      if (direction > 0) then
        if (itemEndTime < cursorTime) or ((bestJumpTime ~= nil) and (bestJumpTime < itemStartTime)) then
          goto nextitem
        end
      else
        if (itemStartTime > cursorTime) or ((bestJumpTime ~= nil) and (bestJumpTime > itemEndTime)) then
          goto nextitem
        end
      end

      if options.itemBounds then
        bestJumpTime = moveComparatorHelper(itemStartTime,  cursorTime, bestJumpTime, direction, "TIME")
        bestJumpTime = moveComparatorHelper(itemEndTime,    cursorTime, bestJumpTime, direction, "TIME")
      end

      if options.notes or options.itemGrid then
        local takeCount = reaper.GetMediaItemNumTakes(mediaItem)
        local ti        = 0

        while ti < takeCount do

          local take            = reaper.GetMediaItemTake(mediaItem, ti)

          local itemStartPPQ    = reaper.MIDI_GetPPQPosFromProjTime(take, itemStartTime)
          local itemEndPPQ      = reaper.MIDI_GetPPQPosFromProjTime(take, itemEndTime)
          local cursorPPQ       = reaper.MIDI_GetPPQPosFromProjTime(take, cursorTime)
          local bestJumpPPQ     = nil

          if options.notes then
            local _, notecnt, _, _ = reaper.MIDI_CountEvts(take)
            local ni = 0

            while (ni < notecnt) do
              local n = GetNote(take, ni)

              bestJumpPPQ = moveComparatorHelper(n.startPPQ, cursorPPQ, bestJumpPPQ, direction, "PPQ")
              bestJumpPPQ = moveComparatorHelper(n.endPPQ, cursorPPQ, bestJumpPPQ, direction, "PPQ")

              ni = ni+1
            end -- end note iteration

            if bestJumpPPQ then
              -- Found a snap note inside item, convert back to time and compare to already found bestJumpTime
              local bjt    = reaper.TimeMap2_QNToTime(0, reaper.MIDI_GetProjQNFromPPQPos(take, bestJumpPPQ))
              bestJumpTime = moveComparatorHelper(bjt, cursorTime, bestJumpTime, direction, "TIME")
            end
          end

          if options.itemGrid then
            bestJumpTime = gridSnapHelper("ITEM", direction, cursorTime, cursorQN, bestJumpTime, take, itemStartTime, itemEndTime)
          end

          ti = ti + 1
        end -- end take iteration

      end

      ::nextitem::
      ii = ii+1
    end -- end item iteration
  end -- end options.enabled

  if options.projectGrid then
    -- SWS version of BR_GetNextGrid has a bug, use my own implementation
    bestJumpTime = gridSnapHelper("PROJECT", direction, cursorTime, cursorQN, bestJumpTime)
  end

  -- Add track boundaries
  bestJumpTime = moveComparatorHelper(0,        cursorTime, bestJumpTime, direction, "TIME")
  bestJumpTime = moveComparatorHelper(maxTime,  cursorTime, bestJumpTime, direction, "TIME")

  -- Safety
  if bestJumpTime == nil then
    if maxTime == nil then
      maxTime = cursorTime
    end
    bestJumpTime = (direction > 0) and (cursorTime) or 0
  end

  return {
    time = bestJumpTime,
    qn   = reaper.TimeMap2_timeToQN(0, bestJumpTime)
  }
end

local function snapOptions()
  return {
    enabled     = getSetting("Snap"),
    itemBounds  = getSetting("SnapItemBounds"),
    notes       = getSetting("SnapNotes"),
    itemGrid    = getSetting("SnapItemGrid"),
    projectGrid = getSetting("SnapProjectGrid")
  }
end

local function nextSnapFromCursor(track, direction)
  return nextSnap(track, direction, reaper.GetCursorPosition(), snapOptions())
end

local function navigate(track, direction)
  local ns = nextSnapFromCursor(track, direction)

  reaper.Undo_BeginBlock();
  reaper.SetEditCurPos(ns.time, false, false);
  if getSetting("AutoScrollArrangeView") then
    KeepEditCursorOnScreen()
  end
  reaper.Undo_EndBlock("One Small Step: " .. ((direction > 0) and ("advanced") or ("stepped back")),-1);
end


local function navigateForward(track)
  navigate(track, 1)
end

-- Commits the currently held notes into the take
local function navigateBack(track)
  navigate(track, -1)
end


local function commitDescription(direction, addcount, remcount, shcount, extcount, mvcount)
  local description = {}

  if shcount+addcount+remcount+shcount+extcount == 0 then
    if direction > 0 then
      description[#description+1] = "advanced"
    else
      description[#description+1] = "stepped back"
    end
  end
  if addcount > 0 then
    description[#description+1] = "added " .. addcount .. " notes"
  end
  if remcount > 0 then
    description[#description+1] = "removed " .. remcount .. " notes"
  end
  if mvcount > 0 then
    description[#description+1] = "moved " .. mvcount .. " notes"
  end
  if shcount > 0 then
    description[#description+1] = "shortened " .. shcount .. " notes"
  end
  if extcount > 0 then
    description[#description+1] = "extended " .. extcount .. " notes"
  end

  return "One Small Step: " .. table.concat(description, ", ")
end

local function AllowKeyEventNavigation()
  return getSetting("AllowKeyEventNavigation")
end


-- Commits the currently held notes into the take
local function commit(track, take, notes_to_add, notes_to_extend, triggered_by_key_event)

  local currentop       = resolveOperationMode(true)

  local writeModeON     = (currentop.mode == "Write")
  local navigateModeOn  = (currentop.mode == "Navigate")
  local insertModeOn    = (currentop.mode == "Insert")
  local replaceModeOn   = (currentop.mode == "Replace")

  if navigateModeOn then
    if (not triggered_by_key_event) or AllowKeyEventNavigation() then
      return navigateForward(track)
    else
      -- Triggered by key event and not allowed ... do nothing
      return
    end
  end

  -- Other operations perform changes so go.
  if take == nil then
    take = CreateItemIfMissing(track);
  end

  local note_len                  = resolveNoteLenQN(take);
  local mediaItem                 = reaper.GetMediaItemTake_Item(take)

  local cursorTime                = reaper.GetCursorPosition()
  local cursorQN                  = reaper.TimeMap2_timeToQN(0, cursorTime)
  local cursorPPQ                 = reaper.MIDI_GetPPQPosFromProjTime(take, cursorTime)

  local advanceQN                 = cursorQN + note_len;
  local advanceTime               = reaper.TimeMap2_QNToTime(0, advanceQN)
  local advancePPQ                = reaper.MIDI_GetPPQPosFromProjTime(take, advanceTime)

  local newMaxQN                  = (justAdvancing and cursorQN) or advanceQN

  local shcount, remcount, mvcount, addcount, extcount = 0, 0, 0, 0, 0

  local torem  = {}
  local tomod  = {}
  local toadd  = {}

  local buildNewMidiNote = function(note_from_manager)
    return {
          index     = nil,
          selected  = getSetting("SelectInputNotes"),
          muted     = false,
          chan      = note_from_manager.chan,
          pitch     = note_from_manager.note,
          vel       = note_from_manager.velocity,
          startPPQ  = cursorPPQ,
          endPPQ    = advancePPQ,
          startQN   = cursorQN,
          endQN     = advanceQN
        }
  end

  reaper.Undo_BeginBlock();

  -- First, move some notes if insert mode is on
  if insertModeOn then
    local _, notecnt, _, _ = reaper.MIDI_CountEvts(take)
    local ni = 0

    while (ni < notecnt) do
      local n = GetNote(take, ni);

      if noteStartsAfterPPQ(n, cursorPPQ, false) then
        -- Move the note
        setNewNoteBounds(n, take, n.startPPQ, n.endPPQ, note_len, note_len)

        if n.endQN > newMaxQN then
          newMaxQN = n.endQN
        end

        -- It should be removed and readded, because the start position changes
        torem[#torem + 1] = n
        toadd[#toadd + 1] = n

        mvcount = mvcount + 1
      end

      ni = ni + 1
    end
  end

  if replaceModeOn then
    -- Erase forward
    local _, notecnt, _, _ = reaper.MIDI_CountEvts(take);

    local ni = 0;
    while (ni < notecnt) do

      -- Examine each note in item
      local n = GetNote(take, ni);

      if noteStartsAfterPPQ(n, advancePPQ, false) then
        -- Note is not in the erasing window
        --
        --     C     A
        --     |     |
        --     |     | ====
        --     |     |
        --
      elseif noteStartsAfterPPQ(n, cursorPPQ, false) then
        if noteEndsBeforePPQ(n, advancePPQ, false) then
          -- Note should be suppressed
          --
          --     C     A
          --     |     |
          --     | === |
          --     |     |
          --
          torem[#torem+1] = n
          remcount        = remcount + 1
        else
          -- The note should be shortened (removing tail).
          -- Since its start will change, it should be removed and reinserted (see reaper's API doc)
          --
          --     RC    A
          --     |     |
          --     |   ==|===
          --     |     |
          --
          setNewNoteBounds(n, take, advancePPQ, n.endPPQ, 0, 0)

          torem[#torem+1]   = n
          toadd[#toadd+1]   = n

          shcount = shcount + 1
          mvcount = mvcount + 1
        end
      else
        if noteEndsAfterPPQ(n, advancePPQ, false) then
          -- We should make a hole. Shorten (or erase) left part. Shorten (or erase) right part
          --
          --     C     A
          --     |     |
          --   ==|=====|===
          --     |     |
          --
          if noteStartsOnPPQ(n, cursorPPQ) then
            -- The start changes, remove and reinsert
            setNewNoteBounds(n, take, advancePPQ, n.endPPQ, 0, 0)

            torem[#torem+1]   = n
            toadd[#toadd+1]   = n

            shcount = shcount + 1
            mvcount = mvcount + 1
          else
            -- Copy note
            local newn = {}
            for k,v in pairs(n) do
              newn[k] = v
            end

            -- Shorten the note
            setNewNoteBounds(n, take, n.startPPQ, cursorPPQ, 0, 0)

            tomod[#tomod+1] = n
            shcount         = shcount + 1

            if not noteEndsOnPPQ(newn, advancePPQ) then
              -- Add new note
              setNewNoteBounds(newn, take, advancePPQ, newn.endPPQ, 0, 0);
              toadd[#toadd+1] = newn
              addcount        = addcount + 1
            end
          end

        elseif noteEndsAfterPPQ(n, cursorPPQ, true) then
          -- Note ending should be erased
          --
          --     C     A
          --     |     |
          --   ==|===  |
          --     |     |
          --
          setNewNoteBounds(n, take, n.startPPQ, cursorPPQ, 0, 0);
          tomod[#tomod+1] = n
          shcount         = shcount + 1
        else
          -- Leave untouched
          --
          --     C     A
          --     |     |
          -- === |     |
          --     |     |
          --
        end

      end

      ni = ni + 1;
    end

  end

  -- All modes (Write / Insert / Replace) will insert new notes
  for _, v in ipairs(notes_to_add) do
    toadd[#toadd+1] = buildNewMidiNote(v)
    addcount = addcount + 1
  end

  -- All modes (Write / Insert / Replace) will extend existing notes
  if #notes_to_extend > 0 then
    local _, notecnt, _, _ = reaper.MIDI_CountEvts(take);

    for _, exnote in pairs(notes_to_extend) do

      -- Search for a note that could be extended (matches all conditions)
      local ni    = 0;
      local found = false;

      while (ni < notecnt) do
        local n = GetNote(take, ni);

        -- Extend the note if found
        if noteEndsOnPPQ(n, cursorPPQ) and (n.chan == exnote.chan) and (n.pitch == exnote.note) then

          tomod[#tomod + 1] = n
          setNewNoteBounds(n, take, n.startPPQ, advancePPQ, 0, 0)

          extcount = extcount + 1;
          found = true
        end

        ni = ni + 1;
      end

      if not found then
        -- Could not find a note to extend... create one !
        toadd[#toadd+1] = buildNewMidiNote(exnote)
        addcount = addcount + 1
      end
    end
  end

  -- Modify notes
  for ri = 1, #tomod, 1 do
    local n = tomod[ri]
    reaper.MIDI_SetNote(take, n.index, nil, nil, n.startPPQ, n.endPPQ, nil, nil, nil, true )
  end

  -- Delete notes that were shorten too much
  -- Do this in reverse order to be sure that indices are descending
  for ri = #torem, 1, -1 do
    reaper.MIDI_DeleteNote(take, torem[ri].index)
  end

  -- Reinsert moved notes
  for ri = 1, #toadd, 1 do
    local n = toadd[ri]
    reaper.MIDI_InsertNote(take, n.selected, n.muted, n.startPPQ, n.endPPQ, n.chan, n.pitch, n.vel, true )
  end

  -- Advance and mark dirty
  reaper.MIDI_Sort(take)
  reaper.UpdateItemInProject(mediaItem)
  reaper.SetEditCurPos(advanceTime, false, false);
  if getSetting("AutoScrollArrangeView") then
    KeepEditCursorOnScreen()
  end

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

  reaper.Undo_EndBlock(commitDescription(1, addcount, remcount, shcount, extcount, mvcount),-1);
end

local blockRewindRef = nil

local function commitBack(track, take, notes_to_shorten, triggered_by_key_event)

  local currentop       = resolveOperationMode(true)

  local writeModeON     = (currentop.mode == "Write")
  local navigateModeOn  = (currentop.mode == "Navigate")
  local insertModeOn    = (currentop.mode == "Insert")
  local replaceModeOn   = (currentop.mode == "Replace")

  local fullEraseMode = false

  if navigateModeOn or not take then
    if triggered_by_key_event and not AllowKeyEventNavigation() then
      -- Do nothing, not allowed
      return
    else
      return navigateBack(track)
    end
  end

  if insertModeOn  then

    fullEraseMode = true

    if (#notes_to_shorten > 0) then

      -- Back + Insert + Selective ??
      -- This is a complicated behavior : we want to erase back, but only some notes
      -- For the others what to we do ? move them ? if they're after the cursor ?
      -- And if they contain the cursor ?

      -- For now, just force a full erase
      notes_to_shorten = {}
    end

    if triggered_by_key_event and not AllowKeyEventNavigation() then
      -- Don't allow erasing when triggered by key
      return
    end
  end

  if replaceModeOn then
    fullEraseMode = true
    if #notes_to_shorten > 0 then
      -- Ignore selective erasing
      notes_to_shorten = {}
    end

    if triggered_by_key_event and not AllowKeyEventNavigation() then
      -- Don't allow erasing when triggered by key
      return
    end
  end

  local mediaItem     = reaper.GetMediaItemTake_Item(take)

  local note_len      = resolveNoteLenQN(take);

  local cursorTime    = reaper.GetCursorPosition()
  local cursorPPQ     = reaper.MIDI_GetPPQPosFromProjTime(take, cursorTime)
  local cursorQN      = reaper.TimeMap2_timeToQN(0, cursorTime)

  local itemStartTime = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
  local itemStartPPQ  = reaper.MIDI_GetPPQPosFromProjTime(take, itemStartTime)

  local rewindTime    = reaper.TimeMap2_QNToTime(0, cursorQN - note_len)

  if rewindTime < itemStartTime then
    rewindTime = itemStartTime
  end

  local rewindPPQ     = reaper.MIDI_GetPPQPosFromProjTime(take, rewindTime)

  -- If we're at the start of an item don't move things
  if math.abs(itemStartPPQ - cursorPPQ) < PPQ_TOLERANCE then
    return
  end

  local shcount, remcount, mvcount, addcount, extcount = 0, 0, 0, 0, 0

  reaper.Undo_BeginBlock();

  -- Try to extend existing notes
  local torem  = {}
  local tomod  = {}
  local toadd  = {}

  local _, notecnt, _, _ = reaper.MIDI_CountEvts(take);

  local ni = 0;
  while (ni < notecnt) do

    -- Examine each note in item
    local n = GetNote(take, ni);

    local targetable = false

    if fullEraseMode then
      -- steping back with insert mode on makes all notes potentially targetable
      targetable = true
    else
      for _, shnote in pairs(notes_to_shorten) do
        if n.chan == shnote.chan and n.pitch == shnote.note then
          targetable = true
          break
        end
      end
    end

    if targetable then
      if noteStartsAfterPPQ(n, cursorPPQ, false) then
        -- Note should be moved back or left untouched (if in cursor mode or not)
        --
        --     R     C
        --     |     |
        --     |     | ====
        --     |     |
        --
        if insertModeOn then
          -- Move the note back
          setNewNoteBounds(n, take, n.startPPQ, n.endPPQ, -note_len, -note_len)

          torem[#torem+1]   = n -- Remove
          toadd[#toadd+1]   = n -- And readd

          mvcount           = mvcount + 1
        end
      elseif noteStartsAfterPPQ(n, rewindPPQ, false) then
        if noteEndsBeforePPQ(n, cursorPPQ, false) then
          -- Note should be suppressed
          --
          --     R     C
          --     |     |
          --     | === |
          --     |     |
          --
          torem[#torem+1] = n
          remcount        = remcount + 1
        else
          -- The note should be shortened (removing tail).
          -- Since its start will change, it should be removed and reinserted (see reaper's API doc)
          --
          --     R     C
          --     |     |
          --     |   ==|===
          --     |     |
          --
          local offset = (insertModeOn) and (-note_len) or (0)
          setNewNoteBounds(n, take, cursorPPQ, n.endPPQ, offset, offset)

          torem[#torem+1]   = n
          toadd[#toadd+1]   = n

          shcount = shcount + 1
          mvcount = mvcount + 1
        end
      else
        if noteEndsAfterPPQ(n, cursorPPQ, false) then
          -- Note should be cut.
          --
          --     R     C
          --     |     |
          --   ==|=====|===
          --     |     |
          --
          if insertModeOn or noteEndsOnPPQ(n, cursorPPQ) then
            setNewNoteBounds(n, take, n.startPPQ, n.endPPQ, 0, -note_len)

            tomod[#tomod+1] = n
            shcount         = shcount + 1
          else
            -- Create a hole in the note. Copy note
            local newn = {}
            for k,v in pairs(n) do
              newn[k] = v
            end

            -- Shorted remaining note
            setNewNoteBounds(n, take, n.startPPQ, rewindPPQ, 0, 0);
            tomod[#tomod+1] = n
            shcount         = shcount + 1

            -- Add new note
            setNewNoteBounds(newn, take, cursorPPQ, newn.endPPQ, 0, 0);
            toadd[#toadd+1] = newn
            addcount        = addcount + 1
          end

        elseif noteEndsAfterPPQ(n, rewindPPQ, true) then
          -- Note ending should be erased
          --
          --     R     C
          --     |     |
          --   ==|===  |
          --     |     |
          --
          setNewNoteBounds(n, take, n.startPPQ, rewindPPQ, 0, 0);
          tomod[#tomod+1] = n
          shcount         = shcount + 1
        else
          -- Leave untouched
          --
          --     R     C
          --     |     |
          -- === |     |
          --     |     |
          --
        end
      end
    end

    ni = ni + 1;
  end

  -- Modify notes
  for ri = 1, #tomod, 1 do
    local n = tomod[ri]
    reaper.MIDI_SetNote(take, n.index, nil, nil, n.startPPQ, n.endPPQ, nil, nil, nil, true )
  end

  -- Delete notes that were shorten too much
  -- Do this in reverse order to be sure that indices are descending
  for ri = #torem, 1, -1 do
    reaper.MIDI_DeleteNote(take, torem[ri].index)
  end

  -- Reinsert moved notes
  for ri = 1, #toadd, 1 do
    local n = toadd[ri]
    reaper.MIDI_InsertNote(take, n.selected, n.muted, n.startPPQ, n.endPPQ, n.chan, n.pitch, n.vel, true )
  end

  -- Rewind and mark dirty
  reaper.MIDI_Sort(take);
  reaper.UpdateItemInProject(mediaItem)
  reaper.MarkTrackItemsDirty(track, mediaItem)

  local blockRewind       = false

  if writeModeON then
    -- We block the rewind in certain conditions (when erasing failed, and when during this pedal session, the erasing was blocked)
    local pedalStart        = currentKeyEventManager():keyActivityForTrack(track).pedal.first_ts
    local hadCandidates     = (#notes_to_shorten > 0)
    local failedToErase     = (hadCandidates and (shcount+remcount == 0))

    blockRewind = (getSetting("DoNotRewindOnStepBackIfNothingErased") and failedToErase) or ((not hadCandidates) and (pedalStart == blockRewindRef))
  end

  if blockRewind then
    blockRewindRef = pedalStart
  else
    if fullEraseMode or (not hadCandidates) or (not nothingWasErased) then
      reaper.SetEditCurPos(rewindTime, false, false);
      if getSetting("AutoScrollArrangeView") then
        KeepEditCursorOnScreen()
      end
    end
  end

  reaper.Undo_EndBlock(commitDescription(-1, addcount, remcount, shcount, extcount, mvcount),-1);
end

local function hasTrigger(forward)
  local res = false
  for k,v in pairs(ActionTriggers) do
    local cond = false
    if forward then
      cond = not v.back
    else
      cond = v.back
    end
    if cond then
      res = (res or getActionTrigger(k))
    end
  end
  return res
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

  -- Get the manager for the current input mode
  local manager = currentKeyEventManager();

  -- Update manager with new info from the helper JSFX
  manager:updateActivity(track, oss_state);

  local spmod = IsStepBackModifierKeyPressed();
  local pedal = manager:pullPedalTriggerForTrack(track);

  manager:tryAdvancedCommitForTrack(track,
    function(candidates, held_candidates)
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
  if (pedal and not spmod) or hasTrigger(true) then
    manager:simpleCommit(track, function(commit_candidates, held_candidates)
        commit(track, take, commit_candidates, held_candidates, false);
      end
    );
  end

  if (pedal and spmod) or hasTrigger(false) then
    manager:simpleCommitBack(track, function(shorten_candidates)
        commitBack(track, take, shorten_candidates, false)
      end
    );
  end

  manager:clearOutdatedActivity()

  clearAllActionTriggers()

  if getSetting("PedalRepeatEnabled") then
    manager:forgetPedalTriggerForTrack(track, getSetting("PedalRepeatTime"), getSetting("PedalRepeatFirstHitMultiplier"))
  end
end

-- To be called from companion action script
function reaperAction(action_name)
  setActionTrigger(action_name)
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

  clearAllActionTriggers()
  mayRestorePlaybackMarkerOnStart()
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

  IsStepBackModifierKeyPressed  = IsStepBackModifierKeyPressed,
  resolveOperationMode          = resolveOperationMode,

  -- Enums
  InputMode                     = InputMode,
  EditMode                      = EditMode,
  NoteLenParamSource            = NoteLenParamSource,
  NoteLenModifier               = NoteLenModifier,

  ModifierKeys                  = ModifierKeys,
  ModifierKeyLookup             = ModifierKeyLookup,
  ModifierKeyCombinations       = ModifierKeyCombinations,
  ModifierKeyCombinationLookup  = ModifierKeyCombinationLookup,

  NoteLenDefs                   = NoteLenDefs,

  setInputMode                  = setInputMode,
  getInputMode                  = getInputMode,

  setNoteLenParamSource         = setNoteLenParamSource,
  getNoteLenParamSource         = getNoteLenParamSource,

  setPlaybackMeasureCount       = setPlaybackMeasureCount,
  getPlaybackMeasureCount       = getPlaybackMeasureCount,

  setTupletDivision             = setTupletDivision,
  getTupletDivision             = getTupletDivision,

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

  reaperAction                  = reaperAction,

  TakeForEdition                = TakeForEdition,
  TrackForEditionIfNoItemFound  = TrackForEditionIfNoItemFound,

  TrackFocus                    = TrackFocus,
  RestoreFocus                  = RestoreFocus,
}

return EngineLib;