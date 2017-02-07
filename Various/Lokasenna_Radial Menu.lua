--[[
Description: Radial Menu
Version: 1.94
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	Bug fix: Crashing when using SWS actions
Links:
	Forum Thread http://forum.cockos.com/showthread.php?p=1788321
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
	Provides a circular "quick menu" for commonly-used actions, similar
	to how weapons are selected in many FPS games.
	
	Instructions:
	
		- Bind the script to a key
		- Hold the key down, a window will open
		- Use the mouse to choose menu options and click on actions
		- Let the key go when you're done, and the window will close
		
		- Right-click the window to enter Setup mode
			- You can release the keyboard key; the window will stay open
	
	Setup mode:
		- Click and hold the left mouse button on a menu option to edit it
		- Buttons can be relabelled and assigned any Action ID you want
		- Alternatively, set the action to e.g. 'menu 12' to create a new submenu
			-1 	- reserved for script settings. Don't use it.
			0	- the one you see when the script starts
			1-8	- the eight default submenus
		- You should be able to make as many submenus as you want.
		
		- Press F1 to access color settings; all are RGBA, 0-255
		
	See the forum thread for further documentation, reporting bugs, etc.	
	
Extensions:
--]]

-- Licensed under the GNU GPL v3


local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]

local function Msg(str)
	reaper.ShowConsoleMsg(str.."\n")
end


local name, w, h = "Radial Menu", 260, 260
local x, y = reaper.GetMousePosition()
x, y = x - (w / 2) - 8, y - (h / 2) - 30

-- Global button dimensions
local ra, rb, rc, rd = 50, 60, 64, (w - 2) / 2
local ox, oy = w / 2, h / 2

-- We don't need a ton of precision
local pi = 3.1415927

local col_main = {192, 192, 192, 255}
local col_hover = {224, 224, 224, 255}
local col_tog_on = {0, 192, 0, 255}
local col_bg = {51, 51, 51, 255}


-- Make the trig functions local because we're going to be using them a LOT
local sin, cos, tan, asin, acos, atan, sqrt = math.sin, math.cos, math.tan, math.asin, math.acos, math.atan, math.sqrt


-- Take 0-1 RGB values and return the combined integer
-- (equal to 8-bit hex colors of the form 0xRRGGBB)
local function rgb2num(red, green, blue)

	green = green * 256
	blue = blue * 256 * 256

	return red + green + blue

end

local function setcolor(col)
	
	local r, g, b, a = table.unpack(col)
	r, g, b, a = r / 256, g / 256, b / 256, a / 256
	
	gfx.set(r, g, b, a)
	
end


--[[

- All menu entries have two subvalues - .lbl and .act
- Setting 'act' to 'menu 9' will cause that button to open the menu at mnu_arr[9]
- Moving to a depth that doesn't exist yet will auto-init eight buttons for it
- Setting an elm's label to blank will hide that button

]]--


-- Create a blank submenu, eight buttons
local function init_menu(i, lbl)
	
	mnu_arr[i] = {}
	
	if not lbl then lbl = "menu "..i end
	
	for j = 0, 7 do

		mnu_arr[i][j] = { lbl = lbl.." "..j, act = "" }
	
	end
end


