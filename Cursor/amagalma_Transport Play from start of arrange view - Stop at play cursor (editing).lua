-- @description Transport Play from start of arrange view / Stop at play cursor (editing)
-- @author amagalma
-- @version 1.01
-- @changelog - improvement
-- @donation https://www.paypal.me/amagalma
-- @about
--   - Starts playing from start of arrange view (without moving the arrange)
--   - Stops at play cursor position
--   - No undo is created
--   - Useful while editing


if reaper.GetPlayState() & 1 == 1 then
  reaper.SetEditCurPos( reaper.GetPlayPosition(), false, false )
  reaper.OnStopButton()
else
  local start_time, end_time = reaper.GetSet_ArrangeView2( 0, 0, 0, 0 )
  reaper.SetEditCurPos( (end_time - start_time)/200 + start_time, false, false )
  reaper.PreventUIRefresh( 1 )
  reaper.OnPlayButton()
  reaper.GetSet_ArrangeView2( 0, 1, 0, 0, start_time, end_time )
  reaper.PreventUIRefresh( -1 )
end
reaper.defer(function() end)
