-- @description Toggle input FX bypass for selected tracks (8 actions)
-- @version 1.0
-- @author cfillion
-- @metapackage
-- @provides
--   [main] . > cfillion_Toggle input FX 1 bypass for selected tracks.lua
--   [main] . > cfillion_Toggle input FX 2 bypass for selected tracks.lua
--   [main] . > cfillion_Toggle input FX 3 bypass for selected tracks.lua
--   [main] . > cfillion_Toggle input FX 4 bypass for selected tracks.lua
--   [main] . > cfillion_Toggle input FX 5 bypass for selected tracks.lua
--   [main] . > cfillion_Toggle input FX 6 bypass for selected tracks.lua
--   [main] . > cfillion_Toggle input FX 7 bypass for selected tracks.lua
--   [main] . > cfillion_Toggle input FX 8 bypass for selected tracks.lua

local UNDO_STATE_FX = 2 -- track/master fx

local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local fxIndex = tonumber(name:match("FX (%d+)"))

if fxIndex then
  fxIndex = 0x1000000 + (fxIndex - 1)
else
  error('could not extract slot from filename')
end

reaper.Undo_BeginBlock()

for ti=0,reaper.CountSelectedTracks()-1 do
  local track = reaper.GetSelectedTrack(0, ti)

  reaper.TrackFX_SetEnabled(track, fxIndex,
    not reaper.TrackFX_GetEnabled(track, fxIndex))
end

reaper.Undo_EndBlock(name, UNDO_STATE_FX)
