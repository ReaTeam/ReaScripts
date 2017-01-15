--[[
Reascript name:  js_Remove redundant CCs.lua
Version: 3.10
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Extensions: SWS/S&M 2.8.3 or later
REAPER version: 5.32 or later
Donation: https://www.paypal.me/juliansader
About:
  # Description
  
  Removes redundant events from selected CCs in 7-bit CC, pitchwheel, channel pressure and program select lanes with a single click.

  # Instructions

  In the USER AREA of the script (below the changelog), the user can customize the following options:
  (It may be useful to link different versions of the script to different shortcuts.)
  
  - lanes_from_which_to_remove:  "all", "last clicked" or "under mouse"
  
  - ignore_LSB_of_pitch:  Ignore LSB when comparing pitchwheel events
  
  - only_analyze_selected_events:  Ignore unselected events in the target lane

  NOTE: If lanes_from_which_to_remove == "all", each 7-bit lane of 14-bit CCs will be analyzed separately. 
        This will ensure maximum efficiency in removal of redundant events, but may cause 14-bit CCs to 'disappear' 
        since MSB and LSB parts may be deleted separately.
        
  There are two ways in which this script can be run:  
  
  1) First, the script can be linked to its own shortcut key.
  
  2) Second, this script, together with other "js_" scripts that edit the "lane under mouse",
          can each be linked to a toolbar button.  

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
  * v0.9 (2016-05-28)
    + Initial release.
  * v0.91 (2016-06-29)
    + The "Remove Redundant CCs" script has several settings that the user can customize in the script's USER AREA. This is a version of the script with the following settings:
    + CC LANE: CCs will be removed from the lane that is under the mouse at the time the script is called (not from the last clicked lane).
    + SELECTION: Only selected CCs will be analyzed. Unselected CCs will be ignored.
    + MUTED: Muted CCs will automatically be removed since they are inherently redundant.
    + 14BIT CC LSB: When analyzing pitchwheel events, the LSB will be ignored.
  * v2.0 (2016-07-04)
    + All the "lane under mouse" js_ scripts can now be linked to toolbar buttons and run using a single shortcut.
    + Description and instructions are included inside script - please read with REAPER's built-in script editor.
  * v2.1 (2016-11-16)
    + Header and About info updated for ReaPack 1.1 format.
    + IMPROVED SPEED!
  * v3.00 (2016-12-16)
    + Improved speed.
    + Works in 14-bit CC lanes.
    + Requires REAPER v5.30.
  * v3.10 (2017-01-09)
    + Requires REAPER 5.32.
    + Option to analyze all events or only selected events.
]]

-- USER AREA:
-- (Settings that the user can customize)

local lanes_from_which_to_remove = "all" --"last clicked" -- "all", "last clicked" or "under mouse". 

local ignore_LSB_of_pitch = true -- Ignore LSB when comparing pitchwheel events 

local only_analyze_selected_events = true -- true or false

-- End of USER AREA
-----------------------------------------------------------------  


------------------------------------------------------------------------------------------------
-- Set this script as the armed command that will be called by "js_Run the js action..." script.
-- This function is only relevant if lanes_from_which_to_remove = "under mouse".
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
 
 
-----------------------------
-- Code execution starts here
-----------------------------
-- function main()

local editor, take, targetLane
    
local countRedundancies = 0 -- The undo point will be informative, giving the number of redundant CCs deleted

local s_unpack = string.unpack
local s_pack   = string.pack


-- To prevent REAPER from automatically creating an undo point, even if code does not reach own Undo_BeginBlock
--    simply defer any function.
function noUndo()
end
reaper.defer(noUndo)

-- This script does not run a loop in the background, so it can simply delete
--    the extstate.  The other js functions do so in the exit() function.
reaper.DeleteExtState("js_Mouse actions", "Status", true)

-- Test whether user customizable parameters are usable
if not (lanes_from_which_to_remove == "under mouse" 
        or lanes_from_which_to_remove == "last clicked" 
        or lanes_from_which_to_remove == "all") then
    reaper.ShowMessageBox('The setting lanes_from_which_to_remove can only take on the values "under mouse", "last clicked" or "all".', "ERROR", 0)
    return(false) end
