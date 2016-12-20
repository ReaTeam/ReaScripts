--[[
ReaScript name:  js_Option - Selecting single note or CC in active take sets channel for new events.lua
Version: 2.10
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=178256
About:
  # Description 
  Inserting events in the wrong channel is an all-too-easy mistake to make, particularly after 
       switching the active track. With this new option, the user can switch to the correct 
       channel by simply clicking a note or CC of the new track. 
       
   It is intended to be similar to the built-in action "Option: Drawing or selecting 
       a note sets the new note length" (but for channel instead of note length).
       
   NOTE: This script causes the following artefacts:
       ~ If an event in a *new* channel is selected by left-clicking on the event, 
         the event can not be edited immediately; instead, the mouse button must be released first.
         (This can be a useful indicator that the active channel has been changed.)
       ~ While this script is running, it may interact with the manual settings of the MIDI editor's 
         channel filter dropdown menu.
         
  # Instructions
  This script can be linked to a toolbar button for easy starting and stopping.
  While activated, the toolbar button will light up.
  (The first time that the script is stopped, REAPER will pop up a dialog box 
       asking whether to terminate or restart the script.  Select "Terminate"
       and "Remember my answer for this script".)Screenshot: 
]]
 
--[[
 Changelog:
  * v1.0 (2016-07-15)
    + Initial release
  * v2.00 (2016-12-19)
    + Improved speed and responsiveness.
    + Requires REAPER v5.30.
  * v2.10 (2016-12-20)
    + Even better speed and responsiveness.
]]

local prevTake, prevHash
local matchNoteOn = string.char(91,1,3,93,3,0,0,0,91,0x90,45,0x9F,93,46,91,94,0,93) -- [13]3000[0x90-0x9F].[^0]

---------------
function exit()
    -- Deactivate toolbar button when exiting
    _, _, sectionID, ownCommandID, _, _, _ = reaper.get_action_context()
    if not (sectionID == nil or ownCommandID == nil or sectionID == -1 or ownCommandID == -1) then
        reaper.SetToggleCommandState(sectionID, ownCommandID, 0)
        reaper.RefreshToolbar2(sectionID, ownCommandID)
    end
end -- function exit

------------------------------------------------------------------------------------------------
-- This function will use a combination of REAPER's standard API (MIDI_EnumSelCC and MIDI_GetCC)
--    and the new API of v5.30 (MIDI_GetAllEvts).
-- For getting the info of only a few events, EnumSelCC and GetCC is very fast, whereas 
--    EnumSelNotes and GetNote is very slow.  GetAllEvts is in-between.
-- To optimize speed, the CC functions will therefore be used first of all, and only if no CCs or more than one CC
--    is found, will GetAllEvts be used.
function loopGetSetChannel()

    local editor = reaper.MIDIEditor_GetActive()
    if editor ~= nil then 
    
        local take = reaper.MIDIEditor_GetTake(editor)
        if reaper.ValidatePtr(take, "MediaItem_Take*") then
        
            local hashOK, hash = reaper.MIDI_GetHash(take, false, "")
            if take ~= prevTake or hash ~= prevHash then
            
                prevTake = take
                prevHash = hash
                local newChannel, CC1, CC2, _
                
                -- If no CCs are selected, then CC1 == -1 and CC2 == nil.  
                -- If more than one CCs are selected, CC1 > -1 and CC2 > -1.
                -- If precisely one CC is selected, CC1 > -1 and CC2 == -1. 
                CC1 = reaper.MIDI_EnumSelCC(take, -1)
                if CC1 ~= -1 then
                    CC2 = reaper.MIDI_EnumSelCC(take, CC1)
                end
                
                if CC2 == -1 then
                    _, _, _, _, _, newChannel, _, _ = reaper.MIDI_GetCC(take, CC1)
                else
                    -- Search for notes using new MIDI_GetAllEVts function.
                    local gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
                    if gotAllOK then 
                        local posNote1 = MIDIstring:find(matchNoteOn, 1)
                        if posNote1 then
                            local posNote2 = MIDIstring:find(matchNoteOn, posNote1+1)
                            if not posNote2 then
                                newChannel = MIDIstring:byte(posNote1+5)&0x0F
                            end
                        end
                    end
                end
                        
                if newChannel then
                    local defaultChannel = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")
                    if newChannel ~= defaultChannel then
                        reaper.MIDIEditor_OnCommand(editor, 40482+newChannel)
                    end
                end
                
            end -- if take ~= pevTake or hash ~= prevHash
        end -- if reaper.ValidatePtr(take, "MediaItem_Take*")
    end -- if editor ~= nil

    reaper.runloop(loopGetSetChannel)
end -- function loop GetSetChannel

--------------------------------------------------------------------
-- Here the code execution starts
--------------------------------------------------------------------
-- function main()

-- Check whether the required version of REAPER is available
if not reaper.APIExists("MIDI_GetAllEvts") then
    reaper.ShowMessageBox("This script requires REAPER v5.30 or higher.", "ERROR", 0)
    return(false)
end

reaper.atexit(exit)

-- Activate toolbar button when starting
_, _, sectionID, ownCommandID, _, _, _ = reaper.get_action_context()
if not (sectionID == nil or ownCommandID == nil or sectionID == -1 or ownCommandID == -1) then
    reaper.SetToggleCommandState(sectionID, ownCommandID, 1)
    reaper.RefreshToolbar2(sectionID, ownCommandID)
end

reaper.runloop(loopGetSetChannel)
