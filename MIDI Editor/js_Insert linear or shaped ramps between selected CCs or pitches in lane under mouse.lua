--[[
ReaScript name:  js_Insert linear or shaped ramps between selected CCs or pitches in lane under mouse.lua
Version: 3.01
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Screenshot: http://stash.reaper.fm/27617/Insert%20linear%20or%20shaped%20ramps%20between%20selected%20CCs%20or%20pitches%20in%20lane%20under%20mouse%20-%20Copy.gif
REAPER version: 5.32 or later
Extensions: SWS/S&M 2.8.3 or later
Donation: https://www.paypal.me/juliansader
About: 
  # Description

  Useful for quickly adding ramps between 'nodes'.

  Useful for smoothing transitions between CCs that were drawn at low resolution.

  The script starts with a dialog box in which the user can set:
  - the lane to use ("under mouse" at start of script, or "last clicked")
  - the CC density (using either the MIDI editor's grid or the default value in Preferences -> CC density), 
  - the shape of the ramp (as a sine, linear or power function),
  - whether the new events should be selected, and
  - whether redundant events should be skipped.

  (Any extraneous CCs between selected events are deleted)
      
  In the velocity lane, the script will not insert new notes, but will set velocities of existing notes to ramp from leftmost and rightmost notes.

  # Instructions

  For faster one-click execution, skip the dialog box by setting "showDialogBox" to "false" in the USER AREA.

  The default ramp properties can also be defined in the USER AREA.

  Combine with warping script to easily insert all kinds of weird shapes.

  There are two ways in which this script can be run:  
  1) First, the script can be linked to its own shortcut key.
  2) Second, this script, together with other "js_" scripts that edit the "lane under mouse",can each be linked to a toolbar button.  
    - In this case, each script need not be linked to its own shortcut key.  Instead, only the 
      accompanying "js_Run the js_'lane under mouse' script that is selected in toolbar.lua"
      script needs to be linked to a keyboard shortcut (as well as a mousewheel shortcut).
    - Clicking the toolbar button will 'arm' the linked script (and the button will light up), 
      and this selected (armed) script can then be run by using the shortcut for the 
      aforementioned "js_Run..." script.
    - For further instructions - please refer to the "js_Run..." script. 
]] 

--[[
 Changelog:
  * v1.0 (2016-05-15)
    + Initial Release.
  * v1.1 (2016-05-18)
    + Added compatibility with SWS versions other than 2.8.3 (still compatible with v2.8.3).
  * v1.11 (2016-05-29)
    + Script does not fail when "Zoom dependent" CC density is selected in Preferences.
  * v1.12 (2016-06-08)
    + New options in USER AREA to define default shape and/or to skip dialog box.
    + More extensive error messages.
  * v1.13 (2016-06-13)
    + New shape, "sine".
  * v1.14 (2016-06-13)
    + Fixed deletion bug when inserting 14bit CC ramps.
  * v2.0 (2016-07-04)
    + All the "lane under mouse" js_ scripts can now be linked to toolbar buttons and run using a single shortcut.
    + Description and instructions are included inside script - please read with REAPER's built-in script editor.
  * v3.00 (2016-12-25)
    + Script will work in inline editor.
    + Script will work in looped takes.
    + Script will work with multiple channel (each channel will be ramped separately).
    + Much faster execution, particularly in takes with many thousands of MIDI events.
    + Requires REAPER v5.32 or later.
    + In velocity lane, will set velocities of existing notes to ramp from leftmost and rightmost notes.
  * v3.01 (2017-01-20)
    + Fixed bug when custom 'shape' is number.
  * v3.02 (2017-03-13)
    + In Tempo track, insert CCs (tempos) at MIDI editor grid spacing.  
]] 

-- USER AREA
-- (Settings that the user can customize)

showDialogBox = true -- Should the dialog box be skipped and default values used?  true or false.

-- If laneToUse = "under mouse", the script can be controlled by the js_Run master script, 
--    and can also be used in the inline editor.
laneToUse = "under mouse" -- "under mouse" or "last clicked"

-- Default values for ramp shape:
shape = "s" -- Shape of the ramp.  Either "sine" (or "s"), or a number > 0 for a power curve (1 implies linear).
CCdensity = "p" -- "g" or "p". "g" uses the MIDI editor's current grid settings, whereas "p" uses the default CC density set in REAPER's Preferences -> MIDI editor -> Events per quarter note when drawing in CC lanes.
skipRedundantCCs = true -- Should redundant CCs be skipped?  true or false.
newCCsAreSelected = true -- Should the newly inserted CCs be selected?  true or false.


-- End of USER AREA
--------------------------------------------------------------------





-- ################################################################################################
---------------------------------------------------------------------------------------------------
-- CONSTANTS AND VARIABLES (that modders may find useful)

--[[ General notes:

Speed:
REAPER's MIDI API functions such as InsertCC and SetCC are very slow if the active take contains 
    hundreds of thousands of MIDI events.  
Therefore, this script will not use these functions, and will instead directly access the item's 
    raw MIDI stream via new functions that were introduced in v5.30: GetAllEvts and SetAllEvts.
Parsing of the MIDI stream can be relatively straightforward, but to improve speed even
    further, this script will use several 'tricks', which will unfortunately also make the 
    parsing function, parseAndExtractTargetMIDI, quite complicated.

Sorting:
Prior to v5.32, sorting of MIDI events, either by MIDI_Sort or by other functions such as MIDI_SetNote
    (with sort=true) was endlessly buggy (http://forum.cockos.com/showthread.php?t=184459
    is one of many threads).  In particular, it often mutated overlapping notes or unsorted notes into
    infinitely extende notes.
Finally, in v5.32, these bugs were (seemingly) all fixed.  This new version of the script will therefore
    use the MIDI_Sort function (instead of calling a MIDI editor action via OnCommand to induce sorting).

However, sorting is still relatively slow, so since MIDI will under normal circumstances already be 
    sorted when the script is run (the MIDI editor automatically sorts the data whenever any small edit
    is made), MIDI_Sort will not automatically be called when the script starts.  Instead, offsets will 
    be checked during parsing, and if any negative offsets are detected, MIDI_Sort will be called.
    It is actually faster to check for unsorted data during parsing.
]]

