--[[
	This script is part of Lokasenna_Adjust ReaSamplomatic 5000 Pitch Offset.lua
	NoIndex: true
--]]

-- Licensed under the GNU GPL v3

reaper.Undo_BeginBlock()

add = 1

local script_path = debug.getinfo(1,'S').source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "../Lokasenna_Adjust ReaSamplomatic 5000 Pitch Offset.lua")