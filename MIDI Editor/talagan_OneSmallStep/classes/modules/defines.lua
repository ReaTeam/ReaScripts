-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

-- Tolerance to detect if events match
local TIME_TOLERANCE  = 0.001
local QN_TOLERANCE    = 0.01
local PPQ_TOLERANCE   = 1

local IsMacOs                   = (reaper.GetOS():find('OSX') ~= nil);

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
  Write             = "Write",
  Navigate          = "Navigate",
  Insert            = "Insert",
  Repitch           = "Repitch",
  Replace           = "Replace",
  Stretch           = "Stretch",
  Stuff             = "Stuff"
}

local ActionTriggers = {
  Commit            = { action = "Commit",       back = false   },
  CommitBack        = { action = "Commit",       back = true    },

  Write             = { action = "Write",        back = false   },
  Navigate          = { action = "Navigate",     back = false   },
  Insert            = { action = "Insert",       back = false,  markerAlternate = "Stretch" },
  Replace           = { action = "Replace",      back = false,  markerAlternate = "Stuff"   },
  Repitch           = { action = "Repitch",      back = false   },
  Stretch           = { action = "Stretch",      back = false   },
  Stuff             = { action = "Stuff",        back = false   },

  WriteBack         = { action = "Write",        back = true    },
  NavigateBack      = { action = "Navigate",     back = true    },
  InsertBack        = { action = "Insert",       back = true,  markerAlternate = "StretchBack"  },
  ReplaceBack       = { action = "Replace",      back = true,  markerAlternate = "StuffBack"    },
  RepitchBack       = { action = "Repitch",      back = true    },
  StretchBack       = { action = "Stretch",      back = true    },
  StuffBack         = { action = "Unstuff",      back = true    }
}

local RepitchModeAffects = {
  PitchesOnly           = "Pitches only",
  VelocitiesOnly        = "Velocities only",
  PitchesAndVelocities  = "Pitches + Velocities"
}

local MiddleInsertBehavior = {
  LeaveUntouched        = "Leave Untouched",
  Cut                   = "Cut note",
  Extend                = "Extend note",
  CutAndAdd             = "Cut note and insert new one"
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

local ModifierKeys    = IsMacOs and MacOSModifierKeys or OtherOSModifierKeys;

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
    local m2 = ModifierKeys[j]
    ModifierKeyCombinations[#ModifierKeyCombinations+1] = { label = m1.name .. "+" .. m2.name, id = "" .. m1.vkey .. "+" .. m2.vkey, vkeys = { m1.vkey, m2.vkey } }
  end
end

local ModifierKeyCombinationLookup = {};
for i,v in ipairs(ModifierKeyCombinations) do
  ModifierKeyCombinationLookup[v.id] = v;
end

return {
  TIME_TOLERANCE                = TIME_TOLERANCE,
  PPQ_TOLERANCE                 = PPQ_TOLERANCE,
  QN_TOLERANCE                  = QN_TOLERANCE,

  InputMode                     = InputMode,
  EditMode                      = EditMode,
  IsMacOs                       = IsMacOs,

  RepitchModeAffects            = RepitchModeAffects,

  MiddleInsertBehavior          = MiddleInsertBehavior,

  ActionTriggers                = ActionTriggers,

  NoteLenDefs                   = NoteLenDefs,
  NoteLenLookup                 = NoteLenLookup,

  NoteLenParamSource            = NoteLenParamSource,
  NoteLenModifier               = NoteLenModifier,

  ModifierKeys                  = ModifierKeys,
  ModifierKeyLookup             = ModifierKeyLookup,

  ModifierKeyCombinations       = ModifierKeyCombinations,
  ModifierKeyCombinationLookup  = ModifierKeyCombinationLookup
}

