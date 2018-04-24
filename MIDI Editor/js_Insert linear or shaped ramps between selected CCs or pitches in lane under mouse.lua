--[[
ReaScript name:  js_Insert ramps between selected CCs in lane under mouse (use mouse and mousewheel to shape ramps).lua
Version: 3.33
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Screenshot: http://stash.reaper.fm/27617/Insert%20linear%20or%20shaped%20ramps%20between%20selected%20CCs%20or%20pitches%20in%20lane%20under%20mouse%20-%20Copy.gif
REAPER version: 5.32 or later
Extensions: SWS/S&M 2.8.3 or later
Donation: https://www.paypal.me/juliansader
Provides: [main=main,midi_editor,midi_inlineeditor] .
About: 
  # Description

  * Useful for quickly adding ramps between 'nodes'.

  * Useful for smoothing transitions between CCs that were drawn at low resolution.


  The "Insert ramps" scripts are available in several variants (all of which can be dowloaded via ReaPack).  For example:  
  
  * Some variants start with a dialog box in which the user can customize several features; 
  
  * Other variants are single-click functions that immediately apply the default settings.
  
  (The user can create additional variants with customized settings, by editing the default settings in the the scripts' "USER AREA" and saving the edited versions as new scripts.)
  

  This variant uses mousewheel and mouse movement to shape the ramps (similar to REAPER's "mouse modifier" actions such as "Linear ramp CC events"):
  
  * Moving the mousewheel toggles between sine (aka "slow start / slow end") curves and linear (aka "triangle") curves.
  
  * Moving the mouse left or right warps the ramp CCs left or right, thereby creating "fast start / slow end" or "slow start / fast end" curves, respectively.
  
  
  Notes:
  
  * If snap-to-grid is ENabled in the MIDI editor, new CCs will be inserted at grid spacing.
  
  * If snap-to-grid is DISabled, new CCs will be inserted at the MIDI editor's default density that is set in Preferences -> CC density.
  
  * Any extraneous CCs between selected events will deleted.
  
  * By default, newly inserted CCs will be selected.  (Can be changed in the script's USER AREA.)
  
  * The script can optionally skip redundant CCs (that is, CCs with the same value as the preceding CC), 
      if the control script "js_Option - Toggle skip redundant events when inserting CCs" is toggled on.
  

  # INSTRUCTIONS

  1) Select the "node" CCs between which ramps will be inserted.
  
  2) Position mouse over the target CC lane (in the case of notes, either the notes area or the velocity lane).
  
  3) Press the shortcut key. (Do not press any mouse button.)
  
  4) Move the mouse or mousewheel to shape the ramps.
  
  5) To stop the script, move the mouse out of the CC lane, or press the shortcut key again. 
      

  KEYBOARD SHORTCUT
        
  There are two ways in which this script can be run:  
  
  1) First, the script can be linked to its own easy-to-remember shortcut key, such as "shift+V".  
      (Using the standard steps of linking any REAPER action to a shortcut key.)

  2) Second, this script, together with other "js_" scripts that edit the "lane under mouse",
      can each be linked to a toolbar button.  
      
      * In this case, each script need not be linked to its own shortcut key.  Instead, only the 
        accompanying "js_Run the js_'lane under mouse' script that is selected in toolbar.lua"
        script needs to be linked to a keyboard shortcut (as well as a mousewheel shortcut).
      
      * Clicking the toolbar button will 'arm' the linked script (and the button will light up), 
        and this selected (armed) script can then be run by using the shortcut for the 
        aforementioned "js_Run..." script.
      
      * For further instructions - please refer to the "js_Run..." script.                 
 
  Since this function is a user script, the way it responds to shortcut keys and 
    mouse buttons is opposite to that of REAPER's built-in mouse actions 
    with mouse modifiers:  To run the script, press the shortcut key *once* 
    to start the script and then move the mouse or mousewheel *without* 
    pressing any mouse buttons.  Press the shortcut key again once to 
    stop the script.  

  (The first time that the script is stopped, REAPER will pop up a dialog box 
    asking whether to terminate or restart the script.  Select "Terminate"
    and "Remember my answer for this script".)   


  MOUSEWHEEL MODIFIER
  
  A mousewheel modifier is a combination such as Ctrl+mousewheel, that can be assigned to an
  Action, similar to how keyboard shortcuts are assigned.
  
  As is the case with keyboard shortcuts, the script can either be controlled via its own
  mousewheel modifier, or via the mousewheel modifier that is linked to the "js_Run..." control script.
  
  Linking each script to its own mousewheel modifier is not ideal, since it would mean that the user 
  must remember several modifier combinations, one for each script.  (Mousewheel modifiers such as 
  Ctrl+Shift+mousewheel are more difficult to remember than keyboard shortcuts such as "A".)
  
  An easier option is to link a single mousewheel+modifier shortcut to the "js_Run..." script, 
  and this single mousewheel+modifier can then be used to control any of the other "lane under mouse" scripts. 
  
  NOTE: The mousewheel modifier that is assigned to the "js_Run..." script can be used to control 
      the other scripts, including the Arching scripts, even if these scripts
      were started from their own keyboard shortcuts.
    
    
  PERFORMANCE TIP: The responsiveness of the MIDI editor is significantly influenced by the total number of events in 
      the visible and editable takes.  If the MIDI editor is slow, try reducing the number of editable and visible tracks.
      
  PERFORMANCE TIP 2: If the MIDI editor gets slow and jerky when a certain VST plugin is loaded, 
      check for graphics driver incompatibility by disabling graphics acceleration in the plugin.
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
  * v3.03 (2017-12-21)
    + Return focus to MIDI editor after closing dialog box.
  * v3.30 (2018-01-24)
    + Ramps can be shaped by mouse and mousewheel movement.
  * v3.33 (2018-04-21)
    + Skipping redundant events can be toggled by separate script.
]] 

