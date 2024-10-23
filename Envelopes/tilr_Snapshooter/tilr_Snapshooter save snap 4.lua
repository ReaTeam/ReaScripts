-- @noindex

skip_init = true
local sep = package.config:sub(1, 1)
local script_folder = debug.getinfo(1).source:match("@?(.*[\\|/]).*[\\|/]")
local snapshooter = dofile(script_folder .. sep .. 'tilr_Snapshooter.lua')

snapshooter.savesnap(4)
