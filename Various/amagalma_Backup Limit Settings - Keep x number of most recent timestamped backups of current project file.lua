-- @description Backup Limit Settings - Keep x number of most recent timestamped backups of current project file
-- @author amagalma
-- @version 1.0
-- @provides . > amagalma_Backup Limit/amagalma_Backup Limit Settings - Keep x number of most recent timestamped backups of current project file.lua
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

local files_to_keep = reaper.GetExtState( "amagalma_backup_limit", "files_to_keep" )
local keep_one_per_date = reaper.GetExtState( "amagalma_backup_limit", "keep_one_per_date" )

files_to_keep = files_to_keep ~= "" and tonumber(files_to_keep) or 5
keep_one_per_date = keep_one_per_date == "1"

local accept = {
  yes = true,
  no = false,
  y = true,
  n = false,
  ["0"] = false,
  ["1"] = true
}

::INPUT::
local ok, retval = reaper.GetUserInputs("Backup Limit Settings", 2, "Files to keep ( integer > 0 ),Keep one file per diferent date (y/n)",
             string.format("%i,%s", files_to_keep, keep_one_per_date and "y" or "n") )

local a,b, problem

if ok then
  a,b = retval:match("(.*),(.*)")
  a = tonumber(a)
  if a and a > 0 then
    a = math.ceil(a)
  else
    problem = "'Files to keep' must be a positive number.\n\n"
  end
  b = b:lower()
  if b ~= "" and accept[b] ~= nil then
    b = accept[b] and 1 or 0
  else
    problem = "'Keep one file per diferent date' accepted answers:\n- yes/no\n- y/n\n- 1/0\n\n"
  end
  if problem then
    try = reaper.MB(problem .. "Try again?", "Invalid input!", 1)
    problem = nil
    if try == 1 then
      goto INPUT
    end
  else
    reaper.SetExtState( "amagalma_backup_limit", "files_to_keep", a, true )
    reaper.SetExtState( "amagalma_backup_limit", "keep_one_per_date", b, true )
  end
end

reaper.defer(function() end)
