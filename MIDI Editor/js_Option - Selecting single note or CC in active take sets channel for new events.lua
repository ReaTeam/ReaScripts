--[[
ReaScript name:  js_Option - Selecting single note or CC in active take sets channel for new events.lua
Version: 2.20
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=178256
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION 
  
  Inserting events in the wrong channel is an all-too-easy mistake to make, particularly after 
       switching the active track. With this new option, the user can switch to the correct 
       channel by simply clicking a note or CC of the new track. 
       
   It is intended to be similar to the built-in action "Option: Drawing or selecting 
       a note sets the new note length" (but for channel instead of note length).
       
   NOTE: This script causes the following artefacts:
       ~ If an event in a *new* channel is selected by left-clicking on the event, 
         the event can not be edited immediately; instead, the mouse button must be released first.
         (This can be a useful indicator that the active channel has been changed.)
       ~ While this script is running, it may interact with the manual settings of the MIDI editor's 
         channel filter dropdown menu.
         
  # INSTRUCTIONS
  
  This script can be linked to a toolbar button for easy starting and stopping.
  
  While activated, the toolbar button will light up.
  
  (The first time that the script is stopped, REAPER will pop up a dialog box 
       asking whether to terminate or restart the script.  Select "Terminate"
       and "Remember my answer for this script".)
]]
 
--[[
 Changelog:
  * v1.0 (2016-07-15)
    + Initial release
  * v2.00 (2016-12-19)
    + Improved speed and responsiveness.
    + Requires REAPER v5.30.
  * v2.10 (2017-01-16)
    + Improved speed and responsiveness.
    + CC bug fix.
  * v2.20 (2019-02-23)
    + If MIDI Inspector is active, the Option script can also be enabled with no performance costs.
]]

local prevChannel = 0
local prevHash, prevHashNotes

local matchCCorNote = string.char(91,1,3,93,91,2,3,93,0,0,0,91,0x90,45,0xDF,93) -- [13][23]000[0x90-0xDF] - [selected or muted&selected][msg len 2 or 3]
local matchNoteOn   = string.char(91,1,3,93,     3,   0,0,0,91,0x90,45,0x9F,93) -- [13]3000[0x90-0x9F]
local matchCC       = string.char(91,1,3,93,91,2,3,93,0,0,0,91,0xB0,45,0xDF,93) -- [13][23]000[0xB0-0xDF]

local prevTime = 0

---------------
function exit()
    -- Deactivate toolbar button when exiting
    if not (sectionID == nil or ownCommandID == nil or sectionID == -1 or ownCommandID == -1) then
        reaper.SetToggleCommandState(sectionID, ownCommandID, 0)
        reaper.RefreshToolbar2(sectionID, ownCommandID)
    end
end -- function exit

