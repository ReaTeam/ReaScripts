-- @noindex
--[[
ReaScript name: BuyOne_REAPER Profile terminal (guide inside)
Version: 1.0
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
]]


HELP = [[

The script was designed to facilitate sharing one REAPER installation between several users. However this concept can be applied to using the same REAPER installation for different purposes which would likely entail different workflows and thus different setup requirements.

Technically it's achieved by copying files storing REAPER settings from REAPER resource directory to a separate folder homonymous with the profile and which is located under \ProfileTerminalData directory in REAPER resource directory, and then copying them back to the REAPER resource directory when profile is being loaded.

It was inspired by a user feature request from https://forum.cockos.com/showthread.php?t=254201

The script is complete with Help accessible from its dialogues.

If it was installed via ReaPack it was added to both Main and MIDI Editor sections of the Action list.


▓ ♦ 'Log in & load/create profile' dialogue

Meant for logging in or creating a profile and logging in.

To create a profile simply type in some new profile name. Names preceded with semicolon (;) aren't supported since it's used as a modifier (see 'COMMANDS SUMMARY' section below), which shouldn't be particulartly limiting.

To log in type in a name of an existing profile. If it's different from the last used profile 'Restart prompt' will come up.

It's important to restart REAPER after logging in by responding 'OK' to the 'Restart prompt'. If Restart is denied the profile settings won't be loaded.

After restart it's not nesessary to log in again unless you want access to the 'Profile console' to manage your profile settings or update them at the end of the session. Without logging in the settings will still be available which is also true after logout from the currently active profile during the session.
The settings of a loaded profile remain active until another profile is loaded and REAPER restarted.

To be able to load another profile the user must first log out of the current one using 'out' or 'oout' commands in the 'Profile console' (see 'COMMANDS SUMMARY' section below).


▓ ♦ 'Profile console'

This is where all the rest of operations are performed.

It's accessible when the user of the currently loaded profile is logged in.

Here you manage your profile settings, are able to open your profile folder, log out of the profile and close REAPER, all with the commands listed in the 'COMMANDS SUMMARY' section below.

	► Currently 'Profile console' supports following settings:

▪ Everything —— all settings listed below
▪ Global and last session settings —— reaper.ini
▪ Window pin states —— reaper-pinstates.ini
▪ Modal window positions —— REAPER-wndpos.ini
▪ Menus —— reaper-menu.ini
▪ Action and script shortcuts —— reaper-kb.ini
▪ Mouse modifiers —— reaper-mouse.ini
▪ Screensets —— reaper-screensets.ini
▪ FX folders and shortcuts —— reaper-fxfolders.ini, reaper-fxoptions.ini
▪ Default FX presets —— reaper-defpresets.ini
▪ Monitor FX chain —— reaper-hwoutfx.ini
▪ Render settings and presets —— reaper-render.ini
▪ SWS Extension global —— S&M.ini
▪ SWS Extension autocolor —— sws-autocoloricon.ini
▪ SWS Extension cycle actions —— S&M_Cyclactions.ini


'Profile console' setting slots which correspond to the settings stored in the currently active profile are autofilled with the digit 1.
If some settings were saved for which there're no corresponding .ini files in the REAPER resource directory because some functions hadn't been used/modified yet their slots won't be autofilled with 1 in the 'Profile console'.
If 'Everything' slot was used to store the settings but not all types of files were available in REAPER resource directory to begin with because some functions hadn't been used/modified yet, autofill will fill out individual slots instead of the slot 'Everything'.
When 'Everything' slot is the only one filled out, meaning all possible settings are stored under the current profile, in order to delete some of them remove the digit 1 from the 'Everything' slot and use 0s to delete them (see 'COMMANDS SUMMARY' section below), otherwise instead of some settings being deleted all settings will be updated.
To delete all settings from the current profile it siffices to submit 0 in the 'Everything' slot regardless of the other slots state.

To delete profile entirely delete its folder from \ProfileTerminalData directory located in REAPER resource directory accessible with the action 'Show REAPER resource path in explorer' normally evailabe in the 'Options' menu.

With command 'auto' run from the 'Profile console' the script can be set to continuously automatically update current profile settings every N minutes while you work in REAPER. Be aware that in this case you will lose the ability to restore using 'reload' command the profile settings saved during previous session if you happen to need them, because by that time they will be overwtitten with the most recent settings. (See 'COMMANDS SUMMARY' section below).
When the script is launched in 'auto' mode the slots of the settings to be updated must not be empty but filled out with the digit 1 in the 'Profile console'.
To stop the 'auto' mode run the script again and if 'ReaScript task control' dialogue appears tick 'Remember my answer for this script' checkbox and click 'Terminate all instances' button. Next time the dialogue won't pop up. But if all goes well it won't pop up to begin with.
When a script instance is in 'auto' mode its dialogues are inaccessible, but they're accessible from its other instances residing in other Action list sections and so it can also be stopped from 'Profile console' of such other instances (see 'COMMANDS SUMMARY' section below).
A running instance of the script is also stopped when a user logs out of the current profile using 'Profile console' of its another instance (see 'COMMANDS SUMMARY' section below).
When any instance of the sctipt runs in 'auto' mode, in the ribbon of 'Profile console' in all other instances an indication 'AUTO' is displayed.
Only one instance of the script out of all its instances in all Action list sections can run in 'auto' mode. Setting any of its instances to run in 'auto' mode automatically stops all other running instances.


▓ ♦ STATUS MONITOR BUTTON

The script provides an option to automatically add and/or use status monitor button in a toolbar.

This is done with relevant command listed in the COMMANDS SUMMARY section below. However you can add such button manually as well by linking a new toolbar button to this script.

To the Main toolbar and MIDI Paino roll toolbar (both are main in Arrange in MIDI Editor respectively) button will only be added via the script if these were already edited previously. This is to avoid ovewriting their default content. With floating toolbars there's no such limitation.

When the button is added under a profile which didn't have 'Menu' setting such setting is stored in it and after 'Profile console' is refreshed the 'Menu' slot is filled out with 1 indicating its storage. If the profile did have 'Menu' setting its updated with the new content which includes the newly added button.

The newly created button will only become available in REAPER after restart.

To any toolbar the button is only added once as long as it's not there to begin with, therefore subsequent commands targeting the same toolbar run from the 'Profile console' won't have any effect.

The name of status monitor button indicates currently loaded profile. The button name is updated everytime another profile is loaded. The script updates the name of any toolbar button linked to it, if there're several in different toolbars the names of all will be updated.

The status monitor button is lit when the user of currently loaded profile is logged in. When the user is logged out of the profile the button dims but the profile settings remain active and so the button name.

When new profile is created the status monitor button keeps displaying the last loaded profile name but will light up at log-in because at this point there's no difference between the last used and the new profile settings. The button name will only display the new profile name after REAPER is restarted and the same new profile is loaded.

The status monitor button state changes in all Arrange toolbars it's been added to regardless of the Action list section from which the script instance has been used to perform a login or logout. The button in MIDI Editor toolbars will only change its state to ON when the MIDI Editor is active or the script is run from the MIDI Editor section of the Action list.

And the button of course can be used to actually run the script.


▓ ♦ COMMANDS SUMMARY (all case ignorant)

	► Available in both 'Log in & load/create profile' dialogue and the 'Profile console'

▪ h —— Help (this text)

	► Only avalable in 'Log in & load/create profile' dialogue

▪ ; —— when immediately precedes the profile name, log in and open 'Profile console'; status monitor button state won't be updated until the console is closed

	► Only avalable in the 'Profile console'

Only in the slots which correspond to the setting(s) being managed:
▪ 1 —— save/update a setting
▪ 0 —— delete a setting

From any empty slot:
▪ open —— open current profile folder
▪ oopen —— open current profile folder and keep 'Profile console' open
▪ toolbar# —— add status monitor button to a toolbar where # is toolbar number in the following format:
--		Arrange floating toolbar numbers: 1 - 16
--		MIDI floating toolbar numbers: 1m - 8m
--		Main toolbar number: 0
--		MIDI Editor main toolbar number: 0m
--		e.g. toolbar0m, toolbar11 (MIDI Editor main toolbar, Arrange Floating toolbar 11 respectively)
▪ auto# —— set the script to update current profile settings automatically every some minutes where # is an integer (non-fractional number) indicating the number of minutes, e.g. auto5; only minute unit is supported and all digits except 0
▪ auto0 —— cancel automatic settings update mode; to be used from another script instance in another section of the Action list since the running instance itself can be stopped by running it again
▪ reload —— reload current profile settings if there's a need to restore some of them
▪ out —— log out of profile
▪ oout —— log out of profile and open 'Log in & load/create profile' dialogue; status monitor button state won't be updated until the dialogue is closed
Logging out stops all and any script instances running in 'auto' mode.
▪ quit —— close REAPER saving/updating/deleting current profile settings
▪▪ 'quit' and 'toolbar#' commands can be combined provided they're inserted in different empty slots

The command 'quit' or 'quit' along with 'toolbar' run from a non-empty slot prevent the corresponding setting from being saved, updated or deleted.


▓ ♦ SOME TIPS AND WARNINGS

When using profiles it's strongly recommended to close REAPER at the end of the session via the 'Profile console' with the 'quit' command so the profile is always kept up-to-date with the latest settings and their selection.
If REAPER is closed convenionally and in the interim until another session no other profile is loaded the lst used profile settings will still be available in the next session.

When loading a profile, at restart it's not recommended to respond 'Cancel' to 'Save project' dialogue as it may disrupt consistent work of the script for a couple of runs.

It's not recommended to use several instances of the script loaded from different locations on the hard drive if you intend to also use status monitor buttons, since buttons are instance specific and if linked to different instances won't reflect the login status uniformly.

The file \ProfileTerminalData\ProfileTerminal.ini logs currently loaded profile name to prevent 'Restart prompt' being triggered when logging in to the already loaded profile and alternatively to trigger the prompt when another profile is being loaded. Therefore its deletion is not recommended, because although it eventually will be recreated for the time when it's absent the script might behave inconsistently.

If sharing the same Action list content across profiles is important for work, any update to it in terms of custom actions and scripts done under one profile must be replicated in others. The easiest way would be to export those as .ReaperKeyMap file from one profile and import under another profile as long as custom keyboard shortcuts are either not assigned or manually deleted from .ReaperKeyMap file.

Since most of the configuration .ini files REAPER and 3d party plugins generate when the related functions/settings first used/changed, at the time of the first script run not all of them may be available in REAPER resource directory and thus not available for saving to profile.

When a profile contains 'FX folders and shortucts' settings and there're existing FX (chain) keyboard shortcuts it makes sense to also save 'Keyboard shortcuts' setting which is the Action list contents wherefrom these FX (chain) shortcuts will be called. If they're not listed in the Action list they won't work.

]]


