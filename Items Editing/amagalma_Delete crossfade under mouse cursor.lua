-- @description amagalma_Delete crossfade under mouse cursor
-- @author amagalma
-- @version 1.0
-- @about
--   # Deletes the crossfade (if any) under the mouse cursor
--   - creates undo only if a crossfade was deleted
--   - does not work for multiple selected or grouped items atm

------------------------------------------------------------------------------------------

local reaper = reaper
local ok = false

------------------------------------------------------------------------------------------

local retval, segment, details = reaper.BR_GetMouseCursorContext()
if retval == "arrange" and segment == "track" and details == "item" then
  local item = reaper.BR_GetMouseCursorContext_Item()
  local pos = reaper.BR_GetMouseCursorContext_Position()
  local track = reaper.BR_GetMouseCursorContext_Track()
  local item_cnt = reaper.CountTrackMediaItems( track )
  local itemstart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local itemend = itemstart + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local FadeOutStart = itemend - reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
  local FadeOutAutoStart = itemend - reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO")
  local FadeInEnd = itemstart + reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
  local FadeInAutoEnd = itemstart + reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO")
  local item2, what
  if pos > itemstart and (pos < FadeInEnd or pos < FadeInAutoEnd) then
    -- mouse is over the FadeIn of the item
    for i = 0, item_cnt do -- find the previous item
      local item_chk = reaper.GetTrackMediaItem( track, i )
      if item_chk == item then
        item2 = reaper.GetTrackMediaItem( track, i-1 )
        what = "itemFadeIn"
        break
      end
    end
  elseif pos < itemend and (pos > FadeOutStart or pos > FadeOutAutoStart) then
    -- mouse is over the FadeOut of the item
    for i = 0, item_cnt do -- find the next item
      local item_chk = reaper.GetTrackMediaItem( track, i )
      if item_chk == item then
        item2 = reaper.GetTrackMediaItem( track, i+1 )
        what = "itemFadeOut"
        break
      end
    end
  end
  if item2 then
    local item2start = reaper.GetMediaItemInfo_Value(item2, "D_POSITION")
    local item2end = item2start + reaper.GetMediaItemInfo_Value(item2, "D_LENGTH")
    local FadeOut2Start = item2end - reaper.GetMediaItemInfo_Value(item2, "D_FADEOUTLEN")
    local FadeOutAuto2Start = item2end - reaper.GetMediaItemInfo_Value(item2, "D_FADEOUTLEN_AUTO")
    local FadeIn2End = item2start + reaper.GetMediaItemInfo_Value(item2, "D_FADEINLEN")
    local FadeInAuto2End = item2start + reaper.GetMediaItemInfo_Value(item2, "D_FADEINLEN_AUTO")
    if (pos > item2start and (pos < FadeIn2End or pos < FadeInAuto2End))
    or (pos < item2end and (pos > FadeOut2Start or pos > FadeOutAuto2Start))
    then
      ok = true
    end
  end
  if ok then -- clear crossfade
    if what == "itemFadeIn" then
      reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO", 0)
      reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", 0)
      reaper.SetMediaItemInfo_Value(item2, "D_FADEOUTLEN_AUTO", 0)
      reaper.SetMediaItemInfo_Value(item2, "D_FADEOUTLEN", 0)  
    elseif what == "itemFadeOut" then
      reaper.SetMediaItemInfo_Value(item2, "D_FADEINLEN_AUTO", 0)
      reaper.SetMediaItemInfo_Value(item2, "D_FADEINLEN", 0)
      reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO", 0)
      reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", 0)
    end
    reaper.UpdateArrange()
  end
end

-- Undo point creation -------------------------------------------------------------------

if ok then
  reaper.Undo_OnStateChange2( 0, "Delete crossfade under mouse cursor" )
else
  function NoUndoPoint() end 
  reaper.defer(NoUndoPoint)
end
