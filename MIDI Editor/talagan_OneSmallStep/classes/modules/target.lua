-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local D = require "modules/defines"
local S = require "modules/settings"
local T = require "modules/time"
local F = require "modules/focus"

local function TryToGetTakeFromMidiEditor()
  local midiEditor   = reaper.MIDIEditor_GetActive();
  local midiEditorOk = not (reaper.MIDIEditor_GetMode(midiEditor) == -1);

  -- Prioritize the currently focused MIDI editor.
  -- Use the last known focused element (between arrange view / midi editor) as it is more robust
  -- When OSS window is focused for editing parameters
  if midiEditorOk and F.LastKnownFocus().element == "MIDIEditor" then
    --  -1 if ME not focused
    local take = reaper.MIDIEditor_GetTake(midiEditor);
    if take then
      local mediaItem  = reaper.GetMediaItemTake_Item(take);
      if T.MediaItemContainsCursor(mediaItem, reaper.GetCursorPosition()) then
        return take
      end
    end
  end

  return nil
end

local function TryToGetTakeFromArrangeViewAmongSelectedItems()
  local mediaItemCount = reaper.CountSelectedMediaItems(0);
  local cursorPos      = reaper.GetCursorPosition();

  local candidates  = {};

  for i = 0, mediaItemCount - 1 do

    local mediaItem = reaper.GetSelectedMediaItem(0, i)
    local track     = reaper.GetMediaItem_Track(mediaItem)

    -- Only keep items that contain the cursor pos
    if T.MediaItemContainsCursor(mediaItem, cursorPos) then
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
  local trackCount     = reaper.CountSelectedTracks(0);

  local candidates  = {};

  for i = 0, trackCount - 1 do
    local track     = reaper.GetSelectedTrack(0, i);
    local itemCount = reaper.CountTrackMediaItems(track);
    for j = 0, itemCount - 1 do
      local mediaItem = reaper.GetTrackMediaItem(track, j);

      if T.MediaItemContainsCursor(mediaItem, cursorPos) then
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


-- This function returns the take that should be edited
-- Inspired by tenfour's scripts but modified
-- It uses a strategy based on :
-- - What component has focus (midi editor or arrange window)
-- - What items are selected
-- - What items contain the cursor
-- - What tracks are selected

local function TakeForEdition()
  -- Try to get a take from the MIDI editor
  local take = nil;

  if S.getSetting("AllowTargetingFocusedMidiEditors") then
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

  if S.getSetting("AllowTargetingNonSelectedItemsUnderCursor") then
    -- Third heuristic (if enabled), try to get a take from selected tracks
    take = TryToGetTakeFromArrangeViewAmongSelectedTracks();
    if take then
      return take;
    end
  end

  return nil;
end

local function TrackForEditionIfNoItemFound()
  local trackCount     = reaper.CountSelectedTracks(0);
  if trackCount > 0 then
    return reaper.GetSelectedTrack(0, 0);
  end
  return nil;
end

local function CreateItemIfMissing(track)
  local newitem = reaper.CreateNewMIDIItemInProj(track, reaper.GetCursorPosition(), reaper.GetCursorPosition() + D.TIME_TOLERANCE, false)
  local take = reaper.GetMediaItemTake(newitem, 0)
  local _, tname = reaper.GetTrackName(track)
  reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", tname ..os.date(' - %Y%m%d%H%M%S'), true)
  return take
end

return {
  TrackForEditionIfNoItemFound  = TrackForEditionIfNoItemFound,
  TakeForEdition                = TakeForEdition,
  CreateItemIfMissing           = CreateItemIfMissing
}
