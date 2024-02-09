-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local scriptDir = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]];
local upperDir  = scriptDir:match( "((.*)[\\/](.+)[\\/])(.+)$" );

package.path      = scriptDir .."?.lua;".. package.path

local helper_lib  = require "talagan_OneSmallStep Helper lib";

-- Defines
local noteLenLookup = {
  ["1"]     = {next="1",    prec="1_2",   qn=4      },
  ["1_2"]   = {next="1",    prec="1_4",   qn=2      },
  ["1_4"]   = {next="1_2",  prec="1_8",   qn=1      },
  ["1_8"]   = {next="1_4",  prec="1_16",  qn=0.5    },
  ["1_16"]  = {next="1_8",  prec="1_32",  qn=0.25   },
  ["1_32"]  = {next="1_16", prec="1_64",  qn=0.125  },
  ["1_64"]  = {next="1_32", prec="1_64",  qn=0.0625 }
};

local NoteLenMode = {
  OSS=0,
  ProjectGrid=1,
  ItemConf=2
}

local InputMode = {
  None=0,
  Pedal=1,
  Keyboard=2,
  Action=3
}

local NoteLenModifier = {
  Straight=0,
  Dotted=1,
  Triplet=2,
  Tuplet=3
}


local function DBG(m)
  --reaper.ShowConsoleMsg(m .. "\n");
end

-----------

local function setMode(m)
  reaper.SetExtState("OneSmallStep", "Mode", tostring(m), true)
end
local function getMode()
  return tonumber(reaper.GetExtState("OneSmallStep", "Mode")) or 0;
end

-----------

local function setNoteLenMode(m)
  reaper.SetExtState("OneSmallStep", "NoteLenMode", tostring(m), true)
end
local function getNoteLenMode()
  return tonumber(reaper.GetExtState("OneSmallStep", "NoteLenMode")) or 0;
end

-----------

local function setTupletDivision(m)
  reaper.SetExtState("OneSmallStep", "TupletDivision", tostring(m), true)
end
local function getTupletDivision()
  return tonumber(reaper.GetExtState("OneSmallStep", "TupletDivision")) or 4;
end

-----------

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

-----------

local function setNoteLenModifier(m)
  reaper.SetExtState("OneSmallStep", "NoteLenModifier", tostring(m), true);
end
local function getNoteLenModifier()
  return tonumber(reaper.GetExtState("OneSmallStep", "NoteLenModifier"));
end
local function getNoteLenModifierFactor()

  local m = getNoteLenModifier();

  if m == NoteLenModifier.Straight then
    return 1.0;
  elseif m == NoteLenModifier.Dotted then
    return 1.5;
  elseif m == NoteLenModifier.Triplet then
    return 2/3.0;
  elseif m == NoteLenModifier.Tuplet then
    local div = getTupletDivision();
    return 2.0/div;
  end

  return 1.0;
end

local function increaseNoteLen()
  local l = getNoteLen();
  setNoteLen(noteLenLookup[l].next);
end

local function decreaseNoteLen()
  local l = getNoteLen();
  setNoteLen(noteLenLookup[l].prec);
end

local function getNoteLenQN()
  local nl  = getNoteLen();

  return noteLenLookup[nl].qn;
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

  local nlm = getNoteLenMode();

  if nlm == NoteLenMode.OSS then
    return getNoteLenQN() * getNoteLenModifierFactor();
  elseif nlm == NoteLenMode.ProjectGrid then

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

  -- Grow the midi item
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

--------------------------------------------------------------------
---------------------------------------------------------------------

-- The next functions are used to manage a
-- Table to keep track of key activities
-- With inertia, to avoid losing events for chords
-- When releasing keys (the release events may not be totally synchronized)
local trackKeyActivity  = {};
local keyInertia        = 0.2;

