--[[
 * ReaScript Name: Select items with take FX in active take
 * Description: Fairly self-explanatory - this script will select all items that have take FX loaded in the active take (item remains unselected if it has take FX in inactive takes).
 * Author: EvilDragon
 * Licence: GPL v3
 * REAPER: 5.0+
 * Extensions: SWS required
 * Version: 1.0
--]]

reaper.Undo_BeginBlock()

itemcount = reaper.CountMediaItems(0)

reaper.Main_OnCommand(40289, 0) -- unselect all items first

if itemcount ~= nil then
  for i = 1, itemcount do
    item = reaper.GetMediaItem(0, i - 1)
    if item ~= nil then
      take = reaper.GetActiveTake(item)
      if reaper.BR_GetTakeFXCount(take) ~= 0 then
        reaper.SetMediaItemSelected(item, true)
      end
    end
  end -- for
end

reaper.UpdateArrange()
reaper.Undo_EndBlock('Select items with take FX in active take', 1)
