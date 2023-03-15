-- @description Backup Limit Automatic - Keep x number of most recent timestamped backups of current project file
-- @author amagalma
-- @version 1.0
-- @provides . > amagalma_Backup Limit/amagalma_Backup Limit Automatic - Keep x number of most recent timestamped backups of current project file.lua
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


-- COMMAND ID of Script: amagalma_Backup Limit Manual -------
local ID = "_RS6704e346ea097632e22ad93c48879a5369f8a4ad"
-------------------------------------------------------------


---------------------------------------------------------------------------------------------------------------------------------------------------
ID = reaper.NamedCommandLookup( ID )
local text = reaper.CF_GetCommandText( 0, ID )
local command_name = "Script: amagalma_Backup Limit Manual - Keep x number of most recent timestamped backups of current project file.lua"

if text ~= command_name then
  reaper.MB("Please, find and copy the Command ID of action :\n\n'" .. command_name .. "'\n\nin the Action List and paste it inside this script.", "Copy Command ID", 0)
  return reaper.defer(function() end)
end

-- Toolbar
local _, _, section, cmdID = reaper.get_action_context()  
reaper.SetToggleCommandState( section, cmdID, 1 ) -- Set ON
reaper.RefreshToolbar2( section, cmdID )

reaper.atexit(function()
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
  return reaper.defer(function() end)
end)


local interval = tonumber(({reaper.BR_Win32_GetPrivateProfileString( "reaper", "autosaveint", "", reaper.get_ini_file() )})[2])
if not interval then interval = 3 end
interval = interval*60 + 1


local start = reaper.time_precise()


local function main()
  local time = reaper.time_precise()
  if time > start + interval then
    if reaper.GetPlayState() & 4 ~= 4 then
      reaper.Main_OnCommand( ID, 0 )
      start = time
    end
  end
  reaper.defer(main)
end


main()
