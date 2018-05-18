--[[
ReaScript name: js_Insert CC or pitch at mouse position, leaving other selected.lua
Version: 2.3
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Screenshot: https://stash.reaper.fm/27602/Insert%20CC%20or%20pitch%20at%20mouse%20position%2C%20leaving%20others%20selected.gif
REAPER version: 5.32 or later
Extensions: SWS/S&M 2.9 or later
Donation: https://www.paypal.me/juliansader
Provides: [main=midi_editor,midi_inlineeditor] .
About:
  # Description  
   
  A simple script to insert a CC events, while leaving other events selected.
  
  Strangely, current (v5.20) versions of REAPER do not offer any mouse modifiers 
      for inserting CC events while keeping already-selected events selected.  
      (Compare the "Insert note, leaving other notes selected" mouse action for notes.)
      
  If snapping to grid is enabled in the MIDI editor, the event will be inserted 
     at the closest grid position *before* the mouse position.
     
  Useful for inserting a series of CC 'nodes' at precise grid positions, 
      which can then be linked by linear ramps.
      
  The script does not yet take swing into account when calculating grid positions.
  
  # Instructions
  
  There are two ways in which this script can be run:  
  
  1) First, the script can be linked to its own shortcut key.
  
  2) Second, this script, together with other "js_" scripts that edit the "lane under mouse",
       can each be linked to a toolbar button.  
     In this case, each script need not be linked to its own shortcut key.  Instead, only the 
        accompanying "js_Run the js_'lane under mouse' script that is selected in toolbar.lua"
        script needs to be linked to a keyboard shortcut (as well as a mousewheel shortcut).
     Clicking the toolbar button will 'arm' the linked script (and the button will light up), 
        and this selected (armed) script can then be run by using the shortcut for the 
        aforementioned "js_Run..." script.
     For further instructions - please refer to the "js_Run..." script. 
]]

--[[
  Changelog:
  * v1.0 (2016-05-05)
    + Initial Release
  * v1.1 (2016-05-18)
    + Added compatibility with SWS versions other than 2.8.3 (still compatible with v2.8.3) 
  * v2.0 (2016-07-04)
    + All the "lane under mouse" js_ scripts can now be linked to toolbar buttons and run using a single shortcut.
    + Description and instructions are included inside script - please read with REAPER's built-in script editor.
  * v2.1 (2017-12-15)
    + Formatted Description and Instructions for ReaPack.
    + Create undo point after each insertion.
  * v2.2 (2018-05-18)
    + Install and work in Inline MIDI editor.
  * v2.3 (2018-05-18)
    + Use active channel of Inline MIDI editor.
]]


local _, editor, take, details, mouseLane, mouseTime, mousePPQpos, startQN, PPQ, QNperGrid, mouseQNpos, 
          mousePPQpos, startQN, PPQ, QNperGrid, mouseQNpos, floorGridQN, floorGridPPQ, destPPQpos, 
          events, count, eventIndex, eventPPQpos, msg, msg1, msg2, eventType,
          tempFirstPPQ, tempLastPPQ, firstPPQpos, lastPPQpos, stretchFactor, newPPQpos
    
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

