--[[
ReaScript Name: Exclusive dummy toggles (12 scripts)
Author: BuyOne
Version: 1.0
Changelog: Initial release
Author URL: https://forum.cockos.com/member.php?u=134058
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M extension (recommended for ability to use Cycle action editor)
About:	This set of 10 scripts borrows the concept of SWS extension 'SWS/S&M: Dummy toggle' 
        actions but makes dummy toggle exclusive within the scope of an Action list section,
        meaning that when one of 10 scripts toggle state is ON, toggle state of the rest 9 is OFF 
        while the state of a given script in one Action list section is completely independent 
        from its state in other Acton list sections.  
        These can be useful in switching between options/modes of operation depending 
        on the state of a specific dummy toggle script, for example with the SWS Cycle actions 
        through conditional statements or within other scripts. One such use case is switching
        between velocity presets in the MIDI Editor, another - mouse tool switcher. The switching 
        can be done from a toolbar or a menu via toolbar buttons or menu items linked to the dummy 
        toggle scripts.  
        You can expand the script set by duplicating any instance, giving its duplicate a unique 
        number and importing it into every Action list section.  
        With the USER SETTINGS the script set can be divided into subsets (groups) so that every 
        script in a subset only affects toggle state of other scripts in this subset. This way 
        each subset can be dedicated to a specific task which requires mutually exclusive modes.
	Division into subsets is specific to the Action list section so in each section the dummy 
	toggle script set can have its own subset division scheme.

        The dummy toggle script whose toggle state is currently ON is stored. This allows restoring 
        its state on REAPER startup using 'BuyOne_Exclusive dummy toggle startup script.lua' script 
        from the Main section of the Action list, provided it's included in the SWS extension Startup 
	actions.
		
	SCREENSHOTS:  
	https://raw.githubusercontent.com/Buy-One/screenshots/main/Exclusive%20dummy%20toggle%20scripts.gif  
	Use case   
	https://raw.githubusercontent.com/Buy-One/screenshots/main/Insert%20note%20at%20constant%20velocity%20depending%20on%20dummy%20toggle%20scripts.gif
Metapackage: true
Provides: 	
	[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 1.lua
	[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 2.lua
	[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 3.lua
	[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 4.lua
	[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 5.lua
	[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 6.lua
	[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 7.lua
	[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 8.lua
	[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 9.lua
	[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 10.lua	
	[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle - spawn new script.lua
	[main] BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle startup script.lua
]]
-------------------------------------------------------------------------------------
---------------------------------- USER SETTINGS ------------------------------------
-------------------------------------------------------------------------------------

-- Add a letter between quotation marks to define a subset
-- per Action list section (the register doesn't matter);
-- to have mutually exclusive toggle states all scripts of a subset
-- in the corresponding Action list section should be assigned the same letter,
-- e.g. scripts 1 through 5 in the Main section could have A subset letter
-- (Main = "A") while scripts 6 through 10 could have B subset letter (Main = "B"),
-- consequently scripts 1 through 5 on the one hand and scripts 6 through 10
-- on the other would be mutually exclusive;
-- by default all scripts in the set are assigned the same letter per Action
-- list section which makes toggle states of all mutually exclusive;
-- empty slots and entries other than alphabetical (English) are not supported.

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

function Get_Dummy_Toggle_Scripts(sect_ID, SECT, curr_subset) -- collect all dummy toggle scripts in the same section and of the same subset as the current script to be able to set their state to OFF when the state of the current script is ON
local sep = r.GetResourcePath():match('[\\/]')
local res_path = r.GetResourcePath()..r.GetResourcePath():match('[\\/]') -- path with separator
local cont
local f = io.open(res_path..'reaper-kb.ini', 'r')
	if f then -- if file available, just in case
	cont = f:read('*a')
	f:close()
	end
local t = {}
	if cont and cont ~= '' then
		for line in cont:gmatch('[^\n\r]*') do -- parse reaper-kb.ini code
		local comm_ID, scr_path = line:match('SCR %d+ '..sect_ID..' (.+) "Custom: .+_Exclusive dummy toggle %d+%.lua" "(.+)"')
			if comm_ID then
			-- get subset assignment of a found dummy toggle script
			local f = io.open(res_path..'Scripts'..sep..scr_path, 'r') -- get dummy toggle script code
			local cont = f:read('*a')
			f:close()
			local subset = cont:match('\n'..SECT[sect_ID]..' = "(.-)"') -- leading line break to exclude captures from the settings explanation text (Main = "A")
				if subset == curr_subset then
				t[#t+1] = r.NamedCommandLookup('_'..comm_ID) -- converting to integer
				end
			end
		end
	end
return t
end


local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local scr_name = scr_name:match('([^\\/]+)%.%w+')

local SUBSETS = {[0] = Main, [32060] = MIDI_Ed, [32062] = MIDI_Inline_Ed, [32061] = MIDI_Ev_List, [32063] = Media_Ex}
local SECT = {[0] = 'Main', [32060] = 'MIDI_Ed', [32062] = 'MIDI_Inline_Ed', [32061] = 'MIDI_Ev_List', [32063] = 'Media_Ex'}
local curr_subset = SUBSETS[sect_ID]:gsub(' ',''):upper() -- removing spaces, capitalizing

	if #curr_subset == 0 or not curr_subset:match('[A-Z]') then -- throw an error if a subset setting is invalid
	local x, y = r.GetMousePosition()
	r.TrackCtl_SetToolTip(('\n\n  invalid subset setting \n\n     for '..SECT[sect_ID]..' section \n\n  '):gsub('.','%0 '):upper(), x, y, true) -- topmost true
	return r.defer(function() do return end end)
	end

local t = Get_Dummy_Toggle_Scripts(sect_ID, SECT, curr_subset)
local toolbar = r.RefreshToolbar2
local section_name = 'BuyOne_Exclusive dummy toggle'

	for _, comm_ID in ipairs(t) do -- set ALL dummy toggle scripts in the same Action list section and of the same subset as the current one to OFF state
	r.SetToggleCommandState(sect_ID, comm_ID, 0)
	toolbar(sect_ID, comm_ID)
	end
r.SetToggleCommandState(sect_ID, cmd_ID, 1) -- set current one to ON
toolbar(sect_ID, cmd_ID)
r.SetExtState(section_name, 'section:'..sect_ID..'|subset:'..curr_subset, '_'..r.ReverseNamedCommandLookup(cmd_ID), true) -- persist true // update stored dummy toggle slot to be able to restore it at the start of the next REAPER session provided 'BuyOne_Exclusive dummy toggle startup script.lua' script is added to SWS startup actions; converted to named command ID so it's consistent across sessions (not sure this will be the case with numeric one)


do return r.defer(function() do return end end) end -- no Undo point






