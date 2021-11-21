-- @description Move cursor. Seeking allowed, leaving items selected. (for mouse click in track area)
-- @author AZ
-- @version 1.0

playstate = reaper.GetPlayStateEx(0)

if playstate == 1 then
  reaper.Main_OnCommandEx(40513, 0, 0) -- move edit cursor to mouse
  reaper.Main_OnCommandEx(1007, 0, 0) -- play
else
  reaper.Main_OnCommandEx(40513, 0, 0) -- move edit cursor to mouse
end

reaper.defer(function()end)
