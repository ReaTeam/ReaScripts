-- @description Set time selection to fade under mouse cursor
-- @author Rodilab
-- @version 1.1
-- @changelog Update: Prevent UI Refresh
-- @about
--   Set edit cursor and time selection to fade or crossfade under mouse cursor.
--   If no fade or crossfade under cursor, does not change selection or edit cursor position.
--
--   by Rodrigo Diaz (aka Rodilab)

local item, cursor_position = reaper.BR_ItemAtMouseCursor()

if item ~= nil then
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  local item_start = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
  local item_end = item_start + reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
  local fadein = reaper.GetMediaItemInfo_Value(item,"D_FADEINLEN")
  local fadeout = reaper.GetMediaItemInfo_Value(item,"D_FADEOUTLEN")
  local fadein_auto = reaper.GetMediaItemInfo_Value(item,"D_FADEINLEN_AUTO")
  local fadeout_auto = reaper.GetMediaItemInfo_Value(item,"D_FADEOUTLEN_AUTO")

  if fadein_auto > 0 then
    fadein = item_start + fadein_auto
  else
    fadein = item_start + fadein
  end

  if fadeout_auto > 0 then
    fadeout = item_end - fadeout_auto
  else
    fadeout = item_end - fadeout
  end

  local sel_start = nil
  local sel_end = nil

  if cursor_position < fadein then
    sel_start = item_start
    sel_end = fadein
  elseif cursor_position > fadeout then
    sel_start = fadeout
    sel_end = item_end
  end

  if sel_start ~= nil and sel_end ~= nil then
    reaper.GetSet_LoopTimeRange(true, false, sel_start, sel_end, true)
    reaper.SetEditCurPos(sel_start, true, true)
  end

  reaper.Undo_EndBlock("Set time selection to fade under mouse cursor",0)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end
