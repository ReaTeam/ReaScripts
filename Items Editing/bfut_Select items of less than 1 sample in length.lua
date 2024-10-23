--[[
  @author bfut
  @version 1.0
  @description Select items of less than 1 sample in length
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
local function bfut_GetProjectSamplerate()
  if reaper.GetSetProjectInfo(0, "PROJECT_SRATE_USE", -1, false) > 0.0 then
    return true, reaper.GetSetProjectInfo(0, "PROJECT_SRATE", -1, false)
  end
  return reaper.GetAudioDeviceInfo("SRATE")
end
local retv, min_item_len = bfut_GetProjectSamplerate()
if not retv then
  min_item_len = 192000
end
min_item_len = 60 / min_item_len
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
reaper.Main_OnCommandEx(40769, 0)  
for i = reaper.CountMediaItems(0) - 1, 0, -1 do
  local item = reaper.GetMediaItem(0, i)
  if reaper.GetMediaItemInfo_Value(item, "D_LENGTH") < min_item_len then
    reaper.SetMediaItemSelected(item, true)
  end
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Select items of less than 1 sample in length", -1)
