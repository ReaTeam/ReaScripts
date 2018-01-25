--[[
 * @description Set envelope to maximum value within time selection
 * @about This script will set all envelope points within time selection to maximum value, including edges of time selection. Works on both track and take envelopes.
 * @author EvilDragon
 * @donate https://www.paypal.me/EvilDragon
 * @version 1.0
 * Licence: GPL v3
 * REAPER: 5.0+
 * Extensions: none required
--]]

reaper.Undo_BeginBlock()
reaper.Main_OnCommandEx(40726, 0, 0) -- Envelope: Insert 4 envelope points at time selection
for i = 1, 200 do
  reaper.Main_OnCommandEx(41180, 0, 0) -- Envelopes: Move selected points up a little bit
end
reaper.Undo_EndBlock('Set envelope to maximum value within time selection', 1)
