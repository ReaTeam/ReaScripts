--[[
 * ReaScript Name:  js_Autoincrement MIDI send channels of selected tracks
 * Description:  Autoincrements the MIDI send channels of selected tracks.
 *               Particularly useful when opening large MIDI files, to ensure that each track's MIDI is 1) sent to a 
 *                  single channel, and 2) sent to a different channel than other tracks' MIDI.
 *               The script starts with a dialog box in which the user can select the following:
 *                  - The starting channel from which to increment.
 *                  - Whether to skip channel 10, which is a dedicated percussion channel in the General MIDI standard.
 *                  - Whether to remove audio sends from the selected tracks, which makes the routing matrix easier to read.
 *               
 *               HINT: The following two scripts are useful for setting up the track names of MIDI files:
 *                  "X-Raym_Rename tracks with first VSTi and its preset name.lua"
 *                  "spk77_Rename tracks after first program change (for General MIDI).eel"
 * Instructions:
 * 
 * Screenshot: 
 * Notes: 
 * Category: 
 * Author: juliansader
 * Licence: GPL v3
 * Forum Thread:
 * Forum Thread URL: http://forum.cockos.com/showthread.php?t=176878
 * Version: 1.0
 * REAPER: 5.20
 * Extensions:
]]

--[[
 Changelog:
 * v1.0
    + Initial Release
]]

-- USER AREA
-- Settings that the user can customize

-- End of USER AREA

---------------------------
-- Is there anything to do?
numSelTracks = reaper.CountSelectedTracks(0)
if (numSelTracks == 0) 
    then return(0) 
end

---------------------------------------------------------------------
-- Part 1: Get user inputs (channel from which to start incrementing)
---------------------------------------------------------------------

-- Repeat until we get usable inputs
repeat
    retval, userInputsCSV = reaper.GetUserInputs("Autoincrement MIDI send channels", 
                                                 3, 
                                                 "Starting channel (1-16),Skip channel 10? (y/n),Remove audio sends? (y/n)", 
                                                 "1,y,y")
    if retval == false then
        return(0)
    else -- retval == true
        gotUserInputs = true -- temporary, will be changed to false if anything is wrong

        startChan, skip10, removeAudio = userInputsCSV:match("([^,]+),([^,]+),([^,]+)")
        
        startChan = tonumber(startChan)
        if startChan == nil or startChan < 1 or startChan > 16 then
            gotUserInputs = false
        end
        
        if skip10 ~= "y" and skip10 ~= "Y" and skip10 ~= "n" and skip10 ~= "N" then
            gotUserInputs = false 
        end
        
        if removeAudio ~= "y" and removeAudio ~= "Y" and removeAudio ~= "n" and removeAudio ~= "N" then
            gotUserInputs = false 
        end
    end
until gotUserInputs == true


------------------------------------------------------
-- Now autoincrement all MIDI sends of selected tracks
------------------------------------------------------

-- Note:
-- MIDI hardware cannot be accessed via GetTrackNumSends(selTrack, 1)!
-- 1) Do MIDI hardware output not count as "hardware outputs"?
-- 2) Does REAPER only allow a single MIDI hardware output?
   
-- Iterate through all selected tracks
chan = startChan
for trackIndex = 0, numSelTracks-1 do
     selTrack = reaper.GetSelectedTrack(0, trackIndex);
     
     -- Iterate through all internal track sends
     for sendIndex = 0, reaper.GetTrackNumSends(selTrack, 0)-1 do
          MIDIflags = reaper.GetTrackSendInfo_Value(selTrack, 0, sendIndex, "I_MIDIFLAGS")
          -- I_MIDIFLAGS : returns int *, low 5 bits=source channel 0=all, 1-16, 
          --     next 5 bits=dest channel, 0=orig, 1-16=chan
          -- 4294966303 = b11111111111111111111110000011111
          MIDIflags = (MIDIflags & 4294966303)
          MIDIflags = MIDIflags | (chan << 5)
          -- SetTrackSendInfo_Value(MediaTrack tr, int category, int sendidx, "parmname", newvalue)
          -- category is <0 for receives, 0=sends, >0 for hardware outputs
          reaper.SetTrackSendInfo_Value(selTrack, 0, sendIndex, "I_MIDIFLAGS", MIDIflags)
          
          -- Remove audio sends (I_SRCCHAN : -1 for none)
          if removeAudio == "y" or removeAudio == "Y" then
              reaper.SetTrackSendInfo_Value(selTrack, 0, sendIndex, "I_SRCCHAN", -1)
          end
     end
     
     -- Set MIDI hardware output channel
     MIDIflags = reaper.GetMediaTrackInfo_Value(selTrack, "I_MIDIHWOUT")
     -- I_MIDIHWOUT : int * : track midi hardware output index (<0 for disabled, 
     --     low 5 bits are which channels (0=all, 1-16), 
     --     next 5 bits are output device index (0-31))
     -- 4294967264 = b11111111111111111111111111100000
     MIDIflags = MIDIflags & 4294967264
     MIDIflags = MIDIflags | chan
     reaper.SetMediaTrackInfo_Value(selTrack, "I_MIDIHWOUT", MIDIflags)
         
     -- Increment channel and skip channel 10 if user so selected
     if chan == 16 then chan = 1 else chan = chan + 1 end
     if chan == 10 and (skip10 == "Y" or skip10 == "y") then chan = chan + 1 end

end -- for trackIndex = 0, numSelTracks-1

