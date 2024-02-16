-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local scriptDir = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]];
local upperDir  = scriptDir:match( "((.*)[\\/](.+)[\\/])(.+)$" );

package.path      = scriptDir .."?.lua;".. package.path

local helper_lib                = require "talagan_OneSmallStep Helper lib";
local KeyReleaseActivityManager = require "classes/KeyReleaseActivityManager";
local KeyPressActivityManager   = require "classes/KeyPressActivityManager";

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
}

local NoteLenLookup = {};
for i,v in ipairs(NoteLenDefs) do
  NoteLenLookup[v.id] = v;
end

local AugmentedDiminishedLookup = {};
for i,v in ipairs(AugmentedDiminishedDefs) do
  AugmentedDiminishedLookup[v.id] = v;
end

local NoteLenParamSource = {
  OSS=0,
  ProjectGrid=1,
  ItemConf=2
}

local InputMode = {
  None=0,
  Pedal=1,
  Keyboard=2,
  Action=3,
  KeyboardMelodic=4
}

local NoteLenModifier = {
  Straight=0,
  Dotted=1,
  Triplet=2,
  Tuplet=3,
  Modified=4
}

------------

-- Our manager for the Key Release input mode
local KRActivityManager = KeyReleaseActivityManager:new();

-- Our manager for the Key Press input mode
local KPActivityManager = KeyPressActivityManager:new();

-----------

local function setPlaybackMeasureCount(c)
  reaper.SetExtState("OneSmallStep", "PlaybackMeasureCount", c, true);
end
local function getPlaybackMeasureCount()
  return tonumber(reaper.GetExtState("OneSmallStep", "PlaybackMeasureCount")) or -1; -- -1 is marker mode
end

local function setInputMode(m)
  reaper.SetExtState("OneSmallStep", "Mode", tostring(m), true)
end
local function getInputMode()
  return tonumber(reaper.GetExtState("OneSmallStep", "Mode")) or InputMode.Keyboard;
end

local function setNoteLenParamSource(m)
  reaper.SetExtState("OneSmallStep", "NoteLenParamSource", tostring(m), true)
end
local function getNoteLenParamSource()
  return tonumber(reaper.GetExtState("OneSmallStep", "NoteLenParamSource")) or 0;
end

local function setNoteADSign(plus_or_minus)
  reaper.SetExtState("OneSmallStep", "NoteLenADSign", plus_or_minus, true)
end
local function getNoteADSign()
  return reaper.GetExtState("OneSmallStep", "NoteLenADSign") or "+";
end

local function setNoteADFactor(fraction_string)
  reaper.SetExtState("OneSmallStep", "NoteADFactor", fraction_string, true)
end
local function getNoteADFactor()
  return reaper.GetExtState("OneSmallStep", "NoteADFactor") or "1/2";
end

local function setTupletDivision(m)
  reaper.SetExtState("OneSmallStep", "TupletDivision", tostring(m), true)
end
local function getTupletDivision()
  return tonumber(reaper.GetExtState("OneSmallStep", "TupletDivision")) or 4;
end

local function setNoteLen(str)
  reaper.SetExtState("OneSmallStep", "NoteLen", str, true);
end
local function getNoteLen()
  local nl = reaper.GetExtState("OneSmallStep", "NoteLen");
  if nl == "" or nl == nil then
    return "1_4";
  end
  return nl;
end

local function setNoteLenModifier(m)
  reaper.SetExtState("OneSmallStep", "NoteLenModifier", tostring(m), true);
end
local function getNoteLenModifier()
  return tonumber(reaper.GetExtState("OneSmallStep", "NoteLenModifier"));
end

-----------

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

function setPlaybackMarkerAtCurrentPos()

  local pos       = reaper.GetCursorPosition();

  local id, mpos  = findPlaybackMarker();

  reaper.Undo_BeginBlock();
  if not (id == nil) then
    reaper.DeleteProjectMarkerByIndex(0, id);
  end

  if (mpos == nil) or math.abs(pos - mpos) > 0.001 then
    reaper.AddProjectMarker2(0, false, pos, 0, "OSS Playback", -1, reaper.ColorToNative(0,200,255)|0x1000000);
  end
  reaper.Undo_EndBlock("One Small Step - Set playback cursor", -1);

