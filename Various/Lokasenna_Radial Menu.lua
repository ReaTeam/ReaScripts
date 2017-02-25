--[[
Description: Lokasenna_Radial Menu 
Version: 2.0.0
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
Links:
	Forum Thread http://forum.cockos.com/showthread.php?p=1788321
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
	Provides a circular "quick menu" for commonly-used actions, similar
	to how weapons are selected in many FPS games. 
	
	Use the accompanying script "Lokasenna_Radial Menu Setup.lua" to
	configure the menu and additional settings.
	
	See the forum thread for further documentation/bug reports/help.
Extensions:
Provides:
	[main] Lokasenna_Radial Menu/Lokasenna_Radial Menu Setup.lua > Lokasenna_Radial Menu Setup.lua
	Lokasenna_Radial Menu/Lokasenna_Radial Menu - example menus.txt > Lokasenna_Radial Menu - example menus.txt
--]]

-- Licensed under the GNU GPL v3

--[[
	Just to make debug messaging simpler:
	
	_=dm and Msg("debug stuff here")
	
	More efficient than calling another function and making it check
	
]]--


local dm, _ = debug_mode
local function Msg(str)
	reaper.ShowConsoleMsg(tostring(str).."\n")
end

local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]

--!!REQUIRES START
--!!REQUIRE "Lokasenna_GUI library beta 8.lua"

local function req(file)
	
	local ret = loadfile(script_path .. file) or loadfile(script_path .. "Libraries\\" .. file)
	if not ret then
		reaper.ShowMessageBox("Couldn't find "..file, "Missing library", 0)
		return 0
	else 
		return ret
	end	

end

req("Lokasenna_GUI library beta 8.lua")()

--!!REQUIRES END

_=dm and GUI.Msg(script_path)




-- For the context boxes
GUI.fonts[5] = {"Calibri", 15}

-- For the current tab
GUI.fonts[6] = {"Calibri", 18, "b"}

-- For the radial menu
GUI.fonts[7] = {"Calibri", 16, "b"}
GUI.fonts[8] = {"Calibri", 14}

local settings_file_name = (script_path or "") .. "Lokasenna_Radial Menu - user settings.txt"

-- It's much more efficient to put the trig functions in local variables if we're going
-- to be using them a lot.
local sin, cos, tan, asin, acos, atan, sqrt = math.sin, math.cos, math.tan, math.asin, math.acos, math.atan, math.sqrt

local pi = 3.1416

local ox, oy, frm_w

local cur_depth, last_depth, cur_btn = 0, 0, -2
local base_depth = 0

local redraw_menu = true

-- Current menu option, angle + radius from ox, oy
local mouse_mnu = -2
local mouse_angle, mouse_r, mouse_lr = 0, 0, 0

-- Width (in rads) of each button in the current menu
local mnu_adj = 0

-- For processing swipes
local track_swipe, stopped = false, nil

-- Was the window recently reopened by swiping?
local swipe_retrigger = 0

local startup = true
local hvr_time = 0

--local ra, rb, rc, rd = 50, 60, 64, 160


local key_mode_str = "Close the menu,Perform the highlighted action and close the menu,Keep the menu open"

local misc_opt_str = "Return to the base menu after performing an action,Hover over an option to 'click' it      →"





	---- Documentation ----
	

