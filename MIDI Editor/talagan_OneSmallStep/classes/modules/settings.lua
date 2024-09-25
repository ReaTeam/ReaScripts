-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local D = require "modules/defines"

local TrackSettingDefs = {
  OSSArticulationManagerEnabled = { type = "bool", default = false }
}

local SettingDefs = {
  StepBackModifierKey                                       = { type = "int",     default = D.IsMacOs and 16 or 16 },

  WriteModifierKeyCombination                               = { type = "string",  default = "none" },
  InsertModifierKeyCombination                              = { type = "string",  default = D.IsMacos and "17" or "17" },
  NavigateModifierKeyCombination                            = { type = "string",  default = D.IsMacos and "18" or "18" },
  ReplaceModifierKeyCombination                             = { type = "string",  default = D.IsMacos and "17+18" or "17+18" },
  RepitchModifierKeyCombination                             = { type = "string",  default = "none" },

  HideEditModeMiniBar                                       = { type = "bool",    default = false },

  Mode                                                      = { type = "int",     default = D.InputMode.KeyboardRelease },
  EditMode                                                  = { type = "string",  default = D.EditMode.Write },

  PlaybackMeasureCount                                      = { type = "int",     default = -1 }, -- -1 is marker mode
  NoteLenParamSource                                        = { type = "int",     default = D.NoteLenParamSource.OSS },
  NoteLenFactorDenominator                                  = { type = "int",     default = 1 },
  NoteLenFactorNumerator                                    = { type = "int",     default = 1 },
  TupletDivision                                            = { type = "int",     default = 4 },
  NoteLen                                                   = { type = "string",  default = "1_4"},
  NoteLenModifier                                           = { type = "int",     default = D.NoteLenModifier.Straight },

  PlaybackMarkerPolicyWhenClosed                            = { type = "string",  default = "Keep visible" },
  OperationMarkerPolicyWhenClosed                           = { type = "string",  default = "Keep visible" },

  AllowTargetingFocusedMidiEditors                          = { type = "bool",    default = true },
  AllowTargetingNonSelectedItemsUnderCursor                 = { type = "bool",    default = false },
  AllowCreateItem                                           = { type = "bool",    default = false },

  DoNotRewindOnStepBackIfNothingErased                      = { type = "bool",    default = true},
  CleanupJsfxAtClosing                                      = { type = "bool",    default = true},
  SelectInputNotes                                          = { type = "bool",    default = true},

  KeyPressModeAggregationTime                               = { type = "double",  default = 0.05, min = 0,   max = 0.1 },
  KeyPressModeInertiaTime                                   = { type = "double",  default = 0.5,  min = 0.2, max = 1.0 },
  KeyPressModeInertiaEnabled                                = { type = "bool",    default = true},

  KeyReleaseModeForgetTime                                  = { type = "double",  default = 0.200, min = 0.05, max = 0.4},

  RepitchModeAggregationTime                                = { type = "double",  default = 0.05, min = 0,   max = 0.1 },
  RepitchModeAffects                                        = { type = "string",  default = D.RepitchModeAffects.PitchesOnly, inclusion = { D.RepitchModeAffects.PitchesOnly, D.RepitchModeAffects.VelocitiesOnly, D.RepitchModeAffects.PitchesAndVelocities } },

  PedalRepeatEnabled                                        = { type = "bool" ,   default = true },
  PedalRepeatTime                                           = { type = "double",  default = 0.200, min = 0.05, max = 0.5 },
  PedalRepeatFirstHitMultiplier                             = { type = "int",     default = 4, min = 1, max = 10 },

  SnapNotes                                                 = { type = "bool",    default = true },
  SnapProjectGrid                                           = { type = "bool",    default = true },
  SnapItemGrid                                              = { type = "bool",    default = true },
  SnapItemBounds                                            = { type = "bool",    default = true },

  AutoScrollArrangeView                                     = { type = "bool",    default = true },

  AllowKeyEventNavigation                                   = { type = "bool",    default = false },

  Disarmed                                                  = { type = "bool",    default = false },
  NoteHiglightingDuringPlay                                 = { type = "bool",    default = false },

  UseDebugger                                               = { type = "bool",    default = false },

  VelocityLimiterEnabled                                    = { type = "bool",    default = false },
  VelocityLimiterMin                                        = { type = "int",     default = 0,    min = 0, max = 127 },
  VelocityLimiterMax                                        = { type = "int",     default = 127,  min = 0, max = 127 },
  VelocityLimiterMode                                       = { type = "string",  default = "Linear", inclusion = { "Linear", "Clamp"} },

  InsertModeInMiddleOfMatchingNotesBehaviour                = {
    type = "string",
    default = D.MiddleInsertBehavior.LeaveUntouched,
    inclusion = {
      D.MiddleInsertBehavior.LeaveUntouched,
      D.MiddleInsertBehavior.Extend,
      D.MiddleInsertBehavior.Cut,
      D.MiddleInsertBehavior.CutAndAdd
    }
  },

  InsertModeInMiddleOfNonMatchingNotesBehaviour            = {
    type = "string",
    default = D.MiddleInsertBehavior.LeaveUntouched,
    inclusion = {
      D.MiddleInsertBehavior.LeaveUntouched,
      D.MiddleInsertBehavior.Extend,
      D.MiddleInsertBehavior.Cut,
    }
  }
};