if type(ignore_LSB_of_pitch) ~= "boolean" then
    reaper.ShowMessageBox("The setting 'ignore_LSB_of_pitch' can only take on the values 'true' or 'false'.", "ERROR", 0)
    return(false) end
if type(only_analyze_selected_events) ~= "boolean" then
    reaper.ShowMessageBox("The setting 'only_analyze_selected_events' can only take on the values 'true' or 'false'.", "ERROR", 0)
    return(false) end
--[[if type(automatically_delete_muted_CCs) ~= "boolean" then
    reaper.ShowMessageBox("The setting 'automatically_delete_muted_CCs' can only take on the values 'true' or 'false'.", "ERROR", 0)
    return(false) end   ]]

-- Check whether the required version of REAPER is available
version = tonumber(reaper.GetAppVersion():match("(%d+%.%d+)"))
if version == nil or version < 5.32 then
    reaper.ShowMessageBox("This version of the script requires REAPER v5.32 or higher."
                          .. "\n\nOlder versions of the script will work in older versions of REAPER, but may be slow in takes with many thousands of events"
                          , "ERROR", 0)
    return(false)  
end

-- Check whether an editor and take are available (NOT inline) 
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

-----------------------------------------------------------------------------------------------
-- The following sections do two things:
--    * Gets the target CC lane (either last clicked or under mouse)
--    * If the script is in "under mouse" mode, and if the script is called from a toolbar, 
--      it arms the script as the default js_Run function, but does not run the script further.
--      If the mouse is positioned over a CC lane, the script is run.

if lanes_from_which_to_remove == "last clicked" then

    targetLane = reaper.MIDIEditor_GetSetting_int(editor, "last_clicked_cc_lane")
    if targetLane == -1 then
        reaper.ShowMessageBox("No clicked lane found in MIDI editor.\n\n"
                    .."(Hint: To remove CCs from the lane under the mouse instead of the last clicked lane, "
                    .."change the 'lanes_from_which_to_remove' setting in the USER AREA to 'under mouse'.)", "ERROR", 0)
        return(false)
    end
    
elseif lanes_from_which_to_remove == "under mouse" then
    -- Check whether SWS is available
    if not reaper.APIExists("BR_GetMouseCursorContext") then
        reaper.ShowMessageBox("In order to find the CC lane 'under mouse', the script requires the SWS/S&M extension."
                              .."\n\nThe SWS/S&M extension can be downloaded from www.sws-extension.org.", "ERROR", 0)
        return(false) 
    end
    window, segment, details = reaper.BR_GetMouseCursorContext()
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
        isInline, _, laneUnderMouse, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    else 
        _, isInline, _, laneUnderMouse, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    end
    -- If window == "unknown", assume to be called from floating toolbar
    -- If window == "midi_editor" and segment == "unknown", assume to be called from MIDI editor toolbar
    if window == "unknown" or (window == "midi_editor" and segment == "unknown") then
        setAsNewArmedToolbarAction() --************************IMPORTANT*****************************
        return(0) 
    elseif not (details == "cc_lane" or details == "cc_selector") then 
        reaper.ShowMessageBox("Mouse is not over a CC lane.\n\n"
                   .."(Hint: To remove CCs from the last clicked lane instead of the lane under the mouse, "
                   .."change the 'lanes_from_which_to_remove' setting in the USER AREA to 'last clicked'.)"
                   , "ERROR", 0)
        return(false)
    end
        
    if laneUnderMouse == -1 then
        reaper.ShowMessageBox("Could not determine lane under mouse.", "ERROR", 0)
        return(false)
    else
        targetLane = laneUnderMouse
    end         
end

-- Note that if lanes_from_which_to_remove == "all", each 7-bit part of 14-bit CCs will be analyzed separately,
if lanes_from_which_to_remove == "all" then
    laneIsALLCC, laneIsPITCH, laneIsPROGRAM, laneIsCHPRESS = true, true, true, true
