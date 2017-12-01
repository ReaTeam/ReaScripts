--[[
ReaScript name: js_Zoom MIDI editor to 5 measures at mouse position.lua
Version: 1.22
Author: juliansader
Website: Simple but useful MIDI editor tools http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
About:
  # Description
  When the MIDI editor's active take is switched via the track list to a take that is out of view, 
  the MIDI editor will automatically "Zoom to content".  If the newly active MIDI take is very large, 
  "Zoom to content" provides a nice overview of the entire item, so that the user can easily locate the 
  relevant MIDI data.  However, zooming in again can be a hassle. 

  This script is therefore intended to provide an easy, one-click action to zoom in, without requiring 
  the user to change the note, time or loop selection.
  
  # Instructions
  Simply point the mouse to the appropriate position in the MIDI item and press the linked shortcut 
  or mouse modifier.
  
  In the script's USER AREA, the user can change the number of measures that the script zooms to, and
  these modified scripts can be saved under different names and linked to different shortcuts or mouse 
  modifiers.
  
  # Warning
  The script temporarily changes the loop region, so it may be safer to avoid running the script during 
  playback or recording.  
]]

--[[
Changelog:
  * v1.0 (2016-09-14)
    + Initial release.
  * v1.10 (2016-09-16)
    + Zooming creates undo point.
  * v1.20 (2017-11-30)
    + Compatible with setting "Move edit cursor to start of time selection on time selection change".
  * v1.22 (2017-12-01)
    + Accurate zoom if number of measures is even.
    + Mouse can be placed in arrange view (if SWS extension is installed).
]]

-- USER AREA
number_of_measures = 5

-- End of USER AREA
-------------------

--------------------------------------
editor = reaper.MIDIEditor_GetActive()
if editor ~= nil then
    
    reaper.Undo_BeginBlock2(0)
    
    -- Store any pre-existing loop range
    loopStart, loopEnd = reaper.GetSet_LoopTimeRange2(0, false, true, 0, 0, false)
    
    -- Is the mouse in the MIDI editor, or in the arrange view?
    if reaper.APIExists("BR_GetMouseCursorContext") then
        window, segment, details = reaper.BR_GetMouseCursorContext()
    end
    
    -- Possible bug: MIDI editor does not immediately update after
    --    calling Main actions to move edit cursor, such as
    --    reaper.Main_OnCommandEx(41041, -1, 0) -- Move edit cursor to start of current measure
    if window ~= "midi_editor" then
        reaper.Main_OnCommandEx(40514, -1, 0) -- Move edit cursor to mouse cursor (NO snapping)
    else
        reaper.MIDIEditor_OnCommand(editor, 40443) -- Move edit cursor to mouse cursor
    end
    reaper.Main_OnCommandEx(40837, -1, 0) -- Move edit cursor to start of next measure (no seek)
    for i = 1, math.floor((number_of_measures-1)/2) do
        reaper.Main_OnCommandEx(40839, -1, 0) -- Move edit cursor forward one measure (no seek)
    end
    reaper.Main_OnCommandEx(40223, -1, 0) -- Loop points: Set end point
    
    -- If  "Move edit cursor to start of time selection on time selection change" is ON, 
    --    and time selection follows loop selection,
    --    cursor position may have changed when setting loop point.  
    -- So reset cursor position before setting rightmost edge of loop.
    if window ~= "midi_editor" then
        reaper.Main_OnCommandEx(40514, -1, 0) -- Move edit cursor to mouse cursor (NO snapping)
    else
        reaper.MIDIEditor_OnCommand(editor, 40443) -- Move edit cursor to mouse cursor
    end
    reaper.Main_OnCommandEx(40838, -1, 0) -- Move edit cursor to start of current measure (no seek)
    for i = 1, math.ceil((number_of_measures-1)/2) do
        reaper.Main_OnCommandEx(40840, -1, 0) -- Move edit cursor back one measure (no seek)
    end
    reaper.Main_OnCommandEx(40222, -1, 0) -- Loop points: Set start point
    
    -- Again, reset cursor position
    if window ~= "midi_editor" then
        reaper.Main_OnCommandEx(40513, -1, 0) -- Move edit cursor to mouse cursor (OBEY snap)
    else
        reaper.MIDIEditor_OnCommand(editor, 40443) -- Move edit cursor to mouse cursor
    end
    
    -- Zoom!
    reaper.MIDIEditor_OnCommand(editor, 40726) -- Zoom to project loop selection
    
    -- Reset the pre-existing loop range
    reaper.GetSet_LoopTimeRange2(0, true, true, loopStart, loopEnd, false)
    
    reaper.Undo_EndBlock2(0, "Zoom to 5 measures at mouse position", -1)
end