local settings_help_str = [=[--[[
		Settings for Lokasenna_Radial Menu.lua
	
		This file is written as a Lua table, and must use the appropriate 
	syntax with regard to tables, indices, keys, strings, etc, etc. If
	you run Radial Menu and get an error loading the menu, it either
	couldn't find this file or you've got some incorrect Lua in it.

	A few general notes:

	- Due to quirks with the function that loads these settings into 
	the script, all indices must include square brackets and/or quotation 
	marks rather than being left bare, i.e. 

					[3] 			not		3
					["col_main"]	not		col_main
	
	
	- Colors can be specified per button, per menu, or globally (see
	table index [-1]). Buttons with no colors specified will use their
	menu's settings, menus will use the global settings.
	
	- When a button is assigned to an action that's toggled On, the button
	  will light up; if the mouse is hovering or clicked on it, the toggle 
	  color will be blended with the hover or background color, respectively.
	
	- Menus are numbered starting from 0, and menu numbers do NOT need to
	  be contiguous - that is, 1 2 3 4 9 11 15 20 25 is fine, so feel free
	  to organize your menus by number however you want.
	
	- Buttons are numbered starting from 0, and button numbers DO need to
	  be contiguous.
	  
	- You can add a button in the center of the ring by giving it the
	  number [-1]
	  
	
	  


	Menu #:
	[0] = {	
	
		(There's no limit to the number of menus you can have)
		
		["alias"] = "blah",			A name to use for this menu so you don't have
									to remember menu numbers. Displayed in the
									menu list, and can be used in button actions
									and context boxes. (See below)
	
		["col_main"] = {			Normal button color for buttons in this menu
			[1] = 0.0,				R
			[2] = 1.0,				G	(values are from 0-1)
			[3] = 1.0,				B
			
		["col_tog"] = {				Toggled color, for use with
			...						i.e. "Options: Toggle metronome"
			
		["col_hvr"] = {				Mouse-over color
			...
			
		["col_bg"] = {				Background color
			...
		
	
	
		Button #:
		[0] = {
		
			(Maximum of 16 buttons per menu)
		
			Button settings:
			
			["lbl"] = "cool",			The button's label
			["act"] = "menu 1",			Action to perform / menu to open. Valid
										commands are as follows:
										
										Action IDs:											
										40364	
											
										Script/extension actions:
										_SWS_AWMPLAYTOG
										_RS2bf8e77e958d48b42c7d7b585790ee0427a96a7e
										
										Open a menu:
										menu 20		(opens menu 20)
										menu stuff	(opens the menu with alias 'stuff')
										
	
			["col_main"] = {			Normal button color
				[1] = 0.0,				R
				[2] = 1.0,				G	(values are from 0-1)
				[3] = 1.0,				B
				
			["col_tog"] = {				Toggled color, for use with
				...						i.e. "Options: Toggle metronome"
				
			["col_hvr"] = {				Mouse-over color
				...
				
				
				
	Global settings are kept in index [-1]:
	[-1] = {
	
		["close_time"] = 600,		How long to keep the window open (in ms) on 
									startup	if no key is being held down. Going
									lower than 600ms will probably cause the menu 
									to keep opening and closing.
	
	
									Global color settings:
		["col_main"] = {			Normal button color for buttons in this menu
			[1] = 0.0,				R
			[2] = 1.0,				G	(values are from 0-1)
			[3] = 1.0,				B
			
		["col_tog"] = {				Toggled color, for use with
			...						i.e. "Options: Toggle metronome"
			
		["col_hvr"] = {				Mouse-over color
			...
			
		["col_bg"] = {				Background color
			...
			
		["contexts"] = {			What menu to open on startup for a given mouse
			["mcp|empty"] = 10,		context. Contexts can be assigned with menu 
									numbers or aliases, i.e.
										20
										stuff
									
									If a particular context isn't given a menu, 
									it will	look up one 'level' at a time until
									it finds a match.
									
									Example:									
									The menu was opened with the mouse cursor over 
									an empty area of a track in the Arrange view.
									The script will look for:
										["arrange|track|empty"]
									then:
										["arrange|track"]
									then:
										["arrange"]
									
									If there's still no match, it will open menu 0.				
									(see the Setup script's Context tab for a list
									of available contexts)
			
		
		["hvr_click"] = false,		Boolean - hover over a button to 'click' it
		["hvr_time"] = 200,			Hover time for ^^^ (in ms)
		
		["key_mode"] = 1,			What to do when the shortcut key is released
									(1-3, see the options in the Setup script)
									
		["last_tab"] = 1,			The last tab that was active in the Setup script
		
		["mnu_0_on_act"] = true,	Boolean - return to the base menu after
									performing an action?
									
		["num_btns"] = 8,			Number of buttons for new menus to start with
		
		["preview"] = true,			Whether or not to preview a menu's buttons when
									hovering the mouse over it.
									
		
									Button radiuses/target areas:
		["ra"] = 48,				Center button
		["rb"] = 60,				Currently unused
		["rc"] = 116,				Inside of the button ring
		["rd"] = 192,				Outside of the button ring
		["re"] = 192,				Threshold for tracking Swipes
		
									Note that the preview labels when hovering over
									a menu are drawn with a radius of (rc - ra), so
									adjusting these will affect the labels as well.
		
		["swipe"] = {				Parameters for the Swiping feature:
		
			["accel"] = 65,			Start sensitivity
			["actions"]	= true,		Whether Swipes can trigger actions, or just menus
			["decel"] = 10,			Stop sensitivity
			["enabled"] = true,		Whether Swiping mode is active or not
			["menu"] = 0,			What menu to use for Swipe actions...
			["mode"] = 1,		...if this is set to 2. Setting it to 1 will always
									use the current menu
			["stop"] = 20,			Stop time for Swipes, in milliseconds
			
		
]]--
]=]


local help_pages = {
	


	{"Radial Menu",
		
[[- Assign the Radial Menu script to a key shortcut, hold down the key to bring up the menu, and release it to close the menu again. While the menu is open, left-clicking inside the window will run the highlighted action or open a submenu.
 
    (Some key shortcuts may not play nicely with the script, causing the window 
    to flicker open and closed. Please let me know in the forum thread)
 
- When hovering over a button assigned to a submenu, that menu's buttons are 'previewed' below the current ones.
 
- To back out of a menu, click any of the outer corners, or in the center of the ring if the current menu has no button there.
 
- Certain Reaper actions will steal 'focus' from the script window and cause it to close prematurely. I'm working on it.

]]},



	{"Menus",
		
[[- Menus may have anywhere from one to sixteen buttons, with an optional button in the center of the ring. Each menu can have its own color settings, or use the colors set in the Global tab.
 
- They can also be given an alias for buttons and contexts to reference rather than having to remember menu numbers.
 
- Right-click buttons in the radial menu at left to edit them. Like menus, they can each have their own colors, or they can use the parent menu's colors; if the menu has no colors assigned, buttons will likewise grab their colors from the Global settings.
 
- Using a | in button labels will wrap the text to a new line.
 
- To paste an action ID, use the Paste button.
 
- Assign buttons to open a menu with 'menu 20', or 'menu stuff'. Assign a button's action to 'back' to return to the base menu.

]]},



	{"Context", 
		
[[- By default, Radial Menu will always open menu 0 at startup. This tab allows you to specify different menus to open based on which Reaper area the mouse cursor is over - i.e. one set of actions for tracks and another for media items.
 
- Any contexts left blank will look at the 'level' above them for a match, and the level above that, eventually defaulting back to 0.
 
- Contexts can be assigned via menu numbers or aliases. 
 
- Double-clicking any of the text boxes will jump to that menu.
 
- To find the context for a Reaper element, hover the mouse over it, making sure this window is in focus, and press F1.
	
]]},



	{"Swiping",
		
[[-	If the basic Radial Menu wasn't fast enough for you, try this. Swiping lets you trigger menus and actions via mouse movements, in the same way as answering a call on your mobile phone.
 	
- When Swiping is enabled, quickly move the mouse out from the center of the Radial Menu window; the option you swiped over will be 'clicked'.
 
- When a submenu is opened via Swiping, the script window will re-center itself on your mouse cursor, allowing very fast navigation through your menu setup.
 
- Adjust the sliders to fine-tune the Swiping logic until it feels right. 
		
]]},



	{"Global",
		
[[- Any menus that don't have their own colors specified will look here, as will buttons in those menus don't have colors of their own.
 
- Sizes and target areas for the radial menu can be adjusted. Be aware that the 'preview' labels drawn when hovering over a menu are centered between the red and yellow rings, so some combinations of settings may not look very good.
  
]]},



	{"Options",
		
[[- Depending on the options selected here, some of Reaper's actions may not play nicely with the script; particularly, anything that opens a window or otherwise takes 'focus' away from the script. It's a Reaper issue, unfortunately.
 
- Settings are saved to 'Lokasenna_Radial Menu settings.txt' in the same folder as this script. Feel free to edit it, but make sure it's written with proper Lua syntax. The settings file also has further documentation for most parameters.
]]},	
	
}


local function init_help_pages()
	
	_=dm and Msg(">init_help_pages")
	
	local w = GUI.elms.frm_help.w - 2*GUI.elms.frm_help.pad
	
	local str_arr = {}
	
	for k, v in ipairs(help_pages) do
		
		-- Add this page's title to the list
		table.insert(str_arr, v[1])	
	
		-- Wrap all of the pages to fit in the frame	
		help_pages[k][2] = GUI.word_wrap(v[2], 4, w, 0, 2)	
	
	end
	
	-- Update the Help menu
	GUI.elms.mnu_help.optarray = str_arr
	GUI.elms.mnu_help.numopts = #str_arr
	
	_=dm and Msg("<init_help_pages")
	
end
	
	





-- The default settings and menus
local mnu_arr = {
	
	-- Using index -1 for random settings so that 'for i = 0, #mnu_arr'
	-- loops won't even see it
	[-1] = {
		["col_main"] = {0.753, 0.753, 0.753},
		["col_hvr"] = {0.878, 0.878, 0.878},
		["col_tog"] = {0, 0.753, 0},
		["col_bg"] = {0.2, 0.2, 0.2},
		["contexts"] = {},
		["num_btns"] = 8,
		["last_tab"] = 1,
		["key_mode"] = 1,
		["mnu_0_on_act"] = false,
		["hvr_click"] = false,
		["hvr_time"] = 200,
		["close_time"] = 600,
		["preview"] = true,
		["ra"] = 48,
		["rb"] = 60,
		["rc"] = 116,
		["rd"] = 192,
		["re"] = 192,
		["swipe"] = {
						accel = 65,
						actions = false,
						decel = 10,
						stop = 20,
						menu_mode = 1,
						menu = 0,
		},
	},
	-- Base level
	[0] = {
		-- Submenu titles 
		[0] = { lbl = "cool", act = "menu 1"},
		[1] = { lbl = "neat", act = "menu 2"},
		[2] = { lbl = "alright", act = "menu 3"},
		[3] = { lbl = "mediocre", act = "menu 4"},
		[4] = { lbl = "boring", act = "menu 5"},
		[5] = { lbl = "crappy", act = "menu 6"},
		[6] = { lbl = "useless", act = "menu 7"},
		[7] = { lbl = "terrible", act = "menu 8"},
	}		
}



-- Create a new button in the specified position and menu
local function init_btn(i, j, lbl)
	
	_=dm and Msg("init button "..tostring(i)..", menu "..tostring(j))
	
	mnu_arr[i][j] = { ["lbl"] = lbl.." "..j, ["act"] = "" }
	
end


-- Create a blank submenu
local function init_menu(i, num_btns, alias)
	
	if mnu_arr[i] then
		reaper.ShowMessageBox("Menu "..tostring(i).." already exists.", "Whoops", 0)
		return 0
	elseif i < 0 then
		reaper.ShowMessageBox("Menus may only use positive numbers.", "Whoops", 0)
		if cur_depth == i then cur_depth = 0 end
		return 0
	end
	
	local num_btns = num_btns or mnu_arr[-1].num_btns
	local lbl = alias or ("menu "..i)
	
	_=dm and Msg("init menu: "..tostring(i).."  "..tostring(num_btns)..tostring(alias).."  ")
	
	mnu_arr[i] = {}
	

	if alias then 
		_=dm and Msg("\talias: "..tostring(alias))
		mnu_arr[i].alias = alias 
	end
	
	mnu_arr[i][-1] = {	lbl = "Back",
						act = "back" }
	
	for j = 0, (num_btns - 1) do

		init_btn(i, j, lbl)
	
	end
end



--[[
	Adapted from a post on Stack Overflow:http://stackoverflow.com/questions/6075262/lua-table-tostringtablename-and-table-fromstringstringtable-functions

	- Changed ' ' indents to a full tab
	- Table indices are given []s and ""s where appropriate; Lua was
	  refusing to read the output as a table without them
	- Combined type calls for Number and Boolean since they can both use tostring()

]]--
local function serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep("\t", depth)

	if name then 
		tmp = tmp .. "[" .. 
		((type(name) == "string") and ('"'..name..'"') or name)
		.. "] = " 
	end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in GUI.kpairs(val, "full") do
            tmp =  tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep("\t", depth) .. "}"
    elseif type(val) == "number" or type(val) == "boolean" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    else
        tmp = tmp .. "\"[unserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
end


-- Save the current menu settings to a text file
-- (Same name and path as the script)
local function save_menu(export)
	
	local file_name = settings_file_name
	--[[
		Disabled until we're able to use the dialog to save a new file
	
	if export then
		ret, user_file = reaper.GetUserFileNameForRead("", "Export user settings...", ".lua")
		if ret then file_name = user_file end
	end
	]]--
	
	local file = io.open(settings_file_name, "w+") or nil
	if not file then 
		return 0 
	end

	local str = settings_help_str .. "\n\nreturn "..serializeTable(mnu_arr)
	
	file:write(str)
	
	io.close(file)
	
end



-- Load the settings file, or browse for a new one
local function load_menu(browse)

	_=dm and Msg("loading menus")

	local file_name = settings_file_name
	local load_settings
	if browse then
		_=dm and Msg("\tprompting for a file")
		local ret, user_file = reaper.GetUserFileNameForRead("", "Import menus...", ".lua" )
		if ret then 
			file_name = user_file
			--load_settings = reaper.ShowMessageBox("Import this file's global settings as well?", "Import settings?", 3)
		end
	
		-- If the user hit Cancel in either of the dialogs
		--if not ret or load_settings == 2 then return 0 end
	
	end
	
	
	_=dm and Msg("\topening "..tostring(file_name))

	local file, err
	if reaper.file_exists(file_name) then
		file, err = io.open(file_name, "r") or nil
	end
		
	if file then
		
		local arr

		_=dm and Msg("\tparsing saved menus")

		local str = file:read("*all")
		
		if str then	arr, err = load(str) end
		if not err then 
			_=dm and Msg("\tparsed menu; checking for missing values\n")
			
			arr = arr()
			
			-- Check for any missing settings in [-1] and copy them from the defaults
			arr[-1] = GUI.table_copy(mnu_arr[-1], arr[-1], 1)
			
			-- Copy the final table over to mnu_arr
			mnu_arr = arr
		else
			reaper.ShowMessageBox("Error parsing menu file:\n"..tostring(err), "Invalid menu file", 0)
			return 0
		end

		io.close()
	else
		
		if not setup then
			reaper.ShowMessageBox("Error opening menu file:\n"..tostring(err), "Menu file not found", 0)
			return 0
		else
			-- Submenus for all of the default menu items
			for i = 1, #mnu_arr[0] + 1 do
				
				local lbl = mnu_arr[0][i - 1].lbl
				init_menu(i, nil, lbl)
				
			end	
		end
	end	


end



-- Print out the contents of mnu_arr, for debugging and shit
local function spit_table()
	
	GUI.Msg("-1 = ")
	
	for k, v in GUI.kpairs(mnu_arr[-1]) do
		
		if type(v) == "table" then
			if k == "contexts" then
				GUI.Msg("\tcontexts: ")
				for c, n in GUI.kpairs(v) do
					GUI.Msg("\t\t"..c.." = "..n)
				end
			elseif k == "misc_opts" then
				local str = ""
				for a, b in ipairs(v) do
					str = str..", "..tostring(b)
				end
				GUI.Msg("\t"..k.." = "..string.sub(str, 3))
			else
				GUI.Msg("\t"..k.." = "..table.concat(v, ", "))
			end
		else
			GUI.Msg("\t"..k.." = "..tostring(v))
		end
	end
	
	
	-- Get a list of all the menus that exist
	local arr = {}
	for k, v in pairs(mnu_arr) do
		if k ~= -1 then
			table.insert(arr, k)
		end
	end
	table.sort(arr)
	
	
	for k = 1, #arr do
		
		--GUI.Msg("working on arr["..k.."]")
		local i = arr[k]
		
		GUI.Msg(i.." = ")
		for j = 0, #mnu_arr[i] do
			
			GUI.Msg("\t"..j.." = ")
			
			if type(mnu_arr[i][j]) == "table" then
				
				for k, v in pairs(mnu_arr[i][j]) do
					
					if type(v) == "table" then
						GUI.Msg("\t\t"..k.." = "..table.concat(v, ", "))
					else
						GUI.Msg("\t\t"..k.." = "..tostring(v))
					end
					
				end
				
			else
			
				GUI.Msg("\t"..j.." = "..tostring(mnu_arr[i][j]))
				
			end
			
		end
		
	end
	
end







-- Update the tooltip label
-- Use force = [tooltip_idx] to, duh, force that tooltip to display
local function update_tooltip(force)

if GUI.tooltip_elm or force then
		--GUI.Msg("step 1")
		if force or GUI.IsInside(GUI.tooltip_elm, GUI.mouse.x, GUI.mouse.y) then
			--GUI.Msg("step 2")
			if GUI.elms.lbl_tooltip.z == 20 or GUI.elms.lbl_tooltip.fade_arr or force then
				
				GUI.elms.lbl_tooltip.fade_arr = nil
				
				GUI.font(4)
				local str = force or GUI.tooltip_elm.tooltip  --tooltips[force or GUI.tooltip_elm.tooltip]
				local str_w, str_h = gfx.measurestr(str)
				
				GUI.elms.lbl_tooltip.x = (GUI.w - str_w) / 2
				GUI.elms.lbl_tooltip.y = 434 + (30 - str_h) / 2
				
				GUI.Val("lbl_tooltip", str)
				GUI.elms.lbl_tooltip.z = 1
			
			end
		elseif not GUI.mouse.down then
			
			--GUI.elms.lbl_tooltip.z = 18
			GUI.elms.lbl_tooltip:fade(2, 1, 20)
			GUI.tooltip_elm = nil	
			--GUI.Msg("setting nil")
			
		end
	end
	
	GUI.forcetooltip = nil
	
end





local function check_alias(str)

	if str == "" or str == nil then return false end

	_=dm and Msg("looking up alias '"..tostring(str).."'")
	local found = false
	for i, v in pairs(mnu_arr) do
		
		_=dm and Msg("\tmenu "..tostring(i)..": "..tostring(mnu_arr[i].alias))
		
		if mnu_arr[i].alias and mnu_arr[i].alias == str then	
			_=dm and Msg("got: "..tostring(i))
			found = tonumber(i)
		end
	end
	
	return found
	
end



-- Get the mouse context from Reaper and parse it into context_arr's format
local function get_context_str()
	
	local wnd, seg, det = reaper.BR_GetMouseCursorContext()
			
	local str = (not wnd or wnd == "unknown")
				and ""
				or wnd .. 	((not seg or seg == "")
							and ""
							or "|" .. seg ..	(( not det or det == "" )
												and ""
												or "|" .. det 
												)
							)	
	
	return str
	
end


-- Find the appropriate menu for the current mouse context
local function get_context_mnu()
	
	_=dm and Msg("getting mouse context")
	
	local str = get_context_str()
	
	
	-- See if there's an exact match; if there isn't, trim off the last value and try again
	while str do
		_=dm and Msg("\tlooking for context: '"..tostring(str).."'")
		if mnu_arr[-1].contexts[str] then
			_=dm and Msg("\tfound context at "..str)
			local depth = mnu_arr[-1].contexts[str]
			depth = tonumber(depth) or check_alias(depth)
			_=dm and Msg(tostring(depth))
			if depth and depth > 0 then
				base_depth = depth
				break
			end
		end
		str = string.match(str, "(.*)|[^|]*$")
		
	end
	
	-- Show the user what context is being used
	if str then GUI.elms.lbl_context = GUI.Label:new(1,	8, -20, "Context: "..str, false, 4) end
	
	cur_depth = base_depth
	_=dm and Msg("\tsettled on depth "..base_depth)
	
end

-- Highlight the text box for the current mouse context
local function get_context_txt()
	
	_=dm and Msg(">get_context")
	
	local wnd, seg, det = reaper.BR_GetMouseCursorContext()
			
	local str = get_context_str()
			
	_=dm and Msg("\tgot context str: "..tostring(str))

	if str and str ~= "" then
		
		for k, v in pairs(context_arr) do

			if v.con == str then
				GUI.elms["txt_context_"..k].focus = true
			elseif v.lbl ~= "" then
				GUI.elms["txt_context_"..k].focus = false
			end
			
		end		
		
	end
	
	GUI.redraw_z[6] = true	
		
	_=dm and Msg("<get_context")	
		
end



-- Parse and run the current action
local function run_act(act)

	_=dm and Msg("running action: "..tostring(act))

	-- Blank?
	if act == "" then
		
		return 0
		--last_depth = 0
		--cur_depth = 0
	
	
	elseif act == "back" then
	
		
		_=dm and Msg("\tresetting to base depth")
		cur_depth = base_depth
		last_depth = base_depth	
		if setup then  end
		cur_btn = -2
		redraw_menu = true
	
	-- Is it a menu?
	elseif string.sub(act, 1, 4) == "menu" then
					
		local num = string.sub(act, 6)
		
		_=dm and Msg("\topening menu "..tostring(num))
		
		new_depth = tonumber(num) or check_alias(num)
		
		if new_depth and new_depth > 0 then
			last_depth = cur_depth
			cur_depth = new_depth
			if setup then  end
			cur_btn = -2
			redraw_menu = true
			
		else
		
			reaper.ShowMessageBox("Menu '"..tostring(num).."' doesn't seem to exist.", "Whoops", 0)
			
		end	
	
	
	-- It's not a special command, so it must be a plain ol' action
	else

		if string.sub(act, 1, 1) == "_" then act = reaper.NamedCommandLookup(act) end
		
		-- Just some error checking because Lua occasionally 
		-- throws a fit about numbers that are strings
		act = tonumber(act)
		
		_=dm and Msg("sending action to Reaper: "..tostring(act))
		
		if act and act > 0 then reaper.Main_OnCommand(act, 0) end
		if not setup and mnu_arr[-1].mnu_0_on_act then
			cur_depth = base_depth
			last_depth = base_depth
			if setup then  end
			cur_btn = -2
			redraw_menu = true
		end
	end	

	_=dm and Msg("\tcur_depth is now "..tostring(cur_depth))
	_=dm and Msg("finished with action")	
	
end



-- Figure out an appropriate text color for a given background
-- Adapted from WT's 'colorsmart' macro in the Default 5.0 theme
local function colorsmart(bg)
--[[
set luma      + + * 0.299 [trackcolor_r] * 0.587 [trackcolor_g] * 0.114 [trackcolor_b]
	=	0.299 * r	+	0.587 * g	+	0.114 * b

]]--
	local r, g, b = table.unpack(bg)
	local luma = 0.299 * r + 0.587 * g + 0.114 * b

	-- I love this ternary structure so, so much
	return (luma > 0.4) 	and ((luma > 0.9) and 	{0, 0, 0}
											  or	{0.1, 0.1, 0.1}
								)
							or  ((luma > 0.1) and	{0.9, 0.9, 0.9}
											  or	{1, 1, 1}
								)
end


-- Automate the process of looking for color values so I don't
-- have to keep typing it out every time
local function get_color(key, i)
	
	local col

	if key == "hvr_tog" or key == "bg_tog" then
		
		_=dm and Msg("getting hover/toggle colors @ "..i)
		
		local col_str = (key == "hvr_tog") and "col_hvr" or "col_bg"
		
		local col_a, col_b = get_color(col_str, i), get_color("col_tog", i)
		_=dm and Msg("col_a = "..table.concat(col_a, ", "))
		_=dm and Msg("col_b = "..table.concat(col_b, ", "))
		
		_=dm and Msg("got colors, getting gradient")
		
		col = {GUI.gradient(col_a, col_b, 0.5)}

		_=dm and Msg("grad rgb = "..table.concat(col, ", "))

	else
		
		if mnu_arr[cur_depth][i] and mnu_arr[cur_depth][i][key] then
			col = mnu_arr[cur_depth][i][key]
		elseif mnu_arr[cur_depth][key] then
			col = mnu_arr[cur_depth][key]
		else
			col = mnu_arr[-1][key]
		end
	end

	return col

end




-- Update the "Working on menu" box's menu list
local function update_mnu_menu()
	
	_=dm and Msg("updating mnu_menu")
	
	local arr = {}

	_=dm and Msg("\tadding menus to arr")

	local str
	for k, v in pairs(mnu_arr) do
		
		if k >= 0 then
			
			if mnu_arr[k].alias then
				str = k.." - "..mnu_arr[k].alias
			else
				str = k
			end
			table.insert(arr, str)
			
			_=dm and Msg("\t\t"..#arr.." = "..arr[#arr])
			
		end
	end
	
	_=dm and Msg("\tmade arr")
	
	table.sort(arr, GUI.full_sort)
	
	-- Make a note of which entry is the current menu
	-- so we can set it afterward
	
	_=dm and Msg("\tlooking for current depth")
	
	local val
	for k, v in pairs(arr) do
		_=dm and Msg("\t\t"..tostring(k).." = "..tostring(v))
		if tonumber(string.match(v, "^(%d+)")) == cur_depth then
			_=dm and Msg("\tfound val "..tostring(v).." at pos "..tostring(k))
			val = k
			break
		end
	end
	
	GUI.elms.mnu_menu.optarray = arr
	GUI.elms.mnu_menu.numopts = #arr
	--GUI.Val("mnu_menu", tonumber(val))
	GUI.elms.mnu_menu.retval = tonumber(val)
	
	_=dm and Msg("finished with mnu_menu")

end



-- Update global/misc settings from the values in mnu_arr
local function update_glbl_settings()
	
	_=dm and Msg("updating global settings")

	-- Swipe tab stuff
	GUI.Val("chk_swipe", {mnu_arr[-1].swipe.enabled})
	GUI.elms.frm_no_swipe.z = mnu_arr[-1].swipe.enabled and 20 or 17
	GUI.Val("sldr_accel", mnu_arr[-1].swipe.accel)
	GUI.Val("sldr_decel", mnu_arr[-1].swipe.decel)
	GUI.Val("sldr_stop", mnu_arr[-1].swipe.stop / 5 - 1)
	GUI.Val("opt_swipe_mode", mnu_arr[-1].swipe.mode)
	GUI.Val("txt_swipe_menu", mnu_arr[-1].swipe.menu)
	GUI.Val("chk_swipe_acts", {mnu_arr[-1].swipe.actions})



	GUI.elms.frm_col_g_btn.col_user = mnu_arr[-1].col_main
	GUI.elms.frm_col_g_hvr.col_user = mnu_arr[-1].col_hvr
	GUI.elms.frm_col_g_tog.col_user = mnu_arr[-1].col_tog
	GUI.elms.frm_col_g_bg.col_user = mnu_arr[-1].col_bg

	GUI.Val("sldr_num_btns", mnu_arr[-1].num_btns - GUI.elms.sldr_num_btns.min)
	GUI.Val("chk_preview", {mnu_arr[-1].preview})
	GUI.Val("tabs", mnu_arr[-1].last_tab)
	GUI.Val("opt_key_mode", mnu_arr[-1].key_mode)
	GUI.Val("chk_misc_opts", {mnu_arr[-1].mnu_0_on_act, mnu_arr[-1].hvr_click})
	GUI.Val("txt_hvr_time", mnu_arr[-1].hvr_time)
	GUI.Val("txt_close_time", mnu_arr[-1].close_time)


	GUI.redraw_z[GUI.elms.frm_col_g_btn.z] = true
	
	redraw_menu = true

	_=dm and Msg("done updating global settings")

	
end


-- Update menu settings from the values in mnu_arr
local function update_mnu_settings()
	
	_=dm and Msg("updating menu settings, cur_depth = "..tostring(cur_depth))
	
	if not mnu_arr[cur_depth] then 
		init_menu(cur_depth) 
		update_mnu_menu()
	end
	
	GUI.Val("txt_alias", mnu_arr[cur_depth].alias or "")
	
	local c_main, c_hvr, c_tog, c_bg
	
	c_main = get_color("col_main", -2)
	c_hvr = get_color("col_hvr", -2)
	c_tog = get_color("col_tog", -2)
	c_bg = get_color("col_bg", -2)
	
	GUI.elms.frm_col_m_btn.col_user = c_main
	GUI.elms.frm_col_m_hvr.col_user = c_hvr
	GUI.elms.frm_col_m_tog.col_user = c_tog
	GUI.elms.frm_col_m_bg.col_user = c_bg
	
	GUI.Val("chk_center", ({not not mnu_arr[cur_depth][-1]}))
	
	
	-- See if this is the menu assigned to swiping
	local swipe = mnu_arr[-1].swipe.menu
	if  	mnu_arr[-1].swipe.enabled 
		and cur_depth == (tonumber(swipe) or check_alias(swipe)) 
		and GUI.Val("opt_swipe_mode") == 2 
		then
		
		GUI.elms.frm_swipe_menu.z = 22
		GUI.elms.lbl_swipe_menu.z = GUI.elms.mnu_menu.z
		
		
		
	else
	
		GUI.elms.frm_swipe_menu.z = 20
		GUI.elms.lbl_swipe_menu.z = 20
	
	end
	
	redraw_menu = true

	GUI.redraw_z[GUI.elms.frm_col_m_btn.z] = true
	
	_=dm and Msg("done updating menu settings")
	
end


-- Update the current button settings from the values in mnu_arr
local function update_btn_settings()
	
	_=dm and Msg("updating button settings, cur_btn = "..tostring(cur_btn))
	
	local lbl, act, c_main, c_hvr, c_tog
	if cur_btn ~= -2 then
		lbl = mnu_arr[cur_depth][cur_btn].lbl
		act = mnu_arr[cur_depth][cur_btn].act
		c_main = get_color("col_main", cur_btn)
		c_hvr = get_color("col_hvr", cur_btn)
		c_tog = get_color("col_tog", cur_btn)
		GUI.elms.frm_no_btn.z = 20
	else
		lbl = ""
		act = ""
		c_main = "elm_frame"
		c_hvr = "elm_frame"
		c_tog = "elm_frame"
		GUI.elms.frm_no_btn.z = 3
	end
	
	GUI.Val("txt_btn_lbl", lbl)
	GUI.Val("txt_btn_act", act)
	GUI.elms.frm_col_b_btn.col_user = c_main
	GUI.elms.frm_col_b_hvr.col_user = c_hvr
	GUI.elms.frm_col_b_tog.col_user = c_tog
	GUI.redraw_z[GUI.elms.frm_col_b_btn.z] = true
	
	redraw_menu = true
	
	_=dm and Msg("done updating button settings")
		
end




-- Clear the menu's custom colors so get_color will use the globals
local function use_global_colors()
	
	mnu_arr[cur_depth].col_main = nil
	mnu_arr[cur_depth].col_hvr = nil
	mnu_arr[cur_depth].col_tog = nil	
	mnu_arr[cur_depth].col_bg = nil
	
	update_mnu_settings()
	
end


-- Clear the button's custom colors so get_color will use the menu
local function use_menu_colors()
	
	mnu_arr[cur_depth][cur_btn].col_main = nil
	mnu_arr[cur_depth][cur_btn].col_hvr = nil
	mnu_arr[cur_depth][cur_btn].col_tog = nil
	
	update_btn_settings()
	
end


-- Since we can't access the clipboard directly, this provides a space
-- for the user to paste action IDs into the script
local function paste_act()
	-- retval, retvals_csv reaper.GetUserInputs( title, num_inputs, captions_csv, retvals_csv )
	local ret, act = reaper.GetUserInputs("Paste an action ID from the clipboard", 1, "Paste here:,extrawidth=64", "")
	
	if ret then
		mnu_arr[cur_depth][cur_btn].act = act
		update_btn_settings()
	end
	
end


-- Open the settings file in an external editor
local function open_txt()
	
	GUI.open_file(settings_file_name)
	
end


-- Add and delete menus
local function add_menu()
	
	_=dm and Msg("Adding menu")
	
	
	-- Find the first blank menu
	local i, def_num = 0
	while not def_num do
		
		if not mnu_arr[i] then
			def_num = i
			break
		end
		
		i = i + 1
		
	end
	
	
	local ret, vals = reaper.GetUserInputs("Add a new menu", 3, "Add menu number:,Alias:,Number of buttons:", (def_num or "")..",,"..mnu_arr[-1].num_btns)
	
	_=dm and Msg("\tCSV: "..tostring(vals))
	
	local num, alias, btns = string.match(vals, "([^,]+),([^,]*),([^,]+)")
	num, btns = tonumber(num), tonumber(btns)
	if alias == "" then alias = nil end
	
	_=dm and Msg("\tParsed as: Menu "..tostring(num)..", Alias: "..tostring(alias)..", Buttons: "..tostring(btns))

	if ret and num and btns then
		cur_depth = num
		init_menu(tonumber(num), tonumber(btns), alias)

		
		cur_btn = -2
		update_mnu_menu()
		update_mnu_settings()
		update_btn_settings()
	end
	
	
end

local function del_menu()
	
	_=dm and Msg("deleting menu "..tostring(cur_depth))
	
	if cur_depth == 0 then return 0 end
	
	local arr = {}
	local act
	
	for k, v in pairs(mnu_arr) do
		
		if k >= 0 then
			table.insert(arr, k)
			
			-- Look for any buttons that were assigned to this menu and clear them
			for i = -1, #mnu_arr[k] do
				
				if mnu_arr[k][i] and mnu_arr[k][i].act then
					act = mnu_arr[k][i].act
				
					if string.match(act, "menu "..cur_depth) 
						or	(mnu_arr[cur_depth].alias and string.match(act, "menu "..mnu_arr[cur_depth].alias) ) then
					
						_=dm and Msg("\tclearing button "..tostring(i).." in menu "..tostring(k))
						mnu_arr[k][i].act = ""						
					end
				end				
			end			
		end
	end
	
	table.sort(arr, GUI.full_sort)
	
	-- Now that we have a list, the current menu can go away
	mnu_arr[cur_depth] = nil
	cur_btn = -2
	
	_=dm and Msg("\tgetting new menu value")
	
	-- Find the menu number below this one
	local val
	for k, v in pairs(arr) do
		if v == cur_depth then
			_=dm and Msg("\t\tfound "..v.." at pos "..k)
			cur_depth = arr[k - 1] or 0
			_=dm and Msg("\t\tnew depth = "..tostring(cur_depth))
			break
		end
	end
	
	_=dm and Msg("finished deleting, updating settings")
	
	update_mnu_menu()
	update_mnu_settings()
	update_btn_settings()	
	
end


-- Add and remove buttons to the current menu
local function remove_btn(cur)
	
	_=dm and Msg("deleting a button")
	
	if cur and cur_btn == -1 then
		
		mnu_arr[cur_depth][-1] = nil
		GUI.Val("chk_center", {false})
		cur_btn = -2
		
	elseif #mnu_arr[cur_depth] > 0 then
	
		local old_arr = mnu_arr[cur_depth]
		local num = cur and cur_btn or #old_arr		
		local arr = {}
		
		_=dm and Msg("\tcreating temporary array")

		
		
		for k, v in pairs(old_arr) do
		
			
			arr[k] = v
			_=dm and Msg("\t\tadded "..tostring(k).." - "..tostring(v))
				
		end
		
		_=dm and Msg("\tremoving btn "..tostring(num).." - "..old_arr[num].lbl.." of "..tostring(#arr))
		
		table.remove(arr, num)
		
		_=dm and Msg("\tarray now has "..tostring(#arr).." buttons")
		_=dm and Msg("\tcopying back to mnu_arr")
		
		old_arr = {}
		
		for k, v in pairs(arr) do
			
			--if type(k) == "number" and k > 1 then k = k - 1 end
			old_arr[k] = v
			_=dm and Msg("\t\tcopied "..tostring(k).." - "..tostring(v))
		
		end
		
		mnu_arr[cur_depth] = old_arr
		
		cur_btn = -2

--[[		
		if #mnu_arr[cur_depth] > 0 then
			if cur_btn == #mnu_arr[cur_depth] then cur_btn = -2 end
			table.remove(mnu_arr[cur_depth], #mnu_arr[cur_depth])
			update_btn_settings()
			GUI.redraw_z[0] = true
		end
]]--		
	end
	
	update_btn_settings()
	GUI.redraw_z[0] = true
	
end

local function add_btn()
	
	--GUI.Msg(cur_depth.." | "..#mnu_arr[cur_depth].." | "..mnu_arr[cur_depth].lbl)
	if #mnu_arr[cur_depth] < 15 then
		init_btn(cur_depth, #mnu_arr[cur_depth] + 1, "btn")	
		update_btn_settings()
		GUI.redraw_z[0] = true
	end
end


local function move_btn(dir)
	
	if cur_btn < 0 then return 0 end
	
	local btn = mnu_arr[cur_depth][cur_btn]
	local swap_num = (cur_btn + dir) % (#mnu_arr[cur_depth] + 1)
	local swap_btn = mnu_arr[cur_depth][swap_num]
	
	mnu_arr[cur_depth][cur_btn] = swap_btn
	mnu_arr[cur_depth][swap_num] = btn
	
	
	cur_btn = swap_num	
	update_btn_settings()

end



-- Reload the menu file (or a new one) and update all settings
local function refresh_menu(new)
	

	load_menu(new)
	
	cur_depth = 0
	cur_btn = -2
	
	update_mnu_menu()
	update_glbl_settings()
	update_mnu_settings()
	update_btn_settings()
	
end










local function check_key()

	_=dm and Msg("check_key")
	
	-- For debugging
	local mod_str = ""
	
	if startup then
		
		_=dm and Msg("Startup, looking for key...")
		
		key_down = GUI.char
		
		if key_down ~= 0 then
					
			--[[
				
				(I have no idea if the same values apply on a Mac)
				
				Need to narrow the range to the normal keyboard ASCII values:
				
				ASCII 'a' = 97
				ASCII 'z' = 122
				
				1-26		Ctrl+			char + 96
				65-90		Shift/Caps+		char + 32
				257-282		Ctrl+Alt+		char - 160
				321-346		Alt+			char - 224

				gfx.mouse_cap values:
				
				4	Ctrl
				8	Shift
				16	Alt
				32	Win
				
				For Ctrl+4 or Ctrl+}... I have no fucking clue short of individually
				checking every possibility.

			]]--	
			
			local cap = GUI.mouse.cap
			local adj = 0
			if cap & 4 == 4 then			
				if not (cap & 16 == 16) then
					mod_str = "Ctrl"
					adj = adj + 96			-- Ctrl
				else				
					mod_str = "Ctrl Alt"
					adj = adj - 160			-- Ctrl+Alt
				end
				--	No change				-- Ctrl+Shift
				
			elseif (cap & 16 == 16) then
				mod_str = "Alt"
				adj = adj - 224				-- Alt
				
				--  No change				-- Alt+Shift
				
			elseif cap & 8 == 8 or (key_down >= 65 and key_down <= 90) then		
				mod_str = "Shift/Caps"
				adj = adj + 32				-- Shift / Caps
			end
	
			hold_char = key_down + adj
			_=dm and Msg("Detected: "..mod_str.." "..string.char(hold_char))
			
			startup = false
		elseif not up_time then
			up_time = reaper.time_precise()
		end
		
	else
		key_down = gfx.getchar(hold_char)
		_ = (dm and key_down == 0) and Msg("Key is no longer down")
	end	

end




local function get_mouse_mnu(swipe)
	
	local mouse_mnu
	local mnu_adj = not swipe and mnu_adj or  2 / (#mnu_arr[swipe] + 1) 
	
	-- Figure out where the mouse is
	-- On the center button?
	if not swipe and mouse_r < mnu_arr[-1].ra and mnu_arr[cur_depth][-1] then
		mouse_mnu = -1
	
	-- Outside the ring, either way?
	-- Ignore '>' cases if we're swiping, since that will frequently be outside the ring
	elseif (not swipe and mouse_r > mnu_arr[-1].rd + 80) or mouse_r < 32 then
		mouse_mnu = -2
	
	-- Must be over a button then
	else
	
		if mouse_angle < 0 then mouse_angle = mouse_angle + 2 end
		mouse_mnu = math.floor(mouse_angle / mnu_adj + 0.5)
		if mouse_mnu == (#mnu_arr[swipe or cur_depth] + 1) then mouse_mnu = 0 end		
	
	end	
	
	return mouse_mnu
	
end



local function check_swipe()
	
	_=dm and Msg(">check_swipe")
	
	local x, y, lx, ly = GUI.mouse.x, GUI.mouse.y, GUI.mouse.lx, GUI.mouse.ly
	
	-- Converting these from human-readable to what we want here
	local accel = 100 - mnu_arr[-1].swipe.accel
	local stop = 0.001 * mnu_arr[-1].swipe.stop	
	
	
	--local diff = sqrt( (x - lx)^2 + (y - ly)^2 )
	local diff = mouse_r - mouse_lr
	
	-- Moving fast enough to start tracking a swipe?
	if diff > accel then track_swipe = true end

	if track_swipe then
		
		stopped = (diff <= mnu_arr[-1].swipe.decel) and (stopped or reaper.time_precise()) or nil

		local mnu = mnu_arr[-1].swipe.mode == 2 and	( 	   tonumber(mnu_arr[-1].swipe.menu) 
													or 	check_alias(mnu_arr[-1].swipe.menu) )
												or	cur_depth


		
		local btn = get_mouse_mnu(mnu)
		
		if stopped and swipe_retrigger == 0 and mnu >= 0 and (reaper.time_precise() - stopped > stop) then
			
			_=dm and Msg("\tpicked up a gesture:\tmenu "..tostring(mnu)..", button "..tostring(btn))
			
			--[[
				act =
						mode 1:		current menu --> get_mouse_mnu()
						mode 2:		swipe menu --> get_mouse_mnu(mnu)
				
				
				
			]]--
			
			local act = mnu_arr[mnu][btn].act
			
							
			if string.sub(tostring(act), 1, 4) == "menu" then

				_=dm and Msg("\topening "..tostring(act))

				run_act(act)
					
				local x, y = reaper.GetMousePosition()
				x, y = x - (frm_w / 2) - 8, y - (frm_w / 2) - 32
				
				gfx.quit()
				gfx.init(GUI.name, GUI.w, GUI.h, 0, x, y)
				
			elseif mnu_arr[-1].swipe.actions then
			
				_=dm and Msg("\trunning action: ")
			
				run_act(act)	
			
			end
			
			GUI.redraw_z[1] = true
			
			swipe_retrigger = 2
			
			stopped = nil
			track_swipe = false
	
		end
	
	end
	
	_=dm and Msg("<check_swipe")
	
end



--[[	Update all of our mouse-related stuff
	
	- Angle, radius, current menu button
	- See if we need to check for swipes
	- See if we need to run the hover timer, or if the hover timer has run out	
	
]]--
local function check_mouse()
	
	_=dm and Msg(">check_mouse")
	
	-- Get the mouse position
	mouse_lr = mouse_r
	mouse_angle, mouse_r = GUI.cart2polar(GUI.mouse.x, GUI.mouse.y, ox, oy)
	
	local prev_mnu = mouse_mnu
	mouse_mnu = get_mouse_mnu()

	
	if not setup and mnu_arr[-1].swipe.enabled and not GUI.mouse.down and not GUI.mouse.r_down and mouse_r > mnu_arr[-1].re then check_swipe() end
	
	

	-- If we're over a new option, reset the hover timer
	if prev_mnu ~= mouse_mnu then
		
		_=dm and Msg("mouse is now over button "..tostring(mouse_mnu))
		
		if mnu_arr[-1].hvr_click  then
			_=dm and Msg("hovering")
			hvr_time = reaper.time_precise()
		end
		
		opt_clicked = false
		
		GUI.redraw_z[GUI.elms.frm_radial.z] = true 
	
	-- If the hover time has run out, click the current option
	elseif hvr_time and mnu_arr[-1].hvr_click and (reaper.time_precise() - hvr_time) > (mnu_arr[-1].hvr_time / 1000) then
		if mnu_arr[cur_depth][mouse_mnu] then
			_=dm and Msg("hovered long enough, clicking")
			run_act(mnu_arr[cur_depth][mouse_mnu].act)
			GUI.redraw_z[GUI.elms.frm_radial.z] = true
			hvr_time = nil
		end
	end
	
	_=dm and Msg("<check_mouse")
	
end












--[[	GUI Elements and Parameters

	Tabframe	z	x y w h 	caption		tabs	pad
	Frame		z	x y w h		[shadow		fill	color	round]
	Label		z	x y			caption		shadow	font
	Button		z	x y w h 	caption		func	...
	Radio		z	x y w h 	caption 	opts	pad
	Checklist	z	x y 		caption 	opts	dir		pad
	Knob		z	x y w		caption 	min 	max		steps	default		ticks
	Slider		z	x y w		caption 	min 	max 	steps 	default		dir		ticks
	Range		z	x y w		caption		min		max		steps 	default_a 	default_b
	Textbox		z	x y w h		caption		pad
	Menubox		z	x y w h 	caption		opts	pad

	Tabframe z_sets are defined like so:

	GUI.elms.tabs_blah:update_sets(
		{
				   __ z levels shown on that tab
		  __ tab  /
		 /		  |
		 |		  v
		 v     
		[1] = {2, 3, 4}, 
		[2] = {5, 6, 7}, 
		[3] = {8, 9, 10},
		}
	)
	
]]--


-- Values to reference elms off of

-- Bottom of tabs
local line_y0 = 22

-- Menu tab's separator
local line_y1 = 192

-- Global tab's separator
local line_y2 = 200

-- Swipe tab's separator
local line_y3 = 54

local line_y_tt = 432

local ref1 = {x = 490, y = line_y0 + 64, w = 270, h = 68}	-- Menu color settings
local ref2 = {x = 490, y = line_y1 + 40, w = 270, h = 68}	-- Button color settings
local ref3 = {x = 490, y = line_y0 + 16, w = 270, h = 68}	-- Global color settings


GUI.elms = not setup and {

	frm_radial = GUI.Frame:new(			19,	0, 0, 400, 400, false, true, "elm_bg", 0),
	
}
or
{



	---- General elements z = 21+
	
	tabs = GUI.Tabframe:new(			24,	432, 0, 56, 22, "", "Menus,Context,Swiping,Global,Options,Help", 8),	
	
	frm_radial = GUI.Frame:new(			23,	0, 0, 432, 432, false, true, "elm_bg", 0),
	
	frm_line_x = GUI.Frame:new(			22,	432, 0, 4, 432, true, true),
	
	frm_line_tt = GUI.Frame:new(		21, 0, line_y_tt, 1024, 4, true, true),
	



	---- Hidden layers z = 20 ----
	
	lbl_tooltip = GUI.Label:new(		20, 386, 442, "tooltip", 0, 4),
	frm_rad_overlay = GUI.Frame:new(	20, 0, 0, 432, 432, false, true, "shadow", 0),

	frm_swipe_menu = GUI.Frame:new(		20, 0, 0, 432, 432, false, true, "magenta", 0),
	lbl_swipe_menu = GUI.Label:new(		20, 616, line_y0 + 32, "Assigned to Swipe", 1, 2),

	---- Menus tab  z = 2,3,4 ----

	-- Menu settings
	mnu_menu = GUI.Menubox:new(			4,	704, line_y0 + 8, 64, 20, "Current menu:", "0,1,2,3,4", 4),
	txt_alias = GUI.Textbox:new(		4,	840, line_y0 + 8, 96, 20, "Alias:", 4),
	btn_add_menu = GUI.Button:new(		4,	464, line_y0 + 8, 48, 20, "Add", add_menu),
	btn_del_menu = GUI.Button:new(		4,	520, line_y0 + 8, 48, 20, "Delete", del_menu),

	lbl_num_m_btns = GUI.Label:new(		4,	ref1.x + 328, ref1.y + 2, "Number of buttons:", 1, 3),
	num_m_btns_rem = GUI.Button:new(	4,	ref1.x + 384, ref1.y + 20, 24, 20, "-", remove_btn),
	num_m_btns_add = GUI.Button:new(	4,	ref1.x + 352, ref1.y + 20, 24, 20, "+", add_btn),

	chk_center = GUI.Checklist:new(		4,	ref1.x + 328, ref1.y + 64, 0, 0, "", "Center button", "v", 0),


	-- Menu colors
	frm_ref1 = dm and GUI.Frame:new(	4,	ref1.x,	ref1.y, ref1.w, ref1.h, false, false, "magenta", 0),

	lbl_col_m_btn = GUI.Label:new(		4,  ref1.x, 		ref1.y + 2, 	"Button color:", 1, 3),
	frm_col_m_btn = GUI.Frame:new(		4,	ref1.x + 82, 	ref1.y, 		20, 20, true, true, "elm_frame", 0),
	lbl_col_m_hvr = GUI.Label:new(		4,	ref1.x - 26, 	ref1.y + 24, 	"Mouseover color:", 1, 3),
	frm_col_m_hvr = GUI.Frame:new(		4,	ref1.x + 82, 	ref1.y + 22, 	20, 20, true, true, "elm_frame", 0),
	lbl_col_m_tog = GUI.Label:new(		4,	ref1.x + 168, 	ref1.y + 2, 	"Toggled color:", 1, 3),
	frm_col_m_tog = GUI.Frame:new(		4,	ref1.x + 250, 	ref1.y, 		20, 20, true, true, "elm_frame", 0),	
	lbl_col_m_bg = GUI.Label:new(		4,	ref1.x + 144, 	ref1.y + 24, 	"Background color:", 1, 3),
	frm_col_m_bg = GUI.Frame:new(		4,	ref1.x + 250, 	ref1.y + 22, 	20, 20, true, true, "elm_frame", 0),

	btn_use_global = GUI.Button:new(	4,	ref1.x + 78,	ref1.y + 48, 	128, 20, "Use global colors", use_global_colors),
	

	-- Button settings
	frm_line_y1 = GUI.Frame:new(		2,	436, line_y1, 600, 4, true, true),
	frm_no_btn = GUI.Frame:new(			3,	436, line_y1, 600, line_y_tt - line_y1, false, true, "faded", 0),
	
	lbl_cur_btn = GUI.Label:new(		4,	448, line_y1 + 8, "Current button settings:", 1, 2),

	--lbl_btn_move = GUI.Label:new(		4,	632, line_y1 + 12, "Move:", 0, 3),
	btn_btn_left = GUI.Button:new(		4,	632, line_y1 + 10, 32, 20, "↓", move_btn, -1),
	btn_btn_del = GUI.Button:new(		4,	672, line_y1 + 10, 64, 20, "Delete", remove_btn, true),
	btn_btn_right = GUI.Button:new(		4,	744, line_y1 + 10, 32, 20, "↑", move_btn, 1),
	
	
	frm_ref2 = dm and GUI.Frame:new(	4,	ref2.x,	ref2.y, ref2.w, ref2.h, false, false, "magenta", 0),
	
	lbl_col_b_btn = GUI.Label:new(		4,	ref2.x, 			ref2.y + 2, 	"Button color:", 1, 3),
	frm_col_b_btn = GUI.Frame:new(		4,	ref2.x + 82, 		ref2.y, 		20, 20, true, true, "elm_frame", 0),
	lbl_col_b_hvr = GUI.Label:new(		4,	ref2.x - 26, 		ref2.y + 24, 	"Mouseover color:", 1, 3),
	frm_col_b_hvr = GUI.Frame:new(		4,	ref2.x + 82, 		ref2.y + 22, 	20, 20, true, true, "elm_frame", 0),		
	lbl_col_b_tog = GUI.Label:new(		4,	ref2.x + 168, 		ref2.y + 2, 	"Toggled color:", 1, 3),
	frm_col_b_tog = GUI.Frame:new(		4,	ref2.x + 250, 		ref2.y, 		20, 20, true, true, "elm_frame", 0),		
	
	btn_use_mnu = GUI.Button:new(		4,	ref2.x + 78, 		ref2.y + 48, 	128, 20, "Use menu colors", use_menu_colors),

	txt_btn_lbl = GUI.Textbox:new(		4,	496, line_y1 + 118, 256, 20, "Label:", 4),
	txt_btn_act = GUI.Textbox:new(		4,	496, line_y1 + 144, 256, 20, "Action:", 4),
	btn_paste = GUI.Button:new(			4,	766, line_y1 + 143, 48, 20, "Paste", paste_act),
	
	
	
	---- Context tab z = 5,6,7 ----
	
		-- Populated at run-time --





	---- Swipe tab z = 17,18,19 ----
	
	
	chk_swipe = GUI.Checklist:new(	18, 444, line_y0 + 6, 0, 0, "", "Swiping enabled", "v", 0),


	frm_line_swipe = GUI.Frame:new(		17,	436, line_y3, 600, 4, true, true),
	frm_no_swipe = GUI.Frame:new(		17, 436, line_y3 + 4, 600, line_y_tt - line_y0 - 34, false, true, "faded", 0),
	
	sldr_accel = GUI.Slider:new(		18,	452, line_y3 + 40, 96, "Start sensitivity", 0, 100, 100, 65, "h"),
	sldr_decel = GUI.Slider:new(		18,	580, line_y3 + 40, 96, "Stop sensitivity", 0, 100, 100, 10, "h"),
	sldr_stop = GUI.Slider:new(			18, 708, line_y3 + 40, 96, "Stop time", 5, 100, 19, 3, "h"),
	sldr_re = GUI.Slider:new(			18,	836, line_y3 + 40, 96, "Swiping threshold", 32, 192, 160, 160, "h"),

	frm_r1 = GUI.Frame:new(				20,	828, line_y3, 112, 80, false, false, nil, 0),

	opt_swipe_mode = GUI.Radio:new(		19,	464, line_y3 + 96, 192, 80, "Swiping uses buttons from:", "The active menu, ", 4),
	txt_swipe_menu = GUI.Textbox:new(	18,	542, line_y3 + 150, 96, 20, "Menu:", 4),
	
	chk_swipe_acts = GUI.Checklist:new(	18, 464, line_y3 + 192, nil, nil, "", "Swiping can trigger actions", "v", 4),

	
	

	---- Global tab z = 8,9,10 ----
	
	frm_ref3 = dm and GUI.Frame:new(	9,	ref3.x,	ref3.y, ref3.w, ref3.h, false, false, "magenta", 0),
	
	lbl_col_g_btn = GUI.Label:new(		9,  ref3.x, 		ref3.y + 2, 	"Button color:", 1, 3),
	frm_col_g_btn = GUI.Frame:new(		9,	ref3.x + 82, 	ref3.y, 		20, 20, true, true, "elm_frame", 0),
	lbl_col_g_hvr = GUI.Label:new(		9,	ref3.x - 26, 	ref3.y + 24, 	"Mouseover color:", 1, 3),
	frm_col_g_hvr = GUI.Frame:new(		9,	ref3.x + 82, 	ref3.y + 22, 	20, 20, true, true, "elm_frame", 0),
	lbl_col_g_tog = GUI.Label:new(		9,	ref3.x + 168, 	ref3.y + 2, 	"Toggled color:", 1, 3),
	frm_col_g_tog = GUI.Frame:new(		9,	ref3.x + 250, 	ref3.y, 20, 	20, true, true, "elm_frame", 0),
	lbl_col_g_bg = GUI.Label:new(		9,	ref3.x + 144, 	ref3.y + 24, 	"Background color:", 1, 3),
	frm_col_g_bg = GUI.Frame:new(		9,	ref3.x + 250, 	ref3.y + 22, 	20, 20, true, true, "elm_frame", 0),

	sldr_num_btns = GUI.Slider:new(		9,	572, line_y0 + 128, 96, "Number of buttons (new menus)", 4, 16, 12, 4, "h"),
	
	chk_preview = GUI.Checklist:new(	9,	816, line_y0 + 17, nil, nil, "", "Show submenu preview", "v", 4),

	frm_line_y2 = GUI.Frame:new(		8,	436, line_y2, 600, 4, true, true),
	lbl_radii = GUI.Label:new(			9,	448, line_y2 + 8, "Radii and target areas:", 1, 2),

	frm_r2 = GUI.Frame:new(				10,	450, line_y2 + 40, 252, 140, false, false, nil, 0),

	sldr_ra = GUI.Slider:new(			9,	464, line_y2 + 72, 96, "Center button", 16, 96, 80, 32, "h"),
	sldr_rc = GUI.Slider:new(			9,	592, line_y2 + 72, 96, "Inside of ring", 64, 160, 96, 52, "h"),
	sldr_rd = GUI.Slider:new(			9,	592, line_y2 + 144, 96, "Outside of ring", 128, 192, 64, 64, "h"),

	sldr_rb = GUI.Slider:new(			20,	464, line_y2 + 144, 96, "Nothing yet", 20, 128, 108, 40, "h"),



	---- Options tab z = 11,12,13

	--mnu_g_shape = GUI.Menubox:new(		12,	500, line_y0 + 96, 64, 20, "Button shape:", "Circle,Square,Arc", 4),	
	
	opt_key_mode = GUI.Radio:new(		12,	464, line_y0 + 16, 336, 108, "When the shortcut key is released:", key_mode_str, 4),
	
	chk_misc_opts = GUI.Checklist:new(	12, 474, line_y0 + 148, 336, 108, "", misc_opt_str, "v", 4),
	txt_hvr_time = GUI.Textbox:new(		12, 756, line_y0 + 172, 48, 20, "(ms):", 4),
	txt_close_time = GUI.Textbox:new(	12, 756, line_y0 + 212, 48, 20, "If no key is detected, close the window after (ms):", 4),
	
	btn_open_txt = GUI.Button:new(		12,	532, line_y0 + 266, 192, 20, "Open settings in text editor", open_txt),
	btn_refresh_txt = GUI.Button:new(	12,	532, line_y0 + 292, 192, 20, "Refresh from settings file", refresh_menu),
	btn_load_txt = GUI.Button:new(		12,	532, line_y0 + 318, 192, 20, "Import menus...", refresh_menu, true),
	--btn_save_txt = GUI.Button:new(		12,	500, line_y0 + 270, 192, 22, "Export user settings...", save_menu, true),
	btn_spit_table = GUI.Button:new(	12,	532, line_y0 + 344, 192, 20, "Show saved data (for debugging)", spit_table),
	
	
	
	
	---- Help tab z = 14,15,16 ----
	
	mnu_help = GUI.Menubox:new(			15, 668, line_y0 + 6, 128, 20, "", "", 4),
	frm_help = GUI.TxtFrame:new(		16, 436, line_y0 + 32, 588, 340, "help stuff", 4, "txt", 8, false, true, "elm_bg", 0),
	
	btn_thread = GUI.Button:new(		15,	640, line_y0 + 380, 96, 20, "Forum thread", GUI.open_file, thread_URL),
	btn_donate = GUI.Button:new(		15,	752, line_y0 + 380, 72, 20, "Donate", GUI.open_file, donate_URL),	
	
}


GUI.elms.frm_radial.state = false
GUI.elms.frm_radial.font = 6




---- Tooltips ----

local function assign_tooltips()
	
	-- Trash variable, placeholder for assigning the same tooltip to multiple elements
	-- rather than having to type/copy/edit them multiple times
	local tip
		
	
	-- Menus tab --
	
	GUI.elms.btn_add_menu.tooltip = "Add a new menu"
	GUI.elms.btn_del_menu.tooltip = "Delete this menu"
	
	GUI.elms.mnu_menu.tooltip = "Select a menu to edit (new menus are created the first time you click the button assigned to them)"

	tip = "Swiping is currently set to use this menu"
	GUI.elms.frm_swipe_menu.tooltip = tip
	GUI.elms.lbl_swipe_menu.tooltip = tip
	
	GUI.elms.txt_alias.tooltip = "Assign an alias to this menu"
	
	tip = "The menu's normal button color"
	GUI.elms.lbl_col_m_btn.tooltip = tip
	GUI.elms.frm_col_m_btn.tooltip = tip
	
	tip = "The menu's mouse-over color"
	GUI.elms.lbl_col_m_hvr.tooltip = tip
	GUI.elms.frm_col_m_hvr.tooltip = tip

	tip = "The menu's 'this action is toggled on' color"
	GUI.elms.lbl_col_m_tog.tooltip = tip
	GUI.elms.frm_col_m_tog.tooltip = tip
	
	tip = "The menu's background color"
	GUI.elms.lbl_col_m_bg.tooltip = tip
	GUI.elms.frm_col_m_bg.tooltip = tip
	
	GUI.elms.btn_use_global.tooltip = "Use the global settings for this menu (won't override individual button colors)"
	
	tip = "Add or remove buttons from the current menu (16 buttons max)"
	GUI.elms.lbl_num_m_btns.tooltip = tip
	GUI.elms.num_m_btns_rem.tooltip = tip
	GUI.elms.num_m_btns_add.tooltip = tip
	
	GUI.elms.chk_center.tooltip = "Add an additional button in the center of this menu"
	
	GUI.elms.frm_no_btn.tooltip = "Right-click a button in the radial menu to edit it"
	
	GUI.elms.btn_btn_left.tooltip = "Move this button counterclockwise"
	GUI.elms.btn_btn_right.tooltip = "Move this button clockwise"
	GUI.elms.btn_btn_del.tooltip = "Delete this button"
	
	
	tip = "The button's normal color"
	GUI.elms.lbl_col_b_btn.tooltip = tip
	GUI.elms.frm_col_b_btn.tooltip = tip
	
	tip = "The button's mouse-over color"
	GUI.elms.lbl_col_b_hvr.tooltip = tip
	GUI.elms.frm_col_b_hvr.tooltip = tip
	
	tip = "The button's 'this action is toggled on' color"
	GUI.elms.lbl_col_b_tog.tooltip = tip
	GUI.elms.frm_col_b_tog.tooltip = tip
	
	GUI.elms.btn_use_mnu.tooltip = "Use the menu's settings for this button"
	
	GUI.elms.txt_btn_lbl.tooltip = "What label to display for the button (Use '|' to wrap text to a new line)"
	GUI.elms.txt_btn_act.tooltip = "What action to assign to this button (see 'Help' tab for extra commands)"
	GUI.elms.btn_paste.tooltip = "Scripts can't access the clipboard, so use this to paste action IDs from Reaper"


	-- Context tab --
	-- Populated at runtime --
	
	

	-- Swiping tab --

	GUI.elms.chk_swipe.tooltip = "Enable/disable mouse swiping to 'click' buttons"
	
	GUI.elms.frm_no_swipe.tooltip = "Enable swiping to use these options"
	
	GUI.elms.sldr_accel.tooltip = "How easily the script will begin tracking a Swipe"
	GUI.elms.sldr_decel.tooltip = "How slow the mouse must be moving to be considered 'stopped'"
	GUI.elms.sldr_stop.tooltip = "How long the mouse must be stopped before triggering an action"
	GUI.elms.sldr_re.tooltip = "Swipes are only tracked if the mouse is outside this radius"
	
	GUI.elms.opt_swipe_mode.tooltip = "What set of actions to use for Swipes"
	GUI.elms.chk_swipe_acts.tooltip = "Allow Swiping to trigger Reaper actions, or only open menus?"



	-- Global tab --

	tip = "The normal button color"
	GUI.elms.lbl_col_g_btn.tooltip = tip
	GUI.elms.frm_col_g_btn.tooltip = tip
	
	tip = "Moused-over button color"
	GUI.elms.lbl_col_g_hvr.tooltip = tip
	GUI.elms.frm_col_g_hvr.tooltip = tip
	
	tip = "'This action is toggled on' button color"
	GUI.elms.lbl_col_g_tog.tooltip = tip
	GUI.elms.frm_col_g_tog.tooltip = tip
	
	tip = "Menu background color"
	GUI.elms.lbl_col_g_bg.tooltip = tip
	GUI.elms.frm_col_g_bg.tooltip = tip
	
	GUI.elms.chk_preview.tooltip = "When hovering over a menu, show a 'preview' of that menu's buttons"
	
	GUI.elms.sldr_num_btns.tooltip = "Number of buttons to add when first creating a new menu"
	
	GUI.elms.sldr_ra.tooltip = "The size of the center button - also the size of the 'dead zone' if the center button isn't shown"
	GUI.elms.sldr_rb.tooltip = "I'm sure I'll find a use for this one soon"
	GUI.elms.sldr_rc.tooltip = "The inner radius of the menu ring"
	GUI.elms.sldr_rd.tooltip = "The outer radius of the menu ring"
	
	
	-- Options tab --
	
	GUI.elms.opt_key_mode.tooltip = "What to do when the script's shortcut key is released"
	
	GUI.elms.btn_open_txt.tooltip = "Open the settings file in the system's text editor"
	GUI.elms.btn_refresh_txt.tooltip = "Refresh menus and settings from the settings file"
	GUI.elms.btn_load_txt.tooltip = "Load menus and settings from another file"
	GUI.elms.btn_spit_table.tooltip = "Display the current menus and settings in Reaper's console (may take a few seconds)"
	
	GUI.elms.btn_thread.tooltip = "Open the official Reaper forum thread for this script"
	GUI.elms.btn_donate.tooltip = "Open a PayPal donation link for the script's author"


end




---- Context text boxes

-- Make a whole bunch of text boxes for the context tab
local context_arr = {
	{lbl = "TCP", 			con = "tcp", 								head = 1},
	{lbl = "Track", 		con = "tcp|track", 							head = 2},
	{lbl = "Envelope", 		con = "tcp|envelope", 						head = 2},
	{lbl = "Empty", 		con = "tcp|empty", 							head = 2},
	{lbl = ""},
	{lbl = "MCP", 			con = "mcp", 								head = 1},
	{lbl = "Track",			con = "mcp|track",							head = 2},
	{lbl = "Empty",			con = "mcp|empty", 							head = 2},
	{lbl = ""},
	{lbl = "Ruler", 		con = "ruler", 								head = 1},
	{lbl = "Region lane", 	con = "ruler|region_lane", 					head = 2},
	{lbl = "Marker lane", 	con = "ruler|marker_lane", 					head = 2},
	{lbl = "Tempo lane", 	con = "ruler|tempo_lane", 					head = 2},
	{lbl = "Timeline", 		con = "ruler|timeline", 					head = 2},

	{lbl = "Arrange", 		con = "arrange", 							head = 1},
	{lbl = "Track", 		con = "arrange|track",						head = 2},
	{lbl = "Empty", 		con = "arrange|track|empty", 				head = 3},
	{lbl = "Item", 			con = "arrange|track|item",					head = 3},
	-- The API function currently won't return this context:
	--{lbl = "Stretch Marker",con = "arrange|track|item_stretch_marker", 	head = 3},
	{lbl = "Env. Point",	con = "arrange|track|env_point",			head = 3},
	{lbl = "Env. Segment",	con = "arrange|track|env_segment",			head = 3},
	{lbl = "Envelope",		con = "arrange|envelope",					head = 2},
	{lbl = "Empty", 		con = "arrange|envelope|empty",				head = 3},
	{lbl = "Env. Point",	con = "arrange|envelope|env_point",			head = 3},
	{lbl = "Env. Segment",	con = "arrange|envelope|env_segment",		head = 3},
	{lbl = "Empty", 		con = "arrange|empty", 						head = 2},

	{lbl = "Transport", 	con = "transport", 							head = 1},
	{lbl = ""},
	{lbl = "MIDI Ed.",		con = "midi_editor",						head = 1},
	{lbl = "Ruler", 		con = "midi_editor|ruler",					head = 2},
	{lbl = "Piano Roll",	con = "midi_editor|piano",					head = 2},
	{lbl = "Notes",			con = "midi_editor|notes",					head = 2},
	{lbl = "CC Lane",		con = "midi_editor|cc_lane",				head = 2},
	{lbl = "CC Selector",	con = "midi_editor|cc_lane|cc_selector",	head = 3},
	{lbl = "CC Lane",		con = "midi_editor|cc_lane|cc_lane",		head = 3},

}

--							z	x	 y				w	h	pad
local txt_con_template = {	6,	504, line_y0 + 16, 80, 20, 4}
local function update_context_elms(init)
	

	
	if init then
		
		_=dm and Msg("initializing context elements")
		
		local z, x, y, w, h, pad = table.unpack(txt_con_template)
		local x_adj, y_adj = 0, 24
		local col_adj = 0
		
		
		local function txt_update(self)
			
			_=dm and Msg("updating context "..context_arr[self.i].con)
			_=dm and Msg("\tuser entered "..self.retval)
			
			GUI.Textbox.lostfocus(self)
			
			if not self.retval or self.retval == "" then
				--self.retval = mnu_arr[-1].contexts[ context_arr[self.i].con ] or ""
				self.retval = ""
				mnu_arr[-1].contexts[ context_arr[self.i].con ] = ""
				
			elseif tonumber(self.retval) and tonumber(self.retval) > 0 then
				_=dm and Msg("\tit's a number; assigning")
				mnu_arr[-1].contexts[ context_arr[self.i].con ] = tonumber(self.retval)
			elseif check_alias(self.retval) then
				_=dm and Msg("\tit's an alias; looking it up")
				mnu_arr[-1].contexts[ context_arr[self.i].con ] = self.retval
				
				_=dm and Msg("\tgot: "..check_alias(self.retval))

			end
			
		end
		
		local function txt_dbl(self)
			
			GUI.Textbox.ondoubleclick(self)
			
			local val = tonumber(self.retval) or check_alias(self.retval)
			
			if val then
				cur_depth = val
				cur_btn = -2
				update_mnu_menu()
				update_mnu_settings()	
				update_btn_settings()
				GUI.Val("tabs", 1)
			
			else
			
				reaper.ShowMessageBox("Menu '"..tostring(self.retval).."' doesn't seem to exist.", "Whoops", 0)
			
			end
			
			self.focus = false
			self:lostfocus()
			
		end
		
		local tip_str = "What menu to open when Radial Menu is run with the context: '"
		
		local col_adj_x, col_adj_y = 196, 0
		
		for i = 1, #context_arr do
			
			local lbl = context_arr[i].lbl
			if lbl ~= "" then
				if context_arr[i].lbl == "Arrange" then 
					x_adj = col_adj_x
					col_adj_y = y_adj * -(i - 1)

				elseif context_arr[i].lbl == "Transport" then
					x_adj = col_adj_x * 2
					col_adj_y = y_adj * -(i - 1)
				end
				
				local name = "txt_context_"..i
				
				local y_adj = (i - 1) * y_adj
				local x_adj = x_adj + ((context_arr[i].head - 1) * 16)
				
				GUI.elms[name] = GUI.Textbox:new(z, x + x_adj, y + y_adj + col_adj_y, w, h, context_arr[i].lbl, pad)
				GUI.elms[name].i = i
				GUI.elms[name].font_A = 	((context_arr[i].head == 1) and 2)
										or	((context_arr[i].head == 2) and 3)
										or	((context_arr[i].head == 3) and 5)
				GUI.elms[name].font_B = 5
				GUI.elms[name].lostfocus = txt_update
				GUI.elms[name].ondoubleclick = txt_dbl
				GUI.elms[name].tooltip = tip_str..context_arr[i].con.."'"
				
			end
		end
	
	
	else

		_=dm and Msg("updating context elements")

		local arr = mnu_arr[-1].contexts
	
		-- Updating textboxes from the values in mnu_arr
		for i = 1, #context_arr do
			
			-- Skip over the entries we're using as spacers
			if context_arr[i].lbl ~= "" then
				
				local name = "txt_context_"..i
				local con = context_arr[GUI.elms[name].i].con
				local val = arr[con] or ""

				GUI.Val(name, val)
				
			end
			
		end
	
	end	

	_=dm and Msg("finished with context elements")

end






if setup then
	
	GUI.elms_hide = {[20] = true}
	GUI.elms_freeze = {[10] = true, [22] = true}
	
	GUI.elms.tabs:update_sets(
		{
		[1] = {2, 3, 4},
		[2] = {5, 6, 7},
		[4] = {8, 9, 10},
		[3] = {17, 18, 19},
		[5] = {11, 12, 13},
		[6] = {14, 15, 16},
		}
	)
	
	
	
	assign_tooltips()
	update_context_elms(true)


	GUI.elms.tabs.font_A = 6

	GUI.elms.frm_radial.state = false
	--GUI.elms.frm_radial.font = 6

	GUI.elms.lbl_swipe_menu.color = "magenta"



	GUI.elms.mnu_menu.font = 2
	GUI.elms.mnu_menu.output = function(text)
		
		return string.match(text, "^(%d+)")
		
	end


	function GUI.elms.txt_alias:ontype()
		
		GUI.Textbox.ontype(self)
		mnu_arr[cur_depth].alias = tostring(self.retval)
	
	end

	function GUI.elms.txt_alias:lostfocus()

		_=dm and Msg("updating menu "..tostring(cur_depth).."'s alias: "..tostring(self.retval))
		mnu_arr[cur_depth].alias = tostring(self.retval)
		
		update_mnu_menu()
		update_mnu_settings()

	end


	GUI.elms.sldr_ra.col_a = "red"
	GUI.elms.sldr_rb.col_a = "lime"
	GUI.elms.sldr_rc.col_a = "yellow"
	GUI.elms.sldr_rd.col_a = "cyan"
	GUI.elms.sldr_re.col_a = "magenta"

	local function rad_sldr_output(self)	
		return tostring(self.curstep + self.min) .. " px" 
	end
	GUI.elms.sldr_ra.output = rad_sldr_output
	GUI.elms.sldr_rb.output = rad_sldr_output
	GUI.elms.sldr_rc.output = rad_sldr_output
	GUI.elms.sldr_rd.output = rad_sldr_output
	GUI.elms.sldr_re.output = rad_sldr_output



	GUI.elms.sldr_accel.output = function(self)
		return self.retval.."%"
	end

	GUI.elms.sldr_decel.output = function(self)
		return self.retval.."%"
	end

	GUI.elms.sldr_stop.output = function(self)
		return (self.retval) .. " ms"
	end




	---- Method overrides ----


	-- Save settings every time the user changes the active tab
	function GUI.elms.tabs:update_sets()
		
		GUI.Tabframe.update_sets(self)
		mnu_arr[-1].last_tab = self.state
		save_menu()
		
	end



	function GUI.elms.frm_line_tt:draw()
		
		GUI.color("elm_bg")
		gfx.rect(0, 432, self.w, 32)
		GUI.Frame.draw(self)
		
	end

end







-- Draw an arc-shaped section of a ring
local function draw_ring_section(angle_c, width, r_in, r_out, ox, oy, pad, fill, color)
	
	local angle_a, angle_b = (angle_c - 0.5 + pad) * width, (angle_c + 0.5 - pad) * width
	
	local ax1, ay1 = GUI.polar2cart(angle_a, r_in, ox, oy)
	local ax2, ay2 = GUI.polar2cart(angle_a, r_out - 1, ox, oy)
	local bx1, by1 = GUI.polar2cart(angle_b, r_in, ox, oy)
	local bx2, by2 = GUI.polar2cart(angle_b, r_out - 1, ox, oy)	

	if color then GUI.color(color) end
	
	-- gfx.arc doesn't use the right reference angle,
	-- so we have to add 0.5 rads to correct it
	angle_a = (angle_a + 0.5) * pi
	angle_b = (angle_b + 0.5) * pi
	
	gfx.arc(ox, oy, r_in, angle_a, angle_b, 1)
	gfx.arc(ox, oy, r_out, angle_a, angle_b, 1)	
	
	-- gfx.arc won't completely fill the space, so we need
	-- to trick it by drawing arcs less than a pixel apart
	--
	-- 0.4 is the highest you can go before the issue is
	-- visible, from what I can tell.
	if fill then
		for j = r_in, r_out, 0.3 do
			gfx.arc(ox, oy, j, angle_a, angle_b, 1)
		end
	else
		gfx.line(ax1, ay1, ax2, ay2, 1)
		gfx.line(bx1, by1, bx2, by2, 1)
	end
end



-- Pink overlay when working on the Swipe menu
local function init_frm_swipe_menu()

	local gap = 12
	
	GUI.elms.frm_swipe_menu.gap = gap
	
	local w = frm_w - 2*gap

	gfx.dest = 101
	gfx.setimgdim(101, -1, -1)
	gfx.setimgdim(101, w, w)
	gfx.set(0, 0, 0, 1)
	
	gfx.circle(ox - gap, oy - gap, mnu_arr[-1].rd + 1.25*gap, true, 1)


	gfx.dest = 100
	gfx.setimgdim(100, -1, -1)
	gfx.setimgdim(100, w, w)
	
	GUI.color("magenta")
	
	gfx.rect(0, 0, w, w)
	
	gfx_mode = 1
	gfx.blit(101, 1, 0)
	
	gfx.muladdrect(0, 0, w, w, 1, 1, 1, 0.5)

	gfx_mode = 0
	gfx.dest = -1	
	
end


-- Draw the chosen color inside the frame
local function draw_col_frame(self)
	
	local x, y, w, h = self.x + 1, self.y + 1, self.w - 2, self.h - 2
	
	GUI.color(self.color)
	gfx.rect(x, y, w, h, true)	
	
	if self.col_user then 
		gfx.set(table.unpack(self.col_user))
		gfx.rect(x + 1, y + 1, w - 2, h - 2, true)
	end
	
	GUI.color("black")
	gfx.rect(x, y, w, h, false)
	
end	


-- Pop up the OS color picker and assign the result to this frame
local function get_color_picker(self)
	
	local retval, colorOut = reaper.GR_SelectColor()
	
	if retval ~= 0 then
		local r, g, b = GUI.num2rgb(colorOut)
		self.col_user = {r / 255, g / 255, b / 255}
		GUI.redraw_z[self.z] = true
		redraw_menu = true
		
	end
end


local function update_rad_sldrs(sldr)
	
	local ra, rb, rc, rd, re = mnu_arr[-1].ra, mnu_arr[-1].rb, mnu_arr[-1].rc, mnu_arr[-1].rd, mnu_arr[-1].re
	
	local gap = 4
	
	if sldr == "a" then
		
		_=dm and Msg("adjusting with sldr A as master")
		
		ra = GUI.Val("sldr_ra") + GUI.elms.sldr_ra.min
		
		if rb - ra < gap then
			rb = ra + gap
		end
		
		if rc - rb < gap then
			rc = rb + gap
		end
		
		if rd - rc < gap then
			rd = rc + gap
		end
		
	elseif sldr == "b" then
	
		_=dm and Msg("adjusting with sldr B as master")

		rb = GUI.Val("sldr_rb") + GUI.elms.sldr_rb.min
		
		if rb - ra < gap then
			ra = rb - gap
			
		else
			if rc - rb < gap then
				rc = rb + gap
			end
			
			if rd - rc < gap then
				rd = rc + gap
			end
		end

	elseif sldr == "c" then
	
		_=dm and Msg("adjusting with sldr C as master")
	
		rc = GUI.Val("sldr_rc") + GUI.elms.sldr_rc.min
		if rc - rb < gap then
			
			rb = rc - gap

			if rb - ra < gap then
				ra = rb - gap
			end

		else
		
			if rd - rc < gap then
				rd = rc + gap
			end
		end
	
	elseif sldr == "d" then
	
		_=dm and Msg("adjusting with sldr D as master")
	
		rd = GUI.Val("sldr_rd") + GUI.elms.sldr_rd.min
		if rd - rc < gap then
			rc = rd - gap
		end
		
		if rc - rb < gap then
			rb = rc - gap
		end
		
		if rb - ra < gap then
			ra = rb - gap
		end	

	end
	
	GUI.Val("sldr_ra", ra - GUI.elms.sldr_ra.min)
	GUI.Val("sldr_rb", rb - GUI.elms.sldr_rb.min)
	GUI.Val("sldr_rc", rc - GUI.elms.sldr_rc.min)
	GUI.Val("sldr_rd", rd - GUI.elms.sldr_rd.min)
	GUI.Val("sldr_re", re - GUI.elms.sldr_re.min)
	
	mnu_arr[-1].ra, mnu_arr[-1].rb, mnu_arr[-1].rc, mnu_arr[-1].rd = ra, rb, rc, rd
	
	redraw_menu = true
		
end






-- All of menu drawing happens here
function GUI.elms.frm_radial:draw_base_menu()
	
	_=dm and Msg(">draw_base_menu")
	
	local ra, rb, rc, rd = mnu_arr[-1].ra, mnu_arr[-1].rb, mnu_arr[-1].rc, mnu_arr[-1].rd
	
	-- In case I ever restore the menu rotation
	local k = 0

	local color

	-- Update the button width while we're here
	mnu_adj = 2 / (#mnu_arr[cur_depth] + 1)	

	gfx.dest = 50
	gfx.setimgdim(50, -1, -1)
	gfx.setimgdim(50, frm_w, frm_w)
	
	_=dm and Msg("\tfrm_w = "..tostring(frm_w))
	
	_=dm and Msg("\tdrawing background")
	
	GUI.color( get_color("col_bg", -2) )
	gfx.rect(self.x, self.y, self.w, self.h, true)	
	
	for i = -1, #mnu_arr[cur_depth] do
		
		_=dm and Msg("\tdrawing button "..tostring(i))
		
		color = get_color("col_main", i)
		_=dm and Msg("\t\t"..table.unpack(color))
		
		if i ~= -1 then
			draw_ring_section(i + k, mnu_adj, rc, rd, ox, oy, 0, true, color)
		elseif mnu_arr[cur_depth][-1] then
			GUI.color(color)
			gfx.circle(ox, oy, ra - 4, true, 1)
		end

	end	
	
	gfx.dest = -1
	
	_=dm and Msg("<draw_base_menu")
	
end

function GUI.elms.frm_radial:draw()
	
	local ra, rb, rc, rd = mnu_arr[-1].ra, mnu_arr[-1].rb, mnu_arr[-1].rc, mnu_arr[-1].rd
	local colors = {}


	_=dm and Msg("drawing menu")

	gfx.x, gfx.y = 0, 0
	gfx.blit(50, 1, 0)

	-- For rotating the menu, i.e. putting button 0 under the mouse when the menu opens
	-- Currently broken, so we're not using it.
	local k = 0
	
	local redraw

	-- Draw the menu options
		_=dm and Msg("drawing... "..tostring(mouse_mnu).."  "..tostring(#mnu_arr[cur_depth + 1]))	
	for i = -1, #mnu_arr[cur_depth] do

		_=dm and Msg("i = "..tostring(i))

		local i = (mouse_mnu and i >= 0) 
				and (i + mouse_mnu + 1) % (#mnu_arr[cur_depth] + 1) 
				or i

		_=dm and Msg("new i = "..tostring(i))

		if mnu_arr[cur_depth][i] then
			_=dm and Msg("\tdrawing button "..tostring(i))

			local opt = mnu_arr[cur_depth][i]
			
			local color = "col_main"
			local r_adj = 0
			
			if i == mouse_mnu then
			-- For rotating the menu
			--if (((i + k) % (#mnu_arr[cur_depth] + 1)) == self.mouse_mnu) then

				r_adj = 4
				color = self.state and "col_bg" or "col_hvr"
				
			end
			
			if string.sub(opt.act, 1, 4) ~= "menu" and opt.act ~= "" then

				local act = opt.act
				if string.sub(act, 1, 1) == "_" then
					act = reaper.NamedCommandLookup(act)
				end
				act = tonumber(act)

				local state = ((act and act > 0) and reaper.GetToggleCommandState(act)) or nil
				
				-- Use a blend of hover/bg and the toggle color, when necessary
				if state == 1 then
					
					color = ((color == "col_hvr") and "hvr_tog")
						or	((color == "col_bg") and "bg_tog")
						or	"col_tog"
						
				end

			end 
			
			redraw = color ~= "col_main"
			
			color = get_color(color, i)


			-- We only need to redraw if the button isn't using its base color
			_=dm and Msg("seeing if we need to draw...")
			if redraw then

				if i ~= -1 then
					draw_ring_section(i + k, mnu_adj, rc - r_adj, rd + r_adj, ox, oy, 0, true, color)
				else
					GUI.color(color)
					gfx.circle(ox, oy, ra - 4 + r_adj, true, 1)
				end
				
			end
			
			
			-- Draw an extra segment on the outside of the current button
			if i == cur_btn then
				if i ~= -1 then
					draw_ring_section(i + k, mnu_adj, rd + 6, rd + 14, ox, oy, 0, true, get_color("col_hvr", -2))
				else
					GUI.color(get_color("col_hvr", -1))
					for j = 0, 8, 0.4 do
						gfx.circle(ox, oy, ra + j, false, 1)
					end
				end			
			end			
			
			
			
			
			--GUI.font(self.font)
			colors[i] = colorsmart(color)

		end
	end
	


	-- If we're hovering over a button assigned to a menu, grab its children
	-- Getting this now because some of the main labels may need to be adjusted
	local mnu_children
	if 		mnu_arr[-1].preview
		and	mnu_arr[cur_depth][mouse_mnu] 
		and mnu_arr[cur_depth][mouse_mnu].act 
		then
		
		local act = mnu_arr[cur_depth][mouse_mnu].act
		if string.sub(act, 1, 4) == "menu" then
			act = string.sub(act, 6)
			mnu_children = tonumber(act) or check_alias(act)

		end
	end




	
	-- Draw all of the labels
	
	_=dm and Msg("\tdrawing labels")
	GUI.font(7)
	
	local str, str_w, str_h, cx, cy, w, h, j
	for i = -1, #mnu_arr[cur_depth] do
		
		if mnu_arr[cur_depth][i] then
			str = string.gsub(mnu_arr[cur_depth][i].lbl, "|", "\n")
			str_w, str_h = gfx.measurestr(str)
			
			cx, cy = table.unpack((i ~= -1) 
						and	{GUI.polar2cart((i + k) * mnu_adj, rc + (rd - rc) / 2, ox, oy)}
						or	{ox, oy}
						)
			GUI.color(colors[i] or "black")
			
			j = 0
			for s in string.gmatch(str.."\n", "([^\r\n]*)[\r\n]") do
				
				w, h = gfx.measurestr(s)
				gfx.x = cx - w / 2
				gfx.y = cy - str_h / 2 + j * h
				gfx.drawstr(s)
				j = j + 1
			end		
		end
	end
	


	-- Draw the preview labels, if necessary
	
	_=dm and Msg("\tmnu_children = "..tostring(mnu_children))	

	if mnu_children and mnu_arr[mnu_children] then
		
		local adj = 2 / (#mnu_arr[mnu_children] + 1)
		local r = ra + (rc - ra) / 2
		
		GUI.font(8)
		--GUI.color(colorsmart(get_color(	(mnu_arr[mnu_children][-1] and "col_main" or "col_bg"), -2)))
		GUI.color(colorsmart(get_color(	(mnu_arr[cur_depth][-1] and "col_main" or "col_bg"), -2)))
		
		local str, str_w, str_h, cx, cy, j, w, h
		
		for i = -1, #mnu_arr[mnu_children] do
			
			if i == 0 then GUI.color(colorsmart(get_color("col_bg", -2))) end
			
			if mnu_arr[mnu_children][i] then
				str = string.gsub(mnu_arr[mnu_children][i].lbl, "|", "\n")
				str_w, str_h = gfx.measurestr(str)
				
				cx, cy = table.unpack((i ~= -1) 
							and	{GUI.polar2cart((i + k) * adj, r, ox, oy)}
							or	{ox, oy + (mnu_arr[cur_depth][-1] and gfx.texth or 0)}
							)
				j = 0
				for s in string.gmatch(str.."\n", "([^\r\n]*)[\r\n]") do
				
					w, h = gfx.measurestr(s)
					gfx.x = cx - w / 2
					gfx.y = cy - str_h / 2 + j * h
					gfx.drawstr(s)
					j = j + 1
				end	
			end
		end
	end

	--[[
		Disabled for now, wasn't working right for last_depths past 8
		
		-- Draw the guide button from the previous menu
	if cur_depth > 0 then
		
		--local k = math.max(last_depth - 1, 0)
		
		--Msg(#mnu_arr[last_depth])
		local adj = 2 / (#mnu_arr[last_depth] + 1)
		
		draw_ring_section(cur_depth - 1, adj, ra, rb, ox, oy, 0, true, get_color("col_main", -2))

	end
	]]--

	_=dm and Msg("finished drawing menu")

end


function GUI.elms.frm_radial:onmouseover() 
	
	check_mouse()
	
	
end


function GUI.elms.frm_radial:onmousedown()
	self.state = true
	GUI.redraw_z[self.z] = true
end


function GUI.elms.frm_radial:onmouseup()
		
	local mnu = mouse_mnu
	
	_=dm and Msg("clicked button "..tostring(mnu))
	
	-- Didn't click a button; reset to the base menu
	if mnu == -2 and cur_depth ~= 0 then
	
		_=dm and Msg("\tresetting to base depth")
		cur_depth = base_depth
		last_depth = base_depth
		
		cur_btn = -2
	
	elseif mnu_arr[cur_depth][mnu] then
		
		
		run_act( mnu_arr[cur_depth][mnu].act )
		
		
	end

	hvr_time = nil

	-- If we're running without a key being held down, reset the Quit timer
	if up_time then 
		_=dm and Msg("\tresetting up_time")
		up_time = reaper.time_precise() 
	end

	--GUI.Val("mnu_menu", cur_depth + 1)

	if setup then
		
		update_btn_settings()
		update_mnu_settings()
		update_mnu_menu()

	end

	opt_clicked = true
	self.state = false
	GUI.redraw_z[self.z] = true
	
	
end


-- Avert a bug where 'state' somehow ends up backward and
-- menus are being hovered with the bg color
function GUI.elms.frm_radial:ondoubleclick()
	self.state = false
end


---------------------------------------------------------
---***-- Right-click methods for the menu frame ---***---
---------------------------------------------------------

function GUI.elms.frm_radial:onmouser_down()
	-- Processed when the right button is first pressed down
end

function GUI.elms.frm_radial:onmouser_drag()
	-- Only processed if the right button is down AND the mouse has moved.
	
	-- This method should keep being called even if the mouse leaves the
	-- window; I haven't tried it though.
end

-- Selecting a button to work on
function GUI.elms.frm_radial:onmouser_up()

	if setup then
		
		
		
		cur_btn = (mouse_mnu ~= -2) and mouse_mnu or -2
		update_btn_settings()
		GUI.redraw_z[self.z] = true		
	end
	
end





---- Setup methods ----

if setup then
		

	function GUI.elms.frm_swipe_menu:draw()
		
		gfx.x, gfx.y = self.gap, self.gap
		gfx.mode = 1
		gfx.blit(100, 1, 0)
		
		gfx.mode = 0
		
	end



	-- Changing the current menu
	function GUI.elms.mnu_menu:val(newval)
		
		local retval = GUI.Menubox.val(self, newval)
		if newval then 
			
			cur_btn = -2
			update_mnu_settings()
			update_btn_settings()
		else
			return retval 
		end

	end
	function GUI.elms.mnu_menu:onmouseup()
		
		GUI.Menubox.onmouseup(self)

		cur_depth = tonumber(string.match(self.optarray[GUI.Val("mnu_menu")], "^(%d+)"))

		cur_btn = -2
		update_mnu_settings()	
		update_btn_settings()

		
	end
	function GUI.elms.mnu_menu:onwheel()
		
		GUI.Menubox.onwheel(self)
		cur_depth = tonumber(string.match(self.optarray[GUI.Val("mnu_menu")], "^(%d+)"))
		cur_btn = -2
		update_mnu_settings()
		update_btn_settings()
		
	end
	


	-- Color pickers --

	function GUI.elms.frm_col_m_btn:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)

	end
	function GUI.elms.frm_col_m_hvr:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)
		
	end
	function GUI.elms.frm_col_m_tog:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)
		
	end
	function GUI.elms.frm_col_m_bg:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)
		
	end
	function GUI.elms.frm_col_b_btn:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)
		
	end
	function GUI.elms.frm_col_b_hvr:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)
		
	end
	function GUI.elms.frm_col_b_tog:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)
		
	end
	function GUI.elms.frm_col_g_btn:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)

	end
	function GUI.elms.frm_col_g_hvr:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)
		
	end
	function GUI.elms.frm_col_g_tog:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)
		
	end
	function GUI.elms.frm_col_g_bg:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)
		
	end



	-- Global colors
	function GUI.elms.frm_col_g_btn:onmouseup() 
		
		get_color_picker(self) 
		mnu_arr[-1].col_main = self.col_user

	end
	function GUI.elms.frm_col_g_hvr:onmouseup() 

		get_color_picker(self) 
		mnu_arr[-1].col_hvr = self.col_user
		
	end
	function GUI.elms.frm_col_g_tog:onmouseup() 
		
		get_color_picker(self) 
		mnu_arr[-1].col_tog = self.col_user
		
	end
	function GUI.elms.frm_col_g_bg:onmouseup() 
		
		get_color_picker(self)
		mnu_arr[-1].col_bg = self.col_user

	end
	

	-- Menu colors
	function GUI.elms.frm_col_m_btn:onmouseup() 
		
		get_color_picker(self) 
		mnu_arr[cur_depth].col_main = self.col_user
		
	end
	function GUI.elms.frm_col_m_hvr:onmouseup() 
		
		get_color_picker(self) 
		mnu_arr[cur_depth].col_hvr = self.col_user
		
	end
	function GUI.elms.frm_col_m_tog:onmouseup() 
		
		get_color_picker(self) 
		mnu_arr[cur_depth].col_tog = self.col_user

	end
	function GUI.elms.frm_col_m_bg:onmouseup() 
		
		get_color_picker(self) 
		mnu_arr[cur_depth].col_bg = self.col_user

	end
	

	-- Button colors
	function GUI.elms.frm_col_b_btn:onmouseup()	
		
		get_color_picker(self) 
		mnu_arr[cur_depth][cur_btn].col_main = self.col_user
		
	end
	function GUI.elms.frm_col_b_hvr:onmouseup() 
		
		get_color_picker(self) 
		mnu_arr[cur_depth][cur_btn].col_hvr = self.col_user

	end
	function GUI.elms.frm_col_b_tog:onmouseup() 
		
		get_color_picker(self) 
		mnu_arr[cur_depth][cur_btn].col_tog = self.col_user

	end




	-- Global "Number of buttons" slider
	function GUI.elms.sldr_num_btns:onmousedown()
		
		GUI.Slider.onmousedown(self)
		mnu_arr[-1].num_btns = self.curstep + self.min
		
	end
	function GUI.elms.sldr_num_btns:ondrag()
		
		GUI.Slider.ondrag(self)
		mnu_arr[-1].num_btns = self.curstep + self.min
		
	end
	function GUI.elms.sldr_num_btns:onwheel()
		
		GUI.Slider.onwheel(self)
		mnu_arr[-1].num_btns = self.curstep + self.min
		
	end



	function GUI.elms.chk_swipe:onmouseup()
		
		GUI.Checklist.onmouseup(self)
		mnu_arr[-1].swipe.enabled = self.optsel[1]
		GUI.elms.frm_no_swipe.z = self.optsel[1] and 20 or 17
		
		update_mnu_settings()
		
	end

	-- Swipe sliders
	function GUI.elms.sldr_accel:onmousedown()
		
		GUI.Slider.onmousedown(self)
		mnu_arr[-1].swipe.accel = self.retval
		
	end
	function GUI.elms.sldr_decel:onmousedown()
		
		GUI.Slider.onmousedown(self)
		mnu_arr[-1].swipe.decel = self.retval

	end
	function GUI.elms.sldr_stop:onmousedown()
		
		GUI.Slider.onmousedown(self)
		mnu_arr[-1].swipe.stop = self.retval
		
	end
	function GUI.elms.sldr_accel:ondrag()
		
		GUI.Slider.ondrag(self)
		mnu_arr[-1].swipe.accel = self.retval
		
	end
	function GUI.elms.sldr_decel:ondrag()
		
		GUI.Slider.ondrag(self)
		mnu_arr[-1].swipe.decel = self.retval

	end
	function GUI.elms.sldr_stop:ondrag()
		
		GUI.Slider.ondrag(self)
		mnu_arr[-1].swipe.stop = self.retval

	end
	function GUI.elms.sldr_accel:onwheel()
		
		GUI.Slider.onwheel(self)
		mnu_arr[-1].swipe.accel = self.retval
		
	end
	function GUI.elms.sldr_decel:onwheel()
		
		GUI.Slider.onwheel(self)
		mnu_arr[-1].swipe.decel = self.retval

	end
	function GUI.elms.sldr_stop:onwheel()
		
		GUI.Slider.onwheel(self)
		mnu_arr[-1].swipe.stop = self.retval

	end
	function GUI.elms.sldr_accel:ondoubleclick()
		
		GUI.Slider.ondoubleclick(self)
		mnu_arr[-1].swipe.accel = self.retval
		
	end
	function GUI.elms.sldr_decel:ondoubleclick()
		
		GUI.Slider.ondoubleclick(self)
		mnu_arr[-1].swipe.decel = self.retval

	end
	function GUI.elms.sldr_stop:ondoubleclick()
		
		GUI.Slider.ondoubleclick(self)
		mnu_arr[-1].swipe.stop = self.retval
		
	end


	-- Swipe modes
	function GUI.elms.opt_swipe_mode:onmouseup()
		
		GUI.Radio.onmouseup(self)
		mnu_arr[-1].swipe.mode = self.retval
		update_mnu_settings()
		
	end

	function GUI.elms.opt_swipe_mode:onwheel()
		
		GUI.Radio.onmouseup(self)
		mnu_arr[-1].swipe.mode = self.retval	
		update_mnu_settings()
		
	end
	
	
	function GUI.elms.txt_swipe_menu:lostfocus()

		GUI.Textbox.lostfocus(self)
		
		_=dm and Msg("updating swipe menu")
		_=dm and Msg("\tuser entered "..self.retval)
		
		if not self.retval or self.retval == "" then
			self.retval = ""
			mnu_arr[-1].swipe.menu = ""
		
		elseif (tonumber(self.retval) and tonumber(self.retval) > 0) then
			_=dm and Msg("\tit's a number; assigning")
			mnu_arr[-1].swipe.menu = tonumber(self.retval)
		elseif check_alias(self.retval) then
			_=dm and Msg("\tit's an alias; looking it up")
			mnu_arr[-1].swipe.menu = self.retval
			
			_=dm and Msg("\tgot: "..check_alias(self.retval))
		else
			self.retval = mnu_arr[-1].swipe.menu or ""
		end	
		
		update_mnu_settings()
		
	end

	function GUI.elms.txt_swipe_menu:ondoubleclick()
		
		GUI.Textbox.ondoubleclick(self)
		
		local val = tonumber(self.retval) or check_alias(self.retval)
		
		if val then
			cur_depth = val
			cur_btn = -2
			update_mnu_menu()
			update_mnu_settings()	
			update_btn_settings()
			GUI.Val("tabs", 1)
			
		else
		
			reaper.ShowMessageBox("Menu '"..tostring(self.retval).."' doesn't seem to exist.", "Whoops", 0)
			
		end
		
		self.focus = false
		self:lostfocus()	
		
	end


	function GUI.elms.chk_swipe_acts:onmouseup()
		
		GUI.Checklist.onmouseup(self)
		mnu_arr[-1].swipe.actions = self.optsel[1]
		
	end



	-- Radius overlay and sliders
	function GUI.elms.frm_rad_overlay:draw()
		
		GUI.Frame.draw(self)
		
		local ra, rb, rc, rd, re = mnu_arr[-1].ra, mnu_arr[-1].rb, mnu_arr[-1].rc, mnu_arr[-1].rd, mnu_arr[-1].re
		local swipe = GUI.elms.tabs.state == 3
		
		
		if not swipe then
			for i = -1.5, 1.5, 0.4 do
				GUI.color("red")
				gfx.circle(ox, oy, ra + i, false, 1)
				GUI.color("lime")
				--gfx.circle(ox, oy, rb + i, false, 1)
				GUI.color("yellow")
				gfx.circle(ox, oy, rc + i, false, 1)
				GUI.color("cyan")
				gfx.circle(ox, oy, rd + i, false, 1)
			end
		else
			for i = -1.5, 1.5, 0.4 do
				GUI.color("magenta")
				local adj = 0.1
				local angle
				for j = 0, 19 do
				
					angle = j * adj * pi
					gfx.arc(ox, oy, re + i, angle - 0.07, angle + 0.07)
					
				end
			end
		end
	end


	function GUI.elms.sldr_ra:onmousedown()
		GUI.Slider.onmousedown(self)
		update_rad_sldrs("a")	
	end
	function GUI.elms.sldr_rb:onmousedown()
		GUI.Slider.onmousedown(self)
		update_rad_sldrs("b")	
	end
	function GUI.elms.sldr_rc:onmousedown()
		GUI.Slider.onmousedown(self)
		update_rad_sldrs("c")	
	end
	function GUI.elms.sldr_rd:onmousedown()
		GUI.Slider.onmousedown(self)
		update_rad_sldrs("d")	
	end
	function GUI.elms.sldr_re:onmousedown()
		GUI.Slider.onmousedown(self)
		mnu_arr[-1].re = self.curstep + self.min	
	end
	function GUI.elms.sldr_ra:ondrag()
		GUI.Slider.ondrag(self)
		update_rad_sldrs("a")	
	end
	function GUI.elms.sldr_rb:ondrag()
		GUI.Slider.ondrag(self)
		update_rad_sldrs("b")	
	end
	function GUI.elms.sldr_rc:ondrag()
		GUI.Slider.ondrag(self)
		update_rad_sldrs("c")	
	end
	function GUI.elms.sldr_rd:ondrag()
		GUI.Slider.ondrag(self)
		update_rad_sldrs("d")	
	end
	function GUI.elms.sldr_re:ondrag()
		GUI.Slider.ondrag(self)
		mnu_arr[-1].re = self.curstep + self.min
	end
	function GUI.elms.sldr_ra:onwheel()
		GUI.Slider.onwheel(self)
		update_rad_sldrs("a")	
	end
	function GUI.elms.sldr_rb:onwheel()
		GUI.Slider.onwheel(self)
		update_rad_sldrs("b")	
	end
	function GUI.elms.sldr_rc:onwheel()
		GUI.Slider.onwheel(self)
		update_rad_sldrs("c")	
	end
	function GUI.elms.sldr_rd:onwheel()
		GUI.Slider.onwheel(self)
		update_rad_sldrs("d")	
	end
	function GUI.elms.sldr_re:onwheel()
		GUI.Slider.onwheel(self)
		mnu_arr[-1].re = self.curstep + self.min
	end
	function GUI.elms.sldr_ra:ondoubleclick()
		GUI.Slider.ondoubleclick(self)
		update_rad_sldrs("a")	
	end
	function GUI.elms.sldr_rb:ondoubleclick()
		GUI.Slider.ondoubleclick(self)
		update_rad_sldrs("b")	
	end
	function GUI.elms.sldr_rc:ondoubleclick()
		GUI.Slider.ondoubleclick(self)
		update_rad_sldrs("c")	
	end
	function GUI.elms.sldr_rd:ondoubleclick()
		GUI.Slider.ondoubleclick(self)
		update_rad_sldrs("d")	
	end
	function GUI.elms.sldr_re:ondoubleclick()
		GUI.Slider.ondoubleclick(self)
		mnu_arr[-1].re = self.curstep + self.min
	end





	-- Update the current button's label/action
	function GUI.elms.txt_btn_lbl:ontype()
		
		GUI.Textbox.ontype(self)
		mnu_arr[cur_depth][cur_btn].lbl = self.retval
		
	end
	function GUI.elms.txt_btn_act:ontype()
		
		GUI.Textbox.ontype(self)
		mnu_arr[cur_depth][cur_btn].act = self.retval
		
	end



	function GUI.elms.chk_center:onmouseup()
		
		GUI.Checklist.onmouseup(self)
		if self.optsel[1] then
			init_btn(cur_depth, -1, "center")
		else
			if cur_btn == -1 then cur_btn = -2 end
			mnu_arr[cur_depth][-1] = nil
		end
		
		update_btn_settings()
		GUI.redraw_z[0] = true
		
	end



	function GUI.elms.chk_preview:onmouseup()
		
		GUI.Checklist.onmouseup(self)
		mnu_arr[-1].preview = self.optsel[1]
		
	end



	function GUI.elms.opt_key_mode:onmouseup()
		
		GUI.Radio.onmouseup(self)
		mnu_arr[-1].key_mode = self.retval
		
	end
	function GUI.elms.opt_key_mode:onwheel()
		
		GUI.Radio.onwheel(self)
		mnu_arr[-1].key_mode = self.retval
		
	end



	function GUI.elms.chk_misc_opts:onmouseup()
		
		GUI.Checklist.onmouseup(self)
		mnu_arr[-1].mnu_0_on_act, mnu_arr[-1].hvr_click = table.unpack(GUI.Val("chk_misc_opts"))
		--GUI.Val("chk_misc_opts", {mnu_arr[-1].misc_opts[1], mnu_arr[-1].misc_opts[2]})
		--GUI.Val("txt_hvr_time", mnu_arr[-1].misc_opts[3])
		
	end

	function GUI.elms.txt_hvr_time:lostfocus()
		
		GUI.Textbox.lostfocus(self)
		local val = tonumber(self.retval)
		if val and val > 0 then

			mnu_arr[-1].hvr_time = val
		else
			self.retval = mnu_arr[-1].hvr_time
		end
		
	end

	function GUI.elms.txt_close_time:lostfocus()
		
		GUI.Textbox.lostfocus(self)
		local val = tonumber(self.retval)
			
		if val and val > 0 then

			-- Make sure we aren't going below the minimum for key detection
			val = math.max(val, 600)
			mnu_arr[-1].close_time = val
			self.retval = val
		else
			self.retval = mnu_arr[-1].close_time
		end
		
	end



	function GUI.elms.mnu_help:onwheel()
		
		GUI.Menubox.onwheel(self)
		GUI.Val("frm_help", help_pages[math.floor(self.retval)][2])
		
	end
	function GUI.elms.frm_help:onwheel() GUI.elms.mnu_help:onwheel() end
	function GUI.elms.mnu_help:onmouseup()
		
		GUI.Menubox.onmouseup(self)
		GUI.Val("frm_help", help_pages[math.floor(self.retval)][2])
		
	end
	function GUI.elms.frm_help:onmouseup() GUI.elms.mnu_help:onmouseup() end






end









local function Main()
	
	_=dm and Msg(">main loop")

	-- Prevent the user from resizing the window
	if GUI.resized then
		local __,x,y,w,h = gfx.dock(-1,0,0,0,0)
		gfx.quit()
		gfx.init(GUI.name, GUI.w, GUI.h, 0, x, y)
		GUI.redraw_z[0] = true
	end	
	
	-- Do we need to redraw the buffered copy of the menu?
	if redraw_menu then
		GUI.elms.frm_radial:draw_base_menu()
		redraw_menu = false
	end	
	
	
	
	-- Radial Menu script loop
	if not setup then
			
		-- Main logic for the shortcut key
		check_key()
		
		-- Update the mouse position/angle/option/tc
		check_mouse()


	
	

		local diff = up_time and (reaper.time_precise() - up_time) or 0

		--[[	See if any of our numerous conditions for running the script are valid

		- Setup mode?
		- Shortcut key down?
		- Startup mode and the timer hasn't run out?
		- Running in "just leave the window open" mode?

		]]--	  

		if (setup or key_down ~= 0 or swipe_retrigger > 0 or (startup and diff < (mnu_arr[-1].close_time * 0.001)) or mnu_arr[-1].key_mode == 3) then
			-- _=dm and Msg("\tnot quitting")
			-- Do nothing, keep the window open
			if swipe_retrigger > 0 then swipe_retrigger = swipe_retrigger - 1 end
			
		elseif mnu_arr[-1].key_mode == 2 then
			_=dm and Msg("\trunning action and quitting")
			
			-- Perform the highlighted action and close the window
			if mouse_mnu > -2 and not (opt_clicked and mnu_arr[-1].hvr_click) then 
				run_act(mnu_arr[cur_depth][mouse_mnu].act) 
			end
			GUI.quit = true
		else
			_=dm and Msg("\tquitting")
			

			GUI.quit = true
		end

	
	
	-- Setup script loop
	else
		
		
		update_tooltip(GUI.forcetooltip)
		
		
		-- See if the user asked to display a context
		if GUI.elms.tabs.state == 2 and GUI.char == GUI.chars.F1 then get_context() end

		
		-- See if we need to draw the radius overlay
		if  (	GUI.elms.tabs.state == 4 and 	(	GUI.IsInside(GUI.elms.frm_r2) 
												or 
												   (GUI.mouse.ox and GUI.IsInside(GUI.elms.frm_r2, GUI.mouse.ox, GUI.mouse.oy)) 
												)
			)
		or	(	GUI.elms.tabs.state == 3 and
				mnu_arr[-1].swipe.enabled and	(	GUI.IsInside(GUI.elms.frm_r1)
												or 
													(GUI.mouse.ox and GUI.IsInside(GUI.elms.frm_r1, GUI.mouse.ox, GUI.mouse.oy)) 
												or
													swiping
												)						
			)
		then
						
			local z = GUI.elms.frm_line_x.z
			
			if GUI.elms.frm_rad_overlay.z == 20 then
				GUI.elms.frm_rad_overlay.z = z
				GUI.redraw_z[z] = true
			end

		elseif GUI.elms.frm_rad_overlay.z ~= 20 then
		
			GUI.elms.frm_rad_overlay.z = 20
			GUI.redraw_z[20] = true

		end
	
	
	end
	
	_=dm and Msg("<main loop")
	
	
	
end


-- Make sure we've got a menu file to work with
if load_menu() == 0 then return 0 end

-- Setup: Things that need to use menus and settings
if setup then
	
	update_mnu_menu()
	update_glbl_settings()
	update_mnu_settings()
	update_btn_settings()
	update_context_elms()
	update_rad_sldrs()

	reaper.atexit(save_menu)	

else

	-- This needs to happen prior to the window being opened; it takes over the cursor
	get_context_mnu()

end

	
if not mnu_arr[cur_depth] then init_menu(cur_depth) end

frm_w = not setup and (2 * mnu_arr[-1].rd) + 16 or 432
ox, oy = frm_w / 2, frm_w / 2


if not setup then
	
	GUI.name = "Radial Menu"
	GUI.x, GUI.y, GUI.w, GUI.h = -8, -32, frm_w, frm_w + 12
	GUI.anchor, GUI.corner = "mouse", "C"
	
	if GUI.elms.lbl_context then
		GUI.h = GUI.h + 16
		GUI.elms.lbl_context.y = GUI.elms.lbl_context.y + GUI.h	
	end
	
	GUI.elms.frm_radial.w, GUI.elms.frm_radial.h = GUI.w, GUI.h
	
	
else

	GUI.name = "Radial Menu Setup"
	GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 1024, 464
	GUI.anchor, GUI.corner = "screen", "C"
	

end



_=dm and Msg("Opening GUI window")

GUI.Init()


-- Init things that need the window open
if setup then
		
	-- Format the Help tab's text so it fits
	-- Needs the window open so it can use gfx functions
	GUI.init_txt_width()
	init_help_pages()
	GUI.Val("frm_help", help_pages[1][2])

	init_frm_swipe_menu()

end

_=dm and Msg("Starting main GUI loop")

GUI.func = Main
GUI.freq = 0

GUI.Main()