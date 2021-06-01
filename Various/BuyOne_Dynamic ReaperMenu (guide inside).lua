--[[
ReaScript name: Dynamic ReaperMenu
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Provides: [main=main,midi_editor] .
About:

	#### GUIDE

	- The script is designed to allow using REAPER menus independently of REAPER
	menu system by loading .ReaperMenu files on demand, which essentially allows
	potentially having and using many more menus and toolbars than the REAPER
	native menu system provides.

	- The dynamic part implies that a currently loaded menu can at any moment be
	replaced with another one.

	- .ReaperMenu files are menu and toolbar dumps which can be created with
	*Export -> Export current menu/toolbar to ReaperMenu file...* option in the
	*Customize menus/toolbars* section accessible from the main *Options* menu
	in the default REAPER installation.

	- So when you need another menu/toolbar but have used up all menus/toolbars
	available in REAPER natively, you can create a backup copy of one of the current
	menus/toolbars, put together a new one in its place, export the newly created
	menu/toolbar to a .ReaperMenu file, then restore the previous one and use such
	exported menu/toolbar via this script.

	- Toolbars loaded with this script are formatted as regular menus.

	- In the USER SETTINGS below the script provides options to specify the full
	path to the .ReaperMenu file per supported section of the Action list.  
	If such path isn't specified the script will offer loading a file and then will
	store its full path so it can be loaded automatically on next runs until another
	menu file is loaded.

	- A menu item titled 'LOAD REAPER MENU FILE' is found at the very bottom of any menu
	loaded via the dialogue. So if your menu is long you may need to scroll all the way
	down to access it. Scrolling can be done with the up/down arrow keys on the keyboard
	while the mouse cursor is placed over the menu.

	- The default directory which the load dialogue is pointed to is \MenuSets in the
	REAPER resource directory, the one to which REAPER offers to save its .ReaperMenu
	files by default. But the file can be browsed to and loaded from elsewhere.  
	The file path specified in the USER SETTINGS may point to a .ReaperMenu file located
	anywhere on the hard drive.

	- When the full path to the .ReaperMenu file is specified in the USER SETTINGS below,
	the load dialogue menu item is inactive because if you load another file, on the
	next run the script will still default to the file located at the path specified in
	the USER SETTINGS.

	- The same script can be added to and run from 3 sections of the Action list:
	*Main*, *MIDI Editor* and *MIDI Event List Editor* and maintain different menus.  
	The sections *Main* and *Main (alt recording)* share the same content, therefore
	the script added to the *Main* section in the *Main (alt recording)* section will have
	the same menu.  
	If this script has been installed via ReaPack application it has been automaticaly 
	added to both *Main* and *MIDI Editor* sections of the Action list.  
	Besides that, multiple instances of the script can be created under slightly different
	names, loaded into any or all 3.5 mentioned sections of the Action list and used with
	different .ReaperMenu files in parallel.  
	If you prefer specifying the path to the menu file in the USER SETTINGS below use the
	option proper for the section of the Action list the script is going to be run from.

	- Actions in *Media Explorer* section of the Action list cannot be launched with this
	script and using it from *MIDI Inline Editor* section is impractical therefore it has
	been made incompatible with them.

	- You can run MIDI Editor menus from Arrange even if the MIDI Editor is closed.  
	If you do so while working with the MIDI Inline Editor be aware that the grid and snap
	settings which will be used by the menu actions (such as Split and the like) are those
	of the main MIDI Editor unless option *Use the same grid division in arrange view and
	MIDI editor* is enabled in the Snap/Grid settings.   
	If MIDI Editor is closed toggle state indicators (if any) won't appear next to the menu 
	items.

	- Likewise Arrange menus can be run from inside the MIDI Editor.

]]
---------------------------------------------------------------------------------------
------------------------------------- USER SETTINGS -----------------------------------
---------------------------------------------------------------------------------------
-- OPTIONAL
-- Insert full path to the .ReaperMenu file between the double square brackets.
-- All options can be filled out, the menu will depend on the current Action list section.
-- FILE_PATH_MAIN when running this script from the 'Main' section of the Action list.
-- FILE_PATH_MIDI_Ed when running this script from the 'MIDI Editor' section.
-- FILE_PATH_MIDI_EvLst when running this script from the 'MIDI Event List' section.

FILE_PATH_MAIN = [[]]
FILE_PATH_MIDI_Ed = [[]]
FILE_PATH_MIDI_EvLst = [[]]