-- The raw MIDI data will be stored in the string.  While parsing the string, targeted events (the
--    ones that will be edited) will be removed from the string.
-- The offset of the first event will be stored separately - not in remainMIDIstring - since this offset 
--    will need to be updated in each cycle relative to the PPQ positions of the edited events.
local origMIDIstring -- The original raw MIDI
local remainMIDIstring -- The MIDI that remained after extracting selected events in the target lane

-- When the info of the targeted events is extracted, the info will be stored in several tables.
-- The order of events in the tables will reflect the order of events in the original MIDI, except note-offs, 
--    which will be replaced by note lengths, and notation text events, which will also be stored in a separate table
--    at the same indices as the corresponding notes.
local tableMsg = {}
local tableMsgLSB = {}
local tableValues = {} -- CC values, 14bit CC combined values, note velocities
local tablePPQs = {}
local tableChannels = {}
local tableFlags = {}
local tableFlagsLSB = {} -- In the case of 14bit CCs, mute/select status of the MSB
local tableSortedIndices = {} -- Instead of calling MIDI_Sort at the beginning of the script, the entries in this table will be the sorted indices.

-- Starting values and position of mouse 
-- Not all of these lanes will be used by all scripts.
-- targetLane: (CC0-127 = 7-bit CC, 0x100|(0-31) = 14-bit CC, 0x200 = velocity, 0x201 = pitch, 
--    0x202=program, 0x203=channel pressure, 0x204=bank/program select, 
--    0x205=text, 0x206=sysex, 0x207=off velocity)
local window, segment, details -- given by the SWS function reaper.BR_GetMouseCursorContext()
local laneIsCC7BIT    = false
local laneIsCC14BIT   = false
local laneIsPITCH     = false
local laneIsPROGRAM   = false
local laneIsBANKPROG  = false
local laneIsCHPRESS   = false
local laneIsVELOCITY  = false
local laneIsOFFVEL    = false
local laneIsPIANOROLL = false
local laneIsNOTES     = false -- Includes laneIsPIANOROLL, laneIsVELOCITY and laneIsOFFVEL
local laneIsSYSEX     = false
local laneIsTEXT      = false
local laneMin, laneMax -- The minimum and maximum values in the target lane
local targetLane

-- REAPER preferences and settings that will affect the drawing of new events in take
local isSnapEnabled = false -- Will be changed to true if snap-togrid is enabled in the editor
local defaultChannel -- In case new MIDI events will be inserted, what is the default channel?
local QNperCC -- CC density resolution, either MIDI editor grid or as set in Preferences -> MIDI editor -> "Events per quarter note when drawing in CC lanes"

-- New CCs will be inserted at grid positions. These variables will be useful
local PPperCC -- ticks per CC ** not necessarily an integer ** 
local PPQ -- ticks per quarter note
local firstCCinTakePPQpos -- CC spacing should not be calculated from PPQpos = 0, since take may not start on grid.

-- The source length when the script begins will be checked against the source length when the script ends,
--    to ensure that the script did not inadvertently shift the positions of non-target events.
local sourceLengthTicks -- = reaper.BR_GetMidiSourceLenPPQ(take)

-- Some internal stuff that will be used to set up everything
local _, item, take, editor, isInline

-- I am not sure that declaring functions local really helps to speed things up...
local s_unpack = string.unpack
local s_pack   = string.pack
local t_insert = table.insert -- myTable[i] = X is actually much faster than t_insert(myTable, X)
local m_floor  = math.floor
local m_cos    = math.cos
local m_pi     = math.pi

  

