-- @description Play next item once
-- @author Rodilab
-- @version 1.1
-- @changelog Update : Prevent UI Refresh
-- @about
--   Select, set time selection and play the next item of the track once.
--
--   by Rodrigo Diaz (aka Rodilab)

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

-- Disable "repeat"
if reaper.GetToggleCommandState(1068) == 1 then
  reaper.Main_OnCommand(1068,0)
end

-- Enable Play/Stop repeat loop
if reaper.GetToggleCommandState(41834) == 0 then
  reaper.Main_OnCommand(41834,0)
end

-- Select and move next item
reaper.Main_OnCommand(40417,0)
-- Time selection on item
reaper.Main_OnCommand(40290,0)
-- Loop on item
reaper.Main_OnCommand(41039,0)
-- Play
reaper.Main_OnCommand(1007,0)

reaper.Undo_EndBlock("Play next item once",0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
