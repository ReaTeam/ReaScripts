-- @noindex

local info = debug.getinfo(1,'S')
dofile(info.source:match[[^@?(.*[\/])[^\/]-$]] .. "spk77_Set solo for send X.lua")

solo_send(4)
