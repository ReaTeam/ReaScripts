-- @description Snap MIDI item(s) edges to grid without changing content position
-- @author amagalma
-- @version 1.0
-- @about
--   # Snaps selected items' edges to grid without changing the position of their content
--
--   - Works only on MIDI items
--   - Undo is created only if there has been a change

-----------------------------------------------------------------------------------------

local reaper = reaper
local change = false

-----------------------------------------------------------------------------------------

local item_cnt = reaper.CountSelectedMediaItems(0)
if item_cnt > 0 then
  reaper.PreventUIRefresh( 1 )
  local items = {}
  for i = 0, item_cnt-1 do
    local selitem = reaper.GetSelectedMediaItem( 0, 0 )
    items[i+1] = selitem
    reaper.SetMediaItemSelected( selitem, false ) 
  end
  local snap = reaper.GetToggleCommandState( 1157 )
  if snap ~= 1 then -- if turned off, turn on
    reaper.Main_OnCommand(1157, 0)
    snap = 2
  end
  for i = 1, #items do
    reaper.SetMediaItemSelected( items[i], true )
    local acttake = reaper.GetActiveTake( items[i] )
    -- Work only with MIDI items
    if acttake and reaper.TakeIsMIDI( acttake ) then
      local Start = reaper.GetMediaItemInfo_Value( items[i], "D_POSITION" )
      local End = Start + reaper.GetMediaItemInfo_Value( items[i], "D_LENGTH" )
      local newStart = reaper.SnapToGrid( 0, Start )
      local newEnd = reaper.SnapToGrid( 0, End )
      if newStart ~= Start then
        reaper.ApplyNudge( 0, 1, 1, 1, newStart, false, 0 )
        change = true
      end
      if newEnd ~= End then
        reaper.ApplyNudge( 0, 1, 3, 1, newEnd, false, 0 )
        change = true
      end
    end
    reaper.SetMediaItemSelected( items[i], false )
  end
  if snap == 2 then -- Restore snap to off, if it was previously off
    reaper.Main_OnCommand(1157, 0)
  end
  -- restore selected items
  for i = 1, #items do
    reaper.SetMediaItemSelected( items[i], true )
  end
  reaper.PreventUIRefresh( -1 )
  reaper.UpdateArrange()
end

-----------------------------------------------------------------------------------------

if change then
  reaper.Undo_OnStateChange( "Snap MIDI item(s) edges to grid without changing content position" )
else
  reaper.defer(function () end)
end