--####################################################################################
--------------------------------------------------------------------------------------
function findTargetCCvaluesAndPPQs()  
    
    -- REAPER v5.30 introduced new API functions for fast, mass edits of MIDI:
    --    MIDI_GetAllEvts and MIDI_SetAllEvts.
    --gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
    
    local MIDIlen = origMIDIstring:len()
    
    -- These functions are fast, but require complicated parsing of the MIDI string.
    -- The following tables with temporarily store data while parsing:
    local tableCCMSB = {} -- While waiting for matching LSB of 14-bit CC
    local tableCCLSB = {} -- While waiting for matching MSB of 14-bit CC
    for chan = 0, 15 do
        tableCCMSB[chan] = {}
        tableCCLSB[chan] = {}
    end
                   
    local runningPPQpos = 0 -- The MIDI string only provides the relative offsets of each event, sp the actual PPQ positions must be calculated by iterating through all events and adding their offsets
            
    local stringPos = 1 -- Keep record of position within MIDIstring. unchangedPos is position from which unchanged events van be copied in bulk.
    local c = 0
    
    ---------------------------------------------------------------------------------------------
    -- OK, got an upper limit.  Not iterate through MIDIstring, until the upper limit is reached.
    while stringPos < MIDIlen do
       
        local offset, flags, msg
        
        offset, flags, msg, stringPos = s_unpack("i4Bs4", origMIDIstring, stringPos)
      
        -- Check flag as simple test if parsing is still going OK
        if flags&252 ~= 0 then -- 252 = binary 11111100.
            reaper.ShowMessageBox("The MIDI data uses an unknown format that could not be parsed."
                                  .. "\n\nPlease report the problem in the thread http://forum.cockos.com/showthread.php?t=176878:"
                                  .. "\nFlags = " .. string.format("%02x", flags)
                                  , "ERROR", 0)
            return false
        end
        
        runningPPQpos = runningPPQpos + offset                 

        -- Only analyze *selected* events - as well as notation text events (which are always unselected)
        if flags&1 == 1 and msg:len() >= 2 then -- bit 1: selected
                          
            if laneIsCC7BIT then if msg:byte(2) == targetLane and (msg:byte(1))>>4 == 11
            then
                c = c + 1 
                tableValues[c] = msg:byte(3)
                tablePPQs[c] = runningPPQpos
                tableChannels[c] = msg:byte(1)&0x0F
                tableFlags[c] = flags
                end 
                                
            elseif laneIsPITCH then if (msg:byte(1))>>4 == 14
            then
                c = c + 1
                tableValues[c] = (msg:byte(3)<<7) + msg:byte(2)
                tablePPQs[c] = runningPPQpos
                tableChannels[c] = msg:byte(1)&0x0F
                tableFlags[c] = flags 
                end                           
                                    
            elseif laneIsCC14BIT then 
                if msg:byte(2) == targetLane-224 and (msg:byte(1))>>4 == 11 -- 14bit CC, only the LSB lane
                then
                    local channel = msg:byte(1)&0x0F
                    -- Has a corresponding LSB value already been saved?  If so, combine and save in tableValues.
                    if tableCCMSB[channel][runningPPQpos] then
                        c = c + 1
                        tableValues[c] = (((tableCCMSB[channel][runningPPQpos].message):byte(3))<<7) + msg:byte(3)
                        tablePPQs[c] = runningPPQpos
                        tableFlags[c] = tableCCMSB[channel][runningPPQpos].flags -- The MSB determines muting
                        tableFlagsLSB[c] = flags
                        tableChannels[c] = channel
                        tableCCMSB[channel][runningPPQpos] = nil -- delete record
                    else
                        tableCCLSB[channel][runningPPQpos] = {message = msg, flags = flags}
                    end
                        
                elseif msg:byte(2) == targetLane-256 and (msg:byte(1))>>4 == 11 -- 14bit CC, only the MSB lane
                then
                    local channel = msg:byte(1)&0x0F
                    -- Has a corresponding LSB value already been saved?  If so, combine and save in tableValues.
                    if tableCCLSB[channel][runningPPQpos] then
                        c = c + 1
                        tableValues[c] = (msg:byte(3)<<7) + (tableCCLSB[channel][runningPPQpos].message):byte(3)
                        tablePPQs[c] = runningPPQpos
                        tableFlags[c] = flags
                        tableChannels[c] = channel
                        tableFlagsLSB[c] = tableCCLSB[channel][runningPPQpos].flags
                        tableCCLSB[channel][runningPPQpos] = nil -- delete record
                    else
                        tableCCMSB[channel][runningPPQpos] = {message = msg, flags = flags}
                    end
                end
                
            elseif laneIsPROGRAM then if (msg:byte(1))>>4 == 12
            then
                c = c + 1
                tableValues[c] = msg:byte(2)
                tablePPQs[c] = runningPPQpos
                tableChannels[c] = msg:byte(1)&0x0F
                tableFlags[c] = flags
                end
                
            elseif laneIsCHPRESS then if (msg:byte(1))>>4 == 13
            then
                c = c + 1
                tableValues[c] = msg:byte(2)
                tablePPQs[c] = runningPPQpos
                tableChannels[c] = msg:byte(1)&0x0F
                tableFlags[c] = flags
                end
            end 
        
        end 
                            
    end -- while              
    
    -- Instead of calling the slow MIDI_Sort, the script will simply find the correct order of selected events itself
    -- The entries in this table will be the sorted indices in tablePPQs.
    tableSortedIndices = {}
    for i = 1, #tablePPQs do
        tableSortedIndices[i] = i
    end
    local function sortPPQs(a, b)
        if tablePPQs[a] < tablePPQs[b] then return true end
    end
    table.sort(tableSortedIndices, sortPPQs)
                        
    return true
                
end -- function findTargetCCvaluesAndPPQs

  
--##################################################################################
------------------------------------------------------------------------------------ 
-- The function that will
--    * parse notes in the MIDI string, 
--    * update velocities
--    * upload the string into take, and
--    * (re-sorting not necessary since velocity stuff will not change the order of events). 

function doVelocityStuff()

    local lastNotePPQpos, firstNotePPQpos = -math.huge, math.huge -- Store PPQ and velocity ranges
    local firstVelocity, lastVelocity
    local stringPos = 1 -- Position in MIDIstring while parsing
    local runningPPQpos = 0 -- PPQ position of event parsed
    local MIDIlen = origMIDIstring:len()
    local offset, flags, msg
    while stringPos < MIDIlen do
        offset, flags, msg, stringPos = s_unpack("i4Bs4", origMIDIstring, stringPos)
        runningPPQpos = runningPPQpos + offset
        if flags&1==1 and msg:len() == 3 then
            if msg:byte(1)>>4 == 9 and not (msg:byte(3) == 0) then
                if runningPPQpos < firstNotePPQpos then 
                    firstNotePPQpos = runningPPQpos 
                    firstVelocity   = msg:byte(3)
                end
                if runningPPQpos > lastNotePPQpos then 
                    lastNotePPQpos = runningPPQpos
                    lastVelocity   = msg:byte(3)
                end
            end
        end
    end
    local PPQrange = lastNotePPQpos - firstNotePPQpos
    if PPQrange > 0 then
        local lastStringPos = stringPos -- Don't need to parse again beyond this position
        local tableEvents = {}
        local t = 0
        local stringPos, prevPos, unchangedPos = 1, 1, 1 -- Position in MIDIstring
        local runningPPQpos = 0 -- PPQ position of event parsed
        local weight
        local velocityRange = lastVelocity - firstVelocity
        while stringPos < lastStringPos do
            prevPos = stringPos
            offset, flags, msg, stringPos = s_unpack("i4Bs4", origMIDIstring, stringPos)
            runningPPQpos = runningPPQpos + offset
            if flags&1==1 and msg:len() == 3 and msg:byte(1)>>4 == 9 and not (msg:byte(3) == 0) then    
                if type(shape) == "number" then
                    weight = ((runningPPQpos - firstNotePPQpos) / PPQrange)^shape
                else -- shape == "sine"
                    weight = (1 - math.cos(math.pi*(runningPPQpos - firstNotePPQpos) / PPQrange))/2
                end
                local newValue = math.floor(firstVelocity + velocityRange*weight + 0.5)
                if newValue > 127 then newValue = 127
                elseif newValue < 1 then newValue = 1
                end
                t = t + 1
                tableEvents[t] = origMIDIstring:sub(unchangedPos, prevPos-1)
                t = t + 1
                tableEvents[t] = string.pack("i4Bi4BBB", offset, flags, 3, msg:byte(1), msg:byte(2), newValue)
                unchangedPos = stringPos
                                                  
            end
        end
        
        tableEvents[t+1] = origMIDIstring:sub(unchangedPos)
        reaper.MIDI_SetAllEvts(take, table.concat(tableEvents))
    end
    
