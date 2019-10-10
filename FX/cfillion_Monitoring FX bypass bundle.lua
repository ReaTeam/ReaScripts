-- @description Monitoring FX bypass bundle (bypass, unbypass or toggle)
-- @author cfillion
-- @version 1.1.1
-- @changelog add actions to set bypass on or off [p=2145580]
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
--   [main] . > cfillion_Bypass monitoring FX 1.lua
--   [main] . > cfillion_Bypass monitoring FX 2.lua
--   [main] . > cfillion_Bypass monitoring FX 3.lua
--   [main] . > cfillion_Bypass monitoring FX 4.lua
--   [main] . > cfillion_Bypass monitoring FX 5.lua
--   [main] . > cfillion_Bypass monitoring FX 6.lua
--   [main] . > cfillion_Bypass monitoring FX 7.lua
--   [main] . > cfillion_Bypass monitoring FX 8.lua
--   [main] . > cfillion_Unbypass monitoring FX 1.lua
--   [main] . > cfillion_Unbypass monitoring FX 2.lua
--   [main] . > cfillion_Unbypass monitoring FX 3.lua
--   [main] . > cfillion_Unbypass monitoring FX 4.lua
--   [main] . > cfillion_Unbypass monitoring FX 5.lua
--   [main] . > cfillion_Unbypass monitoring FX 6.lua
--   [main] . > cfillion_Unbypass monitoring FX 7.lua
--   [main] . > cfillion_Unbypass monitoring FX 8.lua
-- @about This scripts provides actions for bypassing, unbypassing and toggling one of eight effect plugins in the monitoring FX chain. Copy and rename the script to create additional slots for bigger monitoring FX chains.

local UNDO_STATE_FX = 2 -- track/master fx

local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local fxIndex = tonumber(name:match("FX (%d+)"))
local mode = ({Bypass=false, Unbypass=true})[name:match('^(%w+)')]

if fxIndex then
  fxIndex = 0x1000000 + (fxIndex - 1)
else
  error('could not extract slot from filename')
end

reaper.Undo_BeginBlock()

local master = reaper.GetMasterTrack()

if mode == nil then -- toggle
  mode = not reaper.TrackFX_GetEnabled(master, fxIndex)
end

reaper.TrackFX_SetEnabled(master, fxIndex, mode)

reaper.Undo_EndBlock(name, UNDO_STATE_FX)
