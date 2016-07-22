--[[
 * ReaScript Name:  js_Option - Switching active take sets channel for new events to channel of existing events.lua
 * Description: Inserting events in the wrong MIDI channel is an all-too-easy mistake to make, particularly after 
 *                  switching the active track. If this option is activated, the default MIDI channel for new events  
 *                  will automatically be set to the channel of existing MIDI events in the newly active track, 
 *                  whenever the active take is switched. 
 *              If the existing MIDI events in the track use more than one channel, the default channel will be set
 *                  one of these channels, usually - but not always - the channel of the very first event in the take.
 *
 *              To find the channel, the script will first search through the newly active take itself to find
 *                  MIDI events with usable channel info.  If no such MIDI events are found (for example
 *                  if the take is empty) the script will search through other takes in the same track.
 *              If no MIDI events are found anywhere in the track, the script will check whether the track 
 *                  has any MIDI sends, and will use the MIDI send channel of the sends, if any.
 *              (Therefore, by setting a MIDI send channel before drawing new MIDI events in the track, the send
 *                  channel will act as the default channel for MIDI events in the track.) 
 *                
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
 * Version: 1.11
 * REAPER: 5.20
 * Extensions: 
]]
 
--[[
 Changelog:
 * v1.0 (2016-07-15)
    + Initial release
 * v1.01 (2016-07-17)
    + Additional tests to verify REAPER's channel values
 * v1.10 (2016-07-18)
    + Compatible with multi-item tracks
    + Use MIDI send channel as default channel if no MIDI events are found
 * v1.11 (2016-07-22)
    + Implement workaround for bug in MIDIEditor_GetTake
    + Prevent sysex messages from confusing channel detector
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


------------------------------------
function getEventChannelOfTake(take)
    -- This function returns the channel of the first note or CC in the take.
    -- Note that sysex events do not carry channel info, so these events must be ignored, and
    --     the function cannot simply use the first *event* with index 0.
    -- The function assumes that the note or CC indexing will never skip index 0.
    
    if not reaper.ValidatePtr(take, "MediaItem_Take*") then return(-1) end
    
    local noteOK, _, _, notePPQ, _, noteChannel, _, _ = reaper.MIDI_GetNote(take, 0)
    local ccOK, _, _, ccPPQ, _, ccChannel, _, _ = reaper.MIDI_GetCC(take, 0)
    
    -- Just make sure REAPER returned valid values
    if type(noteOK)~="boolean" or type(notePPQ)~="number" or type(noteChannel)~="number" then
        noteOK = false
    elseif (noteChannel%1)~=0 or noteChannel<0 or noteChannel>15 then
        noteOK = false
    end
    
    if type(ccOK)~="boolean" or type(ccPPQ)~="number" or type(ccChannel)~="number" then
        ccOK = false
    elseif (ccChannel%1)~=0 or ccChannel<0 or ccChannel>15 then
        ccOK = false
    end
    
    -- Compare PPQs to find return channel of first event
    if noteOK and ccOK then
        if notePPQ <= ccPPQ then return noteChannel else return ccChannel end
    elseif noteOK and not ccOK then
        return noteChannel
    elseif ccOK and not noteOK then
        return ccChannel
    else -- noteOK==false and ccOK==false
        return(-1)
    end
    
end -- function getEventChannelOfTake


-------------------------------------------------------------
-- The function that will continuously loop in the background
function loopGetSetTakeChannel()
    local editor = reaper.MIDIEditor_GetActive()
    if editor ~= nil then 
        local take = reaper.MIDIEditor_GetTake(editor)
        if reaper.ValidatePtr(take, "MediaItem_Take*") and tableTakes[editor] ~= take then -- Is it a new take in editor?
            tableTakes[editor] = take
            
            -- Firstly, check whether there are MIDI events with usable channel info in the new take itself
            local channel = getEventChannelOfTake(take)
            if channel ~= -1 then            
                reaper.MIDIEditor_OnCommand(editor, 40482+channel) -- Set channel for new events to 0+channel
                goto done
            end
            
            -- If no usable MIDI events could be found in new take, the function will now begin searching through
            --    other takes in the track, as well as the track's MIDI sends
            
            -- First check that a valid item and track can be found
            local item = reaper.GetMediaItemTake_Item(take)
            if reaper.ValidatePtr(item, "MediaItem*") then
                local track = reaper.GetMediaItem_Track(item)
                if reaper.ValidatePtr(track, "MediaTrack*") then
            
                    -- To avoid duplicating searches, all takes that have already been searched will be 
                    --    stored in tableSearchedTakes.
                    local tableSearchedTakes = nil
                    local tableSearchedTakes = {} 
                    tableSearchedTakes[take] = true
                    
                    -- Iterate through all takes within item
                    for takeIndex = 0, reaper.CountTakes(item) - 1 do
                        take = reaper.GetTake(item, takeIndex)
                        if tableSearchedTakes[take] == nil and reaper.TakeIsMIDI(take) then 
                            tableSearchedTakes[take] = true
                            channel = getEventChannelOfTake(take)
                            if channel ~= -1 then            
                                reaper.MIDIEditor_OnCommand(editor, 40482+channel) -- Set channel for new events to 0+channel
                                goto done
                    end end end                            
                    
                    -- Iterate through all items within the track
                    local skipThisItem = item
                    for itemIndex = 0, reaper.CountTrackMediaItems(track) - 1 do
                        item = reaper.GetTrackMediaItem(track, itemIndex)
                        if item ~= skipThisItem and reaper.ValidatePtr(item, "MediaItem*") then
                            for takeIndex = 0, reaper.CountTakes(item) - 1 do
                                take = reaper.GetTake(item, takeIndex)
                                if tableSearchedTakes[take] == nil and reaper.TakeIsMIDI(take) then 
                                    tableSearchedTakes[take] = true
                                    channel = getEventChannelOfTake(take)
                                    if channel ~= -1 then            
                                        reaper.MIDIEditor_OnCommand(editor, 40482+channel) -- Set channel for new events to 0+channel
                                        goto done
                    end end end end end
                    
                    -- NOTE: REAPER's track send channels use the range 1-16, whereas the event channels use range 0-15.
                    
                    -- Iterate through all internal track sends
                    for sendIndex = 0, reaper.GetTrackNumSends(track, 0) - 1 do
                        -- I_MIDIFLAGS : returns int *, low 5 bits=source channel 0=all, 1-16, 
                        --     next 5 bits=dest channel, 0=orig, 1-16=chan.
                        -- The following line gets the send's "MIDIFLAGS" and shifts bits 6-10 to 1-5
                        channel = ((reaper.GetTrackSendInfo_Value(track, 0, sendIndex, "I_MIDIFLAGS")) >> 5) & 0x1F -- 0x1F = b11111
                        if channel >= 1 and channel <= 16 then
                            reaper.MIDIEditor_OnCommand(editor, 40482+channel-1) -- Set channel for new events to 0+channel-1
                            goto done
                    end end
                    
                    -- And finally, check hardware MIDI output channel
                    -- I_MIDIHWOUT : int * : track midi hardware output index (<0 for disabled, 
                    --     low 5 bits are which channels (0=all, 1-16), 
                    --     next 5 bits are output device index (0-31))
                    channel = (reaper.GetMediaTrackInfo_Value(track, "I_MIDIHWOUT")) & 0x1F
                    if channel >= 1 and channel <= 16 then 
                        reaper.MIDIEditor_OnCommand(editor, 40482+channel-1) -- Set channel for new events to 0+channel-1
                        goto done
                    end
            
                    -- If no MIDI channel could be found, do nothing...

                end -- if reaper.ValidatePtr(track, "MediaTrack*")
            end -- if reaper.ValidatePtr(item, "MediaItem*")     
        end -- if reaper.ValidatePtr(take, "MediaItem_Take*") and tableTakes[editor] ~= take   
    end -- if editor ~= nil
    
    ::done::
    reaper.runloop(loopGetSetTakeChannel)
end -- function loop GetSetTakeChannel

--------------------------------------------------------------------
-- Here the code execution starts
--------------------------------------------------------------------
-- function main()

-- This script should not create an undo point, so
function preventUndo()
end
reaper.defer(preventUndo)

reaper.atexit(exit)

-- Activate toolbar button when starting
_, _, sectionID, ownCommandID, _, _, _ = reaper.get_action_context()
if not (sectionID == nil or ownCommandID == nil or sectionID == -1 or ownCommandID == -1) then
    reaper.SetToggleCommandState(sectionID, ownCommandID, 1)
    reaper.RefreshToolbar2(sectionID, ownCommandID)
end

loopGetSetTakeChannel()