else
    if 0 <= targetLane and targetLane <= 127 then -- CC, 7 bit (single lane)
        laneIsCC7BIT = true   
    elseif targetLane == 0x201 then
        laneIsPITCH = true 
    elseif targetLane == 0x202 then
        laneIsPROGRAM = true
    elseif targetLane == 0x203 then -- Channel pressure
        laneIsCHPRESS = true
    elseif 256 <= targetLane and targetLane <= 287 then -- CC, 14 bit (double lane)
        laneIsCC14BIT = true
    else -- not a lane type in which script can be used.
        reaper.ShowMessageBox("This script only works in the following lanes:\n * 7-bit CC lanes,\n * 14-bit CC lanes,\n * Pitchwheel,\n * Channel pressure or \n * Program select.\n\n"
                    .."(Note: The choice of method for removing redundancies from 14-bit CC lanes will depend on the user's intent: "
                    .."For example, LSB information can be removed by simply deleting the CCs in the LSB lane.)"
                    , "ERROR", 0)
        return(false)
    end
end

-----------------------------------------------------------------------------------
-- The source length will be saved and then checked again at the end of the script,
--    to ensure that no inadvertent shifts in PPQ positions happened.
sourceLengthTicks = reaper.BR_GetMidiSourceLenPPQ(take)

----------------------------------------------------------------------------------------------
-- OK, now time to delete events within the active take.
-- This script does not use the standard MIDI API functions such as MIDI_DeleteCC, since these
--    functions are far too slow when dealing with thousands of events.
-- Instead, this script will directly edit the raw MIDI data, using new API functions provided
--    in REAPER v5.30.

-- Note that there are TWO types of redundant events:
--    * Events at the same PPQ position:  Only the last event in the MIDI string will kept.
--    * Events that follow each other with the same values:  Only the first event will be kept.

-- If unsorted MIDI is detected, MIDI_Sort will be called, and the parsing function will restart.
local haveAlreadyCorrectedOverlaps = false
::startAgain::

local gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")

if not gotAllOK then
    reaper.ShowMessageBox("MIDI_GetAllEvts could not load the raw MIDI data.", "ERROR", 0)
    return false 
