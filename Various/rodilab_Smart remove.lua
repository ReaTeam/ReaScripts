-- @description Smart remove
-- @author Rodilab
-- @version 1.1
-- @about
--   If time selection is set and last focus on items, then cut selected area of items.
--   Else, remove items/tracks/envelope points (depending on focus)
--
--   by Rodrigo Diaz (aka Rodilab)

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local time_sel_start, time_sel_end = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
local focus = reaper.GetCursorContext2(true)
local window, segment, details = reaper.BR_GetMouseCursorContext()

if time_sel_end - time_sel_start > 0 and focus == 1 then
  -- Cut selected area of items
  reaper.Main_OnCommand(40307,0)
else

  if window == "tcp" and segment == "envelope" then
    -- Remove envelope
    reaper.Main_OnCommand(40065,0)
  else
    -- Remove items/tracks/envelope points (depending on focus)
    reaper.Main_OnCommand(40697,0)
  end
end

reaper.Undo_EndBlock("Smart remove",0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
