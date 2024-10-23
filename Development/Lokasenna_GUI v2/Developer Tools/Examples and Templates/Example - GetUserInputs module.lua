-- NoIndex: true
--[[

    Demonstration of the GetUserInputs window

]]--

local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please install 'Lokasenna's GUI library v2 for Lua', available on ReaPack, then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()

GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Window.lua")()
GUI.req("Modules/Window - GetUserInputs.lua")()




GUI.name = "GetUserInputs example"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 320, 240
GUI.anchor, GUI.corner = "mouse", "C"



local elms = {}
elms.my_button = {
    type = "Button",
    z = 1,
    x = 48,
    y = 48,
    w = 64,
    h = 22,
    caption = "Inputs..."
}

GUI.CreateElms(elms)


-- We'll pass this function to the user input window; it will be called when the window is closed,
-- with the returned values passed as a table.
local function return_values(vals)

    -- vals is nil if the user clicked Cancel or the X button.
    if not vals then vals = {"cancelled"} end
    reaper.MB("Returned values:\n\n" .. table.concat(vals, "\n"), "Returned:", 0)

end

GUI.elms.my_button.func = function()

    local captions = {"Option 1", "Option 2", "Option 3", "Option 4"}
    local defaults = {"Def 1", "Def 2", "Def 3", "Def 4"}
    GUI.GetUserInputs("Type stuff, please", captions, defaults, return_values, 0)

end

GUI.Init()

GUI.Main()
