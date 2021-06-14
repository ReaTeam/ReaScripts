--[[
ReaScript name: REAPER Profile terminal
Version: 1.0
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About:

	The script was designed to facilitate sharing one REAPER installation between several users. However this concept can be applied to using the same REAPER installation for different purposes which would likely entail different workflows and thus different setup requirements.

	Technically it's achieved by copying files holding selected settings from REAPER resource directory to a separate folder homonymous with the profile and which is located under *\ProfileTerminalData* directory in REAPER resource directory, and then copying them back to the REAPER resource directory when profile is being loaded.
	
	The script is complete with Help accessible from its dialogues.

]]

HELP = [[

▓ ♦ 'Log in & load/create profile' dialogue

Meant for logging in or creating a profile and logging in.

To create a profile simply type in some new profile name. Names preceded with semicolon (;) aren't supported since it's used as a modifier (see 'COMMANDS SUMMARY' section below), which shouldn't be particulartly limiting.

To log in type in a name of an existing profile. If it's different from the last used profile 'Restart prompt' will come up.

It's important to restart REAPER after logging in by responding 'OK' to the 'Restart prompt'. If Restart is denied the profile settings won't be loaded.

After restart it's not nesessary to log in again unless you want access to the 'Profile console' to manage your profile settings or update them at the end of the session. Without logging in the settings will still be available which is also true after logout from the currently active profile during the session.
The settings of a loaded profile remain active until another profile is loaded and REAPER restarted.

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

To delete profile entirely delete its folder from \ProfileTerminalData directory located in REAPER resource directory accessible with the action 'Show REAPER resource path in explorer' normally evailabe in the 'Otions' menu.


▓ ♦ COMMANDS SUMMARY (all case ignorant)

▪ h —— Help (this text) —— available in both 'Log in & load/create profile' dialogue and from the 'Profile console'

	► Only avalable in 'Log in & load/create profile' dialogue

▪ ; —— when immediately precedes the profile name, log in and open 'Profile console'

	► Only avalable in the 'Profile console'

Only in the slots which correspond to the setting(s) being managed:
▪ 1 —— save/update a setting
▪ 0 —— delete a setting

From any empty slot:
▪ open —— open profile folder
▪ oopen —— open profile folder and keep 'Profile console' open
▪ out —— log out of profile
▪ oout —— log out of profile and open 'Log in & load/create profile' dialogue
▪ quit —— close REAPER saving/updating/deleting profile settings

'Profile console' setting slots which correspond to the settings stored in the currently active profile are autofilled with the digit 1.
If 'Everything' slot was used to store the settings but not all types of files were available in REAPER resource directory to begin with because some functions hadn't been used/modified yet, autofill will fill out individual slots instead of the slot 'Everything'.


▓ ♦ STATUS MONITOR BUTTON

The script provides an option to automatically add and/or use status monitor button in a toolbar.

For the sctript to be able to add such button automatically specify the number of the target toolbar in the USER SETTINGS section below adhering to the correct format described in that section. However you can add such button manually as well by linking a new toolbar button to this script.

The name of status monitor button indicates currently loaded profile and it is lit when the user of currently loaded profile is logged in. The status monitor button name is updated everytime another profile is loaded.

When the user is logged out of the profile the button dims but the profile settings remain active.

When new profile is created the status monitor button keeps displaying the last loaded profile name but will light up at log-in because at this point there's no difference between the last used and the new profile settings. The button name will only display the new profile name after REAPER is restarted and the same new profile is loaded.

The script updates the name of any toolbar button linked to it, if there're several the names of all will be updated.


▓ ♦ SOME TIPS AND WARNINGS

When using profiles it's strongly recommended to close REAPER at the end of the session via the 'Profile console' with the 'quit' command so the profile is always kept up-to-date with the latest settings and their selection.
If REAPER is closed convenionally and in the interim until another session no other profile is loaded the lst used profile settings will still be available in the next session.

When loading profile, at restart it's not recommended to respond 'Cancel' to 'Save project' dialogue as it may disrupt consistent work of the script for a couple of runs.

The file \ProfileTerminalData\ProfileTerminal.ini logs currently loaded profile name to prevent 'Restart prompt' being triggered when logging in to the already loaded profile and alternatively to trigger the prompt when another profile is being loaded. Therefore its deletion is not recommended, because although it eventually will be recreated for the time when it's absent the script might behave inconsistently.

If sharing the same Action list content across profiles is important for work, any update to it in terms of custom actions and scripts done under one profile must be replicated in others. The easiest way would be to export those as .ReaperKeyMap file from one profile and import under another profile as long as custom keyboard shortcuts are either not assigned or manually deleted from .ReaperKeyMap file.

Since most of the configuration .ini files REAPER and 3d party plugins generate when the related functions/settings first used/changed, at the time of the first script run not all of them may be available in REAPER resource directory and thus not available for saving to profile.

When a profile contains 'FX folders and shortucts' settings and there're existing FX (chain) keyboard shortcuts it makes sense to also save 'Keyboard shortcuts' setting which is the Action list contents wherefrom these FX (chain) shortcuts will be called. If they're not listed in the Action list they won't work.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- A setting to automatically add login status monitor button to a toolbar.
-- Supports one such button per toolbar and only added once per toolbar. 
--		Arrange floating toolbar numbers 1 - 16
--		MIDI floating toolbar numbers 1m - 8m
--		Main toolbar number is 0
--		MIDI Editor toolbar number is 0m
-- Insert relevant toolbar number within the quotes below

local TOOLBAR = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

function Msg(param)
reaper.ShowConsoleMsg(tostring(param)..'\n')
end

local r = reaper

-- error trap
local TOOLBAR = TOOLBAR:gsub(' ','')
local regul_toolbar = tonumber(TOOLBAR)
local midi_toolbar = TOOLBAR:match('%d+m') and tonumber(TOOLBAR:match('(%d+)m'))

	if TOOLBAR ~= '' and ((regul_toolbar and (regul_toolbar > 16 or regul_toolbar < 0))
	or (midi_toolbar and (midi_toolbar > 8 or midi_toolbar < 0))
	or not regul_toolbar and not midi_toolbar)
	then
	local resp = r.MB('       Toolbar number is malformed.\n\nCorrect format is 0 — 16 or 0m — 8m\n\n\tClick "OK\" to ignore.','ERROR', 1)
		if resp == 2 then r.defer(function() end) return end
	end


-- Settings table
local profile_sett_t = {
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
		f:close()
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

local autofill_t = {}
	if #file_t > 0 then -- create autofill string
		for i = 1, 16 do -- 16 slots in the Profile console, this is the limit, so this table length must be 16 keys
			for k, v in next, file_t do
			local v = #file_t == 16 and i == 1 and '1' or #file_t == 16 and i > 1 and '' -- if all available settings engaged (all possible files present in profile), fill out 'Everything' slot leaving the rest empty
			or #file_t < 16 and (v == profile_sett_t[i] or traverse_nested_sett(profile_sett_t, i, v)) and '1' or '' -- if not all available settings engaged, only fill out slots of those which correspond to .ini files leaving the rest empty, account for nested tables to which at least one match suffices since files which comprise them cannot be managed separately in this setup
			-- 16 since this much files are currently refereneced in the settings, technically could be more if more files are subsumed under any one setting (slot) like 'FX folders and shortcuts'; change this number as more files are added
			-- if not all 16 types of files are available in the REAPER resource directory to begin with 'Everything' slot won't be filled out

			autofill_t[i] = v
			if v ~= '' then break end -- exit as soon as match found otherwise the table value will be replaced with an empty string as the loop continues without matches, empty string should only be stored if no matches whasosever after the loop is completed
			end
		end
	end

	if #autofill_t > 0 then return table.concat(autofill_t, ',') end

end


function profile_console(act_profile, input, autofill)

local prof_name = act_profile ~= '' and act_profile or input
return r.GetUserInputs('Profile console: manage settings for profile \"'..prof_name..'\"', 16, 'extrawidth=100, Everything / \"h\" for Help, Global and last session settings, Window pin states, Modal window positions, Menus, Action and script shortcuts, Mouse modifiers, Screensets, FX folders and shortcuts, Default FX presets, Monitor FX chain, Render settings and presets, Script extended settings, SWS Extension global, SWS Extension autocolor, SWS Extension cycle actions', autofill or '')

end


function capture_command(input, str) -- weed out illegal entries in the Profile console

	for cmd in input:gmatch('[^,]*') do -- check all slots
		if cmd ~= '' and cmd ~= '0' and cmd ~= '1' and not cmd:match('[h]+') and not cmd:match('oo?ut') and cmd ~= 'quit' and not cmd:match('oo?pen') then input = nil break end
	end

	if input and str then
	input = input:match('^'..str..',') or input:match(','..str..',') or input:match(','..str..'$')
	end
return input
end


function open_prof_dir(path, profile_term_dir, act_profile, sect_ID, cmd_ID, section, key) -- Profile console 'open' command routine
-----------------------------------------------------
-- same as in save_delete_settings()
r.EnumerateSubdirectories(path, -1) -- reset cache
local i = 0
	repeat dir = r.EnumerateSubdirectories(profile_term_dir, i)
	i = i + 1
	until dir == act_profile or not dir

	if not dir then -- if profile folder got deleted mid-session
	r.MB(' The profile \"'..act_profile..'\" wasn\'t found.\n\n\tLogging out.','ERROR',0)
	r.DeleteExtState(section, key, 1)
	r.SetToggleCommandState(sect_ID, cmd_ID, 0)
	r.RefreshToolbar2(sect_ID, cmd_ID)
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


function load_settings(path, sep, profile_dir) -- copy profile files to REAPER resource dir
	file_t = {}
	local i = 0
	repeat
	local file = r.EnumerateFiles(profile_dir, i)
		if file and file ~= '' then file_t[i] = file end
	i = i + 1
	until not file or file == ''

	for k, v in next, file_t do
	local f = io.open(profile_dir..v, 'r')
	local cont = f:read('*a')
	f:close()
	local f = io.open(path..sep..v, 'w')
	f:write(cont)
	f:close()
	end
end


function change_check_profile_name(Esc, path, sep, cmd_ID, input, TOOLBAR, check_name) -- in reaper-menu.ini toolbar code to display in a toolbar button and light the button up if loaded profile name and the button name match

local cmd_ID = r.ReverseNamedCommandLookup(cmd_ID)
local f_path = path..sep..'reaper-menu.ini'
local f = io.open(f_path, 'r')

	if f then -- file won't be available if menus/toolbars have never been modified
	local cont = f:read('*a')
	f:close()
		if cont ~= '' then
			if TOOLBAR ~= '' then -- if user specfied the toolbar number in the USER SETTINGS
			local toolbar_sect = TOOLBAR == '0' and 'Main toolbar ' or TOOLBAR == '0m' and 'MIDI piano roll toolbar ' or TOOLBAR:sub(2,2) == 'm' and 'Floating MIDI toolbar ' or TOOLBAR ~= '' and 'Floating toolbar '
			local toolbar_num = toolbar_sect:sub(1,1) == 'M' and '' or TOOLBAR:match('%d+') -- two main toolbars and the rest
			toolbar_cont = cont:match('(%['..toolbar_sect..toolbar_num..'%].-\ntitle=)')
			end

			if check_name then -- when check_name arg is present
			local cont = toolbar_cont or cont -- if toolbar_cont is nil due to TOOLBAR var being empty in the USER SETTINGS check 1st relevant button which occurs in reaper-menu.ini if there're several, the names of all get changed to match the profile being loaded anyway with the routine below
			return cont:match('=_'..cmd_ID..' '..input..'\n') end

		-- write current profile as button name only when there's no check_name arg, in the main routine it's done on restart
		local cont_new = cont
			for tb in cont:gmatch('%[.-toolbar.-%].-\ntitle=') do -- get only toolbars
			local tb = tb:match(cmd_ID) and tb -- the toolbar contains a button linked to this script
				if tb then
				local line = Esc(tb:match('(=_'..cmd_ID..'.-)\n'))
				local tb_new = tb:gsub(line, '=_'..cmd_ID..' '..input) -- change line within the toolbar code
				local tb = Esc(tb)
				cont_new = cont_new:gsub(tb, tb_new) -- update the toolbar code in reaper-menu.ini, keeps updating with every loop cycle because the var is initialized outside of the loop
				end
			end

		local f = io.open(f_path, 'w')
		f:write(cont_new)
		f:close()
		end
	end

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


function save_delete_settings(selection_t, profile_sett_t, path, sep, profile_dir, act_profile, sect_ID, cmd_ID, section, key) -- copy selected files from REAPER resource dir to profile dir or delete them from profile dir

----------------------------------------------------------
-- same as in open_prof_dir()
r.EnumerateSubdirectories(path, -1) -- reset cache
local i = 0
	repeat dir = r.EnumerateSubdirectories(profile_dir:match('(.+)'..act_profile), i) -- access profile_term_dir by truncating profile_dir path
	i = i + 1
	until dir == act_profile or not dir

	if not dir then -- if profile folder got deleted mid-session
	r.MB(' The profile \"'..act_profile..'\" wasn\'t found.\n\n\tLogging out.','ERROR',0)
	r.DeleteExtState(section, key, 1)
	r.SetToggleCommandState(sect_ID, cmd_ID, 0)
	r.RefreshToolbar2(sect_ID, cmd_ID)
	r.defer(function() end) return end
-----------------------------------------------------------

	local function manage_settings(path, sep, profile_dir, v, file) -- sub-function
		if v == '1' then -- store settings
		local f = io.open(path..sep..file..'.ini', 'r')
			if f then -- some ini files may not be available if certain functions haven't been in use yet
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

	for k, v in next, selection_t do
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
	if k == 1 and v ~= 'quit' then break end -- exit in case the user selected 'Everything' and other slots as well which would be redundant; conditioning by v is needed to avoid exit when 'quit' is typed-in in the 1st slot in which case k == 1 as well but that doesn't mean to save everything so loop should continue to access all slots 1 by 1, 'quit' isolation is taken care of earlier so v will only contain a clean string
	end
end


function Esc(str)
return str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
end


function add_toolbar_button(TOOLBAR, cmd_ID, path, sep, input, Esc) -- add a button linked to this script to be checked with change_check_profile_name() later on

local cmd_ID = r.ReverseNamedCommandLookup(cmd_ID)
local file = path..sep..'reaper-menu.ini'

	if TOOLBAR ~= '' then
	local f = io.open(file, 'r')
		if not f then f = io.open(file, 'a') end -- create reaper-menu.ini if not yet present
		if f then
		local cont = f:read('*a')
		f:close()
		local toolbar_sect, toolbar_tit = table.unpack(TOOLBAR == '0' and {'Main toolbar', 'Main toolbar'} or TOOLBAR == '0m'and {'MIDI piano roll toolbar', 'MIDI piano roll toolbar'} or TOOLBAR:sub(2,2) == 'm' and {'Floating MIDI toolbar ', 'MIDI '} or {'Floating toolbar ', 'Toolbar '})
		local toolbar_num = toolbar_sect:sub(1,1) == 'M' and '' or TOOLBAR:match('%d+')
		local toolbar_cont = cont and cont:match('(%['..toolbar_sect..toolbar_num..'%].-\ntitle=)')
			if toolbar_cont and toolbar_cont:match('=_'..cmd_ID) then return end -- when the button already exists in selected toolbar
			if not toolbar_cont then -- create toolbar content
			local button_new = '['..toolbar_sect..toolbar_num..']\nicon_0=text_wide\nitem_0=_'..cmd_ID..' '..input..'\ntitle='..toolbar_tit..toolbar_num
			cont_new = button_new..'\n\n'..cont
			else -- modify
			local last_butt_num = toolbar_cont:match('.+(\n.-)\ntitle=') -- second match in the next line is a safeguard in case this var rerurns nil due to lack of required code
			local last_butt_num = last_butt_num and last_butt_num:match('_(.+)=') -- get last button num
			local new_butt_num = last_butt_num and tostring(tonumber(last_butt_num)+1) or '0' -- if no last button number found because there's only a stub of toolbar code then start from 0
			local new_butt_item = 'item_'..new_butt_num..'=_'..cmd_ID..' '..input
			local toolbar_cont_pt1, toolbar_cont_pt2 = toolbar_cont:match('(%['..toolbar_sect..toolbar_num..'%])(\n?.-)\ntitle=') -- split existing toolbar code
			local toolbar_cont_new = toolbar_cont_pt1..'\nicon_'..new_butt_num..'=text_wide'..toolbar_cont_pt2..'\nitem_'..new_butt_num..'=_'..cmd_ID..' '..input -- concat new code
			local toolbar_cont_old = Esc(toolbar_cont_pt1..toolbar_cont_pt2) -- escape special chars if any
			cont_new = cont:gsub(toolbar_cont_old, toolbar_cont_new)
			end
		local f = io.open(file, 'w')
		f:write(cont_new)
		f:close()
		end
	end

end



-------------- START MAIN ROUTINE ---------------

local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local scr_name = scr_name:match('([^\\/]+)%.%w+')

local section = scr_name..cmd_ID
local key = 'Active profile'

::START::
local act_profile = r.GetExtState(section, 'Active profile')

local sep = r.GetOS():match('Win') and '\\' or '/'
local path = r.GetResourcePath()
local profile_term_dir = path..sep..'ProfileTerminalData'..sep


	-- Accept input
	if act_profile == '' then -- first run in the session or after logout
	retval, input = r.GetUserInputs('Log in & load/create profile', 1, 'Profile name or \"h\" for Help, extrawidth=50', '')
	input_modif = input:match('^[%s;]+') -- detect modifier to open Profile console right after login
	input = input:match('^[%s;]*(.+)') -- strip out modifier if any
	else -- run when logged in
	--if act_profile ~= '' and log_check_restart(profile_term_dir, input, act_profile) then
	local profile_dir = profile_term_dir..act_profile..sep
	local autofill = settings_autofill(profile_sett_t, path, profile_dir)
	retval, input = profile_console(act_profile, input, autofill)
	end

	
	-- Evaluate input
	if not retval or input == '' then r.defer(function() end) return -- abort
	else
	local input = input:lower():gsub(' ','') -- will be accessed in 'create' routine below
		if act_profile ~= '' and capture_command(input,'oo?ut') then -- logout (Profile console)
		r.DeleteExtState(section, key, 1)
		r.SetToggleCommandState(sect_ID, cmd_ID, 0)
		r.RefreshToolbar2(sect_ID, cmd_ID)
			if capture_command(input,'oout') then goto START end
			r.defer(function() end) return -- prevent undo point
		elseif act_profile ~= '' and capture_command(input,'oo?pen') then -- open profile directory (Profile console)
		open_prof_dir(path, profile_term_dir, act_profile, sect_ID, cmd_ID, section, key)
			if capture_command(input,'oopen') then goto START end
			r.defer(function() end) return -- prevent undo point
		elseif input:match('^[h]+$') or capture_command(input,'[h]+') then -- inside either 'Log in & load/create' dialogue or 'Profile console'
		r.ShowConsoleMsg(HELP, r.ClearConsole()) goto START -- display HELP
		elseif act_profile ~= '' and not capture_command(input) then r.MB('    Invalid entry. Supported commands are:\n\n 0 - delete setting;  1 - save/update setting;\n\n     [o]open - open profile folder;  h - Help;\n\n      [o]out - log out;  quit - close REAPER.\n\n\t  Register doesn\'t matter.','ERROR',0) goto START -- inside Profile console
		end
	end



	-- Process input
	if act_profile == '' then -- first run in the session or after logout; check if profile exists, if not then create and log in else log in
	local profile_dir = profile_term_dir..input..sep
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

			if dir == input then -- if successful
			mode, capt, mess = 1, 'PROMPT', '\t           The profile has been created.\n\nClick \"OK\" to access Profile console now to save some settings.\n\n         If during this session you change any of the settings,\n\n\tyou can run the script to call Profile console\n\n             to save them to or update them in your profile.\n\n        To access the Profile console you must be logged in\n\n\t\twhich you currently are.' -- creation succeded
			else mode, capt, mess = 5, 'ERROR', '          Profile creation failed.\n\nLikely due to invalid profile name.\n\n  Try selecting a different name.' -- creation failed
			end
		local resp = r.MB(mess, capt, mode)

			if mode == 1 then -- success message output
			r.SetExtState(section, key, input, 0) -- log in
			add_toolbar_button(TOOLBAR, cmd_ID, path, sep, input, Esc) -- if specified in the USER SETTINGS
			local check_name = 1 -- cond to only run button name evaluation routine in the next function, could be set to true, but 1 is shorter; would make sense unless this lengthy comment
				if change_check_profile_name(Esc, path, sep, cmd_ID, input, TOOLBAR, check_name) then -- change status monitor button names to match the new profile
				r.SetToggleCommandState(sect_ID, cmd_ID, 1)
				r.RefreshToolbar2(sect_ID, cmd_ID) end
			log_check_restart(profile_term_dir, input, act_profile) -- log new profile name
				if resp == 1 then goto START -- open 'Profile console'
				else r.defer(function() end) return end -- prevent undo point
			-- both stem from mode 5; failure message output
			elseif resp == 4 then goto START
			elseif resp == 2 then r.defer(function() end) return
			end

		-- Only prompt to restart when logged and thus active profile is different from the profile being loaded, as long as they're the same logging out and back in won't trigger the prompt
		elseif not create and not log_check_restart(profile_term_dir, input) -- act_profile var is omitted to avoid logging the profile at this stage which would make this cond false, it's only logged at restart; the function is designed to detect difference between last logged profile and input profile name to prompt restart
		then -- profile exists, restart to load one
		r.MB('               REAPER must be restarted\n\n    for the Profile \"'..input..'\" settings to take effect.\n\n     You will be asked to save your project.\n\n      It\'s not recommended to click \"Cancel\"\n\n             in the \"Save project\" dialogue\n\n    as this will disrupt the script consistency.','RESTART PROMPT', 1) -- displayed after reload as well in which case 'No' should be selected hence next condition
			if resp == 2 then r.defer(function() end) return -- if restart isn't conirmed profile isn't loaded
			else
			add_toolbar_button(TOOLBAR, cmd_ID, path, sep, input, Esc)
			r.MarkProjectDirty(0) -- to generate Save prompt if 'undo/prompt to save' is enabled in preferences
			load_settings(path, sep, profile_dir) -- load profile settings to REAPER resource dir
			change_check_profile_name(Esc, path, sep, cmd_ID, input, TOOLBAR) -- only change button name when restart is confirmed, check_name argument is ommitted so change name routine is the only one running
			log_check_restart(profile_term_dir, input, act_profile) -- log profile being loaded to avoid restart prompt after re-logging in
			r.Main_OnCommand(40004, 0) -- File: Quit REAPER
			end
		end -- create cond. end

	-- Logging back in to the profile already loaded with restart
	r.SetExtState(section, key, input, 0) -- log in
	local check_name = 1 -- cond to only run button name evaluation routine in the following function, could be set to true, but 1 is shorter
	if change_check_profile_name(Esc, path, sep, cmd_ID, input, TOOLBAR, check_name) then -- only light button when its name matches the active profile name
		r.SetToggleCommandState(sect_ID, cmd_ID, 1)
		r.RefreshToolbar2(sect_ID, cmd_ID)
			if input_modif then goto START end -- open Profile console right after login
		r.defer(function() end) return end -- prevent undo point

	elseif act_profile ~= '' then -- run when logged in; save settings to the existing profile
	local input = input:lower():gsub(' ','')
	local selection_t = selection_table(input)
	local profile_dir = profile_term_dir..act_profile..sep
	save_delete_settings(selection_t, profile_sett_t, path, sep, profile_dir, act_profile, sect_ID, cmd_ID, section, key)
		if capture_command(input, 'quit') then
		r.MarkProjectDirty(0) -- to generate Save prompt if 'undo/prompt to save' is enabled in preferences
		r.Main_OnCommand(40004, 0) -- File: Quit REAPER
		end
	r.defer(function() end) return end -- main cond. end; prevent undo point





