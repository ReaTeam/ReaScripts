-- @noindex

NO_UI = true
local sep = package.config:sub(1, 1)
local script_folder = debug.getinfo(1).source:match("@?(.*[\\|/]).*[\\|/]")
local highroller = dofile(script_folder .. sep .. 'tilr_HighRoller - MIDI Toolkit.lua')

highroller.Split(false)
