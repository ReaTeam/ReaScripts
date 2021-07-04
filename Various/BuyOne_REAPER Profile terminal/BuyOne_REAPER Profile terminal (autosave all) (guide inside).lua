-- @noindex
--[[
ReaScript name: BuyOne_REAPER Profile terminal (autosave all) (guide insie)
Version: 1.0
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
]]

HELP = [[

The script was designed to facilitate sharing one REAPER installation between several users. However this concept can be applied to using the same REAPER installation for different purposes which would likely entail different workflows and thus different setup requirements.

Technically it's achieved by copying files which store REAPER settings from REAPER resource directory to a separate folder homonymous with the profile and which is located under \ProfileTerminalData directory in REAPER resource directory, and then copying them back to the REAPER resource directory when profile is being loaded.

It was inspired by a user feature request from https://forum.cockos.com/showthread.php?t=254201

This script is a simplified version of BuyOne_REAPER Profile terminal (guide inside).lua with minimum functions.

If it was installed via ReaPack it was added to both Main and MIDI Editor sections of the Action list.


▓ ♦ FEATURES


▪▪ Profile creation.

To create a profile simply type in some new profile name in the 'Log in & create / load / update profile' dialogue.

To log in type in a name of an existing profile. If it's different from the last used profile 'Restart prompt' will come up.

It's important to restart REAPER after logging in by responding 'OK' to the 'Restart prompt'. If Restart is denied the profile settings won't be loaded.
When loading a profile, at restart it's not recommended to respond 'Cancel' to 'Save project' dialogue as it may disrupt consistent work of the script for a couple of runs.

To delete a profile entirely delete its folder from \ProfileTerminalData directory located in REAPER resource directory accessible with the action 'Show REAPER resource path in explorer' normally evailabe in the 'Options' menu.


▪▪ Settings storage

The script runs in the background and automatically stores ALL REAPER settings, available as .ini files in REAPER resource directory, in the folder of a created/loaded profile and reloads them when profile is loaded.

After initial storage the script continues to update the settings periodically.

When another instance of the script is launched from another section of the Action list, currently running instance in any section is automatically stopped.

The default rate at which the profile settings are being updated once the script has been started is 5 minutes. A user can set a custom rate from 1 minute onwards (see COMMANDS section below).

Most recently stored settings can be reloaded mid-session provided the update rate is low enough (see COMMANDS section below).

When the script is stopped automatically as REAPER shuts down for example profile settings are updated again to avoid a situation where the most recently stored settings are older than the latest ones due to update cycle not being completed by that time.


▪▪ Status monitor button

The script updates the name of any toolbar button linked to it everytime another profile is loaded. If there're several such buttons in different toolbars the names of all will be updated and all will.

Status monitor button named after the currently loaded profile is lit when the script runs and dims when the script is stopped.

The newly created button will only become available in REAPER after restart.

To any toolbar the button is only added once as long as it's not there to begin with, therefore subsequent commands targeting the same toolbar run from the 'Profile console' won't have any effect.

When new profile is created the status monitor button keeps displaying the last loaded profile name but will light up when the script runs because at this point there's no difference between the last used and the new profile settings. The button name will only display the new profile name after REAPER is restarted and the same new profile is loaded.

First click on the status monitor button stops the script followed by dimming of the button. Second click calls the 'Log in & load/create profile' dialogue.


▓ ♦ COMMANDS (all case ignorant)

Only accepted from the upper field of the 'Log in & create / load / update profile' dialogue. The lower field is a reminder of settings update rate command format (see below).

▪ h —— Help (this text)

▪ profile_name:rate_in_minutes —— set custom settings update rate, e.g. user:10, only whole numbers are supported

▪ open —— open current profile folder

▪ reload —— reload most recently stored profile settings if there's a need to restore any of them

Reloading only makes sense when settings update rate is low enough, otherwise by the time you might need them reloaded they will likely be overwritten.


▓ ♦ SOME TIPS AND WARNINGS

It's not recommended to use several instances of the script loaded from different locations on the hard drive if you intend to also use status monitor buttons, since buttons are instance specific and if linked to different instances won't reflect the login status uniformly.

The file \ProfileTerminalData\ProfileTerminal.ini logs currently loaded profile name to prevent 'Restart prompt' being triggered when logging in to the already loaded profile and alternatively to trigger the prompt when another profile is being loaded. Therefore its deletion is not recommended, because although it eventually will be recreated for the time when it's absent the script might behave inconsistently.

If sharing the same Action list content across profiles is important for work, any update to it in terms of custom actions and scripts done under one profile must be replicated in others. The easiest way would be to export those as .ReaperKeyMap file from one profile and import under another profile as long as custom keyboard shortcuts are either not assigned or manually deleted from .ReaperKeyMap file.


]]


