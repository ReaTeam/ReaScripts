--[[
Description: Create action to open a file...
Version: 1.3.0
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	Add: Linux compatibility (uses xdg-open)
Links:
	Forum Thread http://forum.cockos.com/showthread.php?t=189152
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About:
	Automates the creation of ReaScripts that will open files or folders
	in their native app. Handy for shortcuts to plugin manuals, or commonly
	used folders, etc.

	Note: Due to Reaper limitations, creating a shortcut to a folder requires you
		  to select a file IN that folder, and then manually erase the filename
		  from the path. Sorry. :/
--]]

-- Licensed under the GNU GPL v3

local function osOpenCommand()
  local commands = {
    {os = "Win", cmd = 'start ""'},
    {os = "OSX", cmd = 'open ""'},
    {os = "Other", cmd = 'xdg-open'},
  }

  local OS = reaper.GetOS()

  for _, v in ipairs(commands) do
    if OS:match(v.os) then return v.cmd end
  end
end

local ret, path, csv

reaper.ShowMessageBox("To create an action that opens a folder:\n\n1. Use the next window to select a file in that folder.\n2. Click 'OK'.\n3. Another window will pop up; manually erase the filename there.\n\nThis is a Reaper limitation - sorry for the inconvenience.", "Create action to open a file...", 0)

ret, path = reaper.GetUserFileNameForRead("", "Select a file", "")
if not ret then return 0 end

-- Cheers to @mpl for this.
local num = path:reverse():find('[%/%\\]')
local alias = path:sub(-num + 1) .. " "

ret, csv = reaper.GetUserInputs("Create action to open a file... ", 2, "File/folder path:,File alias:,extrawidth=128", path..","..alias)
if not ret or csv == "" then return 0 end

path, alias = string.match(csv, "([^,]+),([^,]*)")
if not path then return 0 end

local str =		"-- Created with Lokasenna_Create action to open a file... .lua\n"
  .. [[os.execute(']] .. osOpenCommand() .. [[ "]] .. path .. [["')]]
str = string.gsub(str, [[\]], [[\\]])

local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
local file_name = script_path .. "Open a file - " .. alias .. ".lua"

local file, err = io.open( file_name , "w+")
if not file then
	reaper.ShowMessageBox("Couldn't create file:\n" .. file_name .. "\n\nError: " .. tostring(err), "Whoops", 0)
	return 0
end

file:write(str)

reaper.ShowMessageBox( "Successfully created file:\n"
					.. ( string.len(file_name) > 64 and ( "..." .. string.sub(file_name, -56) )
													or 	file_name),
						"Yay!", 0)

io.close(file)

reaper.AddRemoveReaScript( true, 0, file_name, true )
