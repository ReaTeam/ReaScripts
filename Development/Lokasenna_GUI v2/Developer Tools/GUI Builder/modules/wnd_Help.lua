-- NoIndex: true
local Help = {}

function Help.show_help_msg()

    local str = "GUI Builder will allow you to build basic GUIs for scripts using my Lokasenna_GUI library, " ..
    "which you clearly have installed if you're running this script. It's functional - my last few script releases " ..
    "have used it - but there are features missing and bugs to be expected. Use at your own risk. :)" ..
    "\n\n" ..
    "Usage:\n\n" ..
    "- Right-click to bring up a list of element types.\n\n" ..
    "- Shift-click an element to select it for editing. Be aware that not all element properties are supported yet.\n\n" ..
    "- Shift-drag an element to move it.\n\n" ..
    "- Alt-click an element to delete it.\n\n" ..
    "- Right-click an empty area with an element selected to duplicate it.\n\n" ..
    "- Script window settings and grid/snap options are available in the Settings menu.\n\n" ..
    "- Use File | Export to save scripts. GUI Builder will export a complete, working script.\n\n\n" ..
    "WARNING: At the moment there's no load/import functionality. I do apologize if you lose any work as the result of " ..
    "a crash. Importing is at the top of my to-do list.\n\n" ..
    "Please let me know if you find any bugs, or if you have any cool feature ideas. No promises though."

    reaper.MB(str, "GUI Builder instructions", 0)

end

return Help