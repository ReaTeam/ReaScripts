--[[
 * ReaScript Name:  Insert CC or pitch event at mouse position, leaving other events selected
 * Description:  A simple script to insert a CC events, while leaving other events selected.
 *               Strangely, current (v5.20) versions of REAPER does not offer any mouse modifiers 
 *                   for inserting CC events while keeping already-selected events selected.  
 *                   (Compare the "Insert note, leaving other notes selected" mouse action for notes.)
 *               If snapping to grid is enabled in the MIDI editor, the event will be inserted 
 *                   at the closest grid position *before* the mouse position.
 *               Useful for inserting a series of CC 'nodes' at precise grid positions, 
 *                   which can then be linked by linear ramps.
 *               The script does not yet take swing into account when calculating grid positions.
 * Instructions: 
 * Screenshot: 
 * Notes: 
 * Category: 
 * Author: juliansader
 * Licence: GPL v3
 * Forum Thread: 
 * Forum Thread URL: http://forum.cockos.com/showthread.php?t=176878
 * Version: 1.0
 * REAPER: 5.20
 * Extensions: SWS/S&M 2.8.3
]]
 

--[[
 Changelog:
 * v0.9 (2016-05-05)
    + Initial Release
  
]]

-- USER AREA
 

local _, editor, take, details, mouseLane, mouseTime, mousePPQpos, startQN, PPQ, QNperGrid, mouseQNpos, 
          mousePPQpos, startQN, PPQ, QNperGrid, mouseQNpos, floorGridQN, floorGridPPQ, destPPQpos, 
          events, count, eventIndex, eventPPQpos, msg, msg1, msg2, eventType,
          tempFirstPPQ, tempLastPPQ, firstPPQpos, lastPPQpos, stretchFactor, newPPQpos
    
editor = reaper.MIDIEditor_GetActive()
take = reaper.MIDIEditor_GetTake(editor)
_, _, details = reaper.BR_GetMouseCursorContext()
_, _, mouseLane, mouseCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI() 

if details ~= "cc_lane" or mouseCCvalue == -1 then return(0) end -- function should only run if mouse is in a CC lane     

reaper.Undo_BeginBlock()

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
if (reaper.MIDIEditor_GetSetting_int(editor, "snap_enabled")==1) then
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
      
selected = true
muted = false
channel = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")
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
    end
    
reaper.MIDI_Sort(take)
reaper.Undo_EndBlock("Insert CC, leaving others selected", -1)
