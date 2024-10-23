-- @description Playhead follower
-- @author Edgemeal
-- @version 1.00
-- @link Forum Thread https://forum.cockos.com/showthread.php?t=271236
-- @donation Donate https://www.paypal.me/Edgemeal
-- @about When Transport Repeat mode is off and playhead is near edge of time selection it moves to the right by its length.

function ToolbarButton(enable)
  local _, _, section_id, command_id = reaper.get_action_context()
  reaper.SetToggleCommandState(section_id, command_id, enable)
  reaper.RefreshToolbar2(section_id, command_id)
end

function Loop()
  local ps = reaper.GetPlayState()
  if ((ps&1)==1 or (ps&4)==4) then -- play/record mode
    if reaper.GetToggleCommandState(1068) == 0 then -- Transport Repeat off
      local s_time, e_time = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
      if (e_time > s_time) and (reaper.GetPlayPosition() > (e_time - 0.05)) then -- advance time sel.
        local time_len = e_time - s_time
        reaper.GetSet_LoopTimeRange(true, true, s_time+time_len, e_time+time_len, true)
      end
    end
  end
  reaper.defer(Loop)
end

function exit() ToolbarButton(0) end
reaper.atexit(exit)
ToolbarButton(1)
Loop()
