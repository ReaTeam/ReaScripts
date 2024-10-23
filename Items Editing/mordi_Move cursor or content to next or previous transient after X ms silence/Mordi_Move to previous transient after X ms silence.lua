-- @noindex

reaper.ClearConsole()
function msg(val)
  reaper.ShowConsoleMsg(tostring(val) .. "\n")
end

SCRIPT_NAME = "Move to previous transient after X ms silence"

sel_num = reaper.CountSelectedMediaItems(0)

if sel_num == 0 then
  return
end

-- Check that we have the required script
cmd_id = reaper.NamedCommandLookup("_RSfada8d66fc67ae31f4460bea24e811bf6045b81b")
if cmd_id == nil or cmd_id == 0 then
  reaper.ShowMessageBox("Looks like you're missing a required script: 'Mordi_Move to next transient after X ms silence'", SCRIPT_NAME, 0)
  return
end

function GetCursorPositionMS()
  return reaper.GetCursorPosition() * 1000
end

-- Get leftmost position and rightmost end
leftmost_item_pos = -1
for i = 0, sel_num - 1, 1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  local take = reaper.GetActiveTake(item)
  local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local take_playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  local start_offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  
  -- Ignore start offset if positive
  if start_offset > 0 then
    start_offset = 0
  end
  
  local item_left_edge = item_start - (start_offset / take_playrate)
  
  -- Calculate leftmost edge
  if leftmost_item_pos > item_left_edge or leftmost_item_pos == -1 then
    leftmost_item_pos = item_left_edge
  end
end

-- Set values here
increment_ms = 50 -- How far back we move on each increment
min_threshold_ms = 50 -- How far back we must have moved to consider it a success (partly because tab-to-transient is slightly inaccurate)
------------------

pos_initial_s = reaper.GetCursorPosition()
pos_initial_ms = GetCursorPositionMS()
pos_prev_ms = GetCursorPositionMS()
failed = false
try_pos_s = pos_initial_s

reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)

-- Debug purposes
safety = 0

function sleep(n)
  if n > 0 then os.execute("ping -n " .. tonumber(n+1) .. " localhost > NUL") end
end

while (true) do
  -- Try a position a bit to the left
  try_pos_s = try_pos_s - (increment_ms / 1000)
  reaper.SetEditCurPos(try_pos_s, false, false)
  
  local cursor_pos_before = reaper.GetCursorPosition()
  
  -- Go to next transient
  reaper.Main_OnCommand(cmd_id, 0)
  
  local cursor_pos = reaper.GetCursorPosition()
  
  -- Check success
  if cursor_pos < pos_initial_s - (min_threshold_ms / 1000) and cursor_pos > cursor_pos_before then
    -- Success!
    break
  end
  
  -- Check left boundary
  if try_pos_s < leftmost_item_pos then
    -- Move cursor to left-most edge
    reaper.SetEditCurPos(leftmost_item_pos, false, false)
    break
  end
  
  safety = safety + 1
  if safety > 999 then
    msg(SCRIPT_NAME .. " - Safety break, possibly infinite loop?")
    failed = true
    break
  end
end

if failed then
  -- Move cursor back to original position
  reaper.SetEditCurPos(pos_initial_s, false, false)
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock2(0,SCRIPT_NAME,-1)
