--[[
  @author bfut
  @version 1.0
  @description Unselect items within time selection
  @about
    HOW TO USE:
      1) Run the script.
    REQUIRES: Reaper v6.70 or later
  @website https://github.com/bfut/ReaScripts
  LICENSE:
    Copyright (C) 2022 and later Benjamin Futasz

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
local ORIGINAL_TIMESEL_START, ORIGINAL_TIMESEL_END = reaper.GetSet_LoopTimeRange2(0, false, false, -1, -1, false)  
if ORIGINAL_TIMESEL_END - ORIGINAL_TIMESEL_START < 10^-6 then
  return
end
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
for i = COUNT_SEL_ITEMS - 1, 0, -1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  if pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH") - ORIGINAL_TIMESEL_END <= 0 and
      ORIGINAL_TIMESEL_START - pos <= 0 then
    reaper.SetMediaItemSelected(item, false)
  end
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Unselect items within time selection", -1)