end -- doVelocityStuff()
    

--#########################################################################
---------------------------------------------------------------------------
-- The function that will
--    * parse CCs in the MIDI string, 
--    * insert new events, 
--    * upload the string into take, and
--    * re-sort the MIDI, in the case of CC stuff.

function doCCInsertStuff()

    if not findTargetCCvaluesAndPPQs() or #tablePPQs == 0 then
        return(false)
    end
          
    local tableNewEvents = {}
    local c = 0
    
    local newFlags
    if newCCsAreSelected then newFlags = 1 else newFlags = 0 end
    
    local lastPPQpos = 0
    
    -- First insert the original event, and then check whether any new events must be inserted between this and the next event in the same channel.
    for s, i in ipairs(tableSortedIndices) do 
        if laneIsCC7BIT then
            c = c + 1
            tableNewEvents[c] = s_pack("i4BI4BBB", tablePPQs[i]-lastPPQpos, tableFlags[i], 3, 0xB0 | tableChannels[i], targetLane, tableValues[i])
        elseif laneIsPITCH then
            c = c + 1
            tableNewEvents[c] = s_pack("i4BI4BBB", tablePPQs[i]-lastPPQpos, tableFlags[i], 3, 0xE0 | tableChannels[i], tableValues[i]&127, tableValues[i]>>7)
        elseif laneIsCHPRESS then
            c = c + 1
            tableNewEvents[c] = s_pack("i4BI4BB",  tablePPQs[i]-lastPPQpos, tableFlags[i], 2, 0xD0 | tableChannels[i], tableValues[i])
        elseif laneIsCC14BIT then
            c = c + 1
            tableNewEvents[c] = s_pack("i4BI4BBB", tablePPQs[i]-lastPPQpos, tableFlags[i], 3, 0xB0 | tableChannels[i], targetLane-256, tableValues[i]>>7)
            c = c + 1
            tableNewEvents[c] = s_pack("i4BI4BBB", 0, tableFlagsLSB[i], 3, 0xB0 | tableChannels[i], targetLane-224, tableValues[i]&127)
        elseif laneIsPROGRAM then
            c = c + 1
            tableNewEvents[c] = s_pack("i4BI4BB",  tablePPQs[i]-lastPPQpos, tableFlags[i], 2, 0xC0 | tableChannels[i], tableValues[i])
        end
        lastValue = insertValue
        lastPPQpos = tablePPQs[i]
        
        -- Find next event in same channel
        for a = s+1, #tableSortedIndices do 
            z = tableSortedIndices[a]
            if tableChannels[z] == tableChannels[i] then
                nextValue = tableValues[z]
                nextPPQ   = tablePPQs[z]
                
                local nextCCdensityPPQpos = firstCCinTakePPQpos + PPperCC * math.ceil((tablePPQs[i]+1-firstCCinTakePPQpos)/PPperCC)
                for PPQpos = nextCCdensityPPQpos, nextPPQ-1, PPperCC do
                    PPQround = m_floor(PPQpos + 0.5)
                    if type(shape) == "number" then
                        weight = ((PPQround - tablePPQs[i]) / (nextPPQ - tablePPQs[i]))^shape
                    else -- shape == "sine"
                        weight = (1 - m_cos(m_pi*(PPQround - tablePPQs[i]) / (nextPPQ - tablePPQs[i])))/2
                    end
                    insertValue = tableValues[i] + (nextValue - tableValues[i])*weight
                    if insertValue > laneMax then insertValue = laneMax
                    elseif insertValue < laneMin then insertValue = laneMin
                    else insertValue = m_floor(insertValue + 0.5)
                    end
                    -- If redundant, skip insertion
                    if not (skipRedundantCCs == true and insertValue == lastValue) then
                        if laneIsCC7BIT then
                            c = c + 1
                            tableNewEvents[c] = s_pack("i4BI4BBB", PPQround-lastPPQpos, newFlags, 3, 0xB0 | tableChannels[i], targetLane, insertValue)
                        elseif laneIsPITCH then
                            c = c + 1
                            tableNewEvents[c] = s_pack("i4BI4BBB", PPQround-lastPPQpos, newFlags, 3, 0xE0 | tableChannels[i], insertValue&127, insertValue>>7)
                        elseif laneIsCHPRESS then
                            c = c + 1
                            tableNewEvents[c] = s_pack("i4BI4BB",  PPQround-lastPPQpos, newFlags, 2, 0xD0 | tableChannels[i], insertValue)
                        elseif laneIsCC14BIT then
                            c = c + 1
                            tableNewEvents[c] = s_pack("i4BI4BBB", PPQround-lastPPQpos, newFlags, 3, 0xB0 | tableChannels[i], targetLane-256, insertValue>>7)
                            c = c + 1
                            tableNewEvents[c] = s_pack("i4BI4BBB", 0, newFlags, 3, 0xB0 | tableChannels[i], targetLane-224, insertValue&127)
                        elseif laneIsPROGRAM then
                            c = c + 1
                            tableNewEvents[c] = s_pack("i4BI4BB",  PPQround-lastPPQpos, newFlags, 2, 0xC0 | tableChannels[i], insertValue)    
                        end
                        lastValue = insertValue
                        lastPPQpos = PPQround
                    end -- if not (skipRedundantCCs == true and insertValue == prevCCvalue)
                end -- for PPQpos = nextCCdensityPPQpos, nextPPQ-1, PPperCC do
                     
                break
                   
            end -- if tableChannels[searchAheadIndex] == tableChannels[i] then
            
            
        end -- for searchAheadIndex = i+1, #tablePPQs do
    end -- for i = 1, #tablePPQs do
    
    -- In order to delete existing CCs in range, must get min and max PPQs for each channel
    local tableChannelPPQs = {}
    for chan = 0, 15 do
        tableChannelPPQs[chan] = {min = math.huge, max = -math.huge}
    end
    for i = 1, #tablePPQs do
        if tablePPQs[i] < tableChannelPPQs[tableChannels[i]].min then tableChannelPPQs[tableChannels[i]].min = tablePPQs[i] end
        if tablePPQs[i] > tableChannelPPQs[tableChannels[i]].max then tableChannelPPQs[tableChannels[i]].max = tablePPQs[i] end
    end
     
    -- Delete existing CCs in range and channel
    local tableRemainingEvents = {}
    local t = 0
    local stringPos, prevPos, unchangedPos = 1, 1, 1 -- Position in MIDIstring while parsing
    local runningPPQpos = 0 -- PPQ position of event parsed
    local MIDIlen = origMIDIstring:len()
    local offset, flags, msg, mustDelete
    
    while stringPos < MIDIlen do 
        prevPos = stringPos
        mustDelete = false
        offset, flags, msg, stringPos = s_unpack("i4Bs4", origMIDIstring, stringPos)
        runningPPQpos = runningPPQpos + offset
        if msg:len() > 1 then
            local channel = msg:byte(1)&0x0F
            if runningPPQpos >= tableChannelPPQs[channel].min and runningPPQpos <= tableChannelPPQs[channel].max then
                if laneIsCC7BIT       then if msg:byte(1)>>4 == 11 and msg:byte(2) == targetLane then mustDelete = true end
                elseif laneIsPITCH    then if msg:byte(1)>>4 == 14 then mustDelete = true end
                elseif laneIsCC14BIT  then if msg:byte(1)>>4 == 11 and (msg:byte(2) == targetLane-224 or msg:byte(2) == targetLane-256) then mustDelete = true end
                --elseif laneIsNOTES    then if msg:byte(1)>>4 == 8 or msg:byte(1)>>4 == 9 then mustDelete = true end
                elseif laneIsPROGRAM  then if msg:byte(1)>>4 == 12 then mustDelete = true end
                elseif laneIsCHPRESS  then if msg:byte(1)>>4 == 13 then mustDelete = true end
                end
            end
        end   
        if mustDelete then
            t = t + 1
            tableRemainingEvents[t] = origMIDIstring:sub(unchangedPos, prevPos-1)
            t = t + 1
            tableRemainingEvents[t] = s_pack("i4Bs4", offset, 0, "")
            unchangedPos = stringPos
        end
    end
        
    tableRemainingEvents[t+1] = origMIDIstring:sub(unchangedPos)
    local remainMIDIstring = table.concat(tableRemainingEvents)

    reaper.MIDI_SetAllEvts(take, table.concat(tableNewEvents) .. string.pack("i4", string.unpack("i4", remainMIDIstring, 1) - lastPPQpos) .. remainMIDIstring:sub(5))
    
    ------------------------------------------------------------------------------
    -- MIDI_Sort used to be buggy when dealing with overlapping or unsorted notes,
    --    causing infinitely extended notes or zero-length notes.
    -- Fortunately, these bugs were seemingly all fixed in v5.32.
    reaper.MIDI_Sort(take)  
    
