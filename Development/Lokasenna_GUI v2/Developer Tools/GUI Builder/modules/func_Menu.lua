-- NoIndex: true
------------------------------------
-------- Menu bar ------------------
------------------------------------

--local Export = require("func_Export")
local Menu = {}

-- The menu bar, just so this is easily accessible
Menu.h = 20

Menu.menu = {

    {title = "File", options = {

        {"Export", Export.export_file},

    }},

    {title = "Settings", options = {

        {"Project Settings", function() GUI.elms.GB_wnd_proj:open() end},
        {"Preferences", function() GUI.elms.GB_wnd_prefs:open() end},

    }},

    {title = "Help", options = {

        {"Instructions", function() Help.show_help_msg() end}

    }},

}

GUI.New("GB_mnu_bar", "Menubar", 2, 0, 0, Menu.menu, nil, Menu.h)

return Menu