-- @description Move selected notes to a new MIDI item
-- @author Rodilab
-- @version 1.1
-- @provides [main=main,midi_editor] .
-- @about
--   Move selected notes to a new MIDI item.
--   This is apply to active MIDI Editor take, and all selected MIDI items.
--
--   by Rodrigo Diaz (aka Rodilab)

---------------------------------------
-- Functions
---------------------------------------

function MoveNotesToNewItem(item)
  local take = reaper.GetActiveTake(item)
  if reaper.TakeIsMIDI(take) then
    local track = reaper.GetMediaItem_Track(item)
    local position = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
    local rv, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(take)
    local new_item = reaper.CreateNewMIDIItemInProj(track, position, position+length)
    local new_take = reaper.GetActiveTake(new_item)
    for j=0, notecnt-1 do
      j = notecnt-1-j
      local rv, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, j)
      if selected then
        reaper.MIDI_InsertNote(new_take, selected, muted, startppqpos, endppqpos, chan, pitch, vel, true)
        reaper.MIDI_DeleteNote(take, j)
      end
    end
    reaper.MIDI_Sort(take)
    reaper.MIDI_Sort(new_take)
    return true, new_item
  end
  return false
end

---------------------------------------
-- Main
---------------------------------------

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

-- Disable "Toggle trim content behind media items when editing"
local trim = reaper.GetToggleCommandState(41117)
if trim == 1 then
  reaper.Main_OnCommand(41117, 0)
end

-- Set empty list
local new_items_list = {}

-- Apply to active MIDI Editor take
active_midi_editor = reaper.MIDIEditor_GetActive()
if active_midi_editor then
  local take = reaper.MIDIEditor_GetTake(active_midi_editor)
  local item = reaper.GetMediaItemTake_Item(take)
  if not reaper.IsMediaItemSelected(item) then
    rv, new_item = MoveNotesToNewItem(item)
    if rv then
      table.insert(new_items_list, new_item)
    end
  end
end

-- Apply to all selected MIDI items to
count = reaper.CountSelectedMediaItems(0)
if count > 0 then 
  for i=count-1, 0, -1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    rv, new_item = MoveNotesToNewItem(item)
    if rv then
      table.insert(new_items_list, new_item)
    end
  end
end

-- Add new items to selection
for i, new_item in ipairs(new_items_list) do
  reaper.SetMediaItemSelected(new_item, true)
end

-- Restore "Toggle trim content behind media items when editing" state
if trim == 1 then
  reaper.Main_OnCommand(41117, 0)
end

reaper.Undo_EndBlock("Move selected notes to a new midi item",0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
