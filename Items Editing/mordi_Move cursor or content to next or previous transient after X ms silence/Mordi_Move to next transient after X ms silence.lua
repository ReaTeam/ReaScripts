-- @noindex

SCRIPT_NAME = "Move to next transient after X ms silence"

if reaper.GetSelectedMediaItem(0, 0) == nil then
  return
end

function GetCursorPositionMS()
  return reaper.GetCursorPosition() * 1000
end

-- Set value here (default is 200)
min_silence_ms = 200

jump_ms = 0
pos_initial_s = reaper.GetCursorPosition()
pos_prev_ms = GetCursorPositionMS()

reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)

repeat
  reaper.Main_OnCommand(40375, 0)
  jump_ms = GetCursorPositionMS() - pos_prev_ms
  pos_prev_ms = GetCursorPositionMS()
  --reaper.ShowConsoleMsg(ms_jump .. "\n")
until(jump_ms >= min_silence_ms or jump_ms <= 0)

if jump_ms <= 0 then
  -- Move cursor back to where it was
  reaper.SetEditCurPos(pos_initial_s, false, false)
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock2(0,SCRIPT_NAME,-1)
