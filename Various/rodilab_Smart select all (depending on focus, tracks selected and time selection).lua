-- @description Smart select all (depending on focus, tracks selected and time selection)
-- @author Rodilab
-- @version 1.0
-- @about
--   Select all (tracks, items or points) depending on focus, tracks selected and time selection.
--   - If focus on tracks, then select all tracks
--   - If focus on items, then select all items in selected tracks in time selection (in all tracks if no track selected / in all project if time selection isn't set)
--   - If focus on envelopes, then select all points in time selection (in all project if time selection isn't set)
--
--   by Rodrigo Diaz (aka Rodilab)

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local focus = reaper.GetCursorContext2(true)
local sel_start, sel_end = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
local count_sel_tracks = reaper.CountSelectedTracks(0)
local count_tracks = reaper.CountTracks(0)

if focus == 0 then
  if count_sel_tracks ~= count_tracks then
    -- Select all tracks
    reaper.Main_OnCommand(40296,0)
  else
    -- Unselect all tracks
    reaper.Main_OnCommand(40297,0)
  end
elseif focus == 1 then
  if sel_start == sel_end then
    if count_sel_tracks == 0 then
      -- Select all items
      reaper.Main_OnCommand(40035,0)
    else
      -- Select all items in select tracks
      reaper.Main_OnCommand(40421,0)
    end
  else
    if count_sel_tracks == 0 then
      -- Select all items in time selection
      reaper.Main_OnCommand(40717,0)
    else
      -- Select all items in time selection in tracks
      reaper.Main_OnCommand(40718,0)
    end
  end
elseif focus == 2 then
  if sel_start == sel_end then
    -- Select all points
    reaper.Main_OnCommand(40332,0)
  else
    -- Select all points in time selection
    reaper.Main_OnCommand(40330,0)
  end
end

reaper.Undo_EndBlock("Smart select all (depending on focus)",0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