end

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


local function ArrangeViewIsNotFocused()
 return reaper.GetCursorContext() == -1
end

local function IsInMIDIEditor()
  -- This is the best we can do but it's still dangerous ...
  -- (will return true whenever the arrange view is not focused)
  return ArrangeViewIsNotFocused();
end


-- This function returns the take that should be edited.
-- Inspired by tenfour's scripts but modified
-- It uses a strategy based on :
-- - What component has focus (midi editor or arrange window)
-- - What items are selected
-- - What items contain the cursor
-- - What tracks are selected

local function TakeForEdition()
  local take = nil

  local midiEditor   = reaper.MIDIEditor_GetActive();
  local midiEditorOk = not (reaper.MIDIEditor_GetMode(midiEditor) == -1);

  -- Prioritize the currently focused MIDI editor.
  if midiEditorOk and IsInMIDIEditor() then
    --  -1 if ME not focused
    take = reaper.MIDIEditor_GetTake(midiEditor);
    if reaper.ValidatePtr(take, 'MediaItem_Take*') then
      return take
    end
  end

  -- If no take can be gotten from the MIDI Editors
  -- try to find a Media Item that is under the cursor

  local mediaItemCount = reaper.CountSelectedMediaItems(0);
  local cursorPos      = reaper.GetCursorPosition();

  local candidates  = {};

  for i = 0, mediaItemCount - 1 do

    local mediaItem = reaper.GetSelectedMediaItem(0, i)
    local track     = reaper.GetMediaItem_Track(mediaItem)
    local pos       = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
    local len       = reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")
    local tsel      = reaper.IsTrackSelected(track);

    local fudge = 0.002;
    local left  = pos - fudge;
    local right = pos + len + fudge;

    -- Only keep items that contain the cursor pos
    if cursorPos >= left and cursorPos <= right then
      local tk = reaper.GetActiveTake(mediaItem);
      candidates[#candidates + 1] = { take = tk, tsel = tsel, tname = reaper.GetTrackName(track), name = reaper.GetTakeName(tk) }
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
local function commit(take, notes)

  local note_len                  = resolveNoteLenQN(take);

  local noteStartTime             = reaper.GetCursorPosition()
  local noteStartQN               = reaper.TimeMap2_timeToQN(0, noteStartTime)
  local noteEndTime               = reaper.TimeMap2_QNToTime(0, noteStartQN + note_len)

  local mediaItem                 = reaper.GetMediaItemTake_Item(take)
  local track                     = reaper.GetMediaItemTake_Track(take)

  if #notes > 0 then
    local noteStartPPQ  = reaper.MIDI_GetPPQPosFromProjTime(take, noteStartTime)
    local noteEndPPQ    = reaper.MIDI_GetPPQPosFromProjTime(take, noteEndTime)

    for k,v in pairs(notes) do
      reaper.MIDI_InsertNote(take, true, false, noteStartPPQ, noteEndPPQ, v.chan, v.note, v.velocity)
    end
  end

  -- Advance and mark dirty
  reaper.UpdateItemInProject(mediaItem)
  reaper.SetEditCurPos(noteEndTime, false, false);
  reaper.MarkTrackItemsDirty(track, mediaItem)

  -- Grow the midi item if needed
  local itemStartTime = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
  local itemLength    = reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")
  local itemEndTime   = itemStartTime + itemLength;

  if(itemEndTime >= noteEndTime) then
    return
  end

  local itemStartQN = reaper.TimeMap2_timeToQN(0, itemStartTime)
  local itemEndQN   = reaper.TimeMap2_timeToQN(0, noteEndTime)

  reaper.MIDI_SetItemExtents(mediaItem, itemStartQN, itemEndQN)
end


-- Listen to events from instrumented tracks that have the JSFX companion effect installed (or install it if not present)
local function listenToEvents(called_from_action)

  local mode = getInputMode();

  -- Input mode should be engaged
  if mode == InputMode.None then
    return;
  end

  -- Reaper should not be in play/pause/rec state
  if (not (reaper.GetPlayState()==0)) then
    return;
  end

  local take = TakeForEdition();

  if not take then
    return
  end

  local track     = reaper.GetMediaItemTake_Track(take);
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

  if mode == InputMode.Pedal then

    if oss_state.pedalActivity > 0 or called_from_action then
      -- Pedal event, commit new notes
      reaper.Undo_BeginBlock();
      helper_lib.resetPedalActivity(track);
      commit(take, oss_state.pitches);
      reaper.Undo_EndBlock("One Small Step - Add notes on pedal event",-1);
    end

  elseif mode == InputMode.Action then

    if called_from_action then
      reaper.Undo_BeginBlock();
      commit(take, oss_state.pitches);
      reaper.Undo_EndBlock("One Small Step - Add notes on action",-1);
    end

  elseif mode == InputMode.Keyboard then
    -- Remove old events that are not relevant (cleanup)
    KRActivityManager:clearOutdatedTrackActivity();
    -- Commit new key state
    KRActivityManager:keepTrackOfKeysForTrack(track, oss_state.pitches)

    local lastKnown = KRActivityManager:keyActivityForTrack(track);

    if lastKnown then
      -- We had some notes in our memory
      -- But now it's not the case anymore.
      -- It's a realease key event
      if #lastKnown ~= 0 and #oss_state.pitches == 0 then
        reaper.Undo_BeginBlock();
        commit(take, lastKnown);
        -- Acknowledge note activity, full cleanup.
        KRActivityManager:clearTrackActivityForTrack(track);
        reaper.Undo_EndBlock("One Small Step - Add notes on key(s) release",-1);
      end
    end

    -- Allow the use of the action or pedal, but only insert rests
    if oss_state.pedalActivity > 0 or called_from_action then
      reaper.Undo_BeginBlock();
      helper_lib.resetPedalActivity(track);
      commit(take, {}) ;
      reaper.Undo_EndBlock("One Small Step - Add rest",-1);
    end

  elseif mode == InputMode.KeyboardMelodic then
    -- Remove old events that are not relevant (cleanup)
    KPActivityManager:clearOutdatedTrackActivity();

    -- Commit new key state
    KPActivityManager:keepTrackOfKeysForTrack(track, oss_state.pitches);

    local toCommit  = KPActivityManager:pullNotesToCommitForTrack(track);

    if #toCommit > 0 then
      reaper.Undo_BeginBlock();
      commit(take, toCommit);
      reaper.Undo_EndBlock("One Small Step - Add notes on key(s) press",-1);
    end

    -- Allow the use of the action or pedal, but only insert rests
    if oss_state.pedalActivity > 0 or called_from_action then
      reaper.Undo_BeginBlock();
      helper_lib.resetPedalActivity(track);
      commit(take, {}) ;
      reaper.Undo_EndBlock("One Small Step - Add rest",-1);
    end
  end

end

function reaperActionCommit()
  listenToEvents(true);
end

function cleanupCompanionFXs()
  reaper.Undo_BeginBlock()
  helper_lib.cleanupAllTrackFXs();
  reaper.Undo_EndBlock("One Small Step - Cleanup companion JSFXs",-1);
end

function atStart()
  -- Do some cleanup at engine start
  -- But this adds an undo entry point ...
  -- So rely on the user instead to cleanup the JSFXs using the relevant action
  -- If there's one day a way to prevent reaper from creating Undo points
  -- Then we can uncomment this automatic cleanup
  -- cleanupCompanionFXs();
end

function atExit()
  -- See comment in atStart
  -- cleanupCompanionFXs();
end

function atLoop()
  return listenToEvents();
end


return {
  -- Enums
  InputMode                     = InputMode,
  NoteLenParamSource            = NoteLenParamSource,
  NoteLenModifier               = NoteLenModifier,

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

  reaperActionCommit            = reaperActionCommit,

  TakeForEdition                = TakeForEdition,
}
