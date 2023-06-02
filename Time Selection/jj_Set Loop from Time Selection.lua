-- @description Set Loop from Time Selection
-- @author jj
-- @version 1.0
-- @donation https://paypal.me/johnjallday
-- @about
--   # Sets Loop from a Time Selection.
--   # Useful when Option -> Loop Point Linked to Time Selection is turned Off

function main()
  start_time, end_time = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  reaper.GetSet_LoopTimeRange(true, true, start_time, end_time, false)
end

main()

