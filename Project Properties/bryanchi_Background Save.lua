-- @description Background AutoSave Project
-- @author Bryan Chi
-- @version 0.9
-- @changelog first release
-- @about Uses Ultraschall background copy so Reaper doesn't freeze when saving a big project. Runs in a defer loop to always save the project's latest changes.
r=reaper
ultraschall_path = reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua"
if reaper.file_exists( ultraschall_path ) then
  dofile( ultraschall_path )
end

if not ultraschall or not ultraschall.GetApiVersion then -- If ultraschall loading failed of if it doesn't have the functions you want to use
  reaper.MB("Please install Ultraschall API, available via Reapack. Check online doc of the script for more infos.\nhttps://github.com/Ultraschall/ultraschall-lua-api-for-reaper", "Error", 0)
  return
end

path = r.GetProjectPath()
ProjNm = r.GetProjectName( 0)

TimeGap = 30

filename = path..ProjNm
time1 = reaper.time_precise()


function msg (s)
  r.ShowConsoleMsg(s)
end

function SetButtonState( set )
  local is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
  reaper.SetToggleCommandState( sec, cmd, set or 0 )
  reaper.RefreshToolbar2( sec, cmd )
end




function loop()
 time2 = r.time_precise() 
  if time2 - time1 > TimeGap then 
    time = os.date("*t")
    --if time.min % 5 then -- every 5 mins 

      local Dirty =  r.IsProjectDirty( 0 )
      if Dirty == 1 then 
        path = r.GetProjectPath()
        ProjNm = r.GetProjectName( 0)
        
        filename = path..'/'..ProjNm
        
        current_copyqueue_position = ultraschall.CopyFile_AddFileToQueue(filename, path..'/'..ProjNm..'-bak' , true )
        instance_number = ultraschall.CopyFile_StartCopying()
        SLEM() 
      end
      time1= r.time_precise() 
    --end
  end

  reaper.defer(loop)
end

SetButtonState( 1 )
reaper.defer(loop) 

reaper.atexit( SetButtonState )