-- USER AREA
-- (Settings that the user can customize)

local newCCsAreSelected = true  -- Should the newly inserted CCs be selected?  true or false.
local newEventsAddChannel = 0   -- Difference between channel of newly inserted "curve" CCs, and original "node" CCs.


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

local tableNewEvents = {}
local tableSortedIndices = {} -- Instead of calling MIDI_Sort at the beginning of the script, the entries in this table will be the sorted indices.
local tChannelMinMaxPPQs = {} -- Stores the min and max PPQpos of selected events in each channel separately as {min=, max=}

-- The functions MIDI_SetAllEvts and BR_GetMouseCursorContext (both of which will be called
--    in each iteration of this script) get considerably slowed down by extra data in non-active takes.
-- (Presumably, both have to deal with the full MIDI chunk.)
-- To speed these function up, the non-active takes will therefore temporarily be cleared of all MIDI data.
-- The MIDI data will be stored in this table and restored when the script exists.
local tOtherTakes = {}

-- Starting values and position of mouse 
-- Not all of these lanes will be used by all scripts.
-- mouseOrigCCLane: (CC0-127 = 7-bit CC, 0x100|(0-31) = 14-bit CC, 0x200 = velocity, 0x201 = pitch, 
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
local mouseOrigCCLane, mouseOrigCCLaneID, mouseOrigCCValue, mouseNewCCLane, mouseNewCCLaneID, mouseNewCCValue -- Track mouse movement to compare with original position
local mouseOrigXPos, mouseOrigYPos, mouseNewXPos, mouseNewYPos 

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
local lastSelectedPPQPos -- 

-- Some internal stuff that will be used to set up everything
local _, item, take, editor, isInline

-- I am not sure that declaring functions local really helps to speed things up...
local s_unpack = string.unpack
local s_pack   = string.pack
local t_insert = table.insert -- myTable[i] = X is actually much faster than t_insert(myTable, X)
local m_floor  = math.floor
local m_cos    = math.cos
local m_pi     = math.pi

-- User preferences that can be customized via toggle scripts
local mustDrawCustomCursor
local skipRedundantCCs


--####################################################################################
--------------------------------------------------------------------------------------
function findTargetCCValuesAndPPQs()  
    
    -- REAPER v5.30 introduced new API functions for fast, mass edits of MIDI:
    --    MIDI_GetAllEvts and MIDI_SetAllEvts.
    --gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
    
    local MIDIlen = origMIDIstring:len()
    
    -- These functions are fast, but require complicated parsing of the MIDI string.
    -- The following tables with temporarily store data while parsing:
    local tableCCMSB = {} -- While waiting for matching LSB of 14-bit CC
    local tableCCLSB = {} -- While waiting for matching MSB of 14-bit CC
    for chan = 0, 15 do   -- Each channel will be handled separately
        tableCCMSB[chan] = {} 
        tableCCLSB[chan] = {}
    end
                   
    local runningPPQpos = 0 -- The MIDI string only provides the relative offsets of each event, sp the actual PPQ positions must be calculated by iterating through all events and adding their offsets
            
    local stringPos = 1 -- Keep record of position within MIDIstring. unchangedPos is position from which unchanged events van be copied in bulk.
    local c = 0 -- index in table / number if selected CCs
    
    ----------------------------------------------------------------
    -- Iterate through MIDIstring, until the upper limit is reached.
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
                          
            if laneIsCC7BIT then if msg:byte(2) == mouseOrigCCLane and (msg:byte(1))>>4 == 11
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
                if msg:byte(2) == mouseOrigCCLane-224 and (msg:byte(1))>>4 == 11 -- 14bit CC, only the LSB lane
                then
                    local channel = msg:byte(1)&0x0F
                    -- Has a corresponding MSB value already been saved?  If so, combine and save in tableValues.
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
                        
                elseif msg:byte(2) == mouseOrigCCLane-256 and (msg:byte(1))>>4 == 11 -- 14bit CC, only the MSB lane
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
    --tableSortedIndices = {}
    for i = 1, #tablePPQs do
        tableSortedIndices[i] = i
    end
    local function sortPPQs(a, b)
        if tablePPQs[a] < tablePPQs[b] then return true end
    end
    table.sort(tableSortedIndices, sortPPQs)
                
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
    


-----------------------------------
function deleteExistingCCsInRange()
    -- Thtis function updates remainMIDIstring to delete all CCs within range of selected CCs
    local tableRemainingEvents = {}
    
    -- In order to delete existing CCs in range, must get min and max PPQs for each channel
    tChannelMinMaxPPQs = {} 
    for chan = 0, 15 do
        tChannelMinMaxPPQs[chan] = {min = math.huge, max = -math.huge}
    end
    for i = 1, #tablePPQs do
        if tablePPQs[i] < tChannelMinMaxPPQs[tableChannels[i]].min then tChannelMinMaxPPQs[tableChannels[i]].min = tablePPQs[i] end
        if tablePPQs[i] > tChannelMinMaxPPQs[tableChannels[i]].max then tChannelMinMaxPPQs[tableChannels[i]].max = tablePPQs[i] end
    end
     
    -- Parse MIDIstring, removing CCs within range, handling each chaannel
    
    local t = 0 -- index in table
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
            local channel = ((msg:byte(1)&0x0F) - newEventsAddChannel) % 16 -- Delete only events in "curve" channel, not "node" channel.
            if runningPPQpos >= tChannelMinMaxPPQs[channel].min and runningPPQpos <= tChannelMinMaxPPQs[channel].max then
                if laneIsCC7BIT       then if msg:byte(1)>>4 == 11 and msg:byte(2) == mouseOrigCCLane then mustDelete = true end
                elseif laneIsPITCH    then if msg:byte(1)>>4 == 14 then mustDelete = true end
                elseif laneIsCC14BIT  then if msg:byte(1)>>4 == 11 and (msg:byte(2) == mouseOrigCCLane-224 or msg:byte(2) == mouseOrigCCLane-256) then mustDelete = true end
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
    remainMIDIstring = table.concat(tableRemainingEvents)

end

--[[
    reaper.MIDI_SetAllEvts(take, table.concat(tableNewEvents) .. string.pack("i4", string.unpack("i4", remainMIDIstring, 1) - lastPPQpos) .. remainMIDIstring:sub(5))
    
    ------------------------------------------------------------------------------
    -- MIDI_Sort used to be buggy when dealing with overlapping or unsorted notes,
    --    causing infinitely extended notes or zero-length notes.
    -- Fortunately, these bugs were seemingly all fixed in v5.32.
    reaper.MIDI_Sort(take)  
    
end]]


-- User preferences that can be customized in the js_MIDI editing preferences script
local mustDrawCustomCursor = true
local clearNonActiveTakes  = true
local curveIsLinear = true -- true = linear/power, false = sine
  
--#############################################################################################
-----------------------------------------------------------------------------------------------
-- The function that will track mouse movement and draw MIDI during each defer cycle.
--
-- The function returns true if the looping can continue, and false if the script should quit.
--
-- There are three bottlenecks that impede the speed of this function:
--    Minor: reaper.BR_GetMouseCursorContext(), which must unfortunately unavoidably be called before 
--           reaper.BR_GetMouseCursorContext_MIDI(), and which (surprisingly) gets much slower as the 
--           number of MIDI events in the take increases.
--           ** This script will therefore apply a nifty trick to speed up this function:  using
--           MIDI_SetAllEvts, the take will be cleared of all MIDI before running BR_...! **
--    Minor: MIDI_SetAllEvts (when filled with hundreds of thousands of events) is not fast - but is 
--           infinitely better than the standard API functions such as MIDI_SetCC.
--    Major: Updating the MIDI editor between defer cycles is by far the slowest part of the whole process.
--           The more events in visible and editable takes, the slower the updating.  MIDI_SetAllEvts
--           seems to get slowed down more than REAPER's native Actions such as Invert Selection.
--           If, in the future, the REAPER API provides a way to toggle take visibility in the editor,
--           it may be helpful to temporarily make all non-active takes invisible. 
-- The Lua script parts of this function - even if it calculates thousands of events per cycle,
--    make up only a small fraction of the execution time.
local function trackMouseAndDrawMIDI()

    -------------------------------------------------------------------------------------------
    -- The js_Run... script can communicate with and control the other js_ scripts via ExtState
    if reaper.GetExtState("js_Mouse actions", "Status") == "Must quit" then return(false) end

    -------------------------------------------
    -- Track the new mouse (vertical) position.
    -- (Apparently, BR_GetMouseCursorContext must always precede the other BR_ context calls)
    -- ***** Trick: BR_GetMouse... gets slower and slower as the number of events in the take increases.
    --              Therefore, clean the take *before* calling the function!
    takeIsCleared = true
    reaper.MIDI_SetAllEvts(take, AllNotesOffString)
    -- Tooltip position is changed immediately before getting mouse cursor context, to prevent cursor from being above tooltip.
    mouseNewXPos, mouseNewYPos = reaper.GetMousePosition()
    reaper.TrackCtl_SetToolTip(" \\/\\", mouseNewXPos+7, mouseNewYPos+8, true) 

    window, segment, details = reaper.BR_GetMouseCursorContext()  
    if SWS283 == true then 
        _, mouseNewPitch, mouseNewCCLane, mouseNewCCValue, mouseNewCCLaneID = reaper.BR_GetMouseCursorContext_MIDI()
    else -- SWS287
        _, _, mouseNewPitch, mouseNewCCLane, mouseNewCCValue, mouseNewCCLaneID = reaper.BR_GetMouseCursorContext_MIDI()
    end

    ----------------------------------------------------------------------------------
    -- What must the script do if the mouse moves out of the original CC lane area?
    -- Per default, the script will terminate.  This is an easy way to ensure that 
    --    the script does not continue to run indefinitely without the user realising.
    -- However, if mouse crosses the top or bottom, the script must make sure that 
    --    maximum or minimum values are not skipped, so in these cases the script 
    --    will complete the function before quitting.
    if laneIsPIANOROLL then
        if not (segment == "notes") then 
            return false
        end
    elseif segment == "notes" 
        or (details == "cc_lane" and mouseNewCCLaneID < mouseOrigCCLaneID and mouseNewCCLaneID >= 0) 
        then
        mouseNewCCValue = laneMax
        mustQuitAfterDrawingOnceMore = true
    elseif details == "cc_lane" and mouseNewCCLaneID > mouseOrigCCLaneID then
        mouseNewCCValue = laneMin
        mustQuitAfterDrawingOnceMore = true        
    elseif mouseNewCCLane ~= mouseOrigCCLane then
        return false
    elseif mouseNewCCValue == -1 then 
        mouseNewCCValue = laneMax -- If -1, it means that the mouse is over the separator above the lane.
    end
    
    -----------------------------        
    -- Has mousewheel been moved?     
    -- The script can detect mousewheel in two ways: 
    --    * by being linked directly to a mousewheel mouse modifier (return mousewheel movement with reaper.get_action_context)
    --    * or via the js_Run... script that can run and control the other js_ scripts (return movement via ExtState)
    is_new, _, _, _, _, _, mousewheel = reaper.get_action_context()
    if not is_new then -- then try getting from script
        mousewheel = tonumber(reaper.GetExtState("js_Mouse actions", "Mousewheel"))
        reaper.SetExtState("js_Mouse actions", "Mousewheel", "0", false) -- Reset after getting update
    end
    if not (type(mousewheel) == "number") then mousewheel = 0 end
    -- Prevent curve from flipping multiple times per mousewheel movement
    if (mousewheel > 0 and prevMousewheel <= 0) or (mousewheel < 0 and prevMousewheel >= 0)
        then curveIsLinear = not curveIsLinear 
    end -- Flip curve type in mousewheel is moved in any direction.
    prevMousewheel = mousewheel
  
    ------------------------------------------------------------------
    -- Calculate the new raw MIDI data, and write the tableEditedMIDI!
    ---------------------------------------------------------------- THIS IS THE PART THAT CAN EASILY BE MODDED !! ------------------------
    tableNewEvents = {} -- Clean previous tableEditedMIDI
    local c = 0 -- Count index inside tableEditedMIDI - strangely, this is faster than using table.insert or even #tableEditedMIDI+1
              
    local offset, newPPQpos, noteOffPPQpos, newNoteOffPPQpos
    local lastPPQpos = 0
    
        --local mouseRelativeMovement = (mouseNewCCValue-mouseOrigCCValue)/(laneMax-laneMin) -- Positive if moved to right, negative if moved to left
        local mouseRelativeMovement = (mouseNewXPos - mouseOrigXPos)/400
        if mouseRelativeMovement > 0.49 then mouseRelativeMovement = 0.49 elseif mouseRelativeMovement < -0.49 then mouseRelativeMovement = -0.49 end

        power = math.log(0.5 - math.abs(mouseRelativeMovement), 0.5)
        
        
        local c = 0 -- Index in table of edited events
        local newFlags = newCCsAreSelected and 1 or 0       
        local lastPPQpos = 0
        
        -- First insert the original event, and then check whether any new events must be inserted between this and the next event in the same channel.
        for s, i in ipairs(tableSortedIndices) do 
            if laneIsCC7BIT then
                c = c + 1
                tableNewEvents[c] = s_pack("i4BI4BBB", tablePPQs[i]-lastPPQpos, tableFlags[i], 3, 0xB0 | tableChannels[i], mouseOrigCCLane, tableValues[i])
            elseif laneIsPITCH then
                c = c + 1
                tableNewEvents[c] = s_pack("i4BI4BBB", tablePPQs[i]-lastPPQpos, tableFlags[i], 3, 0xE0 | tableChannels[i], tableValues[i]&127, tableValues[i]>>7)
            elseif laneIsCHPRESS then
                c = c + 1
                tableNewEvents[c] = s_pack("i4BI4BB",  tablePPQs[i]-lastPPQpos, tableFlags[i], 2, 0xD0 | tableChannels[i], tableValues[i])
            elseif laneIsCC14BIT then
                c = c + 1
                tableNewEvents[c] = s_pack("i4BI4BBB", tablePPQs[i]-lastPPQpos, tableFlags[i], 3, 0xB0 | tableChannels[i], mouseOrigCCLane-256, tableValues[i]>>7)
                c = c + 1
                tableNewEvents[c] = s_pack("i4BI4BBB", 0, tableFlagsLSB[i], 3, 0xB0 | tableChannels[i], mouseOrigCCLane-224, tableValues[i]&127)
            elseif laneIsPROGRAM then
                c = c + 1
                tableNewEvents[c] = s_pack("i4BI4BB",  tablePPQs[i]-lastPPQpos, tableFlags[i], 2, 0xC0 | tableChannels[i], tableValues[i])
            end
            local lastValue = insertValue
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
                        local insertValue
                        if curveIsLinear then 
                            if mouseRelativeMovement >= 0 then
                                local weight = ((PPQround - tablePPQs[i]) / (nextPPQ - tablePPQs[i]))^power
                                insertValue = tableValues[i] + (nextValue - tableValues[i])*weight
                            else
                                local weight = ((PPQround - nextPPQ) / (tablePPQs[i] - nextPPQ))^power
                                insertValue = nextValue + (tableValues[i] - nextValue)*weight
                            end
                        else -- shape == "sine"
                            if mouseRelativeMovement >= 0 then
                                local weight = ((1 - m_cos(m_pi*(PPQround - tablePPQs[i]) / (nextPPQ - tablePPQs[i])))/2)^power
                                insertValue = tableValues[i] + (nextValue - tableValues[i])*weight
                            else
                                local weight = ((1 - m_cos(m_pi*(PPQround - nextPPQ) / (tablePPQs[i] - nextPPQ)))/2)^power
                                insertValue = nextValue + (tableValues[i] - nextValue)*weight
                            end
                            
                        end
                        
                        if insertValue > laneMax then insertValue = laneMax
                        elseif insertValue < laneMin then insertValue = laneMin
                        else insertValue = m_floor(insertValue + 0.5)
                        end
                        
                        local insertChannel = (tableChannels[i]+newEventsAddChannel) % 16
                        
                        -- If redundant, skip insertion
                        if not (skipRedundantCCs == true and insertValue == lastValue) then
                            if laneIsCC7BIT then
                                c = c + 1
                                tableNewEvents[c] = s_pack("i4BI4BBB", PPQround-lastPPQpos, newFlags, 3, 0xB0 | insertChannel, mouseOrigCCLane, insertValue)
                            elseif laneIsPITCH then
                                c = c + 1
                                tableNewEvents[c] = s_pack("i4BI4BBB", PPQround-lastPPQpos, newFlags, 3, 0xE0 | insertChannel, insertValue&127, insertValue>>7)
                            elseif laneIsCHPRESS then
                                c = c + 1
                                tableNewEvents[c] = s_pack("i4BI4BB",  PPQround-lastPPQpos, newFlags, 2, 0xD0 | insertChannel, insertValue)
                            elseif laneIsCC14BIT then
                                c = c + 1
                                tableNewEvents[c] = s_pack("i4BI4BBB", PPQround-lastPPQpos, newFlags, 3, 0xB0 | insertChannel, mouseOrigCCLane-256, insertValue>>7)
                                c = c + 1
                                tableNewEvents[c] = s_pack("i4BI4BBB", 0, newFlags, 3, 0xB0 | insertChannel, mouseOrigCCLane-224, insertValue&127)
                            elseif laneIsPROGRAM then
                                c = c + 1
                                tableNewEvents[c] = s_pack("i4BI4BB",  PPQround-lastPPQpos, newFlags, 2, 0xC0 | insertChannel, insertValue)    
                            end
                            lastValue = insertValue
                            lastPPQpos = PPQround
                        end -- if not (skipRedundantCCs == true and insertValue == prevCCvalue)
                    end -- for PPQpos = nextCCdensityPPQpos, nextPPQ-1, PPperCC do
  
                    break -- Found one event in same channel, don't search any further  
                       
                end -- if tableChannels[searchAheadIndex] == tableChannels[i] then
                
                
            end -- for searchAheadIndex = i+1, #tablePPQs do
        end -- for i = 1, #tablePPQs do
                    
                      
    -----------------------------------------------------------
    -- DRUMROLL... write the edited events into the MIDI chunk!
    -- This also updates the offset of the first event in remainMIDIstring relative to the PPQ position of the last event in tableEditedMIDI
    reaper.MIDI_SetAllEvts(take, table.concat(tableNewEvents)
                                  .. s_pack("i4Bs4", -lastPPQpos, 0, "")
                                  .. remainMIDIstring)
    takeIsCleared = false
    if isInline then reaper.UpdateItemInProject(item) end

    if mustQuitAfterDrawingOnceMore then return false else return true end -- return to pcall

end -- trackMouseAndDrawMIDI()


--#######################################################################################
-----------------------------------------------------------------------------------------
function loop_pcall()
    -- Since new versions of the script temporarily clear all MIDI from non-active takes, 
    --    it is important to ensure that, if things go wrong, the script can restore the cleared takes
    --    (otherwise the user may not notice the missing MIDI util it is too late).
    -- Therefore use pcall to call the main trackMouseAndDrawMIDI function.
    local errorFree, mustContinue = pcall(trackMouseAndDrawMIDI)

    -- Continuously loop the function - if don't need to quit
    if not errorFree then
        reaper.MB("Error while tracking mouse movement.\n\nOriginal MIDI data will be restored.\n\n", "ERROR", 0)
        reaper.MIDI_SetAllEvts(take, origMIDIstring)
        takeIsCleared = false
        return
    elseif not mustContinue then 
        return
    else 
        reaper.runloop(loop_pcall)
    end
end


--############################################################################################
----------------------------------------------------------------------------------------------
function onexit()
    
    -- Remove tooltip 'custom cursor'
    reaper.TrackCtl_SetToolTip("", 0, 0, true)
    
    -- For safety, the very first step that must be performed when quitting,
    --    is to restore all MIDI to the cleared non-active takes.
    for otherTake, otherMIDI in pairs(tOtherTakes) do
        reaper.MIDI_SetAllEvts(otherTake, otherMIDI)
    end 
    
    -- Remember that the active take was cleared before calling BR_GetMouseCursorContext
    --    So may need to upload MIDI again.
    if takeIsCleared then
        reaper.MIDI_SetAllEvts(take, table.concat(tableNewEvents)
                                      .. restorePPQPosToZeroString
                                      .. remainMIDIstring)
    end
                                 
    --[[Archive: Since v5.32, MIDI_Sort will be fixed, so no need to use workarounds
                  such as calling the "Invert selection" action.
                                      
    -- Calls to native actions such as "Invert selection" via OnCommand must be placed
    --    within explicit undo blocks, otherwise they will create their own undo points.
    -- Strangely, in the current v5.30, undo blocks are interrupted as soon as the 
    --    atexit-defined function is called.  *This is probably a bug.*  
    -- Therefore must start a new undo block within this onexit function.  Fortunately, 
    --    this undo point seems to undo the entire defered script, not only the stuff that
    --    happens within this onexit function.
    reaper.Undo_BeginBlock2(0)    
    
    -- MIDI_Sort is buggy when dealing with overlapping notes, 
    --    causing infinitely extended notes or zero-length notes.
    -- Even explicitly calling "Correct overlapping notes" before sorting does not avoid all bugs.
    -- Calling "Invert selection" twice is a much more reliable way to sort MIDI.   
    if isInline then
        reaper.MIDI_Sort(take)
        reaper.UpdateArrange()
    else
        reaper.MIDIEditor_OnCommand(editor, 40501) -- Invert selection in active take
        reaper.MIDIEditor_OnCommand(editor, 40501) -- Invert back to original selection
    end
    ]]
        
    -- MIDI_Sort used to be buggy when dealing with overlapping or unsorted notes,
    --    causing infinitely extended notes or zero-length notes.
    -- Fortunately, these bugs were seemingly all fixed in v5.32.
    reaper.MIDI_Sort(take)  
    
    -- Check that there were no inadvertent shifts in the PPQ positions of unedited events.
    if not (sourceLengthTicks == reaper.BR_GetMidiSourceLenPPQ(take)) then
        reaper.MIDI_SetAllEvts(take, origMIDIstring) -- Restore original MIDI
        reaper.ShowMessageBox("The script has detected inadvertent shifts in the PPQ positions of unedited events."
                              .. "\n\nThis may be due to a bug in the script, or in the MIDI API functions."
                              .. "\n\nPlease report the bug in the following forum thread:"
                              .. "\nhttp://forum.cockos.com/showthread.php?t=176878"
                              .. "\n\nThe original MIDI data will be restored to the take.", "ERROR", 0)
    end
        
    if isInline then reaper.UpdateItemInProject(item) end  
     
    -- Communicate with the js_Run.. script that this script is exiting
    reaper.DeleteExtState("js_Mouse actions", "Status", true)
    
    -- Deactivate toolbar button (if it has been toggled)
    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 
        and type(prevToggleState) == "number" 
        then
        reaper.SetToggleCommandState(sectionID, cmdID, prevToggleState)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end    
                
    -- Write nice, informative Undo strings
    if laneIsCC7BIT then
        undoString = "Warp values of 7-bit CC events in lane ".. tostring(mouseOrigCCLane)
    elseif laneIsCHPRESS then
        undoString = "Warp values of channel pressure events"
    elseif laneIsCC14BIT then
        undoString = "Warp values of 14 bit-CC events in lanes ".. 
                                  tostring(mouseOrigCCLane-256) .. "/" .. tostring(mouseOrigCCLane-224)
    elseif laneIsPITCH then
        undoString = "Warp values of pitchwheel events"
    elseif laneIsVELOCITY then
        undoString = "Warp velocities of notes"
    elseif laneIsPROGRAM then
        undoString = "Warp values of program select events"
    else
        undoString = "Warp event values"
    end   
    -- Undo_OnStateChange_Item is expected to be the fastest undo function, since it limits the info stored 
    --    in the undo point to changes in this specific item.
    reaper.Undo_OnStateChange_Item(0, undoString, item)
    
    if reaper.APIExists("SN_FocusMIDIEditor") then reaper.SN_FocusMIDIEditor() end

end -- function onexit


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
function main()

    -- Start with a trick to avoid automatically creating undo states if nothing actually happened
    -- Undo_OnStateChange will only be used if reaper.atexit(onexit) has been executed
    reaper.defer(function() end)
    
    
    -------------------------------------------------------
    -- Test whether user customizable variables are usable.
    if reaper.GetExtState("js_Mouse actions", "skipRedundantCCs") == "false" then
        skipRedundantCCs = false
    else
        skipRedundantCCs = true
    end
    
    if type(newCCsAreSelected) ~= "boolean" then
        reaper.ShowMessageBox("The setting 'newCCsAreSelected' must be either 'true' of 'false'.", "ERROR", 0)
        if reaper.APIExists("SN_FocusMIDIEditor") then reaper.SN_FocusMIDIEditor() end
        return(false)
    end
        
    
    -------------------------------------------------------------
    -- Check whether the required version of REAPER is available.
    if not reaper.APIExists("MIDI_GetAllEvts") then
        reaper.ShowMessageBox("This version of the script requires REAPER v5.32 or higher."
                              .. "\n\nOlder versions of the script will work in older versions of REAPER, but may be slow in takes with many thousands of events"
                              , "ERROR", 0)
        if reaper.APIExists("SN_FocusMIDIEditor") then reaper.SN_FocusMIDIEditor() end
        return(false)
    elseif not reaper.APIExists("BR_GetMouseCursorContext") then
        reaper.ShowMessageBox("This script requires the SWS/S&M extension.\n\nThe SWS/S&M extension can be downloaded from www.sws-extension.org.", "ERROR", 0)
        if reaper.APIExists("SN_FocusMIDIEditor") then reaper.SN_FocusMIDIEditor() end
        return(false)
    end  
    
    
    -----------------------------------------------------
    -- Display notification about new mousewheel feature.
    local lastTipVersion = tonumber(reaper.GetExtState("js_Insert ramps (use mouse)", "Last tip version"))
    --if type(lastTipVersion) == "string" then lastTipVersion = tonumber(lastTipVersion) end
    if not (type(lastTipVersion) == "number") or lastTipVersion < 3.30 then
        reaper.MB([[This updated version of the "Insert ramp" script uses mousewheel and mouse movement to shape the ramps, similar to the "Warp" and "Arch" scripts:
      
    * Moving the mousewheel+modifier toggles between sine (aka "slow start / slow end") curves and linear (aka "triangle") curves.
      
    * Moving the mouse left or right warps the ramp CCs left or right, thereby creating "fast start / slow end" or "slow start / fast end" curves, respectively.
      
    (Remember that the mousewheel+modifier shortcut can be linked to this script directly, or to the "js_Run..." script.)]], 
                  "New feature notification", 0)
        reaper.SetExtState("js_Insert ramps (use mouse)", "Last tip version", "3.30", true)
        if reaper.APIExists("SN_FocusMIDIEditor") then reaper.SN_FocusMIDIEditor() end
        return
    end
    
    
    -----------------------------------------------------------
    -- The following sections checks the position of the mouse:
    -- If the script is called from a toolbar, it arms the script as the default js_Run function, but does not run the script further
    -- If the mouse is positioned over a CC lane, the script is run.
    mouseOrigXPos, mouseOrigYPos = reaper.GetMousePosition() 
    window, segment, details = reaper.BR_GetMouseCursorContext()
    -- If window == "unknown", assume to be called from floating toolbar
    -- If window == "midi_editor" and segment == "unknown", assume to be called from MIDI editor toolbar
    if window == "unknown" or (window == "midi_editor" and segment == "unknown") then
        setAsNewArmedToolbarAction()
        return(true) 
    elseif not(segment == "notes" or details == "cc_lane") then 
        reaper.ShowMessageBox("Mouse is not correctly positioned.\n\n"
                              .. "This script edits the MIDI events in the part of the MIDI editor that is under the mouse, "
                              .. "so the mouse should be positioned over either a CC lane or the notes area of an active MIDI editor.", "ERROR", 0)
        if reaper.APIExists("SN_FocusMIDIEditor") then reaper.SN_FocusMIDIEditor() end
        return(false) 
    else
        -- Communicate with the js_Run.. script that a script is running
        reaper.SetExtState("js_Mouse actions", "Status", "Running", false)
    end    
    
      
    -----------------------------------------------------------------------------------------
    -- We know that the mouse is positioned over a MIDI editor.  Check whether inline or not.
    -- Also get the mouse starting (vertical) value and CC lane.
    -- mouseOrigPitch: note row or piano key under mouse cursor (0-127)
    -- mouseOrigCCLane: CC lane under mouse cursor (CC0-127=CC, 0x100|(0-31)=14-bit CC, 
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
        if reaper.APIExists("SN_FocusMIDIEditor") then reaper.SN_FocusMIDIEditor() end
        return(false)
    end
    if SWS283 == true then
        isInline, _, mouseOrigCCLane, mouseOrigCCValue, mouseOrigCCLaneID = reaper.BR_GetMouseCursorContext_MIDI()
    else 
        _, isInline, _, mouseOrigCCLane, mouseOrigCCValue, mouseOrigCCLaneID = reaper.BR_GetMouseCursorContext_MIDI()
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
        if reaper.APIExists("SN_FocusMIDIEditor") then reaper.SN_FocusMIDIEditor() end
        return(false)
    end
    item = reaper.GetMediaItemTake_Item(take)
    if not reaper.ValidatePtr(item, "MediaItem*") then 
        reaper.ShowMessageBox("Could not determine the item to which the active take belongs.", "ERROR", 0)
        if reaper.APIExists("SN_FocusMIDIEditor") then reaper.SN_FocusMIDIEditor() end
        return(false)
    end
    track = reaper.GetMediaItemTake_Track(take)
    if not reaper.ValidatePtr(track, "MediaTrack*") then 
        reaper.ShowMessageBox("Could not determine the track to which the active take belongs.", "ERROR", 0)
        if reaper.APIExists("SN_FocusMIDIEditor") then reaper.SN_FocusMIDIEditor() end
        return(false)
    end
    trackNameOK, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
    
    
    -------------------------------------------------------------
    -- Since 7bit CC, 14bit CC, channel pressure, and pitch all 
    --     require somewhat different tweaks, these must often be 
    --     distinguished.   
    --[[if segment == "notes" then
        laneIsPIANOROLL, laneIsNOTES = true, true
        laneMax = 127
        laneMin = 0
    else]]
    if type(mouseOrigCCLane) ~= "number" then
        reaper.ShowMessageBox("The script could not detect the number ID of the target lane in the MIDI editor.", "ERROR", 0)
        if reaper.APIExists("SN_FocusMIDIEditor") then reaper.SN_FocusMIDIEditor() end
        return(false)
    elseif 0 <= mouseOrigCCLane and mouseOrigCCLane <= 127 then -- CC, 7 bit (single lane)
        laneIsCC7BIT = true
        laneMax = 127
        laneMin = 0
        laneString = "CC lane " .. tostring(mouseOrigCCLane)    
    elseif mouseOrigCCLane == 0x200 then
        laneIsVELOCITY, laneIsNOTES = true, true
        laneMax = 127
        laneMin = 1    
        laneString = "Velocity"
    elseif mouseOrigCCLane == 0x201 then
        laneIsPITCH = true
        laneMax = 16383
        laneMin = 0
        laneString = "Pitchwheel"
    elseif mouseOrigCCLane == 0x202 then
        laneIsPROGRAM = true
        laneMax = 127
        laneMin = 0
        laneString = "Program select"    
    elseif mouseOrigCCLane == 0x203 then
        laneIsCHPRESS = true
        laneMax = 127
        laneMin = 0
        laneString = "Channel pressure"    
    --[[elseif mouseOrigCCLane == 0x204 then
        laneIsBANKPROG = true
        laneMax = 127
        laneMin = 0]]
    elseif 256 <= mouseOrigCCLane and mouseOrigCCLane <= 287 then -- CC, 14 bit (double lane)
        laneIsCC14BIT = true
        laneMax = 16383
        laneMin = 0
        laneString = "14-bit CC lanes " .. tostring(mouseOrigCCLane-256) .. "/" .. tostring(mouseOrigCCLane-224)    
    --[[elseif mouseOrigCCLane == 0x205 then
        laneIsTEXT = true
    elseif mouseOrigCCLane == 0x206 then
        laneIsSYSEX = true
    elseif mouseOrigCCLane == 0x207 then
        laneIsOFFVEL, laneIsNOTES = true, true
        laneMax = 127
        laneMin = 0]]
    else -- not a lane type in which script can be used.
        reaper.ShowMessageBox("This script will only work in the following MIDI lanes: \n* 7-bit CC, \n* 14-bit CC, \n* Velocity.\n* Pitch, \n* Channel Pressure, or\n* Program select."--\n* Bank/Program,\n* Text or Sysex,\nor in the 'notes area' of the piano roll."
                              , "ERROR", 0)
        if reaper.APIExists("SN_FocusMIDIEditor") then reaper.SN_FocusMIDIEditor() end
        return(0)
    end
    
    
    -----------------------------------------------------------------------------------
    -- If CCdensity == "g", *or if the take is in the Tempo track*,
    --    CCs will be inserted at the MIDI editor's grid spacing.
    -- Otherwise, CCs density will follow the setting in
    -- Preferences -> MIDI editor -> "Events per quarter note when drawing in CC lanes"
    if isInline then
        isSnapEnabled = (reaper.GetToggleCommandStateEx(0, 1157) == 1)
    else
        isSnapEnabled = (reaper.MIDIEditor_GetSetting_int(editor, "snap_enabled") == 1)
    end
    
    local startQN = reaper.MIDI_GetProjQNFromPPQPos(take, 0)
    PPQ = reaper.MIDI_GetPPQPosFromProjQN(take, startQN+1)
    if not isInline and (isSnapEnabled or trackName == "Tempo") then
        QNperCC = reaper.MIDI_GetGrid(take) -- MIDI editor returns grid differently than arrange view: 1 = QN
        CCperQN = math.floor((1/QNperCC) + 0.5)
    elseif isInline and (isSnapEnabled or trackName == "Tempo") then 
        local _, grid, _, _ = reaper.GetSetProjectGrid(0, false) -- 0.25 = QN
        QNperCC = grid*4
        CCperQN = math.floor((1/QNperCC) + 0.5)
    else
        CCperQN = reaper.SNM_GetIntConfigVar("midiCCdensity", 32)
        CCperQN = math.floor(math.max(4, math.min(128, math.abs(CCperQN)))) -- If user selected "Zoom dependent", density<0
        QNperCC = 1/CCperQN
    end
    PPperCC = PPQ/CCperQN -- Not necessarily an integer!
    firstCCinTakePPQpos = reaper.MIDI_GetPPQPosFromProjQN(take, QNperCC*math.ceil(startQN/QNperCC))
    
        
    -----------------------------------------------------------------------
    -- The crucial BR_GetMouseCursorContext function gets slower and slower 
    --    as the number of events in the take increases.
    -- Therefore, this script will speed up the function by 'clearing' the 
    --    take of all MIDI *before* calling the function!
    -- To do so, MIDI_SetAllEvts will be run with no events except the
    --    All-Notes-Off message that should always terminate the MIDI stream, 
    --    and which marks the position of the end of the MIDI source.
    -- Instead of parsing the entire MIDI stream to get the final PPQ position,
    --    simply get the source length.
    -- (Since the MIDI may get sorted in the parseAndExtractTargetMIDI function,
    --    getting the source length has been postponed till now.)
    -- In addition, the source length will be saved and checked again at the end of
    --    the script, to check that no inadvertent shifts in PPQ position happened.
    sourceLengthTicks = reaper.BR_GetMidiSourceLenPPQ(take)
    AllNotesOffString = string.pack("i4Bi4BBB", sourceLengthTicks, 0, 3, 0xB0, 0x7B, 0x00)
    
    
    -----------------------------------------------------
    -- Call the functions that will parse the take's MIDI
    gotAllOK, origMIDIstring = reaper.MIDI_GetAllEvts(take, "")
    if not gotAllOK then
        reaper.ShowMessageBox("MIDI_GetAllEvts could not load the raw MIDI data.", "ERROR", 0)
        if reaper.APIExists("SN_FocusMIDIEditor") then reaper.SN_FocusMIDIEditor() end
        return false 
    end
    
    findTargetCCValuesAndPPQs() -- Updates 
    deleteExistingCCsInRange()
    
    for chan = 0, 15 do -- Check whether enough selected events
        if tChannelMinMaxPPQs[chan].min < tChannelMinMaxPPQs[chan].max then gotTwoEventsInAtLeastOneChannel = true break end
    end
    if not gotTwoEventsInAtLeastOneChannel then
        reaper.ShowMessageBox("At least one MIDI channel should contain two or more selected events in the lane under the mouse.", "ERROR", 0)
        if reaper.APIExists("SN_FocusMIDIEditor") then reaper.SN_FocusMIDIEditor() end
        return
    end
    lastSelectedPPQPos = tablePPQs[tableSortedIndices[#tableSortedIndices]]
    restorePPQPosToZeroString = string.pack("i4Bs4", -lastSelectedPPQPos, 0, "")
    
    
    ---------------------------------------------------------------------------
    -- OK, tests passed, and it seems like this script will do something, 
    --    so toggle button (if any) and define atexit with its Undo statements,
    --    before making any changes to the MIDI.
    reaper.atexit(onexit)
    _, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
        prevToggleState = reaper.GetToggleCommandStateEx(sectionID, cmdID)
        reaper.SetToggleCommandState(sectionID, cmdID, 1)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
    
    
    -------------------------------------------------------------------------------------------
    -- The functions MIDI_SetAllEvts and BR_GetMouseCursorContext (both of which will be called
    --    in each iteration of this script) get considerably slowed down by extra data in non-active takes.
    -- (Presumably, both have to deal with the full MIDI chunk.)
    -- To speed these function up, the non-active takes will therefore temporarily be cleared of all MIDI data.
    -- The MIDI data will be returned when the script exists.
    if not (reaper.GetExtState("js_Mouse actions", "Clear non-active takes") == "false") then
        for t = 0, reaper.CountTakes(item)-1 do
            local otherTake = reaper.GetTake(item, t)
            if otherTake ~= take then --and reaper.TakeIsMIDI(otherTake) then
                -- In rare circumstances, source length may differ between takes, if user changed loop points of individual takes.
                local otherSourceLen = reaper.BR_GetMidiSourceLenPPQ(otherTake)
                if otherSourceLen > 0 then -- If not a MIDI take, will return -1
                    local gotMIDIOK, otherTakeMIDI = reaper.MIDI_GetAllEvts(otherTake, "")
                    if gotMIDIOK then
                        tOtherTakes[otherTake] = otherTakeMIDI
                        otherSourceLen = math.floor(otherSourceLen)
                        reaper.MIDI_SetAllEvts(otherTake, string.pack("i4Bi4BBB", otherSourceLen, 0, 3, 0xB0, 0x7B, 0x00))
                    end
                end
            end
        end
    end
    
    
    -------------------------------------------------------------
    -- Finally, start running the loop!
    -- (But first, reset the mousewheel movement.)
    is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
    
    loop_pcall()
    
end -- function main()

main()
