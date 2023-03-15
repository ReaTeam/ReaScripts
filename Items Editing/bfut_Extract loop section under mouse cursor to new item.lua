--[[
  @author bfut
  @version 1.1
  @description Extract loop section under mouse cursor to new item
  @about
    HOW TO USE:
      1) Hover mouse over looped media item.
      2) Run the script.
    REQUIRES: Reaper v6.12c or later
  @changelog
    + support time signature markers
  @website https://github.com/bfut
  LICENSE:
    Copyright (C) 2020 and later Benjamin Futasz

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
--[[ CONFIG defaults:
  always_pool_midi = false  -- pool resulting split
]]
local CONFIG = {
  always_pool_midi = false
}
local screen_x, screen_y = reaper.GetMousePosition()
local mouse_time, _ = reaper.GetSet_ArrangeView2(0, false, screen_x, screen_x + 1)
local item, _ = reaper.GetItemFromPoint(screen_x, screen_y, true)
if not item then
  return
end
local take = reaper.GetActiveTake(item, 0)
if not take then
  return
end
local function bfut_QNToTimeIfQN(time, isQN)
  if isQN then
    return reaper.TimeMap2_QNToTime(0, time)
  end
  return time
end
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock2(0)
local new_track
if CONFIG["always_pool_midi"] and reaper.TakeIsMIDI(take) then
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
local take_sourcelength, lengthIsQN = reaper.GetMediaSourceLength(reaper.GetMediaItemTake_Source(take))
local take_startoffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
if math.abs(take_sourcelength - take_startoffset) < 10^-13 then
  take_startoffset = 0
end
local take_playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
take_sourcelength = take_sourcelength / take_playrate
take_startoffset = take_startoffset / take_playrate
local split_time = reaper.GetMediaItemInfo_Value(item, "D_POSITION") - take_startoffset
if lengthIsQN then
  mouse_time = reaper.TimeMap2_timeToQN(0, mouse_time)
  split_time = reaper.TimeMap2_timeToQN(0, split_time)
end
if split_time + take_sourcelength > mouse_time then
  reaper.SplitMediaItem(item, bfut_QNToTimeIfQN(split_time + take_sourcelength, lengthIsQN))
else
  while split_time + take_sourcelength < mouse_time do
    split_time = split_time + take_sourcelength
  end
  item = reaper.SplitMediaItem(item, bfut_QNToTimeIfQN(split_time, lengthIsQN))
  if item then
    item = reaper.SplitMediaItem(item, bfut_QNToTimeIfQN(split_time + take_sourcelength, lengthIsQN))
  end
end
if new_track then
  reaper.DeleteTrack(new_track)
end
reaper.Main_OnCommandEx(40528, 0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Extract loop section under mouse cursor to new item", -1)
