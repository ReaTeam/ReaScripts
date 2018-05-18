--[[
ReaScript name: js_Mousewheel - Control js MIDI editing script (if one is running), otherwise zoom horizontally.lua
Version: 1.00
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Screenshot: 
Donation: https://www.paypal.me/juliansader
Provides: [main=main,midi_editor] .
About:
  # DESCRIPTION
  
  This script is intended to simplify mousewheel control of the js MIDI editing scripts that respond to mousewheel movement, 
  such as js_Compress, js_Warp, etc.
  
  Instead of using a separate, dedicated modifier+mousewheel shortcut (such as Ctrl+mousewheel) to control the scripts, 
  the user can use plain mousewheel without any modifier.
  
  If one of these scripts is running, this script will send the mousewheel movement to the running script.
  
  If no js script is running, the script will simply zoom in or out horizontally, as per REAPER's default behavior for mousewheel.
  
  This script also allows mousewheel control of scripts in the inline MIDI editor:  In current versions of REAPER (~v5.90),
  the inline editor does not respond to mousewheel shortcuts and instead passes these through the main arrange view.
  If this script is installed in the Action list's Main section (and linked to the mousewheel shortcut), it will control
  scripts running in the inline editor.
  
  The script works with any of these js MIDI editing scripts (and their variants):
  
       ~ Compress / expand
       ~ Arch
       ~ 1-sided warp
       ~ 2-sided warp
       ~ Draw linear or curved ramp
       ~ Draw sine curve
       ~ Insert ramps between selected CCs
  
  
  # INSTRUCTIONS
  
  Intall script in the Actions list's Main section and well as the MIDI Editor section.  
  (If installed via ReaPack, this will be done automatically.)
  Don't bother installing the script in the Inline MIDI Editor section, since mousewheel shortcuts don't work in the inline editor.
  
  Assign plain mousewheel movement (i.e. without any keyboard modifiers) to this script as shortcut, in both sections.
  
  Once the js mouse edit script is running, it can be controlled by the mousewheel.
]]

--[[
  Changelog:
  * v1.00 (2018-05-18)
    + Initial release.
]]

---------------------------------------------------------

isnew, _, sectionID, _, _, _, val = reaper.get_action_context()

if isnew then
    
    if not (type(val) == "number") then val = 0 end
    
    -- If one of the "under mouse" scripts is already running, broadcast mousewheel
    if reaper.GetExtState("js_Mouse actions", "Status") == "Running" then     
        reaper.SetExtState("js_Mouse actions", "Mousewheel", tostring(val), false)
        
    -- If no "under mouse" script is already running, zoom horizontally.
    -- BUG in REAPER:  Mousewheel shortcuts don't work in inline MIDI editor, and simply passes through to Main context
    -- So, if either inline editor or arrange view, sectionID = 0
    elseif sectionID == 0 then 
        if val > 0 then
            reaper.Main_OnCommandEx(1012, -1, 0) -- Main: Zoom in horizontally
        elseif val < 0 then
            reaper.Main_OnCommandEx(1011, -1, 0) -- Main: Zoom out horizontally
        end 
        
    -- If not main window, assume MIDI editor
    -- (Assuming that this script is only installed in MIDI Editor and Main contexts
    else 
        if val > 0 then
            reaper.MIDIEditor_LastFocused_OnCommand(1012, false) -- Zoom in horizontally
        elseif val < 0 then
            reaper.MIDIEditor_LastFocused_OnCommand(1011, false) -- Zoom out horizontally
        end
    end
    
end

reaper.defer(function() end) -- don't create undo point
