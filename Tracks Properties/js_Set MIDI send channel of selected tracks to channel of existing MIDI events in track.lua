--[[
 * ReaScript Name:  js_Set MIDI send channel of selected tracks to channel of existing MIDI events in track.lua
 * Description:  Sets MIDI send channel of selected tracks to channel of existing MIDI events in track.
 *               Particularly useful when opening large MIDI files, to ensure that each track's MIDI is 1) sent to a 
 *                  single channel, and 2) sent to a different channel than other tracks' MIDI.
 *
 *               If the existing MIDI events in the track use more than one channel, the track's send channel
 *                  will be set to the channel of the first event in the track.
 *
 *               The script starts with a dialog box in which the user can select whether to remove audio sends 
 *                  from the selected tracks, which makes the routing matrix easier to read.
 *               
 *               HINT: The following two scripts are useful for setting up the track names of MIDI files:
 *                  "X-Raym_Rename tracks with first VSTi and its preset name.lua"
 *                  "spk77_Rename tracks after first program change (for General MIDI).eel"
 * Instructions:
 * Screenshot: 
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
    + Initial Release
]]

-- USER AREA
-- Settings that the user can customize

-- End of USER AREA

----------------------------------------
function setTrackChannel(track, channel)
-- WARNING: This function uses channel numbers 1-16, NOT 0-15, since REAPER's own functions for
--    setting track channels use this range.

    -- Note:
    -- MIDI hardware cannot be accessed via GetTrackNumSends(selTrack, 1)!
    -- 1) Do MIDI hardware output not count as "hardware outputs"?
    -- 2) Does REAPER only allow a single MIDI hardware output?
    
    if type(channel) ~= "number" or channel%1 ~= 0 or channel < 1 or channel > 16 then return end
    
    -- Iterate through all internal track sends
    for sendIndex = 0, reaper.GetTrackNumSends(track, 0) - 1 do
        MIDIflags = reaper.GetTrackSendInfo_Value(track, 0, sendIndex, "I_MIDIFLAGS")
        -- I_MIDIFLAGS : returns int *, low 5 bits=source channel 0=all, 1-16, 
        --     next 5 bits=dest channel, 0=orig, 1-16=chan.
        -- The following sets orig (bits 1-5) to "all" and inserts channel into bits 6-10.
        -- 0xFFFFFC00 = b1111 1111 1111 1111 1111 1100 0000 0000
        MIDIflags = (MIDIflags & 0xFFFFFC00)
        MIDIflags = MIDIflags | (channel << 5)
        -- SetTrackSendInfo_Value(MediaTrack tr, int category, int sendidx, "parmname", newvalue)
        -- category is <0 for receives, 0=sends, >0 for hardware outputs
        reaper.SetTrackSendInfo_Value(track, 0, sendIndex, "I_MIDIFLAGS", MIDIflags)
        
        -- Remove audio sends (I_SRCCHAN : -1 for none)
        if removeAudio == "y" or removeAudio == "Y" then
            reaper.SetTrackSendInfo_Value(track, 0, sendIndex, "I_SRCCHAN", -1)
            reaper.SetMediaTrackInfo_Value(track, "B_MAINSEND", 0)
        end
    end
    
    -- Set MIDI hardware output channel
    MIDIflags = reaper.GetMediaTrackInfo_Value(track, "I_MIDIHWOUT")
    -- I_MIDIHWOUT : int * : track midi hardware output index (<0 for disabled, 
    --     low 5 bits are which channels (0=all, 1-16), 
    --     next 5 bits are output device index (0-31))
    -- 0xFFFFFFE0 = b1111 1111 1111 1111 1111 1111 1110 0000
    MIDIflags = MIDIflags & 4294967264
    MIDIflags = MIDIflags | channel
    reaper.SetMediaTrackInfo_Value(track, "I_MIDIHWOUT", MIDIflags)
                 
end -- function setTrackChannel


-----------------------------------------------------------------------------
-- Here the code execution starts
-----------------------------------------------------------------------------
-- function main()

-- Is there anything to do?
if reaper.CountSelectedTracks(0) == 0
    then return(0) 
end

--------------------------
-- Get user inputs
--------------------------

-- Repeat until we get usable inputs
repeat
    OKorCancel, removeAudio = reaper.GetUserInputs("Set MIDI send channels", 
                                                 1, 
                                                 "Remove audio sends? (y/n)", 
                                                 "y")
until OKorCancel == false or (OKorCancel == true and (removeAudio == "y" or removeAudio == "Y" or removeAudio == "n" or removeAudio == "N"))

if OKorCancel == false then 
    return(0) 
end

------------------------------------------------------
-- Now find MIDI events inside track
------------------------------------------------------
   
-- Iterate through all selected tracks
for trackIndex = 0, reaper.CountSelectedTracks(0) - 1 do
    curTrack = reaper.GetSelectedTrack(0, trackIndex)
    
    -- Iterate through all items within the track to find MIDI events
    for itemIndex = 0, reaper.CountTrackMediaItems(curTrack) - 1 do
        curItem = reaper.GetTrackMediaItem(curTrack, itemIndex)
        
        -- Iterate through all takes within item
        for takeIndex = 0, reaper.CountTakes(curItem) - 1 do
            curTake = reaper.GetTake(curItem, takeIndex)
            
            if reaper.TakeIsMIDI(curTake) then
            
                -- Iterate through all events within take until one with usable channel info is found
                eventIndex = 0
                repeat
                    returnOK, _, _, _, msg = reaper.MIDI_GetEvt(curTake, eventIndex, true, true, 0, "")
                    eventIndex = eventIndex + 1
                until returnOK == false or (returnOK == true and type(msg) == "string" and msg ~= "")
                
                if returnOK == true then
                    -- REAPER's functions for track channels use channel range 1-16, NOT 0-15, therefore add 1
                    setTrackChannel(curTrack, 1 + ((tonumber(string.byte(msg:sub(1,1))))&15))
                    goto gotChannelForTrack
                end
            end
        
        end -- for takeIndex
    end -- for itemIndex
    
    ::gotChannelForTrack::
end -- for trackIndex
