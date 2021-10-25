-- @description Move selected items content to previous or next cue (align with snap offset)
-- @author Mordi
-- @version 1.1
-- @changelog Fixed a script not appearing in action list.
-- @provides [main] Mordi_Move selected items content to previous cue (align with snap offset)/Mordi_Move selected items content to next cue (align with snap offset).lua
-- @about
--   # Move selected items content to previous/next cue (align with snap offset)
--
--   Two scripts. I've got these mapped to Alt + Left and Alt + Right.
--
--   Useful for creating variations of sound effects. Make sure to set the snap offset to line up the cues.

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

-- Get some data on selected items
function GetItemMarkers(source)
  if source == nil then
    return nil
  end
  
  local t = {}
  
  -- Insert zero to account for item start
  table.insert(t, 0)
  
  -- Loop through all cues
  i = 0
  repeat
    retval, time, endTime, isRegion, name = reaper.CF_EnumMediaSourceCues(source, i)
    if retval == 0 then
      break
    end
    
    table.insert(t, time)
    
    i = i + 1
  until retval == 0
  
  return t
end

function SetTakeOffset(take, offset)
  reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", offset)
end

reaper.Undo_BeginBlock()

selectedCount = reaper.CountSelectedMediaItems(0)

for i = 0, selectedCount - 1 do
  item = reaper.GetSelectedMediaItem(0, i)
  
  take = reaper.GetActiveTake(item)
  if take == nil then
    return nil
  end
  
  source = reaper.GetMediaItemTake_Source(take)
  
  -- Get item start time
  offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  
  -- Get cue times
  cues = GetItemMarkers(source)
  
  -- Get snap offset
  snapOffset = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
  targetPos = offset + snapOffset
  
  -- Do the magic
  for n = #cues, 1, -1 do
    if cues[n] < targetPos then
      SetTakeOffset(take, cues[n] - snapOffset)
      break
    end
  end
end

-- For some reason, we need to call this to get Reaper to reflect the change visually
reaper.ThemeLayout_RefreshAll()

reaper.Undo_EndBlock("Move selected items content to previous cue (align with snap offset)", 0)