function Msg(param)
reaper.ShowConsoleMsg(tostring(param)..'\n')
end

local r = reaper

_, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
scr_name = scr_name:match('([^\\/]+)%.%w+') -- to be used as section name in Get and Set external state
key = 'Active profile' -- to be used as key name in Get and Set external state
sep = r.GetOS():match('Win') and '\\' or '/'
path = r.GetResourcePath()

	if r.GetExtState(scr_name, 'Defer') == tostring(sect_ID) then r.DeleteExtState(scr_name, 'Defer', 1) end -- delete ext state when exiting the loop to clear 'AUTO' indication in the 'Profile console' ribbon, profile_console() function

-- Settings table
profile_sett_t = {
'', -- Everything
'reaper', -- Global and last session settings
'reaper-pinstates', -- Window pin states -----|
											--| these could be combined if another slot needed
'REAPER-wndpos', -- Modal window positions ---|
'reaper-menu', -- Menus
'reaper-kb', -- Action and script shortcuts
'reaper-mouse', -- Mouse modifiers
'reaper-screensets', -- Screensets
{'reaper-fxfolders', 'reaper-fxoptions'}, -- FX folders and shortcuts --|
																	----| these could be combined
'reaper-defpresets', -- Default FX presets 	----------------------------|
'reaper-hwoutfx', -- Monitor FX chain
'reaper-render', -- Render settings & presets
'reaper-extstate', -- Script extended settings
'S&M', -- SWS Ext. global				 -----|
'sws-autocoloricon', -- SWS Ext. autocolor  --| these could be combined
'S&M_Cyclactions' -- SWS Ext. cycle actions --|
	}


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


