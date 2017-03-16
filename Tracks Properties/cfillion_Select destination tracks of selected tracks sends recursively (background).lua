-- This script is part of cfillion_Select destination tracks of selected tracks sends recursively.lua
-- @noindex

background = true
destination = true

local dir = ({reaper.get_action_context()})[2]:match("^(.*[/\\])")
dofile(dir .. 'cfillion_Select destination tracks of selected tracks sends recursively (logic).lua')
