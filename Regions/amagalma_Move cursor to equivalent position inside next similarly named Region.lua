-- @description Move cursor to equivalent position inside next similarly named Region
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma

local cur_pos = reaper.GetCursorPosition()
local cur_region, _ = {}
_, cur_region.idx = reaper.GetLastMarkerAndCurRegion( 0, cur_pos )
if cur_region.idx == -1 then return end
_, _, cur_region.start, _, cur_region.name = reaper.EnumProjectMarkers( cur_region.idx )
local cur_pos_in_Region = cur_pos - cur_region.start


local function KeepWords(str)
  local t, c = {}, 0
  for word in str:gmatch("%w+") do
    if not tonumber(word) then
      c = c + 1
      t[c] = word
    end
  end
  return table.concat(t)
end


local function compareStrings(A, B)
  if A == B then
    return true
  end

  local numA, numB = tonumber(A), tonumber(B)
  if numA and numB then
    return numB >= numA
  end

  return KeepWords(A) == KeepWords(B)
end


local i = cur_region.idx+1
while true do
  local retval, isrgn, pos, rgnend, name = reaper.EnumProjectMarkers( i )
  if retval == 0 then break end
  if isrgn then
    if compareStrings(cur_region.name, name) then
      local wanted_pos = pos + cur_pos_in_Region
      if wanted_pos <= rgnend then
        reaper.SetEditCurPos(pos + cur_pos_in_Region, true, true)
        break
      end
    end
  end
  i = i + 1
end