function Msg(param)
reaper.ShowConsoleMsg(tostring(param)..'\n')
end

local r = reaper

-- all global vars are there to accommodate save_settings() function in deferred mode

_, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
scr_name = scr_name:match('([^\\/]+)%.%w+') -- to be used as section name in Get and Set external state
key = 'Active profile' -- to be used as key name in Get and Set external state
sep = r.GetOS():match('Win') and '\\' or '/'
path = r.GetResourcePath()


function set_script_instances_mode(path, sep, cmd_ID, scr_name, Esc)

-- set script mode to 260 to terminate deferred instances without the pop-up dialogue
local cmd_ID = r.ReverseNamedCommandLookup(cmd_ID)
local cmd_ID = cmd_ID:match('RS.-_') and cmd_ID:sub(8) or cmd_ID:sub(3) -- only look for ID without the prefix and the infix

local f = io.open(path..sep..'reaper-kb.ini', 'r')
	if f then -- if file available, just in case
	cont = f:read('*a')
	f:close()
	end
	if cont ~= '' then
	local cont_new = cont -- to make sure the var data is updated along with the loop
		for line in cont:gmatch('[^\n\r]*') do
		local line = line:match('SCR 4.+'..cmd_ID..'.+')
			if line	then -- MIDI Editor section script
			local line_new = line:gsub('SCR 4', 'SCR 260')
			local line = Esc(line)
			cont_new = cont_new:gsub(line, line_new)
			end
		end
		if cont_new ~= cont then
		local f = io.open(path..sep..'reaper-kb.ini', 'w')
		f:write(cont_new)
		f:close()
		end
	end

end


function set_toggle_state_and_refresh_toolbars(sect_ID, cmd_ID, toggle_state)

-- refresh in both sections regardless of the section the script instance is being run from
local add_t = (sect_ID == 0 or sect_ID == 100 or sect_ID == 32063) and {[0] = 0, [32060] = -1} or (sect_ID == 32060 or sect_ID == 32061 or sect_ID == 32062) and {[32060] = 0, [0] = 1} -- commandIDs of the same script from the same path in Main and MIDI Edtitor sections differ by 1 with that stemming from the Main section being greater; the difference by 1 only exists when both instances were loaded simultaneously, if one was added later during a session the difference will be greater until restart
r.RefreshToolbar2(0, cmd_ID + add_t[0]) -- Arrange toolbars
r.RefreshToolbar2(32060, cmd_ID + add_t[32060]) -- MIDI Editor toolbars

local cmd_ID = r.ReverseNamedCommandLookup(cmd_ID) -- get named command ID
local cmd_ID = cmd_ID:match('RS.-_') and cmd_ID:sub(8) or cmd_ID:sub(3) -- only consider ID without the prefix and the infix

local infix_t = {
[0] = '',		   -- Main, 0
[32060] = '7d3c_', -- MIDI Editor, 32060
[32061] = '7d3d_', -- MIDI Event list editor, 32061
[32062] = '7d3e_', -- MIDI Inline editor, 32062
[32063] = '7d3f_'  -- Media Explorer, 32063
}
-- set toggle state for script instances in all Action list sections
	for k, v in pairs(infix_t) do
	r.SetToggleCommandState(k, r.NamedCommandLookup('_RS'..v..cmd_ID), toggle_state)
	end

end



function log_check_restart(profile_term_dir, input, log) -- log and check REAPER restart after loading profile to prevent another restart prompt; log argument is either false or true which is set in the main routine

local file = profile_term_dir..'ProfileTerminal.ini'

-- only runs when act_profile argument is provided
	if log then -- create file and/or log profile for which restart is being performed
	local f = io.open(file, 'w')
	f:write(input)
	f:close()
