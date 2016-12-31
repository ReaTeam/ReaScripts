-- @description Insert regions at markers and vice versa in time selection
-- @version 1.0
-- @author cfillion
-- @link http://forum.cockos.com/showthread.php?t=185577

reaper.Undo_BeginBlock()

local UNDO_STATE_MISCCFG = 8

local next_index, boundaries, last_marker = 0, {}, 0
local ts_from, ts_to = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

while true do
  -- marker = {retval, isrgn, pos, rgnend, name, markrgnindexnumber, color}
  local marker = {reaper.EnumProjectMarkers3(0, next_index)}

  next_index = marker[1]
  if next_index == 0 then break end

  if not marker[2] then -- it's not a region
    if boundaries[last_marker] then
      boundaries[last_marker].to = marker[3]
    end

    last_marker = #boundaries + 1
  end

  boundaries[#boundaries + 1] = {isregion=marker[2], from=marker[3],
    to=marker[4], name=marker[5], id=marker[6], color=marker[7]}
end

local function exists(match)
  for _,boundary in ipairs(boundaries) do
    if boundary ~= match and boundary.from == match.from then
      return true
    end
  end

  return false
end

for _,boundary in ipairs(boundaries) do
  local withinTS = ts_to == 0 or (boundary.from >= ts_from and boundary.to <= ts_to)
  if boundary.to > 0 and withinTS and not exists(boundary) then
    reaper.AddProjectMarker2(0, not boundary.isregion, boundary.from,
      boundary.to, boundary.name, boundary.id, boundary.color)
  end
end

reaper.Undo_EndBlock('Insert regions at markers and vice versa in time selection', UNDO_STATE_MISCCFG)
