--[[
Description: Repeat Action
Version: 1.1.0
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	Created scripts are automatically added to the Action List
	(MIDI actions should be in the MIDI Editor's action list)
	Will work with ReaScript and custom action IDs now
Links:
	Forum Thread http://forum.cockos.com/showthread.php?t=188632
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
	Allows action IDs to repeated at a specified interval
	
	1. This script won't do anything by itself; use the included script 'Lokasenna_Repeat Action - Add new action.lua' to generate a script
	for each action you want to repeat.
	
	2. In Reaper's action list, use the 'Load' button and browse to:
		'Reaper/Scripts/ReaTeam Scripts/Various/Lokasenna_Repeat Action/"

	3. Select the scripts you generated.
	
	4. Each script will be individually accessible in the action list for you to bind to a shortcut key.
Extensions:
Provides:
	[nomain] . > Lokasenna_Repeat Action/Lokasenna_Repeat Action.lua
	[main] Lokasenna_Repeat Action - Add new action.lua > Lokasenna_Repeat Action/Lokasenna_Repeat Action - Add new action.lua
--]]

local dm = debug_mode

local function Msg(str)
	reaper.ShowConsoleMsg(tostring(str).."\n")
end

---------------------------------------
------------ USER SETTINGS ------------

-- Minimum time (in seconds) to keep
-- window open if no key is detected
local close_time = 0.6	

---------------------------------------
---------------------------------------

local w, h = 192, 64


local startup = true
local key_down, hold_char
local last = reaper.time_precise()



if not (act and interval) then
	
	local script_path = debug.getinfo(1,'S').source:match[[^@?(.*[\/])[^\/]-$]]
	
	reaper.ShowMessageBox("This script needs an action ID to work with. Please use:\n\n\t'Lokasenna_Repeat Action - Add new action.lua'\n\nto generate a script for each action ID you want to repeat, then use the 'Load' button in Reaper's action list to find them - they're stored in:\n\n\t'"
		..(string.len(script_path) > 20 and ("..."..string.sub(script_path, -20) ) or script_path)
		.."Lokasenna_Repeat Action'", "Whoops", 0)
	return 0
end


-- Convert script GUIDs to action IDs if necessary
if string.sub(act, 1, 1) == "_" then act = reaper.NamedCommandLookup(act) end

-- Just some error checking because Lua occasionally 
-- throws a fit about numbers that are strings
act = tonumber(act)

-- Make really, really sure it's a valid action.
if not act or act <= 0 then
	reaper.ShowMessageBox("Invalid action ID.", "Whoops", 0)
	return 0
end

local wnd = midi and reaper.MIDIEditor_GetActive()
	

local char

local function check_key()

_=dm and Msg(">check_key")
	
	-- For debugging
	local mod_str = ""
	
	_=dm and Msg("\tChecking the shortcut key")
	
	if startup then
		
		_=dm and Msg("\tStartup, looking for key...")
		
		key_down = char
		
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
			
			local cap = gfx.mouse_cap
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
	
			hold_char = math.floor(key_down + adj)
			_=dm and Msg("\tDetected: "..mod_str.." "..hold_char)
			
			startup = false
		elseif not up_time then
			up_time = reaper.time_precise()
		end
		
	else
		key_down = gfx.getchar(hold_char)
		if key_down ~= 0 then
			_=dm and Msg("\tKey "..tostring(hold_char).." is still down (ret:"..tostring(key_down)..")")
		else
			_=dm and Msg("\tKey "..tostring(hold_char).." is no longer down")
		end
	end	
	

	_=dm and Msg("<check_key")

end



local function check_act()
	
	_=dm and Msg(">check_act")
	
	local time = reaper.time_precise()

	_=dm and Msg("\tinterval set to: "..tostring(interval).." seconds")
	_=dm and Msg("\ttime since last action: "
		.. math.floor( (time - last) * 1000 ) / 1000
		.. " seconds"
	)

	if time - last > interval then
		
		if string.sub(act, 1, 1) == "_" then act = reaper.NamedCommandLookup(act) end
		
		-- Just some error checking because Lua occasionally 
		-- throws a fit about numbers that are strings
		act = tonumber(act)
		
		_=dm and Msg("\tinterval elapsed, running action: " .. tostring(act))
		
		if not midi then
			reaper.Main_OnCommand(act, 0)
		else
			reaper.MIDIEditor_OnCommand(wnd, act)
		end
		
		last = time
	
	end	
	
	_=dm and Msg("<check_act")
	
end



local function Main()
	
	_=dm and Msg(">main")
	
	char = gfx.getchar()
	
	if char == -1 or char == 27 then return 0 end
	
	check_key()
	

	local diff = up_time and (reaper.time_precise() - up_time) or 0

	--[[	See if any of our numerous conditions for running the script are valid
		
	- Setup mode?
	- Shortcut key down?
	- Startup mode and the timer hasn't run out?
	- Running in "just leave the window open" mode?

	]]--	  

	if key_down ~= 0 or (startup and diff < close_time) then

		_=dm and Msg("\tchecking action and deferring")
		
		-- See if we need to run the action again
		check_act()


		gfx.update()
		reaper.defer(Main)
		
	else
		_=dm and Msg("\tquitting")

	end



	_=dm and Msg("<main")
	
end

gfx.init("Repeat Action", 192, 0, 0, 20, 20)

Main()