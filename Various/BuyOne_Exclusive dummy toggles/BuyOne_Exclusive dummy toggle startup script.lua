--[[
Noindex: true
ReaScript Name: BuyOne_Exclusive dummy toggle startup script.lua
Author: BuyOne
Version: 1.0
Changelog: Initial release
Author URL: https://forum.cockos.com/member.php?u=134058
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M extension (recommended for ability to use Startup actions)
About:	This is a script ancillary to 'BuyOne_Exclusive dummy toggle' script set 
        designed to provide a mechanism of restoring on REAPER startup the toggle state 
        of a dummy toggle script which was last ON before quitting REAPER.  
        To be able to restore toggle state of a script which was last ON in each 
        subset of the dummy toggle script set per Action list section (in case it's been
        divided into several subsets), a letter associated with each subset needs 
        to be included in the USER SETTINGS below.  
        In order to restore the toggle state of dummy toggle scripts which were 
        last ON populate USER SETTINGS below and include this very script in the 
        SWS extension Startup actions either by itself or inside a custom action along 
        with other startup actions if you use any.  
        This script is only available in the Main section of the Action list because
        SWS extension Startup actions utility doesn't support other sections, nevertheless 
        it will affect dummy toggle scripts in all Action list sections provided their
        subset letters are referenced in the USER SETTINGS below.  
	Alternatively to SWS Startup actions utility you can use an external __startup.lua
	script which runs this script. For more info refer to the thread:  
	https://forum.cockos.com/showthread.php?t=222833
]]
-------------------------------------------------------------------------------------
---------------------------------- USER SETTINGS ------------------------------------
-------------------------------------------------------------------------------------

-- Between the quotation marks insert letter(s) associated with each subset
-- of exclusive toggle dummy script set and which is(are) used in the actual dummy
-- toggle scripts USER SETTINGS, separated by comma, semicolon or colon if more
-- than one, per Action list section, e.g. Main = "A" means subset A in the Main
-- section of the Action list, MIDI_Ed = "A,C" means subsets A and C in the MIDI
-- Editor secton of the Action list;
-- several letters are only required if in a given Action list section
-- dummy toggle script set is divided into several subsets, to ensure
-- that the state of the script which was last ON in each subset is restored
-- on REAPER startup.

Main = "A"
MIDI_Ed = "A"
MIDI_Inline_Ed = "A"
MIDI_Ev_List = "A"
Media_Ex = "A"


-------------------------------------------------------------------------------------
------------------------------ END OF USER SETTINGS ---------------------------------
-------------------------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper

function clear_space(str)
return str:gsub(' ','')
end

local subset_t = {[0] = Main, [32060] = MIDI_Ed, [32062] = MIDI_Inline_Ed, [32061] = MIDI_Ev_List, [32063] = Media_Ex}
local is_used
	for k, v in pairs(subset_t) do -- clear spaces
	subset_t[k] = clear_space(v)
		if #subset_t[k] > 0 then is_used = 1 end
	-- convert subset letters to nested tables
	local t = {}
		for letter in v:gmatch('%a+') do
		t[#t+1] = letter
		end
	subset_t[k] = t
	end

	if not is_used then return r.defer(function() do return end end) end -- if no setting is populated with subset letters


-- collect stored command IDs of scripts whose toggle state was last ON per Action list section and subset
local cmd_t = {}
	for sect_ID, letter_t in pairs(subset_t) do
		for _, letter in ipairs(letter_t) do
		local cmd_ID = r.GetExtState('BuyOne_Exclusive dummy toggle', 'section:'..sect_ID..'|subset:'..letter) -- returns named command ID
			if #cmd_ID > 0 then
			cmd_t[r.NamedCommandLookup(cmd_ID)] = sect_ID -- converting cmd_ID to integer // command ID is used as key since it's unique while section ID can be shared between scripts of different subsets
			end
		end
	end


	-- set scripts toggle state to ON
	for cmd_ID, sect_ID in pairs(cmd_t) do
	r.SetToggleCommandState(sect_ID, cmd_ID, 1) -- set to ON
	r.RefreshToolbar2(sect_ID, cmd_ID)
	end


do return r.defer(function() do return end end) end -- no Undo point





