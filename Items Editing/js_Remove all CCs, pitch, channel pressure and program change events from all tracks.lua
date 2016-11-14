--[[
ReaScript name: Remove all CCs, pitch, channel pressure and program change events from all tracks
Version: 1.00
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
]]

num_items = reaper.CountMediaItems(0)

for i = 0, num_items-1 do
    cur_item = reaper.GetMediaItem(0, i)
    num_takes = reaper.CountTakes(cur_item)
  
    for t = 0, num_takes-1 do
        cur_take = reaper.GetTake(cur_item, t)
        
        if(reaper.TakeIsMIDI(cur_take)) then
          
            -- What is the fastest way of deleting all CCs? 
            -- Here are a few options:
            
            --[[
            _, _, ccevtcnt, _ = reaper.MIDI_CountEvts(cur_take)
            for i = ccevtcnt-1, 0, -1 do
                reaper.MIDI_DeleteCC(cur_take, i)
            end
            ]]
            
            --[[
            repeat
                _, _, ccevtcnt, _ = reaper.MIDI_CountEvts(cur_take)
                if ccevtcnt > 0 then reaper.MIDI_DeleteCC(cur_take, ccevtcnt-1) end
            until ccevtcnt == 0
            ]]
            
            -- This option seems to  be the fastest:
            repeat
                deleteOK = reaper.MIDI_DeleteCC(cur_take, 0)
            until deleteOK == false 
        
        end -- if(reaper.TakeIsMIDI(cur_take))  
     
    end -- for t = 0, num_takes-1 do
  
end -- for i = 0, num_items-1 do

reaper.UpdateArrange()
reaper.Undo_OnStateChange("Remove all CCs from all tracks")
