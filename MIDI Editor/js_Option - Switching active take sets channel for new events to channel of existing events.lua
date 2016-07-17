--[[
 * ReaScript Name:  js_Option - Switching active take sets channel for new events to channel of existing events.lua
 * Description: Inserting events in the wrong MIDI channel is an all-too-easy mistake to make, particularly after 
 *                  switching the active track. If this option is activated, the default MIDI channel for new events  
 *                  will automatically be set to the channel of existing MIDI events in the newly active track, 
 *                  whenever the active track is switched. 
 *              If the existing MIDI events in the track use more than one channel, the default channel will be set
 *                  one of these channels, usually - but not always - the channel of the very first event in the take.
 * Instructions: This script can be linked to a toolbar button for easy starting and stopping.
 *               While activated, the toolbar button will light up.
 *               (The first time that the script is stopped, REAPER will pop up a dialog box 
 *                    asking whether to terminate or restart the script.  Select "Terminate"
 *                    and "Remember my answer for this script".)
 * Screenshot: 
 * Notes: 
 * Category: 
 * Author: juliansader
 * Licence: GPL v3
 * Forum Thread: 
 * Forum Thread URL: http://forum.cockos.com/showthread.php?t=176878, http://forum.cockos.com/showthread.php?t=178256
 * Version: 1.01
 * REAPER: 5.20
 * Extensions: 
]]
 
--[[
 Changelog:
 * v1.0 (2016-07-15)
    + Initial release
 * v1.01 (2016-07-17)
    + Additional tests to verify REAPER's channel values
]]

tableTakes = {} -- The active take of each MIDI editor will be stored in this table

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
function loopGetSetTakeChannel()
    local editor = reaper.MIDIEditor_GetActive()
    if editor ~= nil then 
        local take = reaper.MIDIEditor_GetTake(editor)
        if take ~= nil and tableTakes[editor] ~= take then
            tableTakes[editor] = take
            -- Strangely, if using MIDI_GetEvt, REAPER sometimes returns a msg that is simply a blank string "",
            --    or sometimes other weird strings with event types = 0, etc.
            -- Therefore search through 50 events or until an event is found with usable channel info
            --    or until no event is found at index.
            local index = 0
            local returnOK, msg
            repeat
                returnOK, _, _, _, msg = reaper.MIDI_GetEvt(take, index, true, true, 0, "")
                index = index + 1
            until returnOK == false 
                  or index > 50 -- Don't search more than 50 events
                  or (returnOK == true 
                      and type(msg) == "string" 
                      and msg ~= ""
                      and msg:len() == 3 
                      and ((tonumber(string.byte(msg:sub(1,1))))>>4) >= 8 -- MIDI event types are >= 8.  REAPER sometimes returns a 0.
                     )                    

            if not (returnOK == false or index > 50) then
                local newChannel = (tonumber(string.byte(msg:sub(1,1))))&15
                reaper.MIDIEditor_OnCommand(editor, 40482+newChannel) -- Set channel for new events to 0+newChannel
            end
        end
    end
    reaper.runloop(loopGetSetTakeChannel)
end -- function loop GetSetTakeChannel

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

reaper.runloop(loopGetSetTakeChannel)
