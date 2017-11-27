--[[
ReaScript name: Remove all CC, pitch, channel pressure and program change events from all tracks
Version: 2.00
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=179065
About:
  # Description
  Removes all CCs, pitch, channel pressure and program change events from all takes and all tracks in project.
]]

--[[
Changelog:
  * v1.00 (2016-09-13)
    + Initial release
  * v2.00 (2017-03-18)
    + Much faster execution, using new API in REAPER v5.30.
]]

CC        = 11
PROGSEL   = 12
CHANPRESS = 13
PITCH     = 14
tRemove = {}

gotInputsOK = false
repeat
    gotInputsOK, userInputs = reaper.GetUserInputs("Remove CCs", 4, "Remove all CCs?,Program changes?,Channel pressure?,Pitchbends?", "y,y,y,y")
    
    if not gotInputsOK then return end
    
    userInputs = userInputs:lower()
    tRemove = nil
    tRemove = {}
    tRemove[CC], tRemove[PROGSEL], tRemove[CHANPRESS], tRemove[PITCH] = userInputs:match("([yn]),([yn]),([yn]),([yn])")
    if not (tRemove[CC] and tRemove[PROGSEL] and tRemove[CHANPRESS] and tRemove[PITCH]) then gotInputsOK = false end
    
until gotInputsOK == true

for i = 11, 14 do
    if tRemove[i] == "y" then tRemove[i] = true else tRemove[i] = false end
end

num_items = reaper.CountMediaItems(0)
for i = 0, num_items-1 do

    cur_item = reaper.GetMediaItem(0, i)
    if reaper.ValidatePtr2(0, cur_item, "MediaItem*") then
    
        num_takes = reaper.CountTakes(cur_item)
        for t = 0, num_takes-1 do
        
            cur_take = reaper.GetTake(cur_item, t)    
            if reaper.ValidatePtr2(0, cur_take, "MediaItem_Take*") and reaper.TakeIsMIDI(cur_take) then
              
                local tableEvents = {}
                local t = 0 -- Table key
                local gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(cur_take, "")
                local MIDIlen = MIDIstring:len()
                local stringPos = 1 -- Position inside MIDIstring while parsing
                local offset, flags, msg
                
                while stringPos < MIDIlen-12 do -- -12 to exclude final All-Notes-Off message
                    offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos)
                    if msg:len() > 1 then
                        if tRemove[msg:byte(1)>>4] == true then
                            msg = ""
                        end
                    end
                    t = t + 1
                    tableEvents[t] = string.pack("i4Bs4", offset, flags, msg)
                end
                
                reaper.MIDI_SetAllEvts(cur_take, table.concat(tableEvents) .. MIDIstring:sub(-12))
            
            end -- if(reaper.TakeIsMIDI(cur_take))  
     
        end -- for t = 0, num_takes-1 do
        
    end -- if reaper.ValidatePtr2(0, curItem, "MediaItem*")
  
end -- for i = 0, num_items-1 do

reaper.UpdateArrange()
reaper.Undo_OnStateChange("Remove all CCs from all tracks")
