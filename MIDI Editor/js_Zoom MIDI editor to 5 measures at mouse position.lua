--[[
ReaScript name: Zoom MIDI editor to 5 measures at mouse position
Version: 1.30
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
  
  The script can either zoom to the mouse position, ir to the edit cursor position:
  
  If the mouse is over a part of the interface that has position info (i.e. the arrange view, the ruler, 
  or the MIDI editor's "notes" or "cc" areas), the MIDI editor will zoom to the mouse position.  
  
  If the mouse is positioned anywhere else (for example the "track list" area of the MIDI editor), 
  the MIDI editor will scroll and zoom to the current position of the edit cursor.
  (Zooming to the edit cursor is particularly useful for returning to the last edit position, after inadvertently scrolling to a faraway item.)
  
  # Instructions
  Simply move the mouse to the position that you want to edit, and press the linked shortcut or mouse modifier.
  
  In the script's USER AREA, the user can change the number of measures that the script zooms to, and
  these modified scripts can be saved under different names and linked to different shortcuts or mouse 
  modifiers.
  
  # Warning
  The script temporarily changes the loop region, so it may be safer to avoid running the script during 
  playback or recording.  
Changelog:
  If mouse is not over arrange view, ruler, or MIDI editor's notes or cc area, scroll to current position of edit cursor.
]]

-- USER AREA
number_of_measures = 5

-- End of USER AREA
-------------------

--------------------------------------
-- Is SWS installed?
if not reaper.APIExists("BR_GetMouseCursorContext") then
    reaper.MB("This script requires the SWS/S&M extension, which adds all kinds of nifty features to REAPER.\n\nThe extension can be downloaded from www.sws-extension.org.", "ERROR", 0)
    return
end
    
-- Is there an active MIDI editor?
editor = reaper.MIDIEditor_GetActive()
if editor == nil then return end
    
-- Checks OK, so start undo block
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)

-- Store any pre-existing loop range
loopStart, loopEnd = reaper.GetSet_LoopTimeRange2(0, false, true, 0, 0, false)

-- Is the mouse in the MIDI editor, or in the arrange view?
window, segment, details = reaper.BR_GetMouseCursorContext()

-- If the mouse is over a part of the interface that has position (arrange view, ruler or MIDI editor "notes" or "cc" area),
--    scroll to mouse position.  Otherwise, scroll to current edit position.
-- AFAIK it is not possible to get the mouse time position directly, without using the edit cursor
if window == "midi_editor" and segment ~= "unknown" then -- Is in MIDI editor?
    reaper.MIDIEditor_OnCommand(editor, 40443) -- Move edit cursor to mouse cursor
elseif window == "arrange" or window == "ruler" then -- Is in arrange?
    reaper.Main_OnCommandEx(40513, -1, 0) -- Move edit cursor to mouse cursor (obey snapping)
-- else
--  don't move edit cursor, so will scroll to current edit cursor    
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
