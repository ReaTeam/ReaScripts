-- @description Select destination tracks of selected tracks sends recursively
-- @version 1.1
-- @author cfillion
-- @changelog
--   Add a variant action running in the background
-- @link Forum Thread http://forum.cockos.com/showthread.php?t=183638
-- @donation https://www.paypal.me/cfillion
-- @provides
--   [main] cfillion_Select destination tracks of selected tracks sends recursively (background).lua
--   [nomain] cfillion_Select destination tracks of selected tracks sends recursively (logic).lua

background = false
destination = true

local dir = ({reaper.get_action_context()})[2]:match("^(.*[/\\])")
dofile(dir .. 'cfillion_Select destination tracks of selected tracks sends recursively (logic).lua')