-- Parse the script's text file and use it to fill our array
local function load_menu()
	
	local load_arr = {}
	
	local file_name = script_path.."Lokasenna_Radial Menu.txt"
	
	local file = io.open(file_name, r) or nil
	
	if file then
		
		for line in file:lines() do
			
			local i, j, lbl, act = string.match(line, "(%-?%d+)%s+(%-?%d+)%s+'(.*)'%s+'(.*)'")
			if i and j and lbl then
				i, j = tonumber(i), tonumber(j)
				if not load_arr[i] then 
					load_arr[i] = {} 
				end
				
				load_arr[i][j] = {["lbl"] = lbl, ["act"] = act}
				
			end
			
		end

	io.close()
	end
	

	--Msg(#load_arr)
	if #load_arr > 0 then 
		mnu_arr = load_arr 
		
		-- Extra settings are stored in -1
		if mnu_arr[-1] then
			--col_main = mnu_arr[-1][0].act
			--col_hover = mnu_arr[-1][1].act
			--col_bg = mnu_arr[-1][2].act

			local cap_str = "(%d+)%s+(%d+)%s+(%d+)%s+(%d+)"
			-- convert the stored strings into our color tables
			col_main = {string.match(mnu_arr[-1][0].act, cap_str)}
			col_hover = {string.match(mnu_arr[-1][1].act, cap_str)}
			col_bg = {string.match(mnu_arr[-1][2].act, cap_str)}
			
		end			
		
	else
	
		-- Default menu and settings
		mnu_arr = {
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
		
		for i = 1, #mnu_arr[0] + 1 do
			
			local lbl = mnu_arr[0][i - 1].lbl
			init_menu(i, lbl)
			
		end	
		
	end
end

-- Save the current menu settings to a text file
-- (Same name and path as the script)
local function save_menu()
	
	local file_name = script_path.."Lokasenna_Radial Menu.txt"
	
	local file = io.open(file_name, "w+") or nil
	if not file then 
		--Msg("oops") 
		return 0 
	end
	
	-- Throw in our color settings
	mnu_arr[-1] = {}
	mnu_arr[-1][0] = {["lbl"] = "main color", ["act"] = table.concat(col_main, " ")}
	mnu_arr[-1][1] = {["lbl"] = "hover color", ["act"] = table.concat(col_hover, " ")}
	mnu_arr[-1][2] = {["lbl"] = "bg color", ["act"] = table.concat(col_bg, " ")}
	
	local out_arr = {}
	
	for k1, v1 in pairs(mnu_arr) do
		if v1 then
			for k2, v2 in pairs(v1) do
				--file_out:write(base_file_compiled[i].."\n")
				local str = k1.."  "..k2.."  '"..v2.lbl.."'  '"..v2.act.."'"
				table.insert(out_arr, str)
			end
		end
	end
	

	
	table.sort(out_arr)
	
	for i = 1, #out_arr - 1 do
		file:write(out_arr[i].."\n")
		--Msg(out_arr[i])
	end
	file:write(out_arr[#out_arr])
	
	io.close(file)
	
end


-- Get the width of each menu option in radians (not worrying about pi yet)
local mnu_adj 

local cur_depth = 0
local last_depth = 0


local mouse_x, mouse_y, mouse_mnu, key_down, downtime, mnu_clicked, last_mnu_clicked
local startup = true
local setup = false

local function Msg(str)
	reaper.ShowConsoleMsg(str.."\n")
end


-- You give it x/y coords and an origin, it returns a polar angle and radius
local function cart2polar(x, y, ox, oy)
	
	local dx, dy = x - ox, y - oy
	
	local angle = atan(dy, dx) / pi
	local r = sqrt(dx * dx + dy * dy)

	return angle, r
	
end

-- And vice versa; angle (in rads) and radius --> x/y coords
-- Don't include pi in the angle you give; i.e. 2*pi rads = '2'
local function polar2cart(angle, radius, ox, oy)
	
	local angle = angle * pi
	local x = radius * cos(angle)
	local y = radius * sin(angle)

	
	if ox and oy then x, y = x + ox, y + oy end

	return x, y
	
end

--[[
	Draws a section of a ring 
	(an annular sector, if you want to be technical)
	(or 'a small arc and a large arc, connected by lines at either end')

	angle_c		Center angle in radians, not including pi. i.e. 45 degrees = pi/4 rads --> 0.25
	width		Width of the section in radians, again not including pi. For a ring of buttons, 
				width would	be 2 / #_of_buttons
	r_in		Inner and outer radius, measured in pixels from ox, oy
	r_out
	ox			Center of the hypothetical circles that the arcs are taken from.
	oy
	pad			Shrink the section by this many radians, f.e. if you wanted a little space
				between multiple sections. Don't go overboard; a value of 0.05 is plenty.
	color		Given as a table of r,g,b,a values from 0 to 1, i.e. {0.2, 1, 0.2, 1}
	fill		Boolean, would you like the section colored in? The coloring algorithm is rather
				inefficient, so it may impact performance if you're drawing a lot of these
]]--
local function draw_ring_section(angle_c, width, r_in, r_out, ox, oy, pad, fill, color)
	
	local angle_a, angle_b = (angle_c - 0.5 + pad) * width, (angle_c + 0.5 - pad) * width
	
	local ax1, ay1 = polar2cart(angle_a, r_in, ox, oy)
	local ax2, ay2 = polar2cart(angle_a, r_out - 1, ox, oy)
	local bx1, by1 = polar2cart(angle_b, r_in, ox, oy)
	local bx2, by2 = polar2cart(angle_b, r_out - 1, ox, oy)	
	
	if color then setcolor(color) end
	

	
	-- gfx.arc doesn't use the correct reference angle,
	-- so we have to add 0.5 rads to compensate
	angle_a = (angle_a + 0.5) * pi
	angle_b = (angle_b + 0.5) * pi
	gfx.arc(ox, oy, r_in, angle_a_rads, angle_b_rads, 1)
	gfx.arc(ox, oy, r_out, angle_a_rads, angle_b_rads, 1)	
	
	
	if fill then
		for j = r_in, r_out, 0.4 do
			gfx.arc(ox, oy, j, angle_a, angle_b, 1)
		end
	end
end


-- Draw all of the menu options as segments of a ring
local function draw_mnu()
	
local k = math.max(cur_depth - 1, 0)	

	for i = 0, #mnu_arr[cur_depth] do
		
		local opt = mnu_arr[cur_depth][i]

		if opt.lbl and opt.lbl ~= "" then
		
			--local k = math.max(cur_depth - 1, 0)
			--local k = 0
			
			--local fill =	((i + k) % #mnu_arr == mouse_mnu)
			local fill = true
			local color
			
			if (((i + k) % (#mnu_arr[cur_depth] + 1)) == mnu_clicked) then
				if mouse_l_down then
					fill = false
					color = col_main
				else
					color = col_hover
				end
			else
				color = col_main
			end

			if opt.act and string.sub(opt.act, 1, 4) ~= "menu" and opt.act ~= "" then
				local act = opt.act --string.match(opt.act, "(%d+)")
				if string.sub(act, 1, 1) == "_" then
					act = reaper.NamedCommandLookup(act)
				end
				local state = (type(act) == "number" and act > 0) and reaper.GetToggleCommandState(act) or nil
				if state == 1 then color = col_tog_on end
			end  
			
	
			draw_ring_section(i + k, mnu_adj, rc, rd, ox, oy, 0, fill, color)

			if fill then setcolor(col_bg) end

			-- Center the current option's text in the button
			--Msg(cur_depth.." "..i)
			local str = opt.lbl

			local str_w, str_h = gfx.measurestr(str)
			local cx, cy = polar2cart((i + k) * mnu_adj, rc + (rd - rc) / 2, ox, oy)
			gfx.x, gfx.y = cx - str_w / 2, cy - str_h / 2
			gfx.drawstr(str)

		end

	end	

	-- Draw the guide button from the previous menu
	if cur_depth > 0 then
		
		local k = math.max(last_depth - 1, 0)
		
		--Msg(#mnu_arr[last_depth])
		local adj = 2 / (#mnu_arr[last_depth] + 1)
		
		draw_ring_section(cur_depth - 1, adj, ra, rb, ox, oy, 0, true, col_main)
		--[[
		for i = 0, #mnu_arr[last_depth] do
		
			local fill =	(i + k) == cur_depth - 1
			Msg("i + k = "..(i + k).."   cur_depth - 1 = "..(cur_depth - 1))
			draw_ring_section(i + k, adj, ra, rb, ox, oy, 0.05, fill, col_main)

		end
		]]--

	end
	
	-- Draw the center button if there is one
	if mnu_arr[cur_depth][-1] and mnu_arr[cur_depth][-1].lbl ~= "" then
		
		local fill = true
		local color
		
		if mnu_clicked == -1 then
			if mouse_l_down then
				fill = false
				color = col_main
			else
				color = col_hover
			end
		else
			color = col_main
		end		
		
		setcolor(color)
		gfx.circle(ox, oy, ra - 4, true, 1)
		
		if fill then setcolor(col_bg) end
		local str = mnu_arr[cur_depth][-1].lbl

		local str_w, str_h = gfx.measurestr(str)
		gfx.x, gfx.y = ox - str_w / 2, oy - str_h / 2
		gfx.drawstr(str)
		
	end
end


local function Main()

		
	mouse_x, mouse_y = gfx.mouse_x, gfx.mouse_y
	mouse_cap = gfx.mouse_cap
	mouse_l_down = mouse_cap&1==1
	mouse_r_down = mouse_cap&2==2
	
	mnu_adj = 2 / (#mnu_arr[cur_depth] + 1)

	--[[
		'startup' is used as a bit of a cheat, to keep the window open
		until the script is able to detect the key that was held down
		
		'key_down' figures out what key was held ('hold_char'), and then 
		watches to see if it's been released
		
		'up_time' is used to see if the key was let off before the script
		managed to start up, since that would leave the window open rather
		than closing it
	]]--
	
	--Msg(gfx.getchar())
	cur_char = gfx.getchar()
	
	
	if startup then
		key_down = cur_char
		
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
				
				For Ctrl+4 or Ctrl+]... I have no fucking clue short of individually
				checking every possibility.
			
			]]--
			local cap = gfx.mouse_cap
			local adj = 0
			if cap & 4 == 4 then			
				if not (cap & 16 == 16) then
					adj = adj + 96			-- Ctrl
				else						
					adj = adj - 160			-- Ctrl+Alt
				end
				--	No change				-- Ctrl+Shift
				
			elseif (cap & 16 == 16) then	
				adj = adj - 224				-- Alt
				
				--  No change				-- Alt+Shift
				
			elseif cap & 8 == 8 then		
				adj = adj + 32				-- Shift
			end
	
			hold_char = key_down + adj
			
			startup = false
		elseif not up_time then
			up_time = reaper.time_precise()
		end
		
	else
		key_down = gfx.getchar(hold_char)

	end

	-- Where is the mouse in relation to the center of the window?
	local mouse_angle, mouse_r = cart2polar(mouse_x, mouse_y, ox, oy)
	
	-- Figure out what option the mouse is over
	if mouse_angle < 0 then mouse_angle = mouse_angle + 2 end	
	mouse_mnu = math.floor(mouse_angle / mnu_adj + 0.5)
	if mouse_mnu == (#mnu_arr[cur_depth] + 1) then mouse_mnu = 0 end
	mnu_clicked = mouse_mnu  % (#mnu_arr[cur_depth] + 1)
	if mouse_r < ((mnu_arr[cur_depth][-1] and mnu_arr[cur_depth][-1].lbl ~= "")and 48 or 16) then mnu_clicked = -1 end
	
	if mouse_l_down then
		
		if not last_mouse_l_down then last_mnu_clicked = -2 end
		
		last_mouse_l_down = true
		
		if setup then
			if not down_time then 
				down_time = reaper.time_precise()
			elseif reaper.time_precise() - down_time > 0.5 then
			
				-- User held down the mouse, so lets get their input and update the mnu item
				-- retval, retvals_csv reaper.GetUserInputs( title, num_inputs, captions_csv, retvals_csv )
				if not mnu_arr[cur_depth][mnu_clicked] then
					mnu_arr[cur_depth][mnu_clicked] = {["lbl"] = "new", ["act"] = "0"}
				end
				local cur_lbl, cur_act = mnu_arr[cur_depth][mnu_clicked].lbl, mnu_arr[cur_depth][mnu_clicked].act
				local retval, retstr = reaper.GetUserInputs("Edit menu label", 2, "Label:,Action ID:,extrawidth=32", cur_lbl..","..cur_act)
				
				--Msg(tostring(retval))
				if retval then 

					local ret_lbl, ret_ID = string.match(retstr, "([^,]+),([^,]+)")
					if not ret_lbl or not ret_ID then ret_lbl, ret_ID = "", "" end
					--[[
						Moving this into the on-click code because apparently custom actions
						get a new ID when they're re-added to the Action List
						
					if string.sub(ret_ID, 1, 1) == "_" then
						ret_ID = reaper.NamedCommandLookup(ret_ID)
					end
					]]--
					mnu_arr[cur_depth][mnu_clicked].lbl = ret_lbl
					mnu_arr[cur_depth][mnu_clicked].act = ret_ID
					
					save_menu()
					
					last_mnu_clicked = -2
				end
				
				last_mouse_l_down = false
				down_time = nil
				
			end
		end
		
	elseif last_mouse_l_down then

		if mnu_clicked == -1 and cur_depth ~= 0 then

			cur_depth = 0
			last_depth = 0
			
		elseif mnu_arr[cur_depth][mnu_clicked] then
		
			-- Msg("cur_depth = "..tostring(cur_depth).."mnu_clicked = "..tostring(mnu_clicked)
			local act = mnu_arr[cur_depth][mnu_clicked].act
			if act == "" then
				--Msg("no action")
				last_depth = 0
				cur_depth = 0
			elseif string.sub(act, 1, 4) == "menu" then
				last_depth = cur_depth
				cur_depth = tonumber(string.sub(act, 5))
				if not mnu_arr[cur_depth] then
					init_menu(cur_depth)
				end
				--Msg("moving to menu "..cur_depth)
			else
				--Msg("attempting action "..act)
				if string.sub(act, 1, 1) == "_" then
					act = reaper.NamedCommandLookup(act)
				end
				if type(act) == "number" and act > 0 then reaper.Main_OnCommand(act, 0) end
				cur_depth = 0
			end
			
		end
--[[		
		if cur_depth == 0 then
			cur_depth = mouse_mnu + 1
		elseif mnu_clicked > 0 then
		
			
			-- *** Put your "option was clicked" function here ***
			
			if mnu_arr[cur_depth][mouse_mnu][2] ~= 0 then
				reaper.Main_OnCommand(mnu_arr[cur_depth][mouse_mnu][2], 0)
			end
			
			cur_depth = 0
			
		else

			cur_depth = 0
		end
]]--	
		mnu_adj = 2 / (#mnu_arr[cur_depth] + 1)
		down_time = nil
		last_mouse_l_down = false
		last_mnu_clicked = -2	
	end
	
	if mouse_r_down then
		last_mouse_r_down = true
	elseif last_mouse_r_down then
	
		setup = not setup
		last_mouse_r_down = false
		last_mnu_clicked = -2		
	end
	

	if setup then

		if mnu_clicked ~= last_mnu_clicked then
			-- Let the user know if we're in setup mode
			gfx.set(1, 1, 0.2, 1)
			local str = "SETUP"
			local str_w, str_h = gfx.measurestr(str)
			gfx.x, gfx.y = 2, 2
			gfx.drawstr(str)
				gfx.x, gfx.y = w - str_w - 2, 2
			gfx.drawstr(str)
			gfx.x, gfx.y = 2, h - str_h - 2
			gfx.drawstr(str)
			gfx.x, gfx.y = w - str_w - 2, h - str_h - 2
			gfx.drawstr(str)
		end

		-- Check for F1, to open our generic settings
		if cur_char == 26161 then
		-- retval, retvals_csv reaper.GetUserInputs( title, num_inputs, captions_csv, retvals_csv )

			local defstr = table.concat(col_main, " ")..","..table.concat(col_hover, " ")..","..table.concat(col_bg, " ")

			local retval, retstr = reaper.GetUserInputs("Color Settings", 3, "Main RGBA (0 255):,Hover RGBA:,BG RGBA (requires a restart):,extrawidth=24", defstr)
			
			if retval then
				
				local col_arr = {string.match(retstr, "([^,]+),([^,]+),([^,]+)")}
				col_main = {string.match(col_arr[1], "(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")}
				col_hover = {string.match(col_arr[2], "(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")}
				col_bg = {string.match(col_arr[3], "(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")}
			
			end
		
		-- Use A and D to add and delete buttons to the current submenu
		-- table.insert, mnu_arr[cur_depth][mnu_clicked] = nil?
		--elseif gfx.getchar() == 
		
		end
	
	end

	-- Draw all of the options
	if mnu_clicked ~= last_mnu_clicked then
		draw_mnu()	
		last_mnu_clicked = mnu_clicked
	end

	local diff = up_time and (reaper.time_precise() - up_time) or 0
	
--[[
	If 'up_time' manages to run longer than 0.7s, we'll close the script
	(0.6s is the shortest I could set it on my system without the window
	closing and then opening again when Windows says "this key is still
	being held down", so we'll just bump it 0.7 to be safe)
	
	Otherwise, we keep going until the user lets go of the key
]]--	  

	if cur_char ~= -1 and (setup or key_down ~= 0 or (startup and diff < 0.7)) then
		reaper.defer(Main)
	else
		return 0
	end
	
	gfx.update()
	
end


load_menu()
reaper.atexit(save_menu)

gfx.clear = rgb2num(table.unpack(col_bg, 1, 3))
gfx.init(name, w, h, 0, x, y)
gfx.setfont(1, "Calibri", 18)
Main()
