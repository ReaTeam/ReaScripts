-- @description Toggle take FX bypass for selected items (5 slots)
-- @version 1.0.1
-- @changelog More efficient packaging of the slots for ReaPack.
-- @author cfillion
-- @link Request Thread http://forum.cockos.com/showthread.php?t=181160
-- @metapackage
-- @provides
--   [main] . > cfillion_Toggle take FX 1 bypass for selected items.lua
--   [main] . > cfillion_Toggle take FX 2 bypass for selected items.lua
--   [main] . > cfillion_Toggle take FX 3 bypass for selected items.lua
--   [main] . > cfillion_Toggle take FX 4 bypass for selected items.lua
--   [main] . > cfillion_Toggle take FX 5 bypass for selected items.lua

local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local fxIndex = tonumber(name:match("FX (%d+)"))

if fxIndex then
  fxIndex = fxIndex - 1
else
  error('could not extract slot from filename')
end

reaper.Undo_BeginBlock()

for i=0,reaper.CountSelectedMediaItems()-1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  local take = reaper.GetActiveTake(item)

  reaper.TakeFX_SetEnabled(take, fxIndex,
    not reaper.TakeFX_GetEnabled(take, fxIndex))
end

reaper.Undo_EndBlock(name, 1)
