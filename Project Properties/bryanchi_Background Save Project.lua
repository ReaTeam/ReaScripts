-- @description Background Save Project
-- @author Bryan Chi
-- @version 0.9

r=reaper
dofile(r.GetResourcePath() .. "/UserPlugins/ultraschall_api.lua")



path = r.GetProjectPath()
ProjNm = r.GetProjectName( 0)

filename = path..'/'..ProjNm



current_copyqueue_position = ultraschall.CopyFile_AddFileToQueue(filename, path..'/'..ProjNm..'-bak' , false )
instance_number = ultraschall.CopyFile_StartCopying()
SLEM() 
