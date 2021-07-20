-- @description Keep x number of most recent timestamped backups of current project file (deletes older ones - no undo!)
-- @author amagalma
-- @version 1.02
-- @changelog - Accept timestamp formats with either a space or an underscore between date and time
-- @link
--   https://forum.cockos.com/showthread.php?t=138199
--   https://forum.cockos.com/showthread.php?t=180661
-- @donation https://www.paypal.me/amagalma
-- @about
--   Scans the current project directory (and all its sub-directories) for backups (.rpp-bak) of the current project. Keeps the set number of backups and deletes all older ones. Action cannot be undone.
--
--   - Number of backups to keep is set inside the script (default=5)
--   - Keeps one backup per different date no matter what
--   - Works with timestamped backups only
--   - Can be combined with Save action (40026) into a custom action, so that it tides things up each time you save.
--   - Requires JS_ReaScriptAPI

-- USER SETTINGS ---------
local files_to_keep = 5
--------------------------


if not files_to_keep or not tonumber(files_to_keep) or files_to_keep < 0 then
  error( "Give a sensible number to 'files_to_keep' inside the script!")
end


local sep = package.config:sub(1,1)
local proj, fullpath = reaper.EnumProjects( -1 )
local projpath, filename
if fullpath == "" then -- project is unsaved
  filename = "untitled"
  local backupdir = ({reaper.BR_Win32_GetPrivateProfileString( "reaper", "autosavedir", "", reaper.get_ini_file() )})[2]
  if backupdir ~= "" and backupdir:match(sep) then
    projpath = backupdir
  else
    projpath = reaper.GetProjectPath("") .. sep .. backupdir
  end
else -- project is saved
  projpath, filename = fullpath:match("(.+[\\/])(.+)%.[rR][pP]+")
end


local function GetRPPBackups(dir, files)
  -- based on functions by FeedTheCat
  -- https://forum.cockos.com/showpost.php?p=2444088&postcount=18
  local files = files or {}
  local sub_dirs = {}
  local sub_dirs_cnt = 0
  repeat
    local sub_dir = reaper.EnumerateSubdirectories(dir, sub_dirs_cnt)
    if sub_dir then
      sub_dirs_cnt = sub_dirs_cnt + 1
      sub_dirs[sub_dirs_cnt] = dir .. sub_dir
    end
  until not sub_dir
  for dir = 1, sub_dirs_cnt do
    GetRPPBackups(sub_dirs[dir], files)
  end

  local file_cnt = #files
  local i = 0
  repeat
    local file = reaper.EnumerateFiles(dir, i)
    if file then
      i = i + 1
      -- What to look for
      if file:match("^" .. filename .. "%-%d+%-%d+%-%d+[%_%s]%d+%.[rR][pP]+%-[bB][aA][kK]$") then
        local t,c = {}, 1
        t[1] = dir .. sep .. file
        local _, _, _, modifiedTime = reaper.JS_File_Stat( t[1] )
        for att in modifiedTime:gmatch("[^%.%s%:]+") do
          c = c + 1
          t[c] = tonumber(att)
        end
        file_cnt = file_cnt + 1
        files[file_cnt] = t
      end
    end
  until not file
  return files
end


-- Get all backup files of current project in project path (search all directories)
local files = GetRPPBackups(projpath)


-- Sort them by modification time
table.sort(files, function(a,b)
  for i = 2, 7 do
    if a[i] ~= b[i] then
      return a[i] > b[i]
    end
  end
end)


-- Delete older backups if necessary
local backup_cnt = #files
if backup_cnt > files_to_keep then
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
      os.remove( files[i][1] )
    end
  end
end


reaper.defer(function() end)
