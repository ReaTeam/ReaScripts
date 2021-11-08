-- @description Move selected notes to a new MIDI item
-- @author Rodilab
-- @version 1.0
-- @provides [main=main,midi_editor] .
-- @about
--   Delete selected notes in selected MIDI items, and create new midi item with this notes
--
--   by Rodrigo Diaz (aka Rodilab)

count = reaper.CountSelectedMediaItems(0)

if count > 0 then
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  local trim = reaper.GetToggleCommandState(41117)
  if trim == 1 then
    reaper.Main_OnCommand(41117, 0)
  end
  
  local itemGUID_list = {}
  for i=0, count-1 do
    table.insert(itemGUID_list, reaper.BR_GetMediaItemGUID(reaper.GetSelectedMediaItem(0, i)))
  end

  for i, sGUID in ipairs(itemGUID_list) do
    local item = reaper.BR_GetMediaItemByGUID(0, sGUID)
    local take = reaper.GetActiveTake(item)
    local source = reaper.GetMediaItemTake_Source(take)
    local track = reaper.GetMediaItem_Track(item)
    local position = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')

    if reaper.GetMediaSourceType(source, '') == 'MIDI' then
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
    end
  end

  if trim == 1 then
    reaper.Main_OnCommand(41117, 0)
  end

  reaper.Undo_EndBlock("Split selected notes into new midi items",0)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end
