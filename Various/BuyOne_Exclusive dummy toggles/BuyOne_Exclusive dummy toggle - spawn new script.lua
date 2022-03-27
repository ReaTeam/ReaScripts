--[[
Noindex: true
ReaScript Name: BuyOne_Exclusive dummy toggle - spawn new script.lua
Author: BuyOne
Version: 1.0
Changelog: Initial release
Author URL: https://forum.cockos.com/member.php?u=134058
Licence: WTFPL
REAPER: at least v5.962
About: 	The script generates a new exclusive dummy toggle script and adds it
	to all sections of the Action list bar 'Main (alt recording)'.  
	To be used when you've run out of all original 10 scripts and need
	to engage more options.
]]

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper

local SUBSETS = [[
Main = "A"
MIDI_Ed = "A"
MIDI_Inline_Ed = "A"
MIDI_Ev_List = "A"
Media_Ex = "A"
]]


local sep = r.GetResourcePath():match('[\\/]')
local res_path = r.GetResourcePath()..r.GetResourcePath():match('[\\/]') -- path with separator
local cont
local f = io.open(res_path..'reaper-kb.ini', 'r')
	if f then -- if file available, just in case
	cont = f:read('*a')
	f:close()
	end
	if cont and cont ~= '' then
	local scr_idx, scr_path
		for line in cont:gmatch('[^\n\r]*') do -- parse entire reaper-kb.ini code to get the greatest dummy toggle script instance
		local idx, path = line:match('SCR %d+ .- "Custom: .+_Exclusive dummy toggle (%d+)%.lua" "(.+)"')
			if path then
			scr_idx = math.floor(idx+1) -- trancating trailing decimal zero
			scr_path = path
			end
		end
		if scr_idx then
		local f = io.open(res_path..'Scripts'..sep..scr_path, 'r') -- get dummy toggle script code
		local cont = f:read('*a')
		f:close()
		local subsets = cont:match('\n(Main =.-Media_Ex.-)\n')
		local cont_upd = cont:gsub(subsets, SUBSETS) -- change subsets to default values
		local scr_path = res_path..'Scripts'..sep..scr_path:gsub('toggle %d+','toggle '..scr_idx) -- increment index in the file name
		local f = io.open(scr_path, 'w')
		f:write(cont_upd)
		f:close()
		local SECT = {0, 32060, 32061, 32062, 32063}
			for _, sect_ID in ipairs(SECT) do
			r.AddRemoveReaScript(true, sect_ID, scr_path, true) -- add & commit true
			end
		end
	end

do return r.defer(function() do return end end) end -- no Undo point


