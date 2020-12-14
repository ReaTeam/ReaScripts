-- @description Insert empty space at project start (moving everything)
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about Inserts user specified amount of empty space at the start of the project.

local ok, retval = reaper.GetUserInputs( "Insert empty space at start of project", 1, "How many seconds to insert?", "10" )
retval = tonumber(retval)

if ok and retval then
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh( 1 )
  local st, en = reaper.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
  reaper.GetSet_LoopTimeRange( 1, 1, 0, retval, false )
  reaper.Main_OnCommand(40200, 0) -- Insert empty space at time selection (moving later items)
  reaper.GetSet_LoopTimeRange( 1, 1, st + retval, en + retval, false )
  reaper.PreventUIRefresh( -1 )
  reaper.Undo_EndBlock( "Insert empty space at start of project", -1 )
end
