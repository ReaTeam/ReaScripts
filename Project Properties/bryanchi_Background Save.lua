-- @description Background Save
-- @author Bryan Chi
-- @version 0.9
-- @changelog first release
-- @about Uses Ultraschall background copy so Reaper doesn't freeze when saving a big project. Runs in a defer loop to always save the project's latest changes.

r=reaper
dofile(r.GetResourcePath() .. "/UserPlugins/ultraschall_api.lua")
u = ultraschall

path = r.GetProjectPath()
ProjNm = r.GetProjectName( 0)

filename = path..ProjNm
time = os.date("*t")

function msg (s)
  r.ShowConsoleMsg(s)
end




function loop()
 i = (i or 0 )+1
  if i > 1000 then 
    time = os.date("*t")
    --if time.min % 5 then -- every 5 mins 

      local Dirty =  r.IsProjectDirty( 0 )
      if Dirty == 1 then 
        path = r.GetProjectPath()
        ProjNm = r.GetProjectName( 0)
        
        filename = path..'/'..ProjNm
        
        
        
        current_copyqueue_position = ultraschall.CopyFile_AddFileToQueue(filename, path..'/'..ProjNm..'-bak' , false )
        instance_number = ultraschall.CopyFile_StartCopying()
        SLEM() 
      end
    --end
  end

  reaper.defer(loop)
end

reaper.defer(loop) 




