-- @description Implode items on same track into takes (align with snap offset)
-- @author Rodilab
-- @version 1.0
-- @about
--   Make for sound design. Ideal to group sound variations in a same item.
--   Then use "Take: Switch items to next/previous take" or "Xenakios/SWS: Select takes in selected items, shuffled random".
--   Finish with "Item: Set item start/end to source media start/end" to fit.
--
--   This script :
--   - Disables item loop source option
--   - Set item source section
--   - Align items snap offset with first snap offset
--   - Implode selected items on same track into takes
--   - Increase item length to don't trim any take
--
--   by Rodrigo Diaz (aka Rodilab)

count = reaper.CountSelectedMediaItems(0)
if count < 2 then return end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

reaper.Main_OnCommand(40131, 0) -- Take: Crop to active take in items

track_list = {}
j = 0
for i=0, count-1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  local track = reaper.GetMediaItemTrack(item)
  if not last_track or last_track ~= track then
    j = j + 1
    track_list[j] = {}
    last_track = track
  end

  table.insert(track_list[j], item)
end

for t, item_list in ipairs(track_list) do
  if #item_list > 1 then

    -- Get max item snap offset
    local max_snapoffset, max_endlength
    for i, item in ipairs(item_list) do
      local snapoffset = reaper.GetMediaItemInfo_Value(item, 'D_SNAPOFFSET')
      if not max_snapoffset then
        max_snapoffset = snapoffset
      else
        max_snapoffset = math.max(max_snapoffset, snapoffset)
      end
      local length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
      local endlength = length - snapoffset
      if not max_endlength then
        max_endlength = endlength
      else
        max_endlength = math.max(max_endlength, endlength)
      end
    end

    for i, item in ipairs(item_list) do
      local take = reaper.GetActiveTake(item)

      -- Set audio source section
      reaper.SelectAllMediaItems(0, false)
      reaper.SetMediaItemSelected(item, true)
      local source =  reaper.GetMediaItemTake_Source(take)
      local rv, offs, len, rev = reaper.PCM_Source_GetSectionInfo(source)
      if rv then
        reaper.Main_OnCommand(40547, 0)
      end
      reaper.Main_OnCommand(40547, 0)

      -- Set same items start position
      local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
      local length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
      local snapoffset = reaper.GetMediaItemInfo_Value(item, 'D_SNAPOFFSET')
      local diff = max_snapoffset - snapoffset
      local take_offset = reaper.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
      reaper.SetMediaItemInfo_Value(item, 'D_POSITION', pos-diff)
      reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', max_snapoffset+max_endlength)
      reaper.SetMediaItemInfo_Value(item, 'D_SNAPOFFSET', max_snapoffset)
      reaper.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', take_offset-diff)
    end

  end
end

-- Restore item selection
reaper.SelectAllMediaItems(0, false)
for t, item_list in ipairs(track_list) do
  for i, item in ipairs(item_list) do
    reaper.SetMediaItemSelected(item, true)
  end
end

reaper.Main_OnCommand(40543, 0) -- Take: Implode items on same track into takes

-- Align item with first snapoffset
count = reaper.CountSelectedMediaItems(0)
if count > 1 then
  local first_snapoffset_pos
  for i=0, count-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local snapoffset = reaper.GetMediaItemInfo_Value(item, 'D_SNAPOFFSET')
    local snapoffset_pos = pos + snapoffset
    if not first_snapoffset_pos then
      first_snapoffset_pos = snapoffset_pos
    else
      reaper.SetMediaItemInfo_Value(item, 'D_POSITION', pos-(snapoffset_pos-first_snapoffset_pos))
    end
  end
end

reaper.Undo_EndBlock("Implode items on same track into takes (align with snap offset)",0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
