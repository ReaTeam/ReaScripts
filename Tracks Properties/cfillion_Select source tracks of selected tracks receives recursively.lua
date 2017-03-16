-- @description Select source tracks of selected tracks receives recursively
-- @version 1.0.1
-- @author cfillion
-- @changelog
--   Fix background script using the wrong logic file
-- @donation https://www.paypal.me/cfillion
-- @provides
--   [main] cfillion_Select source tracks of selected tracks receives recursively (background).lua
--   [nomain] cfillion_Select destination tracks of selected tracks sends recursively (logic).lua > cfillion_Select source tracks of selected tracks receives recursively (logic).lua

background = false
destination = false

local dir = ({reaper.get_action_context()})[2]:match("^(.*[/\\])")
dofile(dir .. 'cfillion_Select source tracks of selected tracks receives recursively (logic).lua')
