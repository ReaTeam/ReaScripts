--[[
 * ReaScript Name: Set envelope to minimum value within time selection
 * Description: This script will set all envelope points within time selection to minimum value, including edges of time selection. Works on both track and take envelopes.
 * Author: EvilDragon
 * Licence: GPL v3
 * REAPER: 5.0+
 * Extensions: none required
 * Version: 1.0
--]]

reaper.Undo_BeginBlock()
reaper.Main_OnCommandEx(40726, 0, 0) -- Envelope: Insert 4 envelope points at time selection
for i = 1, 200 do
  reaper.Main_OnCommandEx(41181, 0, 0) -- Envelopes: Move selected points down a little bit
end
reaper.Undo_EndBlock('Set envelope to minimum value within time selection', 1)
