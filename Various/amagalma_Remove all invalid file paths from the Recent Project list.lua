-- @description Remove all invalid file paths from the Recent Project list
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about
--   - All files that are not accessible/available/valid, when the script is run, will be removed
--   - Changes will be visible after a Reaper restart

local inifile = reaper.get_ini_file()
local format = string.format

local retval, maxrecent = reaper.BR_Win32_GetPrivateProfileString( "Reaper", "maxrecent", "", inifile )
if retval ~= 0 then maxrecent = tonumber(maxrecent) else maxrecent = 50 end


local recents = {}
for i = 1, maxrecent do
  local retval, path = reaper.BR_Win32_GetPrivateProfileString( "Recent", format("recent%02d", i), "", inifile )
  if retval ~= 0 then recents[#recents+1] = path end
end

maxrecent = #recents
for i = maxrecent, 1, -1 do
  if not reaper.file_exists( recents[i] ) then
    table.remove( recents, i )
  end
end

if #recents ~= maxrecent then -- REMOVE
  for i = 1, maxrecent do
     reaper.BR_Win32_WritePrivateProfileString( "Recent", format("recent%02d", i), recents[i] or "", inifile )
  end
  reaper.MB( maxrecent-#recents .. " invalid files were removed.\nChanges in the Recent Projects list will be seen after Reaper is restarted.", "Changes were made!", 0 )
else
  reaper.MB( "All paths in the Recent Projects list lead to valid paths.", "No changes were made!", 0 )
end

reaper.defer( function() end )
