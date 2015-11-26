  script_title = "mpl Sort project folder garbage"  
  ---------------- Action -----------------------  
  
  action = 'copy'
  --action = 'move'
  
  -------------- Main Folder --------------------
    
  --common_folder = 'C:/projects_stuff/<project_name>'
  common_folder = '<project_path>'
  
  ------------- Custom folders ------------------
  
  folders = { [1] = {
              ['path'] = common_folder..'/Audio',
              ['ext']  = '.wav .wave .flac .ogg .mp3 .aiff .aifc .aif'},
              [2] = {
              ['path'] = common_folder..'/MIDI',
              ['ext']  = '.mid .midi'},
              [3] = {
              ['path'] = common_folder..'/Peaks',
              ['ext']  = '.reapeaks' }, 
              [4] = {
              ['path'] = common_folder..'/BackUp',
              ['ext']  = '.RPP-bak' },  
              [5] = {
              ['path'] = common_folder..'/Old_Versions',
              ['ext']  = '.RPP' },              
            }
            
  -----------------------------------------------  
  
  ret = reaper.MB('Do you want to '..action..' current project folder garbage to'..
    '\n'..common_folder..' (NO UNDO) ?',
   'Sort project folder garbage', 1)
  
  if ret == 1 then
  
    reaper.Undo_BeginBlock()
    -----------------------------------------------
    OS = reaper.GetOS()
    if OS == "Win32" or OS == "Win64" then slash = '\\' else slash = '/' end
    project_path = reaper.GetProjectPath("")  
    _, project_name = reaper.EnumProjects(-1, '')
    project_name0 = project_name
    repeat
      st1 = string.find(project_name,'\\') if st1 == nil then st1 = 0 end
      st2 = string.find(project_name,'/') if st2 == nil then st2 = 0 end
      st = math.max(st1,st2)    
      project_name = string.sub(project_name, st+1)
    until st == 0
    project_name = string.sub(project_name, 0, -5)
    if project_name == "" then project_name = os.date():gsub(':','.'):gsub(' ', '-') end
    
    -----------------------------------------------
      
    i = 1
    files = {}
    repeat
      str_address = reaper.EnumerateFiles(project_path, i-1)
      if str_address ~= nil and project_path..slash..str_address ~= project_name0 then
        ext = string.sub(str_address, -(str_address:reverse()):find('[.]')) :lower()
        files[i] = {}
        files[i].path = project_path..'/'..str_address
        files[i].ext = ext:lower()
      end
      i = i + 1
    until str_address == nil
  
    -----------------------------------------------
    
    if action == 'move' then if OS == "Win32" or OS == "Win64" then cmd = 'move' else cmd = 'mv' end end
    if action == 'copy' then if OS == "Win32" or OS == "Win64" then cmd = 'copy' else cmd = 'cp' end end
    if OS == "Win32" or OS == "Win64" then mkdir_cmd = 'md' else mkdir_cmd = 'mkdir -p' end 
       
    function sort(src_path, dest_fold)  
      dest_fold = dest_fold:gsub('<project_name>',project_name):gsub('<project_path>',project_path) 
      if OS == "Win32" or OS == "Win64" then       
        dest_fold = dest_fold:gsub('/','\\')
        src_path = src_path:gsub('/','\\')
       else 
        dest_fold = dest_fold:gsub('\\','/') 
        src_path = src_path:gsub('\\','/') 
      end
      
      os.execute(mkdir_cmd..' '..dest_fold)
      os.execute(cmd..' '..src_path..' '..dest_fold)

      count = count + 1
      ret_string = '#'..count..'\n'..
                 'source '..src_path..'\n'..
                 'destination '..dest_fold..'\n'
      return ret_string
    end
    
    ----------------------------------------------- 
    ret_msg = ''
    count = 0
    for i = 1, #files do
      for j = 1, #folders do 
        if files[i] ~= nil then
          s_find1,s_find2 = folders[j].ext:lower():find (files[i].ext)
          ext_len = files[i].ext:len() - 1
          if s_find1 ~= nil and s_find2 ~= nil then      
            if s_find2 - s_find1 == ext_len then           
              ret_msg = ret_msg..sort(files[i].path, folders[j].path)
            end
          end
        end
      end
    end
  
    ----------------------------------------------- 
    reaper.ShowConsoleMsg('Log'..'\n'..ret_msg)
    reaper.Undo_EndBlock(script_title, 1)
    
  end