end



--#############################################################################################
-----------------------------------------------------------------------------------------------
-- Set this script as the armed command that will be called by "js_Run the js action..." script
function setAsNewArmedToolbarAction()

    local tablePrevIDs, prevCommandIDs, prevSeparatorPos, nextSeparatorPos, prevID
    
    _, _, sectionID, ownCommandID, _, _, _ = reaper.get_action_context()
    if sectionID == nil or ownCommandID == nil or sectionID == -1 or ownCommandID == -1 then
        return(false)
    end
    
    tablePrevIDs = {}
    
    reaper.SetToggleCommandState(sectionID, ownCommandID, 1)
    reaper.RefreshToolbar2(sectionID, ownCommandID)
    
    if reaper.HasExtState("js_Mouse actions", "Previous commandIDs") then
        prevCommandIDs = reaper.GetExtState("js_Mouse actions", "Previous commandIDs")
        if type(prevCommandIDs) ~= "string" then
            reaper.DeleteExtState("js_Mouse actions", "Previous commandIDs", true)
        else
            prevSeparatorPos = 0
            repeat
                nextSeparatorPos = prevCommandIDs:find("|", prevSeparatorPos+1)
                if nextSeparatorPos ~= nil then
                    prevID = tonumber(prevCommandIDs:sub(prevSeparatorPos+1, nextSeparatorPos-1))
                    -- Is the stored number a valid (integer) commandID, and not own ID?
                    if type(prevID) == "number" and prevID%1 == 0 and prevID ~= ownCommandID then
                        table.insert(tablePrevIDs, prevID)
                    end
                    prevSeparatorPos = nextSeparatorPos
                end
            until nextSeparatorPos == nil
            for i = 1, #tablePrevIDs do
                reaper.SetToggleCommandState(sectionID, tablePrevIDs[i], 0)
                reaper.RefreshToolbar2(sectionID, tablePrevIDs[i])
            end
        end
    end
    
    prevCommandIDs = tostring(ownCommandID) .. "|"
    for i = 1, #tablePrevIDs do
        prevCommandIDs = prevCommandIDs .. tostring(tablePrevIDs[i]) .. "|"
    end
    reaper.SetExtState("js_Mouse actions", "Previous commandIDs", prevCommandIDs, false)
    
    reaper.SetExtState("js_Mouse actions", "Armed commandID", tostring(ownCommandID), false)
