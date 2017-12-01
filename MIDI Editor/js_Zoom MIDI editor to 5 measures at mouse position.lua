--[[
ReaScript name: js_Zoom MIDI editor to 5 measures at mouse position.lua
Version: 1.23
Author: juliansader
Website: Simple but useful MIDI editor tools http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
About:
  # Description
  When the MIDI editor's active take is switched via the track list to a take that is out of view, 
  the MIDI editor will automatically "Zoom to content".  If the newly active MIDI take is very large, 
  "Zoom to content" provides a nice overview of the entire item, so that the user can easily locate the 
  relevant MIDI data.  However, zooming in again can be a hassle. 
  
  Similarly, when opening multiple MIDI items simultaneously (with Preferences -> MIDI Editor -> Open all selected items),
  the MIDI editor will "zoom to content", trying to fit all the items into the viewport.

  This script is therefore intended to provide an easy, one-click action to zoom in, without requiring 
  the user to change the note, time or loop selection.
  
  # Instructions
  Simply point the mouse to the appropriate position in the MIDI item and press the linked shortcut 
  or mouse modifier.
  
  The mouse can be positioned in the MIDI editor or (if the SWS extension is installed) in the Arrange view.  
  Since the script will work if the mouse is in the Arrange view, the script can be run immediately after
  click-opening MIDI items, and the MIDI editor will zoom to the clicked position.
  
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
  * v1.23 (2017-12-01)
    + Refactored to minimize calling actions.
]]

-- USER AREA
number_of_measures = 5

-- End of USER AREA
-------------------

--------------------------------------
editor = reaper.MIDIEditor_GetActive()
if editor ~= nil then
    
    reaper.Undo_BeginBlock2(0)
    reaper.PreventUIRefresh(1)
    
    -- Store any pre-existing loop range
    loopStart, loopEnd = reaper.GetSet_LoopTimeRange2(0, false, true, 0, 0, false)
    
    -- Is the mouse in the MIDI editor, or in the arrange view?
    if reaper.APIExists("BR_GetMouseCursorContext") then
        window, segment, details = reaper.BR_GetMouseCursorContext()
    end
    
    -- AFAIK it is not possible to get the mouse time position directly, without using the edit cursor
    if window ~= "midi_editor" then
        reaper.Main_OnCommandEx(40513, -1, 0) -- Move edit cursor to mouse cursor (obey snapping)
    else
        reaper.MIDIEditor_OnCommand(editor, 40443) -- Move edit cursor to mouse cursor
    end
    mouseTimePos = reaper.GetCursorPositionEx(0)
    beats, measures = reaper.TimeMap2_timeToBeats(0, mouseTimePos)
    
    -- Zoom!
    zoomStart = reaper.TimeMap2_beatsToTime(0, 0, measures-math.floor(number_of_measures/2))
    zoomEnd   = reaper.TimeMap2_beatsToTime(0, 0, measures+math.ceil(number_of_measures/2))
    reaper.GetSet_LoopTimeRange2(0, true, true, zoomStart, zoomEnd, false)
    reaper.MIDIEditor_OnCommand(editor, 40726) -- Zoom to project loop selection
    
    -- Reset the pre-existing loop range
    reaper.GetSet_LoopTimeRange2(0, true, true, loopStart, loopEnd, false)
    
    reaper.PreventUIRefresh(-1)
    reaper.UpdateTimeline()
    reaper.Undo_EndBlock2(0, "Zoom to 5 measures at mouse position", -1)
end
