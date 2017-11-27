--[[
 * @description Select items with take FX
 * @about Fairly self-explanatory - this script will select all items that have take FX loaded in any take - active or not.
 * @author EvilDragon
 * @donate https://www.paypal.me/EvilDragon
 * @version 1.0
 * Licence: GPL v3
 * REAPER: 5.0+
 * Extensions: SWS required
--]]

reaper.Undo_BeginBlock()

reaper.Main_OnCommand(40289, 0)

itemcount = reaper.CountMediaItems(0)

if itemcount ~= nil then
  for i = 1, itemcount do
    item = reaper.GetMediaItem(0, i - 1)
    if item ~= nil then
      takecount = reaper.CountTakes(item)

      for j = 1, takecount do
        take = reaper.GetTake(item, j - 1)
        if reaper.BR_GetTakeFXCount(take) ~= 0 then
          reaper.SetMediaItemSelected(item, true)
        end
      end -- for
    end
  end -- for
end

reaper.UpdateArrange()
reaper.Undo_EndBlock('Select items with take FX', 1)