----------------------------------------------------------------------------------------
---------------------------------- END OF USER SETTINGS --------------------------------
----------------------------------------------------------------------------------------


function Msg(param)
reaper.ShowConsoleMsg(tostring(param)..'\n')
end

local r = reaper

local _,scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local scr_name = scr_name:match('([^\\/]+)%.%w+')

	if sect_ID == 32062 or sect_ID == 32063 then r.MB('The script wasn\'t meant to be run\n\nfrom this section of the Action list.','ERROR',0) r.defer(function() end) return end


local sect_ID_t = {
[0] = {'Main', FILE_PATH_MAIN},
[32060] = {'MIDI_Ed', FILE_PATH_MIDI_Ed},
[32061] = {'MIDI_EvLst', FILE_PATH_MIDI_EvLst}
}


local file = sect_ID_t[sect_ID][2]
local file = file:match('%s*(.*)%s*') -- trim leading and trailing spaces just in case
-- evaluate path
local file_exists = r.file_exists(file)
local file_tmp = io.open(file, 'r')
local menu_code = file_tmp and file_tmp:read('*a') -- to prevent error when file is invalid
local f_close = file_tmp and file_tmp:close() -- to prevent error when file is invalid
local empty = menu_code and menu_code == '' and 'is empty'
local invalid = menu_code and not menu_code:match('item_%d*=') and 'is invalid' -- no menu tags


-- if user defined file not found
local err = file ~= '' and not file_exists and 'wasn\'t found' or empty or invalid

	if err then resp = r.MB('The user defined ReaperMenu file '..err..'.\n\n\t    "YES" — to load new file\n\n    "NO" — to switch to the last used file (if any)','PROMPT',3)
		if resp == 7 then file = '' -- to trigger GetExtState() below
		elseif resp == 6 then resp = 1 -- to trigger file load dialogue below
		else r.defer(function() end) return end
	end

	-- load file from the saved path
	if file == '' then file = r.GetExtState(scr_name..'_'..sect_ID_t[sect_ID][1], 'menu_file_path') end

local err = file == '' and 'saved ReaperMenu path' or not r.file_exists(file) and 'used ReaperMenu file'
	if err and resp ~= 1 then resp = r.MB('The last '..err..' wasn\'t found.\n\n         Click "OK" to load a new menu file.','ERROR',1) -- ~=1 cond stems from user defined file prompt dialogue above
		if resp == 2 then r.defer(function() end) return end
	end

	::RETRY::
	if file == '' or not file:match('%.ReaperMenu') or resp == 1 or LOAD_NEW then -- =1 cond stems from user defined file prompt dialogue above, LOAD_NEW stems from the last menu item below

	local path = reaper.GetResourcePath()
	local sep = r.GetOS():match('Win') and '\\' or '/'

	retval, file = r.GetUserFileNameForRead(path..sep..'MenuSets'..sep, 'Select and load ReaperMenu file', '.ReaperMenu')
		if not retval then r.defer(function() end) return end
		if not file:match('%.ReaperMenu$') then resp = r.MB('        The selected file desn\'t\n\nappear to be a ReaperMenu file.\n\n            Click "OK" to retry.','ERROR',1)
			if resp == 1 then goto RETRY
			else r.defer(function() end) return end
		end

	local file_tmp = io.open(file, 'r')
	local menu_code = file_tmp:read('*a')
	file_tmp:close()
	local err = menu_code == '' and 'empty' or not menu_code:match('item_%d*=') and 'invalid'
		if err then resp = r.MB('          ReaperMenu file is '..err..'.\n\n\tClick "OK" to retry.','ERROR',1)
			if resp == 1 then goto RETRY
			else r.defer(function() end) return end
		end

	r.SetExtState(scr_name..'_'..sect_ID_t[sect_ID][1], 'menu_file_path', file, true) -- save selected file path

	end

