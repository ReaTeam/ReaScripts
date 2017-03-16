-- This script is part of cfillion_Select source tracks of selected tracks receives recursively.lua
-- @noindex

background = true
destination = false

local dir = ({reaper.get_action_context()})[2]:match("^(.*[/\\])")
dofile(dir .. 'cfillion_Select destination tracks of selected tracks sends recursively (logic).lua')