--------------------------------------------------------------
-- Here the code execution starts
--------------------------------------------------------------
function main()

    if not reaper.APIExists("SN_FocusMIDIEditor") then -- Old versions of SWS have bug in BR_GetMouseCursorContext function
        reaper.ShowMessageBox("This script requires an updated version of the SWS/S&M extension."
                              .."\n\nThe SWS/S&M extension can be downloaded from www.sws-extension.org."
                              , "ERROR", 0)
        return(false)
    end
    
    reaper.DeleteExtState("js_Mouse actions", "Status", true)
    
    window, segment, details = reaper.BR_GetMouseCursorContext()
    -- If window == "unknown", assume to be called from floating toolbar
    -- If window == "midi_editor" and segment == "unknown", assume to be called from MIDI editor toolbar
    if window == "unknown" or (window == "midi_editor" and segment == "unknown") then
        setAsNewArmedToolbarAction()
        return(0) 
    elseif details ~= "cc_lane" then 
        return(0) 
    end
    
    editor, isInline, _, mouseLane, mouseCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
    if mouseCCvalue == -1 then return(0) end  
    
    if isInline then
        take = reaper.BR_GetMouseCursorContext_Take()
        if not (reaper.ValidatePtr(take, "MediaItem_Take*") and reaper.BR_IsMidiOpenInInlineEditor(take)) then
            reaper.MB("Could not determine the take that is open in the inline MIDI editor under mouse.", "ERROR", 0) 
            return(false) 
        end
    else
        take = reaper.MIDIEditor_GetTake(editor)
        if not reaper.ValidatePtr(take, "MediaItem_Take*") then
            reaper.MB("Could not determine the active take in the MIDI editor.", "ERROR", 0) 
            return(false) 
        end
    end
    item = reaper.GetMediaItemTake_Item(take)
    
    --------------------------------------------------------------------
    -- mouseLane = "CC lane under mouse cursor (CC0-127=CC, 0x100|(0-31)=14-bit CC, 
    -- 0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 
    -- 0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207=off velocity)"
    --
    -- eventType is the MIDI event type: 11=CC, 14=pitchbend, etc      
    mouseTime = reaper.BR_GetMouseCursorContext_Position()
    mouseSnapGrid = reaper.SnapToGrid(0, mouseTime)
    mousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, mouseTime)
    
    ------------------------------------------------------------------------------------
    -- If snapping is enabled, get the PPQ position of closest grid BEFORE mouse position
    if isInline then
        snapToGrid = (reaper.GetToggleCommandStateEx(0, 1157) == 1)
    else
        snapToGrid = (reaper.MIDIEditor_GetSetting_int(editor, "snap_enabled") == 1)
    end
    if snapToGrid then
        -- If snap is enabled, we must go through several steps to find the closest grid position
        --     immediately before (to the left of) the mouse position, aka the 'floor' grid.
        -- !! Note that this script does not take swing into account when calculating the grid
        -- First, calculate this take's PPQ:
        startQN = reaper.MIDI_GetProjQNFromPPQPos(take, 0)
        PPQ = reaper.MIDI_GetPPQPosFromProjQN(take, startQN+1)
        -- Calculate position of grid immediately before mouse position
        QNperGrid, _, _ = reaper.MIDI_GetGrid(take) -- Quarter notes per grid
        mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, mousePPQpos) -- Mouse position in quarter notes
        floorGridQN = (mouseQNpos//QNperGrid)*QNperGrid -- last grid before mouse position
        insertPPQpos = reaper.MIDI_GetPPQPosFromProjQN(take, floorGridQN)    
    else 
        -- Otherwise, destination PPQ is exact mouse position
        insertPPQpos = mousePPQpos
    end -- "snap_enabled"
          
          
    -- Get active channel
    if isInline then
        -- REAPER's own GetItemStateChunk is buggy!  
        -- Can't load large chunks!  So must use SWS's SNM_GetSetObjectState.
        local fastStr = reaper.SNM_CreateFastString("")
        local chunkOK = reaper.SNM_GetSetObjectState(item, fastStr, false, false)
        if not chunkOK then 
            reaper.MB("Could not load state chuck of item under mouse", "ERROR", 0)
            return
        end
        chunk = reaper.SNM_GetFastString(fastStr)
        reaper.SNM_DeleteFastString(fastStr)
              
        -- Find current channel and filter
        channelStr = chunk:match("\nCFGEDIT [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ (%d+) ")
        channel = tonumber(channelStr) or 0
        channel = channel - 1 -- InsertCC uses channel numbers 1..16 instead of 0..15
    else
        channel = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")
    end
  
  
    local selected = true
    local muted = false
    if 0 <= mouseLane and mouseLane <= 127 then -- First, test if 7-bit CC (which has no LSB
        reaper.MIDI_InsertCC(take, selected, muted, insertPPQpos, 176, channel, mouseLane, mouseCCvalue)
    elseif mouseLane == 0x203 then  -- channel pressure
        reaper.MIDI_InsertCC(take, selected, muted, insertPPQpos, 13<<4, channel, mouseCCvalue, 0)       
    elseif 256 <= mouseLane and mouseLane <= 287 then -- 14-bit CC's MSB
        MSB = mouseCCvalue>>7
        LSB = mouseCCvalue&127
        reaper.MIDI_InsertCC(take, selected, muted, insertPPQpos, 176, channel, mouseLane-256, MSB)
        reaper.MIDI_InsertCC(take, selected, muted, insertPPQpos, 176, channel, mouseLane-224, LSB) 
    elseif mouseLane == 0x201 then -- pitchwheel
        MSB = mouseCCvalue>>7
        LSB = mouseCCvalue&127        
        reaper.MIDI_InsertCC(take, selected, muted, insertPPQpos, 224, channel, LSB, MSB)
    else
        return
    end
        
    reaper.MIDI_Sort(take)    
    
    -- BUG: InsertCC doesn't mark items dirty!  Neither does MarkTrackItemsDirty!
    -- There apply dummy change to selection
    --reaper.MarkTrackItemsDirty(track, item) -- Doesn't work!
    itemSelected = reaper.IsMediaItemSelected(item)
    reaper.SetMediaItemSelected(item, not itemSelected)
    reaper.SetMediaItemSelected(item, itemSelected)
    reaper.UpdateItemInProject(item)
    reaper.Undo_OnStateChange_Item(0, "Insert CC, leaving others selected", item)
    
end

reaper.defer(function() end) -- Avoid automatic creation of undo point
main()