end



--#####################################################################################################
-------------------------------------------------------------------------------------------------------
-- Here execution starts!
-- function main()

-- Start with a trick to avoid automatically creating undo states if nothing actually happened
-- Undo_OnStateChange will only be used if reaper.atexit(onexit) has been executed
function avoidUndo()
end
reaper.defer(avoidUndo)


-------------------------------------------------------
-- Test whether user customizable variables are usable.
if not (shape == "sine" or shape == "s" or type(shape) == "number") or (type(shape)=="number" and shape <= 0) then 
    reaper.ShowMessageBox('The setting "shape" must either be "sine" or a number larger than 0.', "ERROR", 0) return(false) end
if type(skipRedundantCCs) ~= "boolean" then 
    reaper.ShowMessageBox("The setting 'skipRedundantCCs' must be either 'true' of 'false'.", "ERROR", 0) return(false) end
if type(newCCsAreSelected) ~= "boolean" then
    reaper.ShowMessageBox("The setting 'newCCsAreSelected' must be either 'true' of 'false'.", "ERROR", 0) return(false) end
if type(showDialogBox) ~= "boolean" then
    reaper.ShowMessageBox("The setting 'showDialogBox' must be either 'true' of 'false'.", "ERROR", 0) return(false) end
if not (CCdensity == "g" or CCdensity == "p") then
    reaper.ShowMessageBox('The setting "CCdensity" must be either "g" (to use the MIDI editor'.."'"..'s grid setting)'
                          .. ' or "p" to use the default CC density set in REAPER'.."'"..'s Preferences -> MIDI editor -> Events per quarter note when drawing in CC lanes.'
                          , "ERROR", 0) return(false) end          
if not (laneToUse == "under mouse" or laneToUse == "last clicked") then
    reaper.ShowMessageBox('The setting "laneToUse" must be either "under mouse" or "last clicked"', "ERROR", 0) return(false) end

--[[
---------------------------------------------------------------
-- Get original mouse position in pixel coordinates.
-- Later, once parsing is done (and the user has had a fraction
--    of a second to move the mouse), the new pixel coordinates
--    will be compared to these original coordinates to 
--    determines direction of warping.
local mouseXorig, mouseYorig = reaper.GetMousePosition()
]]


-------------------------------------------------------------
-- Check whether the required version of REAPER is available.
version = tonumber(reaper.GetAppVersion():match("(%d+%.%d+)"))
if version == nil or version < 5.32 then
    reaper.ShowMessageBox("This version of the script requires REAPER v5.32 or higher."
                          .. "\n\nOlder versions of the script will work in older versions of REAPER, but may be slow in takes with many thousands of events"
                          , "ERROR", 0)
    return(false)
end  


------------------------------------------------------------------------------------------
-- Get target lane, editor, etc.  
-- If laneToUse = "under mouse", the script can be controlled by the js_Run master script, 
--    and can also be used in the inline editor.
if laneToUse == "last clicked" then
    editor = reaper.MIDIEditor_GetActive()
    if editor == nil then 
        reaper.ShowMessageBox("No active MIDI editor found.", "ERROR", 0)
        return(false)
    end
    take = reaper.MIDIEditor_GetTake(editor)
    if not reaper.ValidatePtr(take, "MediaItem_Take*") then 
        reaper.ShowMessageBox("Could not find an active take in the MIDI editor.", "ERROR", 0)
        return(false)
    end
    targetLane = reaper.MIDIEditor_GetSetting_int(editor, "last_clicked_cc_lane")
    
    
