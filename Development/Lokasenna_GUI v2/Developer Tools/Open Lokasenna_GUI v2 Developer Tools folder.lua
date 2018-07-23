-- NoIndex: true

-- Opens the folder containing Lokasenna_GUI's Developer Tools package

local path = ({reaper.get_action_context()})[2]:match("(.-)([^/\\]+).lua$")

local function open_file(path)
    
    local OS = reaper.GetOS()

    local cmd = ( string.match(OS, "Win") and "start" or "open" ) ..
                ' "" "' .. path .. '"'

    os.execute(cmd)

end

open_file(path)