-- only runs when act_profile argument isn't provided
	else
	local f = io.open(file, 'r') -- evaluate logged profile name against input to prevent restart prompt after restart and logging in to the same profile
		if f then cont = f:read('*a')
		f:close() -- https://stackoverflow.com/questions/58426879/lua-is-file-closing-mandatory
		return cont == input, cont -- the 2nd value is for 'reload' routine only
		end
	end

end



function save_settings() -- copy all .ini files from REAPER resource dir to profile folder; for the loop to work arguments are not allowed, all variables must be global

----------------------------------------------------------
r.EnumerateSubdirectories(path, -1) -- reset cache
local i = 0
--local prof_dir_name = act_profile ~= '' and act_profile or input
	repeat dir = r.EnumerateSubdirectories(profile_dir:match('(.+)'.. input), i) -- access profile_term_dir by truncating profile_dir path
	i = i + 1
	until dir == input or not dir

	if not dir then -- if profile folder got deleted mid-session
	r.MB(' The profile \"'..input..'\" wasn\'t found.','ERROR',0)
	r.DeleteExtState(scr_name, key, 1)
	set_toggle_state_and_refresh_toolbars(sect_ID, cmd_ID, 0)
	r.defer(function() end) return end
-----------------------------------------------------------

local time_curr = os.time()

local rate = rate or 300 -- 5 mins (300 sec) if not specified by the user

	if time and time_curr - time == rate or not time then -- time var is initialized outside of the function; not time allows running the loop just once when no valid time value right after profile creation
	time = time_curr
	local i = 0
		repeat
		local file = r.EnumerateFiles(path..sep, i)
			if file and file ~= '' and file:match('.ini$') then
			local f = io.open(path..sep..file, 'r')
			local cont = f:read('*a')
			f:close()
			local f = io.open(profile_dir..file, 'w')
			f:write(cont)
			f:close()
			end
		i = i + 1
		until not file or file == ''
	end

	if r.GetExtState(scr_name, key) ~= input..tostring(sect_ID) then return end -- stop this script if another instance in another Action list section has been launched

	if type(rate) == 'number' then
	-- only loop when rate value is a number which allows running the function only once right after profile creation and setting custom rate value
	r.defer(save_settings)
	end

end


function load_settings(path, sep, profile_term_dir, prof_dir) -- copy profile files to REAPER resource dir

local profile_dir = profile_term_dir..prof_dir..sep

-----------------------------------------------------
-- same as in save_delete_settings()
r.EnumerateSubdirectories(path, -1) -- reset cache
local i = 0
	repeat dir = r.EnumerateSubdirectories(profile_term_dir, i)
	i = i + 1
	until dir == prof_dir or not dir

	if not dir then -- if profile folder got deleted mid-session
	r.MB(' The profile \"'..prof_dir..'\" wasn\'t found.','ERROR',0)
	r.defer(function() end) return 'abort' end
---------------------------------------------------

	local i = 0
	repeat
	local file = r.EnumerateFiles(profile_dir, i)
		if file and file ~= '' and file:match('.ini$') then
		local f = io.open(profile_dir..file, 'r')
		local cont = f:read('*a')
		f:close()
		local f = io.open(path..sep..file, 'w')
		f:write(cont)
		f:close()
		end
	i = i + 1
	until not file or file == ''

end


function change_check_profile_name(Esc, path, sep, cmd_ID, input, check_name) -- in reaper-menu.ini toolbar code to display in a toolbar button and light the button up if loaded profile name and the button name match

