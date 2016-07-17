--[[
 * ReaScript Name:  js_Option - Selecting single note or CC in active take sets channel for new events.lua
 * Description: Inserting events in the wrong channel is an all-too-easy mistake to make, particularly after 
 *                  switching the active track. With this new option, the user can switch to the correct 
 *                  channel by simply clicking a note or CC of the new track. 
 *              It is intended to be similar to the built-in action "Option: Drawing or selecting 
 *                  a note sets the new note length" (but for channel instead of note length).
 *              WARNING:  This script causes the folowing artefacts:
 *                  ~ If an event in a *new* channel is selected by left-clicking on the event, 
 *                    the event can not be edited immediately; instead, the mouse button must be released first.
 *                  ~ While this script is running, it will interact with the manual settings of the MIDI editor's 
 *                    channel filter dropdown menu.
 * Instructions: This script can be linked to a toolbar button for easy starting and stopping.
 *               While activated, the toolbar button will light up.
 *               (The first time that the script is stopped, REAPER will pop up a dialog box 
 *                    asking whether to terminate or restart the script.  Select "Terminate"
 *                    and "Remember my answer for this script".) * Screenshot: 
 * Notes: 
 * Category: 
 * Author: juliansader
 * Licence: GPL v3
 * Forum Thread: 
 * Forum Thread URL: http://forum.cockos.com/showthread.php?t=176878, http://forum.cockos.com/showthread.php?t=178256
 * Version: 1.0
 * REAPER: 5.20
 * Extensions:
]]
 
--[[
 Changelog:
 * v1.0 (2016-07-15)
    + Initial release
]]

prevChannel = 0

---------------
function exit()
    -- Deactivate toolbar button when exiting
    _, _, sectionID, ownCommandID, _, _, _ = reaper.get_action_context()
    if not (sectionID == nil or ownCommandID == nil or sectionID == -1 or ownCommandID == -1) then
        reaper.SetToggleCommandState(sectionID, ownCommandID, 0)
        reaper.RefreshToolbar2(sectionID, ownCommandID)
    end
end -- function exit

----------------------------
function loopGetSetChannel()
    local editor = reaper.MIDIEditor_GetActive()
    if editor ~= nil then 
        local take = reaper.MIDIEditor_GetTake(editor)
        if take ~= nil then
            --[[
            -- The following code does not limit selection to a single note or CC:
            local firstSelectedIndex = reaper.MIDI_EnumSelEvts(take, -1)
            if firstSelectedIndex > -1 then
                local returnOK, _, _, _, msg = reaper.MIDI_GetEvt(take, firstSelectedIndex, true, true, 0, "")
                if returnOK == true and type(msg) == "string" and msg ~= "" then
                    local newChannel=(tonumber(string.byte(msg:sub(1,1))))&15
                    -- The following action causes artefacts in the MIDI editor if called while editing with mouse, 
                    --    so should only be called once when channel changes
                    if newChannel ~= prevChannel then
                        reaper.MIDIEditor_OnCommand(editor, 40482+newChannel)
                        prevChannel = newChannel
                    end
                end
            end
            ]]
            
            -- Check whether number of selected notes is exactly one
            local firstNote = reaper.MIDI_EnumSelNotes(take, -1)
            local secondNote = reaper.MIDI_EnumSelNotes(take, firstNote)
            if firstNote ~= -1 and secondNote == -1 then 
                local noteOK, _, _, newPPQstart, _, newChannel, newPitch, _ = reaper.MIDI_GetNote(take, firstNote)
                -- The selected note should only change the channel if it is a *newly* selected note, therefore
                --    check whether this note is different from previously selected note
                if noteOK == true and not (newPPQstart == prevPPQstart and newPitch == prevPitch and newChannel == prevChannel) then
                    prevPPQstart = newPPQstart; prevPitch = newPitch; prevChannel = newChannel
                    -- Check whether different from default channel
                    local defaultChannel = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")
                    if newChannel ~= defaultChannel then
                        reaper.MIDIEditor_OnCommand(editor, 40482+newChannel)
                    end
                end
                
            -- Number of selected notes is note not exactly one, so let's check if there is exactly one selected CC
            else
                local firstCC = reaper.MIDI_EnumSelCC(take, -1)
                local secondCC = reaper.MIDI_EnumSelCC(take, firstCC)
                if firstCC ~= -1 and secondCC == -1 then
                    local ccOK, _, _, newPPQ, _, newChannel, _, _ = reaper.MIDI_GetCC(take, firstCC)
                    -- The selected CC should only change the channel if it is a *newly* selected CC, therefore
                    --    check whether this CC is different from previously selected CC
                    if ccOK == true and not (newPPQ == prevPPQ and newChannel == prevChannel) then
                        prevPPQ = newPPQ; prevChannel = newChannel
                        -- Check whether different from default channel
                        local defaultChannel = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")
                        if newChannel ~= defaultChannel then
                            reaper.MIDIEditor_OnCommand(editor, 40482+newChannel)
                        end
                    end     
                end
            end
        end
    end
    reaper.runloop(loopGetSetChannel)
end -- function loop GetSetChannel

--------------------------------------------------------------------
-- Here the code execution starts
--------------------------------------------------------------------
-- function main()

reaper.atexit(exit)

-- Activate toolbar button when starting
_, _, sectionID, ownCommandID, _, _, _ = reaper.get_action_context()
if not (sectionID == nil or ownCommandID == nil or sectionID == -1 or ownCommandID == -1) then
    reaper.SetToggleCommandState(sectionID, ownCommandID, 1)
    reaper.RefreshToolbar2(sectionID, ownCommandID)
end

reaper.runloop(loopGetSetChannel)
