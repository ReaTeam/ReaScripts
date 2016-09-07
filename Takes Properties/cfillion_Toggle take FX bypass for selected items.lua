-- @description Toggle take FX bypass for selected items (5 slots)
-- @version 1.0
-- @author cfillion
-- @link Request Thread http://forum.cockos.com/showthread.php?t=181160
-- @provides
--   [nomain] .
--   [main] cfillion_Toggle take FX [0-9] bypass for selected items.lua

function toggleTakeFX(fxIndex)
  reaper.Undo_BeginBlock()

  for i=0,reaper.CountSelectedMediaItems()-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)

    reaper.TakeFX_SetEnabled(take, fxIndex,
      not reaper.TakeFX_GetEnabled(take, fxIndex))
  end

  reaper.Undo_EndBlock(string.format("Toggle take FX %d", fxIndex + 1), 1)
end