----------------------------
function loopGetSetChannel()

    local time = reaper.time_precise() -- Spare CPU by not running script too often
    if time > prevTime+0.5 then
    
        prevTime = time
        
        if not reaper.HasExtState("js_Mouse actions", "Status") then
    
            local editor = reaper.MIDIEditor_GetActive()
            if editor ~= nil then 
            
                local newChannel = nil
                inspector = reaper.GetExtState("MIDI Inspector", "Set channel") or ""
                if inspector ~= "" then -- inspector == "Paused" or inspector ~= "Multi" or inspector == channel
                    
                    newChannel = tonumber(inspector) -- nil, if paused or multi
                    
                else
                    
                    local take = reaper.MIDIEditor_GetTake(editor)
                    if reaper.ValidatePtr(take, "MediaItem_Take*") then
                    
                        local hashOK, hash = reaper.MIDI_GetHash(take, false, "")
                        if hashOK and hash ~= prevHash then
            
                            prevHash = hash 
                            
                            local hashNotesOK, hashNotes = reaper.MIDI_GetHash(take, true, "")
                            
                            -- CHECK NOTES:
                            -- Have notes (and perhaps CCs) changed? If so, check everything.
                            -- REAPER's EnumSelNotes and GetNote functions are extremely slow, so instead use GetAllEvts.
                            if hashNotesOK and hashNotes ~= prevHashNotes then
             
                                prevHashNotes = hashNotes
                        
                                local gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
                                if gotAllOK then
                                
                                    -- Note: Why use MIDIstring:byte instead of returning the short sub-string as the third value of string.find?
                                    --    Because string.find's sub-string extraction is surprisingly slow.
                                    local pos1 = MIDIstring:find(matchCCorNote, 1)
                                    if not pos1 then -- Found no selected (and non-muted) notes or CCs
                                        -- nothing   
                                        
                                    -- Notes take precedence, so if note, ignore CCs and only check whether there is more than one note selected
                                    -- Why do notes take precedence?  Because if "CC selection follows note selection" is switched on,
                                    --    selecting a single note may automatically select many CCs.
                                    elseif MIDIstring:byte(pos1+5)&0xF0 == 0x90 then -- Note-On?
                                        local pos2 = MIDIstring:find(matchNoteOn, pos1+1)
                                        if not pos2 then -- found only one selected note, so use channel
                                            newChannel = MIDIstring:byte(pos1+5)&0x0F
                                        end
                                        
                                    -- Got CC, but still check whether any notes are selected
                                    else
                                        -- Check whether there are any selected notes
                                        local pos2 = MIDIstring:find(matchNoteOn, pos1+1)
                                        if pos2 then -- Got one selected note, check whether more than one
                                            local pos3 = MIDIstring:find(matchNoteOn, pos2+1)
                                            if not pos3 then -- Couldn't find more than one note
                                                newChannel = MIDIstring:byte(pos2+5)&0x0F
                                            end
                                        -- No selected notes, so check whether only one selected CC
                                        else
                                            pos2 = MIDIstring:find(matchCC, pos1+1)
                                            if not pos2 then -- Only one selected CC, so use channel
                                                newChannel = MIDIstring:byte(pos1+5)&0x0F
                                            end
                                        end
                                    end                    
                          
                                end -- if gotAllOK
                              
                            -- CHECK CCS:  
                            -- Notes didn't change, but other events did, so only check CCs
                            else
              
                                local CCindex1 = reaper.MIDI_EnumSelCC(take, -1)
                                if CCindex1 ~= -1 then
                                    local CCindex2 = reaper.MIDI_EnumSelCC(take, CCindex1)
                                    if CCindex2 == -1 then
                                        local ccOK, _, _, _, _, chan, _, _ = reaper.MIDI_GetCC(take, CCindex1)
                                        if ccOK then newChannel = chan end
                                    end
                                end
                                    
                            end -- if hashNotesOK and hashNotes ~= prevHashNotes 
                            
                        end -- if hashOK and hash ~= prevHash
                    end -- if reaper.ValidatePtr(take, "MediaItem_Take*")
                end -- if inspector == ""
                
                -- SET NEW CHANNEL:
                if newChannel then
                    local defaultChannel = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")
                    if newChannel ~= defaultChannel then
                        reaper.MIDIEditor_OnCommand(editor, 40482+newChannel)
                    end
                end
                
            end -- if editor ~= nil
        end -- if not reaper.HasExtState("js_Mouse actions", "Status")
    end -- if time > prevTime + 0.5
    
    reaper.runloop(loopGetSetChannel)
    
end -- function loop GetSetChannel

--------------------------------------------------------------------
-- Here the code execution starts
--------------------------------------------------------------------
-- function main()

-- Check whether the required version of REAPER is available
if not reaper.APIExists("MIDI_GetAllEvts") then
    reaper.ShowMessageBox("This script requires REAPER v5.32 or higher.", "ERROR", 0)
    return(false)
end

reaper.atexit(exit)

-- Activate toolbar button when starting
_, _, sectionID, ownCommandID, _, _, _ = reaper.get_action_context()
if not (sectionID == nil or ownCommandID == nil or sectionID == -1 or ownCommandID == -1) then
    reaper.SetToggleCommandState(sectionID, ownCommandID, 1)
    reaper.RefreshToolbar2(sectionID, ownCommandID)
end

reaper.runloop(loopGetSetChannel)