local cmd_ID = r.ReverseNamedCommandLookup(cmd_ID)
-- consider toolbars linked to script instances in both Main and MIDI Editor section of the Action list
local midi_ed_section = cmd_ID:match('RS7d3c_') -- commandIDs of the same script from the same path differ by the presense of an infix, which is absent in the Main section commandID; infix of such sctipt commandID in the MIDI Editor section is '7d3c_'
local cmd_ID_t = midi_ed_section and {cmd_ID:sub(1,2)..cmd_ID:sub(8), cmd_ID} -- Main, MIDI Editor
or {cmd_ID, cmd_ID:sub(1,2)..'7d3c_'..cmd_ID:sub(3)} -- Main, MIDI Editor
local f_path = path..sep..'reaper-menu.ini'
local f = io.open(f_path, 'r')

	if f then -- file won't be available if menus/toolbars have never been modified
	local cont = f:read('*a')
	f:close()
		if cont ~= '' then
			if check_name then -- when check_name arg is present
			local cmd_ID = cmd_ID:match('RS.-_') and cmd_ID:sub(8) or cmd_ID:sub(3) -- only consider ID without the prefix and the infix to accommodate script instances in all section of the Action list
			return cont:match('=_.-'..cmd_ID..' '..input..'\n')
			end

		-- write current profile as button name only when there's no check_name arg, in the main routine it's done on restart
		local cont_new = cont
			for tb in cont:gmatch('%[.-toolbar.-%].-\ntitle=') do -- get only toolbars
			local tb = (tb:match(cmd_ID_t[1]) or tb:match(cmd_ID_t[2])) and tb -- the toolbar contains a button linked to this script
				if tb then
				local cmd_ID = tb:match(cmd_ID_t[1]) and cmd_ID_t[1] or cmd_ID_t[2]
				local line = Esc(tb:match('(=_'..cmd_ID..'.-)\n'))
				local tb_new = tb:gsub(line, '=_'..cmd_ID..' '..input) -- change line within the toolbar code
				local tb = Esc(tb)
				cont_new = cont_new:gsub(tb, tb_new) -- update the toolbar code in reaper-menu.ini, keeps updating with every loop cycle because the var is initialized outside of the loop
				end
			end
		local f = io.open(f_path, 'w')
		f:write(cont_new)
		f:close()
		end -- cont condition end
	end -- f condition end

end


function Esc(str)
return str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
end

function open_prof_dir(path, profile_term_dir, prof_dir, sect_ID, cmd_ID, scr_name, key) -- 'open' command routine

-----------------------------------------------------
-- same as in save_delete_settings()
r.EnumerateSubdirectories(path, -1) -- reset cache
local i = 0
	repeat dir = r.EnumerateSubdirectories(profile_term_dir, i)
	i = i + 1
	until dir == prof_dir or not dir

	if not dir then -- if profile folder got deleted mid-session
	r.MB(' The profile \"'..prof_dir..'\" wasn\'t found.','ERROR',0)
	r.defer(function() end) return end
---------------------------------------------------

	local OS = r.GetOS():sub(1,3)
	local command = OS == 'Win' and {'explorer'} or (OS == 'OSX' or OS == 'mac') and {'open'} or {'nautilus', 'dolphin', 'gnome-open', 'xdg-open', 'gio open', 'caja', 'browse'}
	-- https://askubuntu.com/questions/31069/how-to-open-a-file-manager-of-the-current-directory-in-the-terminal
		for k,v in ipairs(command) do
		local result = r.ExecProcess(v..' '..profile_term_dir..prof_dir, -1)
			if result then return end
		end
end


function exit() -- save settings and reset states at exit
-- save settings, not a function in order to not trigger loop
	local i = 0
		repeat
		local file = r.EnumerateFiles(path..sep, i)
			if file and file ~= '' and file:match('.ini$') then
			local f = io.open(path..sep..file, 'r')
			local cont = f:read('*a')
			f:close()
			local f = io.open(profile_dir..file, 'w')
				if f then f:write(cont)
				f:close() end
			end
		i = i + 1
		until not file or file == ''

-- only change toggle and button states when the same script instance is stopped keeping them ON if another script instance from another Action list section is launched which will stop other instances automatically as set in the save_settings() function
	if r.GetExtState(scr_name, 'Active profile') == input..tostring(sect_ID) then
	set_toggle_state_and_refresh_toolbars(sect_ID, cmd_ID, 0)
	end

end



-------------- START MAIN ROUTINE ---------------

::START::

