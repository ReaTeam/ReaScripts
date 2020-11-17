--[[
  @author bfut
  @version 1.1
  @description Trim to source media lengths (limit items lengths)
  @about
    HOW TO USE:
      1) Select media item(s).
      2) Run the script.
    REQUIRES: Reaper v5.99 or later
  @changelog
    + ignore locked items
  @website https://github.com/bfut
  LICENSE:
    Copyright (C) 2017 and later Benjamin Futasz

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local COUNT_SEL_ITEMS = reaper.CountSelectedMediaItems(0)
if COUNT_SEL_ITEMS < 1 then
  return
end
local IS_ITEM_LOCKED = {
  [1.0] = true,
  [3.0] = true
}
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
for i = 0, COUNT_SEL_ITEMS - 1 do
  item = reaper.GetSelectedMediaItem(0, i)
  if not IS_ITEM_LOCKED[reaper.GetMediaItemInfo_Value(item, "C_LOCK")] then
    local item_activetake = reaper.GetActiveTake(item, 0)
    if item_activetake then
      local item_activetake_mediasourcelength, lengthIsQN = reaper.GetMediaSourceLength(reaper.GetMediaItemTake_Source(item_activetake))
      if lengthIsQN then
        item_activetake_mediasourcelength = reaper.TimeMap_QNToTime(item_activetake_mediasourcelength)
      end
      item_activetake_mediasourcelength = item_activetake_mediasourcelength / reaper.GetMediaItemTakeInfo_Value(item_activetake, "D_PLAYRATE")
      if reaper.GetMediaItemInfo_Value(item, "D_LENGTH") > item_activetake_mediasourcelength then
        reaper.SetMediaItemLength(item, item_activetake_mediasourcelength, false)
      end
    end
  end
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Trim to source media lengths (limit items lengths)", -1)
