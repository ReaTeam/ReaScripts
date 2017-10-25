-- @description Toggle monitoring FX bypass (8 actions)
-- @version 1.0
-- @author cfillion
-- @metapackage
-- @provides
--   [main] . > cfillion_Toggle monitoring FX 1 bypass.lua
--   [main] . > cfillion_Toggle monitoring FX 2 bypass.lua
--   [main] . > cfillion_Toggle monitoring FX 3 bypass.lua
--   [main] . > cfillion_Toggle monitoring FX 4 bypass.lua
--   [main] . > cfillion_Toggle monitoring FX 5 bypass.lua
--   [main] . > cfillion_Toggle monitoring FX 6 bypass.lua
--   [main] . > cfillion_Toggle monitoring FX 7 bypass.lua
--   [main] . > cfillion_Toggle monitoring FX 8 bypass.lua

local UNDO_STATE_FX = 2 -- track/master fx

local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local fxIndex = tonumber(name:match("FX (%d+)"))

if fxIndex then
  fxIndex = 0x1000000 + (fxIndex - 1)
else
  error('could not extract slot from filename')
end

reaper.Undo_BeginBlock()

local master = reaper.GetMasterTrack()

reaper.TrackFX_SetEnabled(master, fxIndex,
  not reaper.TrackFX_GetEnabled(master, fxIndex))

reaper.Undo_EndBlock(name, UNDO_STATE_FX)

