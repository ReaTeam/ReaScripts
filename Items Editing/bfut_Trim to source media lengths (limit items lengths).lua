--[[
  @author bfut
  @version 1.0
  @description Trim to source media lengths (limit items lengths)
  @website https://github.com/bfut
  @about
    HOW TO USE:
      1) Select media item(s).
      2) Run the script.
    REQUIRES: Reaper v5.70 or later
  LICENSE:
    Copyright (c) 2017 and later Benjamin Futasz <bendfu@gmail.com><https://github.com/bfut>
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]
local reaper = reaper
reaper.Undo_BeginBlock2(0)
local gl_CountSelectedMediaItems = reaper.CountSelectedMediaItems(0)
if gl_CountSelectedMediaItems < 1 then
  return
end
reaper.PreventUIRefresh(1)
for i=0,gl_CountSelectedMediaItems-1 do
  local item = reaper.GetSelectedMediaItem(0,i)
  local item_activetake = reaper.GetActiveTake(item,0)
  if item_activetake ~= nil then
    local item_length = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
    local item_activetake_mediasourcelength, lengthIsQN = reaper.GetMediaSourceLength(reaper.GetMediaItemTake_Source(item_activetake))
    if lengthIsQN then
      item_activetake_mediasourcelength = reaper.TimeMap_QNToTime(item_activetake_mediasourcelength)
    end
    item_activetake_mediasourcelength = item_activetake_mediasourcelength/reaper.GetMediaItemTakeInfo_Value(item_activetake,"D_PLAYRATE")
    if item_length > item_activetake_mediasourcelength then
      reaper.SetMediaItemLength(item,item_activetake_mediasourcelength,false)
    end
  end
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0,"Trim to source media lengths (limit items lengths)",-1)
