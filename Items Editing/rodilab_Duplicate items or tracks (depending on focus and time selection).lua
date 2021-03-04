-- @description Duplicate items or tracks (depending on focus and time selection)
-- @author Rodilab
-- @version 1.0
-- @about
--   Duplicate items or tracks (depending on focus)
--   If time selection is set and focus on items, then duplicate selected area of items
--
--   by Rodrigo Diaz (aka Rodilab)

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local sel_start, sel_end = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
local focus =  reaper.GetCursorContext2(true)
local window, segment, details = reaper.BR_GetMouseCursorContext()

if focus == 0 then
  -- Duplicate tracks
  reaper.Main_OnCommand(40062,0)
elseif focus == 1 then
  if sel_start == sel_end then
    -- Duplicate items
    reaper.Main_OnCommand(41295,0)
  else
    -- Duplicate selected area of items
    reaper.Main_OnCommand(41296,0)
  end
end

reaper.Undo_EndBlock("Duplicate items or tracks (depending on focus and time selection)",0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
