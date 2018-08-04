-- NoIndex: true

-- Stores the path to Lokasenna_GUI v2 for other scripts to access
-- Must be run prior to using Lokasenna_GUI scripts

local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]

reaper.SetExtState("Lokasenna_GUI", "lib_path_v2", script_path, true)
reaper.MB("The library path is now set to:\n" .. script_path, "Lokasenna_GUI v2", 0)