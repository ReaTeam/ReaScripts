-- @description Backup Limit Stand-Alone - Keep x number of most recent timestamped backups of the selected project(s) (browse to specify)
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showthread.php?t=255909
-- @donation https://www.paypal.me/amagalma
-- @about
--   This is a stand-alone version of the amagalma_Backup Limit Manual script. Instead of working with the current project, you can browse and specify one or more projects.
--
--   It performs a manual cleanup according to the settings. It has the following features:
--   - You can specify any number of projects
--   - Automatically takes care of backup files created in the current project directory and in the additional directory if set (both with absolute or relative path)
--   - Supports all timestamp formats (both with seconds precision or not)
--   - You can specify how many backups you want to keep (default backup limit = 5) 
--   - "Keep one file per different date" setting, if enabled, will keep one backup per different date that is earier than the backup limit that you have set, so that you can return to the state that your project had in a past date (default = enabled).


-- Browse for files
local defsavepath = ({reaper.BR_Win32_GetPrivateProfileString("reaper", "defsavepath", "", reaper.get_ini_file())})[2]
local retval, filelist = reaper.JS_Dialog_BrowseForOpenFiles("Choose project file(s) to clean backups", defsavepath, "", "REAPER Project files (*.RPP)\0*.rpp\0\0", true )
local project_paths = {}
if retval == 1 then
  local t = {}
  for path in filelist:gmatch("%Z+") do
    t[#t+1] = path
  end
  if #t > 1 then
    for i = 2, #t do
      project_paths[i-1] = t[1] .. t[i]
    end
    table.sort(project_paths, function(a,b) return a<b end)
  elseif #t == 1 then
    project_paths[1] = t[1]
  else
    return reaper.defer(function() end )
  end
else
  return reaper.defer(function() end )
end


local function num(str)
  return tonumber(str)
end


-- SPECIFY NUMBER OF FILES TO KEEP

files_to_keep = 5
keep_one_per_date = true

local accept = {
  yes = true,
  no = false,
  y = true,
  n = false,
  ["0"] = false,
  ["1"] = true
}

::INPUT::
local ok, retval = reaper.GetUserInputs("Backup Limit Settings", 2, "Files to keep ( integer > 0 ),Keep one file per different date (y/n)",
             string.format("%i,%s", files_to_keep, keep_one_per_date and "y" or "n") )

local a,b, problem

if ok then
  a,b = retval:match("(.*),(.*)")
  a = num(a)
  if a and a > 0 then
    a = math.ceil(a)
  else
    problem = "'Files to keep' must be a positive number.\n\n"
  end
  b = b:lower()
  if b ~= "" and accept[b] ~= nil then
    b = accept[b] and 1 or 0
  else
    problem = "'Keep one file per different date' accepted answers:\n- yes/no\n- y/n\n- 1/0\n\n"
  end
  if problem then
    local try = reaper.MB(problem .. "Try again?", "Invalid input!", 1)
    problem = nil
    if try == 1 then
      goto INPUT
    else
      return reaper.defer(function() end )
    end
  else
    files_to_keep = a ~= "" and num(a) or 5
    keep_one_per_date = b == 1
  end
end



-- FUNCTIONS ------------------------------------


local match = string.match
local sep = package.config:sub(1,1)
local ini = reaper.get_ini_file()


local function GetAdditionalDir(projpath)
  local autosavedir
  local file = io.open(ini)
  io.input(file)
  for line in io.lines() do
    autosavedir = line:match("autosavedir=([^\n\r]+)")
    if autosavedir then break end
  end
  file:close()
  if autosavedir then
    local absolute
    if match(reaper.GetOS(), "Win") then
      if autosavedir:match("^%a:\\") or autosavedir:match("^\\\\") then
        absolute = true
      end
    else -- unix
      absolute = autosavedir:match("^/")
    end
    if not absolute then
      if projpath then
        autosavedir = projpath .. sep .. autosavedir
      else
        autosavedir = reaper.GetProjectPath("") .. sep .. autosavedir
      end
    end
    return autosavedir
  end
end


local function GetPaths( fullpath )
  local projpath, proj_filename, in_add_dir, in_proj_dir
  if fullpath == "" then -- project is unsaved
    proj_filename = "untitled"
    in_add_dir = GetAdditionalDir()
  else -- project is saved
    projpath, proj_filename = fullpath:match("(.+)[\\/](.+)%.[rR][pP]+")
    local saveopts = num(({reaper.BR_Win32_GetPrivateProfileString( "reaper", "saveopts", "", ini )})[2])
    if saveopts & 4 == 4 or saveopts & 16 == 16 then -- Save to timestamped file in project directory
      in_proj_dir = projpath
    end
    if saveopts & 8 == 8 then -- Save to timestamped file in additional directory
      in_add_dir = GetAdditionalDir(projpath)
    end
  end
  return projpath, proj_filename, in_add_dir, in_proj_dir
end


local function GetRPPBackups(dir, proj_filename)
  local files = {}
  local i, file_cnt = 0, 0
  repeat
    local file = reaper.EnumerateFiles(dir, i)
    if file then
      i = i + 1
      -- What to look for
      local y,m,d,h,min,s = match(file, "^" .. proj_filename .. "%-(%d+)%-(%d+)%-(%d+)%_(%d%d)(%d%d)(%d?%d?)%.[rR][pP]+%-[bB][aA][kK]$") 
      if y then
        file_cnt = file_cnt + 1
        files[file_cnt] = {dir .. sep .. file, num(y), num(m), num(d), num(h), num(min), num(s) or 0 }
      end
    end
  until not file
  -- Sort them by creation time
  table.sort(files, function(a,b)
    for i = 2, 7 do
      if a[i] ~= b[i] then
        return a[i] > b[i]
      end
    end
  end)
  return files
end


local function DeleteBackups(files)
  local report, rep_cnt, success_cnt = {}, 0, 0
  local backup_cnt = #files
  if backup_cnt > files_to_keep then
    if keep_one_per_date then
      local delete
      local keepdate = {files[files_to_keep][2], files[files_to_keep][3], files[files_to_keep][4] }
      for i = files_to_keep + 1, backup_cnt do
        delete = true
        for j = 2, 4 do
          if files[i][j] ~= files[i-1][j] then
            keepdate = {files[i][2], files[i][3], files[i][4] }
            delete = false
            break
          end
        end
        if delete then
          --reaper.ShowConsoleMsg(files[i][1].."\n")
          local ok, msg = os.remove( files[i][1] )
          if ok then
            success_cnt = success_cnt + 1
          else
            rep_cnt = rep_cnt + 1
            report[rep_cnt] = "[ files[i][1] ] : " .. msg
          end
        end
      end
    else
      for i = files_to_keep + 1, backup_cnt do
        --reaper.ShowConsoleMsg(files[i][1].."\n")
        local ok, msg = os.remove( files[i][1] )
        if ok then
          success_cnt = success_cnt + 1
        else
          rep_cnt = rep_cnt + 1
          report[rep_cnt] = "[ files[i][1] ] : " .. msg
        end
      end
    end
  end
  return success_cnt, report
end



local function DeleteProjectBackups( fullpath )
  local projpath, proj_filename, in_add_dir, in_proj_dir = GetPaths( fullpath )
  
  if not in_proj_dir and not in_add_dir then return end
  
  local report = {[1] = 'Report for project : "' .. proj_filename .. '"\n'}
  report[2] = string.rep("=", #report[1]) .. "\n"
  
  -- Backup files of current project in project path
  if in_proj_dir then
    local in_proj_dir_backups = GetRPPBackups(in_proj_dir, proj_filename)
    local in_proj_dir_success_cnt, in_proj_dir_report = DeleteBackups(in_proj_dir_backups)
    if in_proj_dir_success_cnt ~= 0 then
      report[#report+1] = "In project directory ( " .. in_proj_dir .. " ) :\n"
      report[#report+1] = "Deleted " .. in_proj_dir_success_cnt .. " backups\n"
    else
      report[#report+1] = "No backups needed to be deleted in path : " .. in_proj_dir .. "\n"
    end
    if #in_proj_dir_report ~= 0 then
      report[#report+1] = table.concat(in_proj_dir_report, "\n")
    end
  end
  
  -- Backup files of current project in additional path
  if in_add_dir then
    local in_add_dir_backups = GetRPPBackups(in_add_dir, proj_filename)
    local in_add_dir_success_cnt, in_add_dir_report = DeleteBackups(in_add_dir_backups)
    if in_add_dir_success_cnt ~= 0 then
      report[#report+1] = "In additional directory ( " .. in_add_dir .. " ) :\n"
      report[#report+1] = "Deleted " .. in_add_dir_success_cnt .. " backups\n"
    else
      report[#report+1] = "No backups needed to be deleted in path : " .. in_add_dir .. "\n"
    end
    if #in_add_dir_report ~= 0 then
      report[#report+1] = table.concat(in_add_dir_report, "\n")
    end
  end
  
  report[#report+1] = "\n***\n\n\n"
  reaper.ShowConsoleMsg(table.concat(report))
end


-- MAIN ------------------------------------

for prj = 1, #project_paths do
  if reaper.file_exists( project_paths[prj] ) then
    DeleteProjectBackups( project_paths[prj] )
  else
    reaper.ShowConsoleMsg( "Wrong path : " .. project_paths[prj] .. "\n" )
  end
end
reaper.defer(function() end)
