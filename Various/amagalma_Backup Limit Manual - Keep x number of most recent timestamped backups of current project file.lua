-- @description Backup Limit Manual - Keep x number of most recent timestamped backups of current project file
-- @author amagalma
-- @version 1.03
-- @changelog - Fix for paths starting with space (do not use BR_Win32_GetPrivateProfileString API)
-- @provides . > amagalma_Backup Limit/amagalma_Backup Limit Manual - Keep x number of most recent timestamped backups of current project file.lua
-- @link https://forum.cockos.com/showthread.php?t=255909
-- @donation https://www.paypal.me/amagalma
-- @about
--   The pack consists of three scripts (all have "- Keep x number of most recent timestamped backups of current project file" as a suffix):
--
--   - amagalma_Backup Limit Manual
--   - amagalma_Backup Limit Automatic
--   - Backup Limit Settings
--
--   The Manual version of the script (1) performs a manual cleanup according to the settings. It has the following features:
--   - Automatically takes care of backup files created in the current project directory and in the additional directory if set (both with absolute or relative path)
--   - Works for both saved or unsaved ("untitled") projects
--   - Supports all timestamp formats (both with seconds precision or not)
--   - Has two different modes, according to the settings (keep_one_file_per_date or not)
--   - Can be combined with the Save action (40026) into a custom action, so that it tides things up each time you save
--
--   The Automatic version (2) is a "set and forget" version of the manual version of the script.
--   - A few moments after a backup file is created, it runs automatically the manual version.
--   - It is as light on CPU as it can be!
--   - Can be set on a toolbar if you like, or you can set it as a startup action.
--
--   With the Settings script (3) you can set how many backup files you want to keep (default backup limit = 5) and choose if you want the keep_one_file_per_date mode enabled (default = no).
--   keep_one_file_per_date mode, if enabled, is useful if you do not want to delete all backups earlier than the backup limit that you have set, so that you can return to the state that your project had in a past date.

local function num(str)
  return tonumber(str)
end


files_to_keep = reaper.GetExtState( "amagalma_backup_limit", "files_to_keep" )
keep_one_per_date = reaper.GetExtState( "amagalma_backup_limit", "keep_one_per_date" )

files_to_keep = files_to_keep ~= "" and num(files_to_keep) or 5
keep_one_per_date = keep_one_per_date == "1"


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


local _, fullpath = reaper.EnumProjects( -1 )
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


if not in_proj_dir and not in_add_dir then
  return reaper.defer(function() end)
end


local function GetRPPBackups(dir)
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
          os.remove( files[i][1] )
        end
      end
    else
      for i = files_to_keep + 1, backup_cnt do
        --reaper.ShowConsoleMsg(files[i][1].."\n")
        os.remove( files[i][1] )
      end
    end
  end
end


-- Backup files of current project in project path
if in_proj_dir then
  local in_proj_dir_backups = GetRPPBackups(in_proj_dir)
  DeleteBackups(in_proj_dir_backups)
end


-- Backup files of current project in additional path
if in_add_dir then
  local in_add_dir_backups = GetRPPBackups(in_add_dir)
  DeleteBackups(in_add_dir_backups)
end


reaper.defer(function() end)
