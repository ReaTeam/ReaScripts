-- @description Smart remove
-- @author Rodilab
-- @version 1.0
-- @about
--   If time selection is set and last focus on items, then cut selected area of items.
--   Else, remove items/tracks/envelope points (depending on focus)
--
--   by Rodrigo Diaz (aka Rodilab)

local time_sel_start, time_sel_end = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
local focus = reaper.GetCursorContext()

if time_sel_end - time_sel_start > 0 and focus == 1 then
  -- Cut selected area of items
  reaper.Main_OnCommand(40307,0)
else
  -- Remove items/tracks/envelope points (depending on focus)
  reaper.Main_OnCommand(40697,0)
end
