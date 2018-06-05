--[[
ReaScript name: js_Tilt selected events in lane under mouse to fit chased values on both sides.lua
Version: 1.02
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
Provides: [main=midi_editor,midi_inlineeditor] .
About:
  # DESCRIPTION  
  
  This script tilts and shifts selected events or down to make the leftmost and rightmost event values
  equal to the chased values on either side.
  
  This is useful for ensuring smooth transitions after editing the selected events.
  
  The script only affects events in the MIDI editor lane that is under the mouse cursor.
  
  Each MIDI channel is handled separately.
  
  The script can be used in 7-bit CC lanes, 14-bit CC lanes, velocity, pitchwheel and channel pressure.
  
  
  # INSTRUCTIONS
  
  To use: 
  1) select MIDI events to be tilted,  
  2) position mouse in lane, 
  3) press shortcut key, and
        
  There are two ways in which this script can be run:  
  
  1) First, the script can be linked to its own shortcut key.  This is the standard method.
    
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
  * v1.00 (2018-05-21)
    + Initial Release
  * v1.02 (2018-05-22)
    + Small bug fixes.
]]


--#####################################################################################################
-------------------------------------------------------------------------------------------------------
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


local MIDI, mouseOrigCClane, laneMin, laneMax
-------------------------------------------------------------------------------------------------
function parseAndTiltMIDI()
    
    local tMIDI = {} -- MIDI string will be disassembled into tMIDI, to be re-concatenated later. 
    local tSel = {} -- tSel stored indices of selected events' values in tMIDI.
    local tSelLSB = {} -- If laneIsCC14BI, indices of LSB events
    for chan = 0, 15 do tSel[chan] = {} tSelLSB[chan] = {} end
    local pos, prevPos = 1, 1 -- Positions inside MIDI string
    local ticks = 0 -- Running PPQ position of events while parsing
    local leftChase, leftSel, rightChase, rightSel = {}, {}, {}, {}
    local leftChaseLSB, leftSelLSB, rightChaseLSB, rightSelLSB = {}, {}, {}, {}
    local offset, flags, msg
    
    if laneIsCC7BIT then
        while pos < #MIDI do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            ticks = ticks + offset
            if #msg == 3 and msg:byte(2) == mouseOrigCClane and (msg:byte(1))>>4 == 11 
            then
                local val = msg:byte(3)
                local chan = msg:byte(1)&0x0F
                if flags&1 == 1 then 
                    if not leftSel[chan] then leftSel[chan] = val end
                    rightSel[chan] = val
                    rightChase[chan] = nil
                    tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-2)
                    tMIDI[#tMIDI+1] = msg:sub(-1)
                    prevPos = pos
                    tSel[chan][#tSel[chan]+1] = {t = #tMIDI, val = val, ticks = ticks}
                else
                    if not leftSel[chan] then leftChase[chan] = val end
                    if not rightChase[chan] then rightChase[chan] = val end
                end
            end
        end
    elseif laneIsCC14BIT then
        while pos < #MIDI do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            ticks = ticks + offset
            if #msg == 3 and (msg:byte(1))>>4 == 11 
            then
                if msg:byte(2) == mouseOrigCClane-256
                then
                    local val = msg:byte(3)
                    local chan = msg:byte(1)&0x0F
                    if flags&1 == 1 then 
                        if not leftSel[chan] then leftSel[chan] = val end
                        rightSel[chan] = val
                        rightChase[chan] = nil
                        tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-2)
                        tMIDI[#tMIDI+1] = msg:sub(-1)
                        prevPos = pos
                        tSel[chan][#tSel[chan]+1] = {t = #tMIDI, val = val, ticks = ticks}
                    else
                        if not leftSel[chan] then leftChase[chan] = val end
                        if not rightChase[chan] then rightChase[chan] = val end
                    end
                elseif msg:byte(2) == mouseOrigCClane-224
                then
                    local val = msg:byte(3)
                    local chan = msg:byte(1)&0x0F
                    if flags&1 == 1 then 
                        if not leftSelLSB[chan] then leftSelLSB[chan] = val end
                        rightSelLSB[chan] = val
                        rightChaseLSB[chan] = nil
                        tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-2)
                        tMIDI[#tMIDI+1] = msg:sub(-1)
                        prevPos = pos
                        tSelLSB[chan][#tSelLSB[chan]+1] = {t = #tMIDI, val = val, ticks = ticks}
                    else
                        if not leftSelLSB[chan] then leftChaseLSB[chan] = val end
                        if not rightChaseLSB[chan] then rightChaseLSB[chan] = val end
                    end
                end -- if msg:byte(2) == mouseOrigCClane-256
            end -- if #msg == 3 and (msg:byte(1))>>4 == 11
        end
    elseif laneIsPITCH then
        while pos < #MIDI do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            ticks = ticks + offset
            if #msg == 3 and (msg:byte(1))>>4 == 14
            then
                local val = (msg:byte(3)<<7) + msg:byte(2)
                local chan = msg:byte(1)&0x0F
                if flags&1 == 1 then 
                    if not leftSel[chan] then leftSel[chan] = val end
                    rightSel[chan] = val
                    rightChase[chan] = nil
                    tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-3)
                    tMIDI[#tMIDI+1] = msg:sub(-2)
                    prevPos = pos
                    tSel[chan][#tSel[chan]+1] = {t = #tMIDI, val = val, ticks = ticks}
                else
                    if not leftSel[chan] then leftChase[chan] = val end
                    if not rightChase[chan] then rightChase[chan] = val end
                end
            end
        end   
    elseif laneIsPROGRAM then 
        while pos < #MIDI do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            ticks = ticks + offset
            if #msg == 2 and (msg:byte(1))>>4 == 12
            then
                local val = msg:byte(2)
                local chan = msg:byte(1)&0x0F
                if flags&1 == 1 then 
                    if not leftSel[chan] then leftSel[chan] = val end
                    rightSel[chan] = val
                    rightChase[chan] = nil
                    tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-2)
                    tMIDI[#tMIDI+1] = msg:sub(-1)
                    prevPos = pos
                    tSel[chan][#tSel[chan]+1] = {t = #tMIDI, val = val, ticks = ticks}
                else
                    if not leftSel[chan] then leftChase[chan] = val end
                    if not rightChase[chan] then rightChase[chan] = val end
                end
            end
        end 
    elseif laneIsCHPRESS then 
        while pos < #MIDI do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            ticks = ticks + offset
            if #msg == 2 and (msg:byte(1))>>4 == 13
            then
                local val = msg:byte(2)
                local chan = msg:byte(1)&0x0F
                if flags&1 == 1 then 
                    if not leftSel[chan] then leftSel[chan] = val end
                    rightSel[chan] = val
                    rightChase[chan] = nil
                    tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-2)
                    tMIDI[#tMIDI+1] = msg:sub(-1)
                    prevPos = pos
                    tSel[chan][#tSel[chan]+1] = {t = #tMIDI, val = val, ticks = ticks}
                else
                    if not leftSel[chan] then leftChase[chan] = val end
                    if not rightChase[chan] then rightChase[chan] = val end
                end
            end
        end 
    elseif laneIsVELOCITY then 
        while pos < #MIDI do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            ticks = ticks + offset
            if #msg == 3 and (msg:byte(1))>>4 == 9 and msg:byte(3) ~= 0
            then
                local val = msg:byte(3)
                local chan = msg:byte(1)&0x0F
                if flags&1 == 1 then 
                    if not leftSel[chan] then leftSel[chan] = val end
                    rightSel[chan] = val
                    rightChase[chan] = nil
                    tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-2)
                    tMIDI[#tMIDI+1] = msg:sub(-1)
                    prevPos = pos
                    tSel[chan][#tSel[chan]+1] = {t = #tMIDI, val = val, ticks = ticks}
                else
                    if not leftSel[chan] then leftChase[chan] = val end
                    if not rightChase[chan] then rightChase[chan] = val end
                end
            end
        end 
    elseif laneIsOFFVEL then 
        while pos < #MIDI do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            ticks = ticks + offset
            if #msg == 3 and (msg:byte(1))>>4 == 8
            then
                local val = msg:byte(3)
                local chan = msg:byte(1)&0x0F
                if flags&1 == 1 then 
                    if not leftSel[chan] then leftSel[chan] = val end
                    rightSel[chan] = val
                    rightChase[chan] = nil
                    tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-2)
                    tMIDI[#tMIDI+1] = msg:sub(-1)
                    prevPos = pos
                    tSel[chan][#tSel[chan]+1] = {t = #tMIDI, val = val, ticks = ticks}
                else
                    if not leftSel[chan] then leftChase[chan] = val end
                    if not rightChase[chan] then rightChase[chan] = val end
                end
            end
        end 
    end
    -- Insert all unselected events remaining
    tMIDI[#tMIDI+1] = MIDI:sub(prevPos, nil)
    
    
    -- In order to handle the two tables of 14-bit CCs, this past is separated in to a function.
    --    First it will be called with the original tSel, and then with tSelSLB.
    --    (The MSB and LSB lanes with therefore be tilted separately.)
    local function tilt()
        for chan = 0, 15 do
            if not leftSel[chan] then goto skipChan end
            leftChase[chan] = leftChase[chan] or leftSel[chan]
            rightChase[chan] = rightChase[chan] or rightSel[chan]
            
            local selRange = tSel[chan][#tSel[chan]].ticks - tSel[chan][1].ticks
            if selRange == 0 then goto skipChan end
            local rangeInv = 1/selRange
            
            leftDiff = leftChase[chan] - leftSel[chan]
            rightDiff = rightChase[chan] - rightSel[chan]
            tiltHeight = rightDiff - leftDiff
            if leftDiff == 0 and rightDiff == 0 then goto skipChan end
            
            for i = 1, #tSel[chan] do
                newVal = math.floor(0.5 + tSel[chan][i].val + leftDiff + (tSel[chan][i].ticks - tSel[chan][1].ticks)*rangeInv*tiltHeight)
                if newVal > laneMax then newVal = laneMax
                elseif newVal < laneMin then newVal = laneMin 
                end
                if laneIsPITCH then
                    tMIDI[tSel[chan][i].t] = string.char(newVal&0x00FF, newVal>>7)
                else
                    tMIDI[tSel[chan][i].t] = string.char(newVal)
                end
            end
            ::skipChan::
        end
    end
    
    tilt()
    if laneIsCC14BIT then 
        tSel, leftChase, leftSel, rightSel, rightChase = tSelLSB, leftChaseLSB, leftSelLSB, rightSelLSB, rightChaseLSB
        tilt() 
    end
    
    MIDI = table.concat(tMIDI)
end -- function tilt()


-------------------------------------------------------------------------------
--#############################################################################
-- Here execution starts!
function main()
    
    -- Start with a trick to avoid automatically creating undo states if nothing actually happened
    reaper.defer(function() end)
    
    
    ----------------------------------------------------------------------------
    -- Check whether SWS is available, as well as the required version of REAPER
    if not reaper.APIExists("MIDI_GetAllEvts") then
        reaper.MB("This version of the script requires REAPER v5.32 or higher."
                              .. "\n\nOlder versions of the script will work in older versions of REAPER, but may be slow in takes with many thousands of events"
                              , "ERROR", 0)
        return(false)
    elseif not reaper.APIExists("SN_FocusMIDIEditor") then
        reaper.MB("This script requires an updated version of the SWS/S&M extension.\n\nThe SWS/S&M extension can be downloaded from www.sws-extension.org.", "ERROR", 0)
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
        reaper.SN_FocusMIDIEditor()
        return(false) 
    else
        -- Communicate with the js_Run.. script that a script is running
        reaper.SetExtState("js_Mouse actions", "Status", "Must quit", false)
    end
    
    
    -----------------------------------------------------------------------------------------
    -- We know that the mouse is positioned over a MIDI editor.  Check whether inline or not.
    -- Also get the mouse starting (vertical) value and CC lane.
    -- mouseOrigPitch: note row or piano key under mouse cursor (0-127)
    -- mouseOrigCClane: CC lane under mouse cursor (CC0-127=CC, 0x100|(0-31)=14-bit CC, 
    --    0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 
    --    0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207=off velocity)
    editor, isInline, _, mouseOrigCClane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
            
    if isInline then
        take = reaper.BR_GetMouseCursorContext_Take()
    else
        if editor == nil then 
            reaper.ShowMessageBox("No active MIDI editor found.", "ERROR", 0)
            return(false)
        else
            take = reaper.MIDIEditor_GetTake(editor)
        end
    end
    if not reaper.ValidatePtr(take, "MediaItem_Take*") then 
        reaper.ShowMessageBox("Could not find an active take in the MIDI editor.", "ERROR", 0)
        return(false)
    end
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
    else]]if 0 <= mouseOrigCClane and mouseOrigCClane <= 127 then -- CC, 7 bit (single lane)
        laneIsCC7BIT = true
        laneMax = 127
        laneMin = 0
    elseif mouseOrigCClane == 0x200 then
        laneIsVELOCITY = true
        laneMax = 127
        laneMin = 1    
    elseif mouseOrigCClane == 0x201 then
        laneIsPITCH = true
        laneMax = 16383
        laneMin = 0
    elseif mouseOrigCClane == 0x202 then
        laneIsPROGRAM = true
        laneMax = 127
        laneMin = 0
    elseif mouseOrigCClane == 0x203 then
        laneIsCHPRESS = true
        laneMax = 127
        laneMin = 0
    --[[elseif mouseOrigCClane == 0x204 then
        laneIsBANKPROG = true
        laneMax = 127
        laneMin = 0]]
    elseif 256 <= mouseOrigCClane and mouseOrigCClane <= 287 then -- CC, 14 bit (double lane)
        laneIsCC14BIT = true
        laneMax = 127 -- In this script, the MSB and LSB 7-bit CCs will be tilted separately, so laneMax is 127 for each.
        laneMin = 0
    --[[elseif mouseOrigCClane == 0x205 then
        laneIsTEXT = true
    elseif mouseOrigCClane == 0x206 then
        laneIsSYSEX = true]]
    elseif mouseOrigCClane == 0x207 then
        laneIsOFFVEL, laneIsNOTES = true, true
        laneMax = 127
        laneMin = 0
    else -- not a lane type in which script can be used.
        reaper.ShowMessageBox("This script will only work in the following MIDI lanes: \n* 7-bit CC, \n* 14-bit CC, \n* Velocity and Off-velocity, \n* Channel Pressure, \n* Pitch, or\n* Program select."--\n* Bank/Program,\n* Text or Sysex,\nor in the 'notes area' of the piano roll."
                              , "ERROR", 0)
        reaper.SN_FocusMIDIEditor()
        return(0)
    end
    
    
    -------------------------------------------
    -- Get the MIDI and start parsing!
    reaper.MIDI_Sort(take)
    OK, MIDI = reaper.MIDI_GetAllEvts(take, "")
        
    parseAndTiltMIDI()
    
    reaper.MIDI_SetAllEvts(take, MIDI)
    
    
    -----------------------------------------------------
    -- All done!  Create undo with nice, informative name
    reaper.UpdateItemInProject(item)
    
    if laneIsCC7BIT then 
        undoString = "Tilt to fit 7-bit CC lane ".. tostring(mouseOrigCClane)
    elseif laneIsCHPRESS then
        undoString = "Tilt to fit channel pressure events"
    elseif laneIsCC14BIT then
        undoString = "Tilt to fit 14 bit-CC lanes ".. 
                                  tostring(mouseOrigCClane-256) .. "/" .. tostring(mouseOrigCClane-224)
    elseif laneIsPITCH then
        undoString = "Tilt to fit pitchwheel"
    elseif laneIsVELOCITY then
        undoString = "Tilt to fit velocities"
    elseif laneIsOFFVEL then
        undoString = "Tilt to fit off-velocities"
    elseif laneIsPROGRAM then
        undoString = "Tilt to fit program select"
    else
        undoString = "Tilt to fit event values"
    end   
    
    reaper.Undo_OnStateChange_Item(0, undoString, item)
end -- function main()


-------------------------------------
--###################################
main()
          