local function keepTrackOfKeysForTrack(track, pressed_keys)
  local trackid   = reaper.GetTrackGUID(track);
  local t         = reaper.time_precise();

  if trackKeyActivity[trackid] == nil then
    trackKeyActivity[trackid] = { }
  end

  for _, v in pairs(pressed_keys) do
    local k = tostring(math.floor(v.chan+0.5)) .. "," .. tostring(math.floor(v.note+0.5))
    trackKeyActivity[trackid][k] = {
      note=v.note,
      chan=v.chan,
      velocity=v.velocity,
      ts=t
    };
  end
end

local function keyActivityForTrack(track)
  local trackid        = reaper.GetTrackGUID(track);
  local track_activity = trackKeyActivity[trackid];

  if track_activity == nil then
    return {}
  end

  ttta = track_activity;

  local ret = {};
  for _, v in pairs(track_activity) do
   ret[#ret+1] = v;
  end

  return ret
end

local function clearTrackActivityForTrack(track)
  local trackid = reaper.GetTrackGUID(track);
  trackKeyActivity[trackid] = {};
end

local function clearOutdatedTrackActivity()
  local t         = reaper.time_precise();

  -- Do some cleanup
  for guid, track_activity in pairs(trackKeyActivity) do
    local torem = {};
    for k, note_info in pairs(track_activity) do
      if t - note_info.ts > keyInertia then
        torem[#torem+1] = k
      end
    end

    for k,v in pairs(torem) do
      track_activity[v] = nil;
    end
  end
end

--------------------------------------------------------------------
---------------------------------------------------------------------

-- Listen to events from instrumented tracks that have the JSFX companion effect installed (or install it if not present)
local function listenToEvents(called_from_action)

  local mode = getMode();

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
      -- Acknowledge the pedal
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
    clearOutdatedTrackActivity();
    keepTrackOfKeysForTrack(track, oss_state.pitches)

    local trackid   = reaper.GetTrackGUID(track);
    local lastKnown = keyActivityForTrack(track);

    if lastKnown then
      -- We had some notes in our memory
      -- But now it's not the case anymore.
      -- It's a realease key event
      if #lastKnown ~= 0 and #oss_state.pitches == 0 then
        reaper.Undo_BeginBlock();
        commit(take, lastKnown);
        -- Acknowledge note activity.
        clearTrackActivityForTrack(track);
        reaper.Undo_EndBlock("One Small Step - Add notes on key(s) release",-1);
      end
    end

    -- Allow the use of the action, but only insert rests
    if called_from_action then
      reaper.Undo_BeginBlock();
      commit(take, {}) ;
      reaper.Undo_EndBlock("One Small Step - Add rest on action",-1);
    end
  end

end

function reaperActionCommit()
  listenToEvents(true);
end

function atStart()
  -- Do some cleanup at engine start
  -- But this adds an undo entry point ...
  -- So rely on the user instead to cleanup the JSFXs using the relevant action
  -- If there's one day a way to prevent reaper from creating Undo points
  -- Then we can uncomment this automatic cleanup
  --reaper.Undo_BeginBlock()
  --helper_lib.cleanupAllTrackFXs();
  --reaper.Undo_EndBlock("One Small Step - Cleanup companion JSFXs",-1);
end

function atExit()
  -- See comment in atStart
  --reaper.Undo_BeginBlock()
  --helper_lib.cleanupAllTrackFXs();
  --reaper.Undo_EndBlock("One Small Step - Cleanup companion JSFXs",-1);
end

function atLoop()
  return listenToEvents();
end


return {
  -- Enums
  InputMode                     = InputMode,
  NoteLenMode                   = NoteLenMode,
  NoteLenModifier               = NoteLenModifier,

  --Functions
  setMode                       = setMode,
  getMode                       = getMode,

  setNoteLenMode                = setNoteLenMode,
  getNoteLenMode                = getNoteLenMode,

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

  atStart                       = atStart,
  atExit                        = atExit,
  atLoop                        = atLoop,

  reaperActionCommit            = reaperActionCommit,

  TakeForEdition                = TakeForEdition,
}