else -- laneToUse == "under mouse"
    
    if not reaper.APIExists("BR_GetMouseCursorContext") then
        reaper.ShowMessageBox("This script requires the SWS/S&M extension.\n\nThe SWS/S&M extension can be downloaded from www.sws-extension.org.", "ERROR", 0)
        return(false) 
    end 
    
    -----------------------------------------------------------
    -- The following sections checks the position of the mouse:
    -- If the script is called from a toolbar, it arms the script as the default js_Run function, but does not run the script further
    -- If the mouse is positioned over a CC lane, the script is run.
    window, segment, details = reaper.BR_GetMouseCursorContext()
    -- If window == "unknown", assume to be called from floating toolbar
    -- If window == "midi_editor" and segment == "unknown", assume to be called from MIDI editor toolbar
    if window == "unknown" or (window == "midi_editor" and segment == "unknown") then
        setAsNewArmedToolbarAction()
        return(true) 
    elseif not (details == "cc_lane") then -- other scripts: or segment == "notes"
        reaper.ShowMessageBox("Mouse is not correctly positioned.\n\n"
                              .. "This script edits the MIDI events in the part of the MIDI editor that is under the mouse, "
                              .. "so the mouse should be positioned over a CC lane of an active MIDI editor.", "ERROR", 0) -- either ... or the 'notes area'
        return(false) 
    else
        -- This script does not run a loop in the background, so it can simply delete
        --    the extstate.  The other js functions do so in the exit() function.
        reaper.DeleteExtState("js_Mouse actions", "Status", true)
    end
    
    
    -----------------------------------------------------------------------------------------
    -- We know that the mouse is positioned over a MIDI editor.  Check whether inline or not.
    -- Also get the mouse starting (vertical) value and CC lane.
    -- mouseOrigPitch: note row or piano key under mouse cursor (0-127)
    -- targetLane: CC lane under mouse cursor (CC0-127=CC, 0x100|(0-31)=14-bit CC, 
    --    0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 
    --    0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207=off velocity)
    --
    -- SWS version 2.8.3 has a bug in the crucial function "BR_GetMouseCursorContext_MIDI"
    -- https://github.com/Jeff0S/sws/issues/783
    -- For compatibility with 2.8.3 as well as other versions, the following lines test the SWS version for compatibility
    _, testParam1, _, _, _, testParam2 = reaper.BR_GetMouseCursorContext_MIDI()
    if type(testParam1) == "number" and testParam2 == nil then SWS283 = true else SWS283 = false end
    if type(testParam1) == "boolean" and type(testParam2) == "number" then SWS283again = false else SWS283again = true end 
    if SWS283 ~= SWS283again then
        reaper.ShowMessageBox("Could not determine compatible SWS version.", "ERROR", 0)
        return(false)
    end
    if SWS283 == true then
        isInline, _, targetLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    else 
        _, isInline, _, targetLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    end 

    
    -------------------------------------------------        
    -- Get active take (MIDI editor or inline editor)
    if isInline then
        take = reaper.BR_GetMouseCursorContext_Take()
    else
        editor = reaper.MIDIEditor_GetActive()
        if editor == nil then 
            reaper.ShowMessageBox("No active MIDI editor found.", "ERROR", 0)
            return(false)
        end
        take = reaper.MIDIEditor_GetTake(editor)
    end
    if not reaper.ValidatePtr(take, "MediaItem_Take*") then 
        reaper.ShowMessageBox("Could not find an active take in the MIDI editor.", "ERROR", 0)
        return(false)
    end
    
end -- if laneToUse == ...

item = reaper.GetMediaItemTake_Item(take)
if not reaper.ValidatePtr(item, "MediaItem*") then 
    reaper.ShowMessageBox("Could not determine the item to which the active take belongs.", "ERROR", 0)
    return(false)
end


-------------------------------------------------------------
-- Since 7bit CC, 14bit CC, channel pressure, and pitch all 
--     require somewhat different tweaks, these must often be 
--     distinguished.   
--[[if segment == "notes" then
    laneIsPIANOROLL, laneIsNOTES = true, true
    laneMax = 127
    laneMin = 0
else]]
if type(targetLane) ~= "number" then
    reaper.ShowMessageBox("The script could not detect the number ID of the target lane in the MIDI editor.", "ERROR", 0)
    return(false)
elseif 0 <= targetLane and targetLane <= 127 then -- CC, 7 bit (single lane)
    laneIsCC7BIT = true
    laneMax = 127
    laneMin = 0
    laneString = "CC lane " .. tostring(targetLane)    
elseif targetLane == 0x200 then
    laneIsVELOCITY, laneIsNOTES = true, true
    laneMax = 127
    laneMin = 1    
    laneString = "Velocity"
elseif targetLane == 0x201 then
    laneIsPITCH = true
    laneMax = 16383
    laneMin = 0
    laneString = "Pitchwheel"
elseif targetLane == 0x202 then
    laneIsPROGRAM = true
    laneMax = 127
    laneMin = 0
    laneString = "Program select"    
elseif targetLane == 0x203 then
    laneIsCHPRESS = true
    laneMax = 127
    laneMin = 0
    laneString = "Channel pressure"    
--[[elseif targetLane == 0x204 then
    laneIsBANKPROG = true
    laneMax = 127
    laneMin = 0]]
elseif 256 <= targetLane and targetLane <= 287 then -- CC, 14 bit (double lane)
    laneIsCC14BIT = true
    laneMax = 16383
    laneMin = 0
    laneString = "14-bit CC lanes " .. tostring(targetLane-256) .. "/" .. tostring(targetLane-224)    
--[[elseif targetLane == 0x205 then
    laneIsTEXT = true
elseif targetLane == 0x206 then
    laneIsSYSEX = true
elseif targetLane == 0x207 then
    laneIsOFFVEL, laneIsNOTES = true, true
    laneMax = 127
    laneMin = 0]]
else -- not a lane type in which script can be used.
    reaper.ShowMessageBox("This script will only work in the following MIDI lanes: \n* 7-bit CC, \n* 14-bit CC, \n* Velocity.\n* Pitch, \n* Channel Pressure, or\n* Program select."--\n* Bank/Program,\n* Text or Sysex,\nor in the 'notes area' of the piano roll."
                          , "ERROR", 0)
    return(0)
end


-----------------------------------------------------------------------------------
-- If CCdensity == "g", *or if the take is in the Tempo track*,
--    CCs will be inserted at the MIDI editor's grid spacing.
-- Otherwise, CCs density will follow the setting in
-- Preferences -> MIDI editor -> "Events per quarter note when drawing in CC lanes"
track = reaper.GetMediaItemTake_Track(take)
trackNameOK, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)

local startQN = reaper.MIDI_GetProjQNFromPPQPos(take, 0)
PPQ = reaper.MIDI_GetPPQPosFromProjQN(take, startQN+1)
if CCdensity == "g" or trackName == "Tempo" then
    QNperCC = reaper.MIDI_GetGrid(take)
    CCperQN = math.floor((1/QNperCC) + 0.5)
else
    CCperQN = reaper.SNM_GetIntConfigVar("midiCCdensity", 32)
    CCperQN = math.floor(math.max(4, math.min(128, math.abs(CCperQN)))) -- If user selected "Zoom dependent", density<0
end
    

-------------------------------------------------------------------------------
-- In addition, the source length will be saved and checked again at the end of
--    the script, to check that no inadvertent shifts in PPQ position happened.
sourceLengthTicks = reaper.BR_GetMidiSourceLenPPQ(take)


