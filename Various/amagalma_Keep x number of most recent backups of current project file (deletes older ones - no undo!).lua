-- @description Keep x number of most recent backups of current project file (deletes older ones - no undo!)
-- @author amagalma
-- @version 1.0
-- @link
--   https://forum.cockos.com/showthread.php?t=138199
--   https://forum.cockos.com/showthread.php?t=180661
-- @donation https://www.paypal.me/amagalma
-- @about
--   Scans the current project directory (and all its sub-directories) for backups (.rpp-bak) of the current project. Keeps the set number of backups and deletes all older ones. Action cannot be undone.
--
--   - Number of backups to keep is set inside the script (default=10) 
--   - Can be combined with Save action (40026) into a custom action, so that it tides things up each time you save.
--   - Requires JS_ReaScriptAPI

-- USER SETTINGS ---------
local files_to_keep = 10
--------------------------


if not files_to_keep or not tonumber(files_to_keep) or files_to_keep < 0 then
  error( "Give a sensible number to 'files_to_keep' inside the script!")
end


local proj, fullpath = reaper.EnumProjects( -1 )
if fullpath == "" then return end


local projpath, filename = fullpath:match("(.+[\\/])(.+)%.[rR][pP]+")
local sep = package.config:sub(1,1)


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
      if file:match("^" .. filename) and file:match("%.[rR][pP]+%-[bB][aA][kK]$") then
        local t,c = {}, 1
        t[1] = dir .. sep .. file
        local _, _, _, _, cTime = reaper.JS_File_Stat( t[1] )
        for att in cTime:gmatch("[^%.%s%:]+") do
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


-- Sort them by creation time
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
  for i = files_to_keep + 1, backup_cnt do
    os.remove( files[i][1] )
  end
end


reaper.defer(function() end)