else

    -----------------------------------------------------------------------------------
    -- OK, got the raw MIDI data, so start setting up variable and table.          
  
    -- Initialize tables of last values
    local tableLastCC = {} -- table with last values for each CC type and channel
    local tableLastPitch = {}
    local tableLastChPress = {}
    local tableLastProgram = {}
    local tableCC14BITvaluesMSB = {} -- In case of 14-bit CCs, a table that indicates whether next CC in pair (at specific channel and PPQ) must be deleted
    local tableCC14BITvaluesLSB = {}
    local tableRemoveCC14BIT = {} -- Must the 14-bit CC at this channel and position be removed?
    for chan = 0, 15 do -- initialize channels for MSB and LSB
        tableLastCC[chan] = {}
        tableLastPitch[chan] = {}
        tableCC14BITvaluesMSB[chan] = {}
        tableCC14BITvaluesLSB[chan] = {}
        tableRemoveCC14BIT[chan] = {}
    end    
    
    -- The non-redundant events will temporarily be stored in this table, before being concatenated into a new MIDIstring
    local tableRemainingEvents = {}
    local r = 0 -- Index in table. Inserting using myTable[r]=x is much faster than table.insert(myTable, x) 

    ------------------------------------
    -- Start iterating through all MIDI.
    -- It is crucial that the MIDI offsets be correctly maintained: When a MIDI
    --    event is deleted, its offset will be added to the next remaining event's
    --    offset.
    
    local offset, flags, msg
    local prevPos, nextPos, unchangedPos = 1, 1, 1
    local runningPPQpos, lastRemainPPQpos = 0, 0
    
    local MIDIlen = MIDIstring:len()
    while nextPos < MIDIlen do
    
        local mustDelete = false
        prevPos = nextPos
        offset, flags, msg, nextPos = s_unpack("i4Bs4", MIDIstring, nextPos)
        
        -- Check for unsorted MIDI
        if offset < 0 and prevPos > 1 then   
            -- Try to sort MIDI by running one of the MIDI editor's native editing actions.
            if not haveAlreadyCorrectedOverlaps then
                reaper.MIDI_Sort(take)
                haveAlreadyCorrectedOverlaps = true
                goto startAgain
            else -- haveAlreadyCorrectedOverlaps == true
                reaper.ShowMessageBox("Unsorted MIDI data has been detected."
                                      .. "\n\nThe script has tried to sort the data, but was unsuccessful."
                                      .. "\n\nSorting of the MIDI can usually be induced by any simple editing action, such as selecting a note."
                                      , "ERROR", 0)
                return false
            end
        end
        
        -- offset OK, so can update runningPPQpos
        runningPPQpos = runningPPQpos + offset
    
        -- Bit 1 of flags gives selection status.
        -- Messages of length 0 are used to change PPQ without adding any MIDI events.
        if msg:len() ~= 0 and (flags&1==1 or only_analyze_selected_events==false) then 
                
            local eventType = msg:byte(1)>>4
            local channel   = msg:byte(1)&0x0F
            local msg2      = msg:byte(2)
            local msg3      = msg:byte(3) -- Channel pressure and Program select do not have 3 bytes, so will be nil
                        
            -- 7-bit and 14-bit CCs
            if eventType == 11 then
            
                if laneIsALLCC then
                    if msg3 == tableLastCC[channel][msg2]
                    --or (flags&2 == 2 and automatically_delete_muted_CCs == true) 
                    then
                        mustDelete = true
                    else
                        -- Check whether there are any other CC events on the same PPQ position, later in MIDI string
                        local evPos = nextPos -- Start search at position of next event in MIDI string
                        local evOffset, evFlags, evMsg
                        ::onSamePPQpos:: -- repeat until an offset is found > 0, or a match is found
                            if evPos >= MIDIlen then 
                                goto completedSearching
                            else
                                evOffset, evFlags, evMsg, evPos = s_unpack("i4Bs4", MIDIstring, evPos)
                                if evOffset == 0 then -- Still on same PPQ position
                                    if (evFlags&1 == 1 or only_analyze_selected_events==false) -- Selected
                                    and evMsg:byte(1)  == (0xB0 | channel) -- Match event type and channel
                                    and evMsg:byte(2) == msg2 -- And same lane
                                    then
                                        -- Found matching CC on same PPQ position
                                        mustDelete = true
                                        goto completedSearching
                                    end
                                    goto onSamePPQpos
                                else -- offset > 0, so no other CC event found on same PPQ position, 
                                    tableLastCC[channel][msg2] = msg3
                                    --goto completedSearching 
                                end
                            end
                        ::completedSearching::
                    end
                
                elseif laneIsCC7BIT then
                    if msg2 == targetLane then
                        if tableLastCC[channel] == msg3 -- If laneIsCC7BIT, no need to differentiate between lanes. Faster table access.
                        --or (flags&2 == 2 and automatically_delete_muted_CCs == true) 
                        then
                            mustDelete = true
                        else
                            -- Check whether there are any other CC events on the same PPQ position, later in MIDI string
                            local evPos = nextPos -- Start search at position of next event in MIDI string
                            local evOffset, evFlags, evMsg
                            ::onSamePPQpos:: -- repeat until an offset is found > 0, or a match is found
                                if evPos >= MIDIlen then 
                                    goto completedSearching
                                else
                                    evOffset, evFlags, evMsg, evPos = s_unpack("i4Bs4", MIDIstring, evPos)
                                    if evOffset == 0 then -- Still on same PPQ position
                                        if (evFlags&1 == 1 or only_analyze_selected_events==false) -- Selected
                                        and evMsg:byte(1)  == (0xB0 | channel) -- Match event type and channel
                                        and evMsg:byte(2) == msg2 -- And same lane
                                        then
                                            -- Found matching CC event on same PPQ position
                                            mustDelete = true
                                            goto completedSearching
                                        end
                                        goto onSamePPQpos
                                    else -- offset > 0, so no other CC event found on same PPQ position, 
                                        tableLastCC[channel] = msg3
                                        --goto completedSearching 
                                    end
                                end
                            ::completedSearching::
                        end
                    end
                    
                elseif laneIsCC14BIT then
                
                    if msg2 == targetLane-256 or msg2 == targetLane-224 then
                    
                        -- Has the (final) 14-bit CC value for this PPQ position already been calculated?
                        -- If not, calculate it, and check backward redundancy.
                        --if tableCC14BITvaluesMSB[channel][runningPPQpos] == nil and tableCC14BITvaluesLSB[channel][runningPPQpos] == nil then
                        if tableRemoveCC14BIT[channel][runningPPQpos] == nil then
                            if msg2 == targetLane-256 then
                                tableCC14BITvaluesMSB[channel][runningPPQpos] = msg3
                                tableCC14BITvaluesLSB[channel][runningPPQpos] = tableLastCC[channel][targetLane-224]
                            else
                                tableCC14BITvaluesMSB[channel][runningPPQpos] = tableLastCC[channel][targetLane-256]
                                tableCC14BITvaluesLSB[channel][runningPPQpos] = msg3
                            end
                            -- Check whether there are any other CC events on the same PPQ position, later in MIDI string
                            local evPos = nextPos -- Start search at position of next event in MIDI string
                            local evOffset, evFlags, evMsg
                            repeat -- repeat until an offset is found > 0, or a match is found
                                if evPos >= MIDIlen then break end
                                evOffset, evFlags, evMsg, evPos = s_unpack("i4Bs4", MIDIstring, evPos)
                                if evOffset == 0 then -- Still on same PPQ position
                                    if (evFlags&1 == 1 or only_analyze_selected_events==false)
                                    and evMsg:byte(1)  == (0xB0 | channel) 
                                    --and (flags&2 == 0 or automatically_delete_muted_CCs == false)
                                    then -- Match event type and channel
                                        if evMsg:byte(2) == targetLane-256 then -- MSB lane
                                            tableCC14BITvaluesMSB[channel][runningPPQpos] = evMsg:byte(3)
                                        elseif evMsg:byte(2) == targetLane-224 then -- LSB lane
                                            tableCC14BITvaluesLSB[channel][runningPPQpos] = evMsg:byte(3)
                                        end
                                    end
                                end
                            until evOffset ~= 0
                            
                            -- Now check whether the *final* 14-bit CC at this PPQ position and channel is backward redundant
                            if (tableCC14BITvaluesMSB[channel][runningPPQpos] == tableLastCC[channel][targetLane-256]
                            and tableCC14BITvaluesLSB[channel][runningPPQpos] == tableLastCC[channel][targetLane-224])
                            then
                                -- If redudant, remove all CCs in this channel and PPQ position
                                tableRemoveCC14BIT[channel][runningPPQpos] = true
                            else
                                tableLastCC[channel][targetLane-256] = tableCC14BITvaluesMSB[channel][runningPPQpos]
                                tableLastCC[channel][targetLane-224] = tableCC14BITvaluesLSB[channel][runningPPQpos]
                                tableRemoveCC14BIT[channel][runningPPQpos] = false
                            end
                        end
                        
                        -- OK, so we've already analyzed the (final) 14-bit CC values for this PPQ position
                        -- Is this 14-bit CC backward redundant?
                        if tableRemoveCC14BIT[channel][runningPPQpos] == true 
                        --or (flags&2 == 2 and automatically_delete_muted_CCs == true)
                            then
                            mustDelete = true
                            
                        -- Check forward redundancy
                        else                            
                            -- Check whether there are any other CC events on the same PPQ position, later in MIDI string
                            local evPos = nextPos -- Start search at position of next event in MIDI string
                            local evOffset, evFlags, evMsg
                            ::onSamePPQpos:: -- repeat until an offset is found > 0, or a match is found
                                if evPos >= MIDIlen then 
                                    goto completedSearching
                                else
                                    evOffset, evFlags, evMsg, evPos = s_unpack("i4Bs4", MIDIstring, evPos)
                                    if evOffset == 0 then -- Still on same PPQ position
                                        if (evFlags&1 == 1 or only_analyze_selected_events==false) -- Selected
                                        and evMsg:byte(1)  == (0xB0 | channel) -- Match event type and channel
                                        and evMsg:byte(2) == msg2 -- And same lane
                                        then
                                            -- Found matching CC event on same PPQ position
                                            mustDelete = true
                                            goto completedSearching
                                        end 
                                        goto onSamePPQpos
                                    end
                                end
                            ::completedSearching::
                        end
                    
                    end -- if msg2 == targetLane-256 or msg2 == targetLane-224        
                          
                end -- if laneIsALLCC / laneIsCC7BIT / laneIsCC14BIT then                

            -- Pitchwheel
            elseif eventType == 14 then 
                if laneIsPITCH then
                    if (ignore_LSB_of_pitch == true and msg3 == tableLastPitch[channel].MSB)
                    or (ignore_LSB_of_pitch == false and msg3 == tableLastPitch[channel].MSB and msg2 == tableLastPitch[channel].LSB)
                    --or (flags&2 == 2 and automatically_delete_muted_CCs == true)
                    then
                        mustDelete = true
                    else
                        -- Check whether there are any other pitch events on the same PPQ position, later in MIDI string
                        local evPos = nextPos -- Start search at position of next event in MIDI string
                        local evOffset, evFlags, evMsg
                        ::onSamePPQpos:: -- repeat until an offset is found > 0, or a match is found
                            if evPos >= MIDIlen then 
                                goto completedSearching
                            else
                                evOffset, evFlags, evMsg, evPos = s_unpack("i4Bs4", MIDIstring, evPos)
                                if evOffset == 0 then -- Still on same PPQ position
                                    if (evFlags&1 == 1 or only_analyze_selected_events==false) -- Selected
                                    and evMsg:byte(1) == (0xE0 | channel) then -- Match Pitch event type and channel
                                        -- Found pitch event on same PPQ position
                                        mustDelete = true
                                        goto completedSearching
                                    end
                                    goto onSamePPQpos
                                else -- No other pitch event found on same PPQ position, 
                                    tableLastPitch[channel].MSB = msg3 
                                    tableLastPitch[channel].LSB = msg2
                                    --goto completedSearching 
                                end
                            end
                        ::completedSearching::
                    end
                end
                
            -- Channel pressure
            elseif eventType == 13 then
                if laneIsCHPRESS then
                    if tableLastChPress[channel] == msg2
                    --or (flags&2 == 2 and automatically_delete_muted_CCs == true)
                    then
                        mustDelete = true
                    else
                        -- Check whether there are any other channel pressure events on the same PPQ position, later in MIDI string
                        local evPos = nextPos -- Start search at position of next event in MIDI string
                        local evOffset, evFlags, evMsg
                        ::onSamePPQpos:: -- repeat until an offset is found > 0, or a match is found
                            if evPos >= MIDIlen then 
                                goto completedSearching
                            else
                                evOffset, evFlags, evMsg, evPos = s_unpack("i4Bs4", MIDIstring, evPos)
                                if evOffset == 0 then -- Still on same PPQ position
                                    if (evFlags&1 == 1 or only_analyze_selected_events==false) -- Selected
                                    and evMsg:byte(1)  == (0xD0 | channel) then -- Match event type and channel
                                        -- Found channel pressure event on same PPQ position
                                        mustDelete = true
                                        goto completedSearching
                                    end
                                    goto onSamePPQpos
                                else -- offset > 0, so no other channel pressure event found on same PPQ position, 
                                    tableLastChPress[channel] = msg2
                                    --goto completedSearching 
                                end
                            end
                        ::completedSearching::
                    end
                end
                                    
            -- Program select
            elseif eventType == 12 then
                if laneIsPROGRAM then
                    if tableLastProgram[channel] == msg2
                    --or (flags&2 == 2 and automatically_delete_muted_CCs == true)
                    then
                        mustDelete = true
                    else
                        -- Check whether there are any other channel pressure events on the same PPQ position, later in MIDI string
                        local evPos = nextPos -- Start search at position of next event in MIDI string
                        local evOffset, evFlags, evMsg
                        ::onSamePPQpos:: -- repeat until an offset is found > 0, or a match is found
                            if evPos >= MIDIlen then 
                                goto completedSearching
                            else
                                evOffset, evFlags, evMsg, evPos = s_unpack("i4Bs4", MIDIstring, evPos)
                                if evOffset == 0 then -- Still on same PPQ position
                                    if (evFlags&1 == 1 or only_analyze_selected_events==false) -- Selected
                                    and evMsg:byte(1)  == (0xC0 | channel) then -- Match event type and channel
                                        -- Found channel pressure event on same PPQ position
                                        mustDelete = true
                                        goto completedSearching
                                    end
                                    goto onSamePPQpos
                                else -- offset > 0, so no other channel pressure event found on same PPQ position, 
                                    tableLastProgram[channel] = msg2
                                    --goto completedSearching 
                                end
                            end
                        ::completedSearching::
                    end
                end
                           
            end -- if eventType ==
                
        end -- if only_analyze_selected == false or flags&1==1
     
        -------------------------------------------------------------
        -- Store events in tables (with updated offsets if necessary)
        if mustDelete then
            countRedundancies = countRedundancies + 1
            -- The chain of unchanged remaining events is broken, so write to tableRemainingEvents
            if unchangedPos < prevPos then
                r = r + 1
                tableRemainingEvents[r] = MIDIstring:sub(unchangedPos, prevPos-1)
            end
            unchangedPos = nextPos
            mustUpdateNextOffset = true
            
        -- The offset of a remaining event only needs to be changed if it follows an extracted event.
        elseif mustUpdateNextOffset then
            r = r + 1
            tableRemainingEvents[r] = s_pack("i4Bs4", runningPPQpos-lastRemainPPQpos, flags, msg)
            lastRemainPPQpos = runningPPQpos
            unchangedPos = nextPos
            mustUpdateNextOffset = false
            
        -- If remaining events that is preceded by other remaining events, postpone writing to table
        else
            lastRemainPPQpos = runningPPQpos
        end -- if mustDelete / mustUpdateNextOffset
            
    end -- while nextPos < MIDIlen
         
    -- Reached end of MIDIstring. Write the last remaining events to table
    --if unchangedPos < MIDIlen then
        r = r + 1
        tableRemainingEvents[r] = MIDIstring:sub(unchangedPos)
    --end   
  
    -------------------------------------------------------------------------------
    -- Finally, (perhaps) going to make some changes to the take. Start Undo block.
    --reaper.Undo_BeginBlock2(0)
    if countRedundancies ~= 0 then
        reaper.MIDI_SetAllEvts(take, table.concat(tableRemainingEvents))
    end    
    
    ---------------------------------------
    -- Create nice, informative undo points
    -- Unfo point that are limited to items, such as Undo_OnStateChange_Item or Undo_EndBlock with flag=4
    --    are much faster than undo point that include everything, which happens when flag=-1 is used.
    item = reaper.GetMediaItemTake_Item(take)
    if lanes_from_which_to_remove == "all" then
        undoString = "Removed ".. tostring(countRedundancies) .. " redundant events from all lanes"
    else -- lanes_from_which_to_remove ~= "all" then
        if laneIsCC7BIT then
            undoString = "Removed ".. tostring(countRedundancies) .. " redundant events from 7-bit CC lane " .. tostring(targetLane)
        elseif laneIsPITCH then
            undoString = "Removed ".. tostring(countRedundancies) .. " redundant events from pitchwheel lane"
        elseif laneIsCHPRESS then
            undoString = "Removed ".. tostring(countRedundancies) .. " redundant events from channel pressure lane"
        elseif laneIsPROGRAM then
            undoString = "Removed ".. tostring(countRedundancies) .. " redundant events from program select lane"
        elseif laneIsCC14BIT then
            undoString = "Removed ".. tostring(countRedundancies) .. " redundant events from 14-bit CC lane " .. tostring(targetLane-256).."/"..tostring(targetLane-224)
        end
    end
    
    ----------------------------------------------------------------
    -- Checked that no inadvertent shifts in PPQ positions occurred.
    if not (sourceLengthTicks == reaper.BR_GetMidiSourceLenPPQ(take)) then
        reaper.MIDI_SetAllEvts(take, MIDIstring) -- Restore original MIDI
        reaper.ShowMessageBox("The script has detected inadvertent shifts in the PPQ positions of unedited events."
                              .. "\n\nThis may be due to a bug in the script, or in the MIDI API functions."
                              .. "\n\nPlease report the bug in the following forum thread:"
                              .. "\nhttp://forum.cockos.com/showthread.php?t=176878"
                              .. "\n\nThe original MIDI data will be restored to the take.", "ERROR", 0)
        undoString = "FAILED: Remove redundant events"
    end
    
    -----------
    -- The End!
    reaper.Undo_OnStateChange_Item(0, undoString, item)
    
end -- if gotAllOK