profile_term_dir = path..sep..'ProfileTerminalData'..sep


	-- Accept input
	retval, input = r.GetUserInputs('Log in & create / load / update profile', 2, 'Profile name or \"h\" for Help,Update rate format: profile name,extrawidth=110', ',:rate in minutes; e.g. my_profile:5')
	input = input:match('%s*(.+),') -- truncate leading space if any and exclude 2nd field which contains info

	-- Evaluate input
	if not retval or not input then r.defer(function() end) return -- abort
	else
	local input = input:lower():gsub(' ','') -- will be accessed in 'create' routine below
		if input:match('^[h]+$') then
		r.ShowConsoleMsg(HELP, r.ClearConsole()) goto START -- display HELP
		elseif input:match('^open$') then -- open profile directory (Profile console)
		local prof_dir = select(2, log_check_restart(profile_term_dir, input, false)) -- profile name is extracted from ProfileTerminal.ini as in this script it's the only stable profile name source, r.GetExtState() stores one only after the script has been launched
			if prof_dir == '' or not prof_dir then r.MB('Could not open profile directory\n\nas profile name is undetermined.','ERROR',0)  -- when ProfileTerminal.ini is empty or unabailable for whatever reason
			else open_prof_dir(path, profile_term_dir, prof_dir, sect_ID, cmd_ID, scr_name, key) end
		goto START
		elseif input:match('^reload$') then -- reload settings
		local prof_dir = select(2, log_check_restart(profile_term_dir, input, false)) -- profile name is extracted from ProfileTerminal.ini as in this script it's the only stable profile name source, r.SetExtState() stores one only after the script has been launched
			if prof_dir == '' or not prof_dir then r.MB('      Could not reload settings\n\nas profile name is undetermined.','ERROR',0) goto START end -- when ProfileTerminal.ini is empty or unabailable for whatever reason
		local resp = r.MB('To reload settings REAPER must be restarted.','PROMPT',1)
			if resp == 2 then r.defer(function() end) return end -- won't be reloaded if denied in the dialogue;
		local retval = load_settings(path, sep, profile_term_dir, prof_dir)
			if retval == 'abort' then goto START end
		r.MarkProjectDirty(0) -- to generate Save prompt if 'undo/prompt to save' is enabled in preferences
		r.Main_OnCommand(40004, 0) -- File: Quit REAPER
		return end -- prevents continuation after 'reload' to avoid treating 'reload' command as input
	end


	input, rate = input:match('([^:]*)(.*)') -- separate profile name and settings update rate value if any
	input = input:match('(.-)%s*$') -- strip out trailing space