local act_t, menu_t, cap_t = {}, {}, {}
local form_t = {['-1'] = '|', ['-2'] = '>', ['-3'] = '<', ['-4'] = '#'} -- menu formatting special characters
local cntr = 1
local close_submenu

	for line in io.lines(file) do
		if cntr == 1 then -- cntr prevents evaluation of lines other than the 1st
		menu_name = line:match('%[(.+)%]')  -- to be added to the menu at the bottom
		MIDI = menu_name:match('MIDI') -- the var is used to condition way of calling actions from the menu
		end
		if line:match('=') and line:match('[%s]') or line:match('[%-]') then -- the last 2 conditions target toolbars to avoid capturing icons and text formatting lines whose tags lack these characters
		local action = line:match('=([^%s%-]+)')
			if action then act_t[#act_t+1] = action
			cap_t[#cap_t+1] = line:match('%s(.+)') end -- collect menu item names to display as undo cap
		local form, item = line:match('=(%-%d)'), line:match('%s(.+)$')
		local menu_elem = form and (form == '-2' or form == '-4') and form_t[form]..item..'|' or form and form ~= '-3' and form_t[form] or item and item..'|'
		menu_t[#menu_t+1] = menu_elem and menu_elem
		-- Submenu closures, respecting several closures in a row, when there're several nested submenus
			if form == '-3' and not close_submenu -- 1st closure
			then table.insert(menu_t,#menu_t,'<') close_submenu = true -- insert closure tag before the most recent line  pushing it to a later position
			elseif form == '-3' and close_submenu then menu_t[#menu_t+1] = form_t[form]..'|' -- every next closure
			else close_submenu = false end -- reset the value if no closures
		end -- cond. end
	cntr = cntr + 1
	end -- loop end


-- Add toggle ON indicator to menu items
	for k1,v1 in next, act_t do
		if r.GetToggleCommandStateEx(MIDI and 32060 or 0, r.NamedCommandLookup(v1)) > 0 then -- some actions may return 2 instead of 1, probably those which have Off state but don't have an explicit On state, e.g. 'View: Show notation text on notes' in the MIDI Editor section,
			for k2,v2 in next, menu_t do
				local cap = cap_t[k1]:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0') -- escape special chars, doesn't work directly inside string.match()
				if v2:match(cap) then  -- if it's the same menu item line in all tables
				menu_t[k2] = '!'..v2 end
			end
		end
	end


gfx.init('Dynamic ReaperMenu', 0, 0)
-- open menu at the mouse cursor
gfx.x = gfx.mouse_x
gfx.y = gfx.mouse_y


local data = '#menu name: '..menu_name..'|#file name: '..file:match('[^\\/]-$') -- display menu and file names in the menu
local load = sect_ID_t[sect_ID][2] ~= '' and file_exists and not empty and not invalid and '#' or '' -- only activate the option to load a file when no user defined file path, or when either such path or the file are invalid
local input = gfx.showmenu(table.concat(menu_t)..'|'..load..'♦  LOAD REAPER MENU FILE|'..data)


	if input > 0 and input <= #act_t then -- menu returns 0 upon closure so the relational operator is meant to prevent error at r.NamedCommandLookup(act_t[input]) function when the menu closes since there's no 0 key in the table
		if r.NamedCommandLookup(act_t[input]) == 0 then r.MB('The (custom) action / script wasn\'t found.','ERROR',0) r.defer(function() end) return end
	r.Undo_BeginBlock()
		if sect_ID == 32060 or sect_ID == 32061 then -- MIDI Editor sections
			if not MIDI then
			r.Main_OnCommand(r.NamedCommandLookup(act_t[input]),0)
			else
			r.MIDIEditor_OnCommand(r.MIDIEditor_GetActive(), r.NamedCommandLookup(act_t[input])) -- run action associated with pressed menu item
			end
		elseif sect_ID == 0 or sect_ID == 100 then
			if MIDI then
			local is_open = r.MIDIEditor_GetActive()
				if not is_open then r.Main_OnCommand(40153, 0) -- Item: Open in built-in MIDI editor
				end
			local HWND = r.MIDIEditor_GetActive()
			r.MIDIEditor_OnCommand(HWND, r.NamedCommandLookup(act_t[input]))
				if not is_open then r.MIDIEditor_OnCommand(HWND, 2) -- File: Close window
				end
			else local ID = r.Main_OnCommand(r.NamedCommandLookup(act_t[input]),0)
			end
		end
	r.Undo_EndBlock(cap_t[input]:gsub('[&]',''), -1) -- remove quick access ampersand if any for the cap
	elseif input > #act_t then LOAD_NEW = true -- when the last menu item 'LOAD REAPER MENU FILE' is selected
	goto RETRY
	elseif input == 0 then r.defer(function() end) return end -- prevent 'Script: Run' caption when menu closes without action


gfx.quit()



