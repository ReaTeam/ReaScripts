--[[
  @author bfut
  @version 1.3
  @description Split looped item into separate items
  @about
    HOW TO USE:
      1) Select media item(s).
      2) Run the script.
    REQUIRES: Reaper v6.12c or later
  @changelog
    + support time signature markers
    # Fix: no more infinite loop for empty items
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
--[[ CONFIG options:
  always_pool_midi = false  -- pool resulting splits
]]
local CONFIG = {
  always_pool_midi = false
}
local COUNT_SEL_ITEMS = reaper.CountSelectedMediaItems(0)
if COUNT_SEL_ITEMS < 1 then
  return
end
local function bfut_QNToTimeIfQN(time, isQN)
  if isQN then
    return reaper.TimeMap2_QNToTime(0, time)
  end
  return time
end
local function bfut_SplitLoopedItemAtLoopPoints(item)
  local new_track
  if CONFIG["always_pool_midi"] then
    local take = reaper.GetActiveTake(item, 0)
    if take and reaper.TakeIsMIDI(take) then
      local original_cursor_position = reaper.GetCursorPosition()
      local view_start, view_end = reaper.GetSet_ArrangeView2(0, false, 0, 0, -1, -1)
      reaper.InsertTrackAtIndex(0, true)
      new_track = reaper.GetTrack(0, 0)
      reaper.SetOnlyTrackSelected(new_track)
      reaper.SelectAllMediaItems(0, false)
      reaper.SetMediaItemSelected(item, true)
      reaper.Main_OnCommandEx(40698, 0)
      reaper.Main_OnCommandEx(41072, 0)
      reaper.SetEditCurPos2(0, original_cursor_position, false, false)
      reaper.GetSet_ArrangeView2(0, true, 0, 0, view_start, view_end)
    end
  end
  reaper.SelectAllMediaItems(0, false)
  reaper.SetMediaItemSelected(item, true)
  repeat
    local take = reaper.GetActiveTake(item, 0)
    if take then
      local take_sourcelength, lengthIsQN = reaper.GetMediaSourceLength(reaper.GetMediaItemTake_Source(take))
      local take_startoffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
      if math.abs(take_sourcelength - take_startoffset) < 10^-13 then
        take_startoffset = 0
      end
      local take_playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
      take_sourcelength = take_sourcelength / take_playrate
      take_startoffset = take_startoffset / take_playrate
      local next_split_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION") - take_startoffset
      if lengthIsQN then
        next_split_pos = reaper.TimeMap2_timeToQN(0, next_split_pos)
      end
      item = reaper.SplitMediaItem(item, bfut_QNToTimeIfQN(next_split_pos + take_sourcelength, lengthIsQN))
    end
  until not item or not take
  if new_track then
    reaper.DeleteTrack(new_track)
  end
  return
end
local IS_ITEM_LOCKED = {
  [1.0] = true,
  [3.0] = true
}
local item = {}
for i = 0, COUNT_SEL_ITEMS - 1 do
  item[i] = reaper.GetSelectedMediaItem(0, i)
end
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock2(0)
for i = 0, COUNT_SEL_ITEMS - 1 do
  if not IS_ITEM_LOCKED[reaper.GetMediaItemInfo_Value(item[i], "C_LOCK")] then
    bfut_SplitLoopedItemAtLoopPoints(item[i])
  end
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Split looped item into separate items", -1)