set_script_instances_mode(path, sep, cmd_ID, scr_name, Esc) -- set script defer mode in reaper-kb.ini to 260 to prevent pop-up dialogue when stopped; only runs if other than 260


	-- Process input
	profile_dir = profile_term_dir..input..sep
	local i = 0
		repeat
		dir1 = r.EnumerateSubdirectories(path, i)
		i = i + 1
		until dir1 == 'ProfileTerminalData' or not dir1 or dir1 == ''

		if dir1 == 'ProfileTerminalData' then
		local i = 0
			repeat
			dir2 = r.EnumerateSubdirectories(profile_term_dir, i)
			i = i + 1
			until dir2 == input or not dir2 or dir2 == ''
		end

		if not dir1 or dir1 == '' or not dir2 or dir2 == '' then resp = r.MB(' The profile \"'..input..'\" wasn\'t found.\n\n       Should it be created now?','PROMPT',4)
			if resp == 7 then r.defer(function() end) return end
			create = true
		end

		if create -- profile doesn't exist, create one
		then
		r.RecursiveCreateDirectory(profile_dir:match('(.+)'..sep), -1) -- if upper level directory already exists it's skipped and next level is being taken care of, last separator is stripped off so the function can return proper value https://forum.cockos.com/showthread.php?t=250568#10
		r.EnumerateSubdirectories(path, 0) -- reset cache
		local i = 0
			repeat -- check if creation successful
			dir = r.EnumerateSubdirectories(profile_term_dir, i)
			i = i + 1
			until dir == input or not dir or dir == ''

			if dir == input	then -- if successful
			mode, capt, mess = 1, 'PROMPT', '\t  The profile has been created.\n\nThe profile settings will be updated every 5 minutes.\n\n       To set a different update rate click \"Cancel\".' -- creation succeded
			else mode, capt, mess = 5, 'ERROR', '          Profile creation failed.\n\nLikely due to invalid profile name.\n\n  Try selecting a different name.' -- creation failed
			end

		local resp = r.MB(mess, capt, mode)

			if mode == 1 then -- success message output
			r.SetExtState(scr_name, key, input, 0) -- log in
			change_check_profile_name(Esc, path, sep, cmd_ID, input) -- change state monitor button names to match newly created profile name
			local check_name = 1 -- cond to only run button name evaluation routine in the next function, could be set to true, but 1 is shorter; would make sense unless this lengthy comment
				if change_check_profile_name(Esc, path, sep, cmd_ID, input, check_name) then -- evaluate if name change is successful -- ESSENTIALLY REDUNDANT
				set_toggle_state_and_refresh_toolbars(sect_ID, cmd_ID, 1)
				end
			log_check_restart(profile_term_dir, input, true) -- true is the log argument value to allow logging new profile name and avoid restart prompt in the beginning of the next session
			save_settings(path, sep, profile_dir, rate, time)
			-- stems from mode 1
				if resp == 2 then -- set another update rate
				set_toggle_state_and_refresh_toolbars(sect_ID, cmd_ID, 0)
				create = nil -- reset var so profile creation success message doesn't re-appear
				goto START end -- to set another settings update rate
			-- both stem from mode 5; failure message
			elseif resp == 4 then create = nil; goto START -- retry creating profile with diff name; reset create var to prevent create routine from being triggered if on retry a name of an existing profile was entered
			elseif resp == 2 then r.defer(function() end) return
			end

		-- Only prompt to restart when logged and thus active profile is different from the profile being loaded, as long as they're the same logging out and back in won't trigger the prompt
		elseif not create and not log_check_restart(profile_term_dir, input, false) -- false is the log argument value to avoid logging the profile at this stage which would make this cond false, it's only logged at restart; the function is designed to detect difference between last logged profile and input profile name to prompt restart
		then -- profile exists, restart to load one
		local resp = r.MB('               REAPER must be restarted\n\n    for the Profile \"'..input..'\" settings to take effect.\n\n     You will be asked to save your project.\n\n      It\'s not recommended to click \"Cancel\"\n\n             in the \"Save project\" dialogue\n\n    as this will disrupt the script consistency.','RESTART PROMPT', 1) -- displayed after reload as well in which case 'No' should be selected hence next condition
			if resp == 2 then r.defer(function() end) return -- if restart isn't conirmed profile isn't loaded
			else
			r.MarkProjectDirty(0) -- to generate Save prompt if 'undo/prompt to save' is enabled in preferences
			local prof_dir = select(2, log_check_restart(profile_term_dir, input, false)) -- profile name is extracted from ProfileTerminal.ini as in this script it's the only stable profile name source, r.SetExtState() stores one only after the script has been launched
			load_settings(path, sep, profile_term_dir, prof_dir) -- load profile settings to REAPER resource dir
			change_check_profile_name(Esc, path, sep, cmd_ID, input) -- only change button name when restart is confirmed, check_name argument is ommitted so change name routine is the only one running
			log_check_restart(profile_term_dir, input, true) -- true is the log argument value to allow logging profile being loaded and avoid restart prompt after re-logging in
			r.Main_OnCommand(40004, 0) -- File: Quit REAPER
			end
		end -- create cond. end

	r.SetExtState(scr_name, key, input..sect_ID, 0) -- log in
	local check_name = 1 -- cond to only run button name evaluation routine in the following function, could be set to true, but 1 is shorter
		if change_check_profile_name(Esc, path, sep, cmd_ID, input, check_name) then -- only light button when its name matches the active profile name
		set_toggle_state_and_refresh_toolbars(sect_ID, cmd_ID, 1) end
	rate = rate ~= '' and rate:match(':([0-9]+)$') or rate == '' and rate -- $ to catch fractional numbers
		if not rate or #rate > 0 and rate == '0' then -- fractional number or only zero(s), illegal
		local resp = r.MB('\tThe update rate is malformed.\n\n     Only whole numbers are supported except 0.\n\n       Click \"Retry\" to re-log in with correct value\n\nor \"Cancel\" to fall back on default rate of 5 minutes.','ERROR',5)
			if resp == 4 then -- retry
			set_toggle_state_and_refresh_toolbars(sect_ID, cmd_ID, 0)
			goto START
			else rate = nil -- fall back on default rate value; to be evaluated inside save_settings() function below
			end
		elseif #rate > 0 then -- legal
		rate = tonumber(rate)*60 -- calc outside of the deferred function, hopefully more efficient
		elseif rate == '' then rate = nil -- no rate value set, to be evaluated in save_settings() function below
		end
	time = os.time() -- only start loop when the routine reaches here
	save_settings(path, sep, profile_dir, rate, time) -- loop, arguments are just for the info, they're disallowed in deferred functions, all variables are global


r.atexit(exit)






