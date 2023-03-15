--[[
ReaScript name: js_Hotstrings
Version: 0.90
Author: juliansader
Website: https://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION
  
  REAPER's native keyboard shortcuts consist of a combination of modifier keys + a *single* alphanumeric hotkey.
  These modifier keys combinations can be difficult to remember. 
  
  This script enables the use of easy-to-remember *sequences* of alphanumeric keys -- aka "hotstrings" -- as shortcuts.
  
  For example, instead of holding Ctrl+Alt+Shift+Z to zoom to the entire project, the user can simply type Z and then P. 
  
  The hotstrings and their linked Actions can be customized by the users, and must all be saved in a file named "js_Hotstrings - table.lua" in the same folder as the script.
  (The reason why this data is stored in a separate file, is to prevent it from being overwritten whenever the script file is updated.)
  
  If the script is run with an alphanumeric hotkey (or a modifier + alphanumeric hotkey), that hotkey will be interpreted as the first character in the hotstring.
  It is therefore helpful to link the script to multiple hotkeys -- namely the first letter in each hotstring -- in REAPER's Actions list.
  
  The "js_Hotstrings - table.lua" file should be formatted as a standard Lua table, as in this short example:
  
  tableCommands = {
        -- Zoom
        zz = reaper.NamedCommandLookup("_SWS_TOGZOOMIONLY"), -- Toggle zoom items
        zp = 40295, -- Zoom project
        zt = 40031, -- Zoom time selection
  }
  
]]

--[[
  Changelog:
  * v0.90 (2020-06-04)
    + Initial beta release: Hotstrings (i.e. sequences of keys) to replace modifiers+single key shortcuts.
]]

exampleTable = [[

-- Copy this text into a file named "js_Hotstrings - table.lua",
--    and then customize the file with your own hotstrings.
-- The hotstrings and their linked Action command IDs should be formatted 
--    as a standard Lua table, as demonstrated in this example.
-- Hotstrings can any unique string of alphanumeric characters.

tableCommands = {
      -- Zoom
      zz = reaper.NamedCommandLookup("_SWS_TOGZOOMIONLY"), -- Toggle zoom items
      zp = 40295, -- Zoom project
      zt = 40031, -- Zoom time selection
}
]]
_, context = reaper.get_action_context()
tablePath = context:match(".+[/\\]") .. "js_Hotstrings - table.lua"

if not reaper.file_exists(tablePath) then --f and fMsg:match("No such file") then
    reaper.ClearConsole()
    reaper.ShowConsoleMsg(exampleTable)
    reaper.MB("The script requires a file named \"js_Hotstrings - table.lua\" in the same folder as the script."
            .."\n\nAll the hotstrings and their linked Actions can be listed in this file and customized by the user."  
            .."\n\nThe reason why this data is stored in a separate file, is to prevent it from being overwritten whenever the script file is updated."
            .."\n\nAn example of the text that the file should contain has been copied to REAPER's console.", "ERROR", 0)
    return
end

dofile(tablePath)
if not (type(tableCommands) == "table") then 
    reaper.ClearConsole()
    reaper.ShowConsoleMsg(exampleTable)
    reaper.MB("The \"js_Hotstrings - table.lua\" file does not appear to be correctly formatted."
            .."\n\nAn example of the text that the file should contain has been copied to REAPER's console.", "ERROR", 0)
    return
elseif not reaper.JS_LICE_LoadJPG then
    reaper.MB("This script requires an up-to-date version of the ReaScriptAPI extension, which can be installed via ReaPack.", "ERROR", 0) 
    return
elseif not reaper.CF_GetCommandText then
    reaper.MB("This script requires an up-to-date version of the SWS/S&M extension, which can be downloaded from \n\nwww.sws-extension.com", "ERROR", 0) 
    return
end

local tC = tableCommands

lastInputTime = reaper.time_precise() -- approximate time shortcut was pressed
input = ""

-- At first, only open unobstrusive GUI (this window will gain focus, and therefore get all new keystrokes)
gfx.init("", w, h, 0, 0, 0)
gfx.setfont(1, "Arial", 16, "")
reaper.atexit(gfx.quit)


-- If user is uncertain, waiting too long to respond, this function will be called. It expands the GUI with all options that match the keys pressed so far.
function ShowHelp(help)
    tK, tT = {}, {}
    for key, command in pairs(tC) do
        if key:match("^"..input) then
            tK[#tK+1] = key --:gsub("(.)", "%1 ")
            tT[#tT+1] = reaper.CF_GetCommandText(0, command)
        end
    end
    
    keys, text = "", ""
    if #tK > 0 then
        esc = canStillMatch and "Press Esc at any time to stop the script." or "Press Esc at any time to stop the script.\n\nThe last keystroke does not match any command, and can be re-typed:"
        
        tSort = {} -- helper table with which to sort keys and text together
        for i = 1, #tK do tSort[i] = i end
        table.sort(tSort, function(a, b) return tK[a] < tK[b] end)
        for i = 1, #tSort do
            keys = keys .. "\n" .. tK[tSort[i]]
            text = text .. "\n" .. tT[tSort[i]]
        end
    else
        esc = "Press Esc at any time to stop the script.\n\nNo commands match the input."
    end
    we, he = gfx.measurestr(esc)
    wk, hk = gfx.measurestr(keys)
    wt, ht = gfx.measurestr(text)
    gfx.quit()
    gfx.clear = 0x202020
    gfx.init("Matching shortcuts", math.max(we, wk+wt) + 20, he+ht+10, 0, 0, 0)
    gfx.setfont(1, "Arial", 16, "")
    gfx.x, gfx.y = 5, 5
    gfx.r, gfx.g, gfx.b, gfx.a = 1, 0, 0, 1
    gfx.drawstr(esc)
    gfx.x, gfx.y = 5, he+5
    gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, 1
    gfx.drawstr(keys)
    gfx.x, gfx.y = wk+15, he+5
    gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 0, 0.8
    gfx.drawstr(text)
end


-- The main deferred loop to get input
function Loop()
    -- First time entering loop, get shortcut used to launch script (skip modifier keys); otherwise, use gfx.getchar
    c = (not c) and reaper.JS_VKeys_GetState(-0.5):sub(1, 0x5A):find("\1", 0x30) or gfx.getchar() -- 0x30 - 0x5A are the standard letters and numbers; only use those; if another key was used for shortcut, ignore
    if c == 27 or c < 0 then -- Esc or window closed
        return
    elseif c > 0 then
        input = input .. string.lower(string.char(c))
        if tC[input] then 
            reaper.Main_OnCommandEx(tC[input], -1, 0)
            return
        else
            alreadyHelpedForThisInput = false -- may need to show new help for new input
            lastInputTime = reaper.time_precise()
            -- Check if input can still match anything
            canStillMatch = false 
            for key in pairs(tC) do
                if key:match("^"..input) then canStillMatch = true break end
            end
            if not canStillMatch then
                mustShowHelp = true
                alreadyHelpedForThisInput = true
                input = input:sub(1,-2) -- Remove last invalid keystroke os that can be re-typed
            end
        end
    else -- c == 0 -- no input in this cycle
        if not alreadyHelpedForThisInput and reaper.time_precise() > lastInputTime + 1.5 then 
            alreadyHelpedForThisInput = true
            canStillMatch = true
            mustShowHelp = true
        end
    end
    -- If user hesitates a little, or if input can't match, show help
    if mustShowHelp then --and not alreadyHelped then 
        mustShowHelp = false
        ShowHelp()
    end
    
    reaper.defer(Loop)
end

Loop()

