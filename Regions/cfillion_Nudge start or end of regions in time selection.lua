-- @description Nudge start or end of regions in time selection
-- @version 1.0
-- @author cfillion
-- @donation https://www.paypal.me/cfillion
-- @link Forum Thread http://forum.cockos.com/showthread.php?t=186689

local TITLE = "Nudge start or end of regions in time selection"
local UNDO_STATE_MISCCFG = 8

local _, csv = reaper.GetUserInputs(TITLE, 2,
  "Nudge region start by:,Nudge region end by:", "0.0,0.0")
local start_offset, end_offset = csv:match("^([^,]+),([^,]+)$")
start_offset, end_offset = tonumber(start_offset), tonumber(end_offset)

if not start_offset or not end_offset or start_offset == 0 or end_offset == 0 then
  return reaper.defer(function() end) -- no undo point
end

local next_index = 0
local ts_from, ts_to = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

reaper.Undo_BeginBlock()

while true do
  -- reg = {retval, isrgn, pos, rgnend, name, markrgnindexnumber}
  local reg = {reaper.EnumProjectMarkers(next_index)}

  next_index = reg[1]
  if next_index == 0 then break end

  local withinTS = ts_to == 0 or (reg[3] >= ts_from and reg[4] <= ts_to)
  if reg[2] and withinTS then -- it's a region
    reaper.SetProjectMarker(reg[6], reg[2],
      reg[3] + start_offset, reg[4] + end_offset, reg[5])
  end
end

reaper.Undo_EndBlock(TITLE, UNDO_STATE_MISCCFG)