function log_check_restart(profile_term_dir, input, act_profile) -- log and check REAPER restart after loading profile to prevent another restart prompt

local file = profile_term_dir..'ProfileTerminal.ini'

-- only runs when act_profile argument is provided
	if act_profile == '' then -- create file and/or log profile for which restart is being performed
	local f = io.open(file, 'w')
	f:write(input)
	f:close()
-- only runs when act_profile argument isn't provided
	elseif not act_profile then
	local f = io.open(file, 'r') -- evaluate logged profile name against input to prevent restart prompt after restart and logging in to the same profile
		if f then cont = f:read('*a')
		f:close() -- https://stackoverflow.com/questions/58426879/lua-is-file-closing-mandatory
		return cont == input
		end
	end

end


function settings_autofill(profile_sett_t, path, profile_dir) -- autofill Profile console with settings which exist in profile
r.EnumerateFiles(path, -1) -- clear cache
local file_t = {} -- collect profile ini files
local i = 0
	repeat
	local file = r.EnumerateFiles(profile_dir, i)
		if file and file ~= '' then file_t[#file_t+1] = file:sub(1,-5) -- strip out extension to evaluate against  profile_sett_t below, could have been done by adding .ini extension below instead
		end
	i = i + 1
	until not file or file == ''

	local function traverse_nested_sett(profile_sett_t, i, v) -- sub-function to traverse settings which include more than one file, e.g. 'FX folders and shortcuts'
		for k, sett in ipairs(profile_sett_t[i]) do
			if v == sett then return true end -- return as soon as at least one match which in this setup is enough as files under one setting are inseparable
		end
	end

-- create a condition to account for a case where profile folder contains 16 or more ini files not all of which may correspond to settings availabe in the Profile console, such which can be the result of using 'REAPER profile terminal (autosave all).lua' script; if all settings are there counter value must be equal to 15, not 16 since 1 match counts for 2 nested settings out of 16 slots, should be increased if new nested tables are added but not if the existing nested table(s) is(are) expanded
local counter = 0
	for k, v in ipairs(profile_sett_t) do
		if type(v) == 'table' then v = v[1] end -- nested settings table, checking one table value is enough since in this setup the corresponding files are inseparable
		for j, w in ipairs(file_t) do
			if v == w then counter = counter + 1 break end
		end
	end


local autofill_t = {}
	if #file_t > 0 then -- create autofill string
		for i = 1, 16 do -- 16 slots in the Profile console, this is the limit, so this table length must be 16 keys
			for k, v in next, file_t do
			local v = #file_t >= 16 and counter == 15 and i == 1 and '1' or #file_t >= 16 and counter == 16 and i > 1 and '' -- if all available settings engaged (all possible files present in profile), fill out 'Everything' slot leaving the rest empty; >= 16 to account for 'REAPER profile terminal (autosave all).lua' script which copies all .ini files to the profile folder of which there're likely to be more than 16; explanation for value 15 see above
			or (#file_t < 16 or counter < 15) and (v == profile_sett_t[i] or traverse_nested_sett(profile_sett_t, i, v)) and '1' or '' -- if not all available settings engaged, only fill out slots of those which correspond to .ini files leaving the rest empty, account for nested tables to which at least one match suffices since files which comprise them cannot be managed separately in this setup; explanation for value 15 see above
			-- 16 since this many files are currently referenced in the settings, technically could be more if more files are subsumed under any one setting (slot); change this number as more files are added
			-- if not all 16 types of files are available in the REAPER resource directory to begin with 'Everything' slot won't be filled out
			autofill_t[i] = v
			if v ~= '' then break end -- exit as soon as match found otherwise the table value will be replaced with an empty string as the loop continues without matches, empty string should only be stored if no matches whasosever after the loop is completed
			end
		end
	end

	if #autofill_t > 0 then return table.concat(autofill_t, ',') end

end


function profile_console(act_profile, input, autofill, auto)
Msg('AUTOFILL = '..tostring(autofill))
local prof_name = act_profile ~= '' and act_profile or input
Msg('AUTO = '..tostring(auto))
local auto = r.GetExtState(scr_name, 'Defer') ~= '' and '|   (AUTO)' or ''
return r.GetUserInputs('Profile console   |   \"'..prof_name..'\"   '..auto, 16, 'extrawidth=100, Everything / \"h\" for Help, Global and last session settings, Window pin states, Modal window positions, Menus, Action and script shortcuts, Mouse modifiers, Screensets, FX folders and shortcuts, Default FX presets, Monitor FX chain, Render settings and presets, Script extended settings, SWS Extension global, SWS Extension autocolor, SWS Extension cycle actions', autofill or '')

end


function capture_command(input, str) -- weed out illegal entries in the Profile console

	for cmd in input:gmatch('[^,]*') do -- check all slots; if dot were added here it would help to catch decimal numbers, but opted for error in the main routine
		if cmd ~= '' and cmd ~= '0' and cmd ~= '1' and not cmd:match('^h+$') and not cmd:match('oo?ut') and cmd ~= 'quit' and not cmd:match('oo?pen') and cmd ~= 'reload' and not cmd:match('toolbar[0-9]+') and not cmd:match('toolbar[0-8]m') and not cmd:match('auto[0-9]+') and cmd ~= 'auto0' then input = nil break end
	end

	if input and str then
	input = input:match('^('..str..'),') or input:match(',('..str..'),') or input:match(',('..str..')$')
	end

return input

end


function open_prof_dir(path, profile_term_dir, act_profile, sect_ID, cmd_ID, scr_name, key) -- Profile console 'open' command routine
-----------------------------------------------------
-- same as in save_delete_settings()
r.EnumerateSubdirectories(path, -1) -- reset cache
local i = 0
	repeat dir = r.EnumerateSubdirectories(profile_term_dir, i)
	i = i + 1
	until dir == act_profile or not dir

	if not dir then -- if profile folder got deleted mid-session
	r.MB(' The profile \"'..act_profile..'\" wasn\'t found.\n\n\tLogging out.','ERROR',0)
	r.DeleteExtState(scr_name, key, 1)
	set_toggle_state_and_refresh_toolbars(sect_ID, cmd_ID, 0)
	r.defer(function() end) return end
---------------------------------------------------
	local OS = r.GetOS():sub(1,3)
	local command = OS == 'Win' and {'explorer'} or (OS == 'OSX' or OS == 'mac') and {'open'} or {'nautilus', 'dolphin', 'gnome-open', 'xdg-open', 'gio open', 'caja', 'browse'}
	-- https://askubuntu.com/questions/31069/how-to-open-a-file-manager-of-the-current-directory-in-the-terminal
		for k,v in ipairs(command) do
		local result = r.ExecProcess(v..' '..profile_term_dir..act_profile, -1)
			if result then return end
		end
end


function load_settings(path, profile_term_dir, act_profile, sect_ID, cmd_ID, scr_name, key) -- copy profile files to REAPER resource dir

-----------------------------------------------------
-- same as in save_delete_settings()
r.EnumerateSubdirectories(path, -1) -- reset cache
local i = 0
	repeat dir = r.EnumerateSubdirectories(profile_term_dir, i)
	i = i + 1
	until dir == act_profile or not dir

	if not dir then -- if profile folder got deleted mid-session
	r.MB(' The profile \"'..act_profile..'\" wasn\'t found.\n\n\tLogging out.','ERROR',0)
	r.DeleteExtState(scr_name, key, 1)
	set_toggle_state_and_refresh_toolbars(sect_ID, cmd_ID, 0)
	r.defer(function() end) return 'abort' end
---------------------------------------------------

local profile_dir = profile_term_dir..act_profile..sep

-- the table isn't necessary, could be done within a single loop
	local file_t = {}
	local i = 0

	repeat
	local file = r.EnumerateFiles(profile_dir, i)
		if file and file ~= '' then file_t[i] = file end
	i = i + 1
	until not file or file == ''

	if #file_t > 0 then
		for k, v in next, file_t do
		local f = io.open(profile_dir..v, 'r')
		local cont = f:read('*a')
		f:close()
		local f = io.open(path..sep..v, 'w')
		f:write(cont)
		f:close()
		end
	end

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
		local cont_new = cont -- to make sure the var data is updated along with the loop
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
			if cont_new ~= cont then
			local f = io.open(f_path, 'w')
			f:write(cont_new)
			f:close()
			end
		end -- cont condition end
	end -- f condition end

end


function selection_table(input) -- construct a table out of slots selected by the user in the Profile console
	local selection_t = {}
	local cntr = 0 -- defines the index of Profile console settings slot
		for field in input:gmatch('([^,]*)') do
		cntr = cntr + 1
			if field:gsub(' ', '') ~= '' then -- only store filled out slots excluding empty spaces
			selection_t[cntr] = field -- implied either 1 or 0 the rest will be ignored
			end
		end
	return selection_t
end


function save_delete_settings() -- copy selected files from REAPER resource dir to profile dir or delete them from profile dir
-- vars for reference: selection_t, profile_sett_t, path, sep, profile_dir, act_profile, sect_ID, cmd_ID, scr_name, key, auto
-- not supported as arguments in deferred functions, must be global

----------------------------------------------------------
-- same as in open_prof_dir()
r.EnumerateSubdirectories(path, -1) -- reset cache
local i = 0
	repeat dir = r.EnumerateSubdirectories(profile_dir:match('(.+)'..act_profile), i) -- access profile_term_dir by truncating profile_dir path
	i = i + 1
	until dir == act_profile or not dir

	if not dir then -- if profile folder got deleted mid-session
	r.MB(' The profile \"'..act_profile..'\" wasn\'t found.\n\n\tLogging out.','ERROR',0)
	r.DeleteExtState(scr_name, key, 1)
	set_toggle_state_and_refresh_toolbars(sect_ID, cmd_ID, 0)
	r.defer(function() end) return end
-----------------------------------------------------------

		local function manage_settings(path, sep, profile_dir, v, file) -- sub-function
			if v == '1' then -- store settings
			local f = io.open(path..sep..file..'.ini', 'r')
				if f then -- some ini files may not be available if certain REAPER features haven't been in use yet
				local cont = f:read('*a')
				f:close()
				local f = io.open(profile_dir..file..'.ini', 'w')
				f:write(cont)
				f:close()
				end
			elseif v == '0' then -- delete settings
			os.remove(profile_dir..file..'.ini')
			end
		end

local time_curr = os.time()

	if (time and time_curr - time == auto) or not time then -- minimum time unit is minutes, 'not time' is there to allow running the routine in regular mode as well, the var is initialized outside of the function
	time = time_curr
		for k, v in next, selection_t do
		-- only 1 or 0 are considered as v, the rest is ignored
			for k2, v2 in next, profile_sett_t do
			local v2 = k == 1 and v2 or profile_sett_t[k] -- when k == 1 everything should be stored hence the settings table is traversed in full otherwise only keys matching selected slots are accessed in the settings table
				if type(v2) == 'table' then -- to address nested tables of settings when several files are combined under one slot like 'FX folders and shortucts'; a more advanced but also potentially confusing for a user solution would be to target nested settings individually with combinations of 1s and 0s within the same slot, e.g. 101, i.e. save/update the 1st and the 3d but delete the 2nd, with a single 1 meaning update all and a single 0 meaning delete all
					for k3, v3 in next, v2 do
					manage_settings(path, sep, profile_dir, v, v3) -- v is either 1 or 0, v3 is the name of the file to store or delete
					end
				else manage_settings(path, sep, profile_dir, v, v2) -- same
				end
				if k ~= 1 then break end -- to immediately go to the next item when not 'Everything'
			end
		if k == 1 and v ~= 'quit' and not v:match('auto%d+') then break end -- exit in case the user selected 'Everything' and other slots as well which would be redundant; conditioning by v is needed to avoid exit when 'quit' or 'auto' is typed-in in the 1st slot in which case k == 1 as well but that doesn't mean to save everything so loop should continue to access all slots 1 by 1, 'quit' isolation is taken care of earlier so v will only contain a clean string
		end
	end

	if auto and r.GetExtState(scr_name, 'Defer') == tostring(sect_ID) then -- when 'auto' mode is enabled, the var is initialized outside of the function; ext state is set outside of the function, makes deferred loop stop if 'auto' mode has been laucnhed in another instance of the script in another section of the Action list since the section ID changes
	r.defer(save_delete_settings)
	end

end


function Esc(str)
return str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
end


function add_toolbar_button(input, act_profile, sect_ID, cmd_ID, scr_name, key, path, sep, profile_term_dir, Esc, butt_err) -- add a button linked to this script to be checked with change_check_profile_name() later on

	if butt_err then return end

local TOOLBAR = input:match('toolbar(%d+m?)')
local tb_num = tonumber(TOOLBAR:match('%d+'))

	if TOOLBAR:match('m') and (tb_num < 0 or tb_num > 8) or not TOOLBAR:match('m') and (tb_num < 0 or tb_num > 16) then
	r.MB('       Toolbar number is malformed.\n\nCorrect format is 0 — 16 or 0m — 8m.','ERROR', 0)
	return end -- if invalid toolbar numbers

local cmd_ID = r.ReverseNamedCommandLookup(cmd_ID)

-- accommodate commandID to the toolbar type, either Arrange or MIDI Editor; commandIDs of the same script from the same path differ by the presense of an infix, which is absent in the Main section commandID; infix of such sctipt commandID in the MIDI Editor section is '7d3c_'
local cmd_ID = sect_ID == 0 and TOOLBAR:match('m') and cmd_ID:sub(1,2)..'7d3c_'..cmd_ID:sub(3) -- add infix
or sect_ID == 32060 and not TOOLBAR:match('m') and cmd_ID:sub(1,2)..cmd_ID:sub(8) -- remove infix
or cmd_ID
local file = path..sep..'reaper-menu.ini'

	if TOOLBAR ~= '' then
	local f = io.open(file, 'r')
		if not f then f = io.open(file, 'a') end -- create reaper-menu.ini if not yet present
		if f then
		local cont = f:read('*a')
		f:close()
		local toolbar_sect, toolbar_tit = table.unpack(TOOLBAR == '0' and {'Main toolbar', 'Main toolbar'} or TOOLBAR == '0m' and {'MIDI piano roll toolbar', 'MIDI piano roll toolbar'} or TOOLBAR:sub(2,2) == 'm' and {'Floating MIDI toolbar ', 'MIDI '} or {'Floating toolbar ', 'Toolbar '})
		local toolbar_num = toolbar_sect:sub(1,1) == 'M' and '' or TOOLBAR:match('%d+') -- main or floating toolbar
		local toolbar_cont = cont and cont:match('(%['..toolbar_sect..toolbar_num..'%].-\ntitle=)')
			if toolbar_cont and toolbar_cont:match('=_'..cmd_ID) then return end -- when the button already exists in selected toolbar
			if not toolbar_cont and not TOOLBAR:match('0') then -- create toolbar content, only for floating toolbars to avoid overwriting main toolbars default content
			local button_new = '['..toolbar_sect..toolbar_num..']\nicon_0=text_wide\nitem_0=_'..cmd_ID..' '..act_profile..'\ntitle='..toolbar_tit..toolbar_num
			cont_new = button_new..'\n\n'..cont
			elseif toolbar_cont then -- modify
			local last_butt_num = toolbar_cont:match('.+(\n.-)\ntitle=') -- a safeguard to be used in the line below in case there's no buttons code in the existing toolbar code if it's just a stub
			local last_butt_num = last_butt_num and last_butt_num:match('_(.+)=') -- get last button num
			local new_butt_num = last_butt_num and tostring(tonumber(last_butt_num)+1) or '0' -- if no last button number found because there's only a stub of toolbar code then start from 0
			local new_butt_item = 'item_'..new_butt_num..'=_'..cmd_ID..' '..act_profile
			local toolbar_cont_pt1, toolbar_cont_pt2 = toolbar_cont:match('(%['..toolbar_sect..toolbar_num..'%])(\n?.-)\ntitle=') -- split existing toolbar code
			local toolbar_cont_new = toolbar_cont_pt1..'\nicon_'..new_butt_num..'=text_wide'..toolbar_cont_pt2..'\nitem_'..new_butt_num..'=_'..cmd_ID..' '..act_profile -- concat new code
			local toolbar_cont_old = Esc(toolbar_cont_pt1..toolbar_cont_pt2) -- escape special chars if any
			cont_new = cont:gsub(toolbar_cont_old, toolbar_cont_new)
			end

			if cont_new then
			local f = io.open(file, 'w')
			f:write(cont_new)
			f:close()
			-- create or update profile reaper-menu.ini file in the profile folder right away
			local f = io.open(profile_term_dir..act_profile..sep..'reaper-menu.ini', 'w')
				if not f then r.MB(' The profile \"'..act_profile..'\" wasn\'t found.\n\n\tLogging out.','ERROR',0) -- path is unavailable
				r.DeleteExtState(scr_name, key, 1)
				set_toggle_state_and_refresh_toolbars(sect_ID, select(4, r.get_action_context()), 0) -- get numeric cmd_ID since it was converted to a string in this function above
				return end
			f:write(cont_new)
			f:close()
			end
		end
	end -- end of the main cond.

end


function prevent_button_creation(input, path, sep, sect_ID, cmd_ID)

-- Prevent creation of a button for the Action list section where instance of this script is absent, Main or MIDI Editor; using NamedCommandLookup() won't work because for the MIDI Editor section the data only updates after reastart and for the Main section the function returns commandID even without script present

local TOOLBAR = input:match('toolbar%d+m?')

local file = path..sep..'reaper-kb.ini'

	if r.file_exists(file) then
	local reverseID = r.ReverseNamedCommandLookup(cmd_ID)
	local cond1 = sect_ID == 32060 and not TOOLBAR:match('m') and reverseID:sub(1,2)..reverseID:sub(8) -- remove infix, look for the instance in the Main section
	local cond2 = sect_ID == 0 and TOOLBAR:match('m') and 'RS7d3c_'..reverseID:sub(3) -- add infix, look for the instance in the MIDI Editor section
		if cond1 or cond2 then
			for line in io.lines(file) do
			found = cond1 and line:match(cond1) or cond2 and line:match(cond2) -- line can't be used as a var, doesn't keep value beyond the loop
				if found then break end -- if found
			end
		end
	butt_err = cond1 and not found and '    Main     ' or cond2 and not found and 'MIDI Editor' -- also evaluated inside add_toolbar_button() function
		if butt_err then r.MB('                   The status monitor button\n\n        won\'t be added to the toolbar specified\n\n            due to absence of a script instance\n\n      in the '..butt_err..' section of the Action list.', 'WARNING', 0)
		end
	end
return butt_err

end



-------------- START MAIN ROUTINE ---------------

-- all global vars are there to accommodate save_delete_settings() function in deferred mode

::START::
act_profile = r.GetExtState(scr_name, 'Active profile')

local profile_term_dir = path..sep..'ProfileTerminalData'..sep

	-- Accept input
	if act_profile == '' then -- first run in the session or after logout
	retval, input = r.GetUserInputs('Log in & load/create profile', 1, 'Profile name or \"h\" for Help, extrawidth=50', '')
	input_modif = input:match('^[%s;]+') -- detect modifier to open Profile console right after login
	input = input:match('^[%s;]*(.-)%s*$') -- strip out modifier, leading and trailing space if any
	else -- run when logged in
	local profile_dir = profile_term_dir..act_profile..sep
	local autofill = settings_autofill(profile_sett_t, path, profile_dir)
	retval, input = profile_console(act_profile, input, autofill, auto)
	end

	-- Evaluate input
	if not retval or input == '' or not input then r.defer(function() end) return -- abort
	else
	local input = input:lower():gsub(' ','') -- will be accessed in 'create' routine below
		if input:match('^[h]+$') or capture_command(input,'h+') then -- inside either 'Log in & load/create' dialogue or 'Profile console'
		r.ShowConsoleMsg(HELP, r.ClearConsole()) goto START -- display HELP
		elseif act_profile ~= '' then
			if capture_command(input,'oo?ut') then -- logout (Profile console)
			r.DeleteExtState(scr_name, key, 1)
			r.DeleteExtState(scr_name, 'Defer', 1) -- stop any deferred instances of the script at logout
			set_toggle_state_and_refresh_toolbars(sect_ID, cmd_ID, 0)
				if capture_command(input,'oout') then goto START end
			r.defer(function() end) return -- prevent from continuing and from creating undo point
			elseif capture_command(input,'oo?pen') then -- open profile directory (Profile console)
			open_prof_dir(path, profile_term_dir, act_profile, sect_ID, cmd_ID, scr_name, key)
				if capture_command(input,'oopen') then goto START end
			r.defer(function() end) return -- prevent from continuing and from creating undo point
			elseif capture_command(input,'reload') then -- reload settings
			local resp = r.MB('To reload settings REAPER must be restarted.','PROMPT',1)
				if resp == 2 then r.defer(function() end) return end -- won't be reloaded if denied in the dialogue
			local retval = load_settings(path, profile_term_dir, act_profile, sect_ID, cmd_ID, scr_name, key)
				if retval == 'abort' then r.defer(function() end) return end -- profile directory wasn't found
			r.MarkProjectDirty(0) -- to generate Save prompt if 'undo/prompt to save' is enabled in preferences
			r.Main_OnCommand(40004, 0) -- File: Quit REAPER
			elseif not capture_command(input) then r.MB('        Invalid entry. Supported commands are:\n\n     0 - delete setting;  1 - save/update setting;\n\n\t     reload - reload settings;\n\nauto# - enable settings auto-update every # mins;\n\ntoolbar# - add status monitor button to toolbar #,\n\n         toolbar # format is 0 — 16,   0m — 8m;\n\n         [o]open - open profile folder;  h - Help;\n\n[o]out - log out;  quit - close REAPER saving settings.\n\n\t      Register doesn\'t matter.','ERROR',0) goto START -- inside Profile console
			end
		end
	end


set_script_instances_mode(path, sep, cmd_ID, scr_name, Esc) -- set script defer mode in reaper-kb.ini to 260 to prevent pop-up dialogue when stopped; only runs if other than 260


	-- Process input
	if act_profile == '' then -- first run in the session or after logout; check if profile exists, if not then create and log in else log in
	local profile_dir = profile_term_dir..input..sep
	local i = 0
		repeat
		dir1 = r.EnumerateSubdirectories(path, i) -- closing dir with separator isn't required but it doesn't affect functionality
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

			if dir == input then -- if successful
			mode, capt, mess = 1, 'PROMPT', '\t           The profile has been created.\n\nClick \"OK\" to access Profile console now to save some settings.\n\n         If during this session you change any of the settings,\n\n\tyou can run the script to call Profile console\n\n             to save them to or update them in your profile.\n\n        To access the Profile console you must be logged in\n\n\t\twhich you currently are.' -- creation succeded
			else mode, capt, mess = 5, 'ERROR', '          Profile creation failed.\n\nLikely due to invalid profile name.\n\n  Try selecting a different name.' -- creation failed
			end

		local resp = r.MB(mess, capt, mode)

			if mode == 1 then -- success message output; the entire routine mainly replicates the regular login routine below
			r.SetExtState(scr_name, key, input, 0) -- log in
			change_check_profile_name(Esc, path, sep, cmd_ID, input) -- change state monitor button names to match newly created profile name
			local check_name = 1 -- cond to only run button name evaluation routine in the next function, could be set to true, but 1 is shorter; would make sense unless this lengthy comment
				if change_check_profile_name(Esc, path, sep, cmd_ID, input, check_name) then -- evaluate if name change is successful -- ESSENTIALLY REDUNDANT
				set_toggle_state_and_refresh_toolbars(sect_ID, cmd_ID, 1)
				end
			log_check_restart(profile_term_dir, input, act_profile) -- log new profile name to avoid restart prompt in the beginning of the next session
			-- stems from mode 1; success message --
				if resp == 1 then goto START -- open 'Profile console'
				else r.defer(function() end) return end -- prevent undo point
			r.defer(function() end) return -- prevent routine from continuing to avoid running the same functions below meant for regular login
			-- both stem from mode 5; failure message --
			elseif resp == 4 then create = nil; goto START -- retry creating profile with diff name; reset create var to prevent create routine from being triggered if on retry a name of an existing profile was entered
			elseif resp == 2 then r.defer(function() end) return
			end

		-- Only prompt to restart when logged and thus active profile is different from the profile being loaded, as long as they're the same logging out and back in won't trigger the prompt
		elseif not create and not log_check_restart(profile_term_dir, input) -- act_profile var is omitted to avoid logging the profile at this stage which would make this cond false, it's only logged at restart; the function is designed to detect difference between last logged profile and input profile name to prompt restart
		then -- profile exists, restart to load one
		local resp = r.MB('               REAPER must be restarted\n\n    for the Profile \"'..input..'\" settings to take effect.\n\n     You will be asked to save your project.\n\n      It\'s not recommended to click \"Cancel\"\n\n             in the \"Save project\" dialogue\n\n    as this will disrupt the script consistency.','RESTART PROMPT', 1) -- displayed after reload as well in which case 'No' should be selected hence next condition
			if resp == 2 then r.defer(function() end) return -- if restart isn't conirmed profile isn't loaded
			else
			r.MarkProjectDirty(0) -- to generate Save prompt if 'undo/prompt to save' is enabled in preferences
			load_settings(path, sep, profile_dir) -- load profile settings to REAPER resource dir
			change_check_profile_name(Esc, path, sep, cmd_ID, input) -- only change button name when restart is confirmed, check_name argument is ommitted so change name routine is the only one running
			log_check_restart(profile_term_dir, input, act_profile) -- log profile being loaded to avoid restart prompt after re-logging in
			r.Main_OnCommand(40004, 0) -- File: Quit REAPER
			end
		end -- create cond. end

	-- Logging back in to the profile already loaded with restart
	r.SetExtState(scr_name, key, input, 0) -- log in
	local check_name = 1 -- cond to only run button name evaluation routine in the following function, could be set to true, but 1 is shorter
		if change_check_profile_name(Esc, path, sep, cmd_ID, input, check_name) then -- only light button when its name matches the active profile name
		set_toggle_state_and_refresh_toolbars(sect_ID, cmd_ID, 1)
		end
		if input_modif then goto START -- open Profile console right after login; input_modif var stems from the 'Accept input' routine above
		else r.defer(function() end) return end -- prevent undo point

	elseif act_profile ~= '' then -- run when logged in; save settings to the existing profile
	local input = input:lower():gsub(' ','')
		if capture_command(input, 'toolbar[0-9]+m?') then
		local butt_err = prevent_button_creation(input, path, sep, sect_ID, cmd_ID)
		add_toolbar_button(input, act_profile, sect_ID, cmd_ID, scr_name, key, path, sep, profile_term_dir, Esc, butt_err) -- if butt_err the function is aborted
			if not capture_command(input, 'quit') then goto START end -- allows adding a button and quitting in one go, otherwise after adding a button Profile console stays on
		end
	selection_t = selection_table(input)
	profile_dir = profile_term_dir..act_profile..sep
	auto = capture_command(input, 'auto[0-9]+') -- if autosave is being enabled
		if auto == 'auto0' then
		r.DeleteExtState(scr_name, 'Defer', 1) goto START -- exit deferred mode from another instance of the script in another Action list section
		elseif auto then
		time = os.time()
		auto = tonumber(auto:sub(5))*60 -- calc outside of the deferred function, hopefully more efficient
		r.SetExtState(scr_name, 'Defer', sect_ID, 0) -- to monitor in deferred save_delete_settings() function and stop it if another instance of the script has been used in another section of the action list
		elseif input:match('auto')
		then r.MB('            Malformed time value.\n\nOnly whole numbers are supported.','ERROR',0) goto START  -- elseif for specificity otherwise simple OK with empty field produces error message
		end
	save_delete_settings(selection_t, profile_sett_t, path, sep, profile_dir, act_profile, sect_ID, cmd_ID, scr_name, key, auto) -- arguments are just for reference and not necessary here as all vars are global to work in defer mode
		if capture_command(input, 'quit') then
		r.MarkProjectDirty(0) -- to generate Save prompt if 'undo/prompt to save' is enabled in preferences
		r.Main_OnCommand(40004, 0) -- File: Quit REAPER
		end
	r.defer(function() end) return end -- main cond. end; prevent undo point






