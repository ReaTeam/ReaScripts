script_title = "Color pooled MIDI takes as selected reference"

reaper.Undo_BeginBlock()

ref_item = reaper.GetSelectedMediaItem(0,0)
if ref_item ~= nil then
  ref_take = reaper.GetActiveTake(ref_item) 
  if ref_take ~= nil then   
    retval, ref_guid = reaper.BR_GetMidiTakePoolGUID(ref_take)
    ref_col = reaper.GetDisplayedMediaItemColor2(ref_item, ref_take)
  end
end

function main() local i, j, itemcount, item, takecount, take, src
  itemcount = reaper.CountMediaItems(0)
  if itemcount ~= nil then
    for i = 1, itemcount do
      item = reaper.GetMediaItem(0, i-1)  
      if item ~= nil then          
        takecount = reaper.CountTakes(item)
        for j = 1, takecount, 1 do
          take = reaper.GetTake(item, j-1)           
          if take ~= nil then              
            retval, take_guid = reaper.BR_GetMidiTakePoolGUID(take) 
            if take_guid ~= nil then   
              if take_guid == ref_guid then               
                reaper.SetMediaItemTakeInfo_Value(take, "I_CUSTOMCOLOR", ref_col|0x100000)                
                reaper.UpdateItemInProject(item)
              end  
            end  
          end        
        end  
      end  
    end      
  end
end 

main()

reaper.Undo_EndBlock(script_title, 0)
