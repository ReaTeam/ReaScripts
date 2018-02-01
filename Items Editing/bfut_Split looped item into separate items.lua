--[[
  @author bfut
  @version 1.0
  @description Split looped item into separate items
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
local r = reaper
local function bfut_SplitLpdItmsIntoSeparateItms(item)
  r.SelectAllMediaItems(0,false)
  r.SetMediaItemSelected(item,true)
  repeat
    local tk = r.GetActiveTake(item,0)
    if tk ~= nil then
      local l, v = r.GetMediaSourceLength(r.GetMediaItemTake_Source(tk))
      if v then l = r.TimeMap_QNToTime(l) end
      item = r.SplitMediaItem(item,r.GetMediaItemInfo_Value(item,"D_POSITION")+l/r.GetMediaItemTakeInfo_Value(tk,"D_PLAYRATE"))
    end
  until not item and true
  return
end
local c = r.CountSelectedMediaItems(0)
if c < 1 then return end
r.PreventUIRefresh(1)
r.Undo_BeginBlock2(0)
local item = {}
for i=0,c-1 do item[i] = r.GetSelectedMediaItem(0,i) end
for i=0,c-1 do bfut_SplitLpdItmsIntoSeparateItms(item[i]) end
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock2(0,"Split looped item into separate items",-1)