local function unsafestr(str)
  if str == "" then
    return nil
  end
  return str
end

local function serializedStringToValue(str, spec)
  local val = unsafestr(str);

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

  return val
end

local function valueToSerializedString(val, spec)
  local str = ''
  if spec.type == 'bool' then
    str = (val == true) and "true" or "false";
  elseif spec.type == 'int' then
    str = tostring(val);
  elseif spec.type == 'double' then
    str = tostring(val);
  elseif spec.type == "string" then
    -- No conversion needed
    str = val
  end
  return str
end

local function getSetting(setting)
  local spec  = SettingDefs[setting];

  if spec == nil then
    error("Trying to get unknown setting " .. setting);
  end

  local str = reaper.GetExtState("OneSmallStep", setting)

  return serializedStringToValue(str, spec)
end

local function setSetting(setting, val)
  local spec  = SettingDefs[setting];

  if spec == nil then
    error("Trying to set unknown setting " .. setting);
  end

  if val == nil then
    reaper.DeleteExtState("OneSmallStep", setting, true);
  else
    local str = valueToSerializedString(val, spec);
    reaper.SetExtState("OneSmallStep", setting, str, true);
  end
end

local function getTrackSetting(track, setting)
  local spec  = TrackSettingDefs[setting];

  if track == nil then
    error("Trying to get setting " .. setting .. " from nil track ")
  end

  if spec == nil then
    error("Trying to get unknown track setting " .. setting);
  end

  local succ, str = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:OneSmallStep:" .. setting, '', false);

  return serializedStringToValue(str or '', spec)
end

local function setTrackSetting(track, setting, val)
  local spec  = TrackSettingDefs[setting];

  if track == nil then
    error("Trying to set setting " .. setting .. " to nil track ")
  end
  if spec == nil then
    error("Trying to set unknown track setting " .. setting);
  end

  local str = valueToSerializedString(val, spec);
  reaper.GetSetMediaTrackInfo_String(track, "P_EXT:OneSmallStep:" .. setting, str, true)
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

local function AllowKeyEventNavigation()          return getSetting("AllowKeyEventNavigation")   end

local function precpow2(n)
  local b = 0
  local a = (n >> b)
  while a > 0 do
    b = b + 1
    a = (n >> b)
  end
  return (1 << (b-1))
end

local function getTupletFactor(div)
  return precpow2(div)/div
end

local function getNoteLenModifierFactor()

  local m   = getNoteLenModifier()
  local nls = getNoteLenParamSource()

  if m == D.NoteLenModifier.Straight then
    return 1.0;
  elseif m == D.NoteLenModifier.Dotted then
    return 1.5;
  elseif m == D.NoteLenModifier.Triplet then
    return 2/3.0;
  elseif m == D.NoteLenModifier.Modified then
    return getSetting("NoteLenFactorNumerator") / getSetting("NoteLenFactorDenominator");
  elseif m == D.NoteLenModifier.Tuplet then
    local div = getTupletDivision();

    if nls == D.NoteLenParamSource.OSS then
      return getTupletFactor(div)
    else
      -- In grid mode, we just return 1/n
      return 1/div
    end
  end

  return 1.0;
end

local function increaseNoteLen()
  local l = getNoteLen();
  setNoteLen(D.NoteLenLookup[l].next);
end

local function decreaseNoteLen()
  local l = getNoteLen();
  setNoteLen(D.NoteLenLookup[l].prec);
end

local function getNoteLenQN()
  local nl  = getNoteLen();

  return D.NoteLenLookup[nl].qn;
end

return {
  SettingDefs                 = SettingDefs,

  getSetting                  = getSetting,
  setSetting                  = setSetting,
  resetSetting                = resetSetting,
  getSettingSpec              = getSettingSpec,

  getTrackSetting             = getTrackSetting,
  setTrackSetting             = setTrackSetting,

  setPlaybackMeasureCount     = setPlaybackMeasureCount,
  getPlaybackMeasureCount     = getPlaybackMeasureCount,

  setInputMode                = setInputMode,
  getInputMode                = getInputMode,

  setNoteLenParamSource       = setNoteLenParamSource,
  getNoteLenParamSource       = getNoteLenParamSource,

  setTupletDivision           = setTupletDivision,
  getTupletDivision           = getTupletDivision,

  setNoteLen                  = setNoteLen,
  getNoteLen                  = getNoteLen,

  setNoteLenModifier          = setNoteLenModifier,
  getNoteLenModifier          = getNoteLenModifier,

  getNoteLenFactorNumerator   = getNoteLenFactorNumerator,
  getNoteLenFactorDenominator = getNoteLenFactorDenominator,
  getNoteLenModifierFactor    = getNoteLenModifierFactor,

  increaseNoteLen             = increaseNoteLen,
  decreaseNoteLen             = decreaseNoteLen,
  getNoteLenQN                = getNoteLenQN,

  AllowKeyEventNavigation     = AllowKeyEventNavigation
}

