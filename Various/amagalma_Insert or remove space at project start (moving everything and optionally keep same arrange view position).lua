-- @description Insert or remove space at project start (moving everything and optionally keep same arrange view position)
-- @author amagalma
-- @version 1.01
-- @changelog Fix crash when choosing cancel
-- @donation https://www.paypal.me/amagalma
-- @about Inserts or removes user specified amount of space at the start of the project

local ok, retval = reaper.GetUserInputs( "Insert/remove space at start of project", 2, "Seconds: (>0 insert | <0 remove),\z
                   Keep same arrange view: (y/n),extrawidth=20", "10,y" )
local space, keepView = retval:match("([-%.%d]+),([yYnN])")
if not ok or not space or not keepView then return end

space, keepView = tonumber(space), keepView:upper()

if space and space ~= 0 then
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh( 1 )
  
  -- Get current values
  local st, en = reaper.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
  local cur_pos = reaper.GetCursorPosition()
  local start_time, end_time = reaper.GetSet_ArrangeView2( 0, 0, 0, 0 )
  
  -- Insert or Remove
  reaper.GetSet_LoopTimeRange( 1, 1, 0, space, false )
  if space > 0 then
    reaper.Main_OnCommand(40200, 0) -- Insert empty space at time selection (moving later items)
  else
    reaper.Main_OnCommand(40201, 0) -- Remove contents of time selection (moving later items)
  end
  
  -- Restore values
  reaper.SetEditCurPos( cur_pos + space, false, false )
  if keepView == "Y" then
    reaper.GetSet_ArrangeView2( 0, 1, 0, 0, start_time + space, end_time + space )
  end
  reaper.GetSet_LoopTimeRange( 1, 1, st + space, en + space, false )

  reaper.PreventUIRefresh( -1 )
  local desc = (space > 0 and "Insert " or "Remove ") .. math.abs(space) .. " seconds at start of project"
  reaper.Undo_EndBlock( desc, -1 )
end