-------------------------------------------------------------
-- Get user inputs
function getUserInputs()

    if laneIsNOTES then
    
        gotUserInputs = false
        shapeString = tostring(shape)
        while gotUserInputs == false do
        retval, shape = reaper.GetUserInputs("Insert ramps: ".. laneString, 1, 'Shape ("s"ine or number>0):', tostring(shapeString))
            if retval == false then
                return retval
            else
                if shape == "sine" or shape == "s" then 
                    gotUserInputs = true 
                else 
                    shape = tonumber(shape)
                    if type(shape) == "number" and shape > 0 then 
                        gotUserInputs = true 
                    end
                end
            end
        end -- while gotUserInputs == false
    
    else

        descriptionsCSVstring = 'Events per QN (integer>0):,Shape ("s"ine or number>0):,Skip redundant CCs? (y/n),New CCs selected? (y/n)'
        if skipRedundantCCs then skipStr = "y" else skipStr = "n" end
        if newCCsAreSelected then newSelStr = "y" else newSelStr = "n" end
        defaultsCSVstring = tostring(CCperQN) .. "," .. tostring(shape) .. "," .. skipStr .. "," .. newSelStr
        
        -- Repeat getUserInputs until we get usable inputs
        gotUserInputs = false
        while gotUserInputs == false do
            retval, userInputsCSV = reaper.GetUserInputs("Insert ramps: ".. laneString, 4, descriptionsCSVstring, defaultsCSVstring)
            if retval == false then
                return retval
            else
                CCperQN, shape, skipRedundantCCs, newCCsAreSelected = userInputsCSV:match("([^,]+),([^,]+),([^,]+),([^,]+)")
                
                gotUserInputs = true -- temporary, will be changed to false if anything is wrong
                
                CCperQN = tonumber(CCperQN) 
                if CCperQN == nil then gotUserInputs = false
                elseif CCperQN ~= math.floor(CCperQN) or CCperQN <= 0 then gotUserInputs = false 
                end
                
                if not(shape == "sine" or shape == "s") then
                    shape = tonumber(shape)
                    if shape == nil then gotUserInputs = false 
                    elseif shape <= 0 then gotUserInputs = false 
                    end
                end
                
                if skipRedundantCCs == "y" or skipRedundantCCs == "Y" then skipRedundantCCs = true
                elseif skipRedundantCCs == "n" or skipRedundantCCs == "N" then skipRedundantCCs = false
                else gotUserInputs = false
                end
                
                if newCCsAreSelected == "y" or newCCsAreSelected == "Y" then newCCsAreSelected = true
                elseif newCCsAreSelected == "n" or newCCsAreSelected == "N" then newCCsAreSelected = false
                else gotUserInputs = false
                end 
                
            end -- if retval == 
            
        end -- while gotUserInputs == false
        
    end -- laneIsVELOCITY / else

    return retval
    
end -- if showDialogBox == true

if showDialogBox == true then 
    local retval = getUserInputs() 
    if not retval then return end
end


-----------------------------------------------------------------
-- Calculate remaining grid variables, after getting user inputs.
QNperCC = 1/CCperQN
PPperCC = PPQ/CCperQN -- Not necessarily an integer!

firstCCinTakePPQpos = reaper.MIDI_GetPPQPosFromProjQN(take, QNperCC*math.ceil(startQN/QNperCC))


----------------------------------------
-- Call the functions that will
--    * parse the MIDI string, 
--    * insert new events, 
--    * upload the string into take, and
--    * re-sort the MIDI, in the case of CC stuff (the velocity stuff will not change the order of events).
gotAllOK, origMIDIstring = reaper.MIDI_GetAllEvts(take, "")
if not gotAllOK then
    reaper.ShowMessageBox("MIDI_GetAllEvts could not load the raw MIDI data.", "ERROR", 0)
    return false 
end
if laneIsNOTES then doVelocityStuff()
else doCCInsertStuff()
end


---------------------------------------------------------------------------------------
-- Check that there were no inadvertent shifts in the PPQ positions of unedited events.
if not (sourceLengthTicks == reaper.BR_GetMidiSourceLenPPQ(take)) then
    reaper.MIDI_SetAllEvts(take, origMIDIstring) -- Restore original MIDI
    reaper.ShowMessageBox("The script has detected inadvertent shifts in the PPQ positions of unedited events."
                          .. "\n\nThis may be due to a bug in the script, or in the MIDI API functions."
                          .. "\n\nPlease report the bug in the following forum thread:"
                          .. "\nhttp://forum.cockos.com/showthread.php?t=176878"
                          .. "\n\nThe original MIDI data will be restored to the take.", "ERROR", 0)
end
    
if isInline then reaper.UpdateArrange() end
    
 
----------------------------------------            
-- Write nice, informative Undo strings.
if tonumber(shape) == nil then undoString = "Insert sine ramps "
elseif shape == 1 then undoString = "Insert linear ramps "
else undoString = "Insert ramps "
end
if laneIsCC7BIT then 
    undoString = undoString .. "in 7-bit CC lane " .. tostring(targetLane)
elseif laneIsCHPRESS then
    undoString = undoString .. "in channel pressure lane"
elseif laneIsCC14BIT then
    undoString = undoString .. "in 14 bit-CC lanes " .. tostring(targetLane-256) .. "/" .. tostring(targetLane-224)
elseif laneIsPITCH then
    undoString = undoString .. "in pitchwheel"
elseif laneIsVELOCITY then
    undoString = undoString .. "in velocity lane"
elseif laneIsPROGRAM then
    undoString = undoString .. "in program select lane"
end   
-- Undo_OnStateChange_Item is expected to be the fastest undo function, since it limits the info stored 
--    in the undo point to changes in this specific item.
reaper.Undo_OnStateChange_Item(0, undoString, item)
