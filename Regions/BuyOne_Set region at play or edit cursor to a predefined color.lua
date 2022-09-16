--[[
ReaScript name: Set region at play or edit cursor to a predefined color
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About:	During playback looks for the playhead position,
	otherwise - for the edit cursor position.

	When no playback, place the edit cursor at the beginning
	or the end of a region or anywhere in between, run.

	The script can be duplicated to create as many
	individual copies as there're colors you need to set
	your regions to. Name each such copy differently.

]]

------------------------------------------------------------------
-------------------------- USER SETTINGS -------------------------
------------------------------------------------------------------

-- Between the quotation marks insert hexadecimal color code;
-- if malformed or invalid no color will be set.

HEX_COLOR = "#16A085"

-------------------------------------------------------------------
----------------------- END OF USER SETTINGS ----------------------
-------------------------------------------------------------------

local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

function Error_Tooltip(text)
local x, y = r.GetMousePosition()
r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
end


function Validate_HEX_Color_Setting(HEX_COLOR)
local HEX_COLOR = type(HEX_COLOR) == 'string' and HEX_COLOR:gsub('%s','') -- remove empty spaces just in case

local HEX_COLOR = type(HEX_COLOR) == 'string' and #HEX_COLOR >= 4 and #HEX_COLOR <= 7 and HEX_COLOR

	if not HEX_COLOR then return end

-- extend shortened (3 digit) hex color code, duplicate each digit
local HEX_COLOR = #HEX_COLOR == 4 and HEX_COLOR:gsub('%w','%0%0') or not HEX_COLOR:match('^#') and '#'..HEX_COLOR or HEX_COLOR -- adding '#' if absent
return HEX_COLOR -- TO USE THE RETURN VALUE AS ARG IN hex2rgb() function UNLESS IT'S INCLUDED IN THIS ONE AS FOLLOWS
--local R,G,B = hex2rgb(HEX_COLOR) -- R because r is already taken by reaper, the rest is for consistency
end

function hex2rgb(HEX_COLOR)
-- https://gist.github.com/jasonbradley/4357406
    local hex = HEX_COLOR:sub(2) -- trimming leading '#'
    return tonumber('0x'..hex:sub(1,2)), tonumber('0x'..hex:sub(3,4)), tonumber('0x'..hex:sub(5,6))
end


local HEX_COLOR = Validate_HEX_Color_Setting(HEX_COLOR)

	if not HEX_COLOR then
	Error_Tooltip('\n\n the color code is malformed \n\n')
	return r.defer(function() do return end end) end

local R,G,B = hex2rgb(HEX_COLOR)

local curs_pos = r.GetPlayState()&1 == 1 and r.GetPlayPosition() -- returns latency-compensated actual-what-you-hear position
or r.GetCursorPosition()

local retval, num_markers, num_regions = r.CountProjectMarkers(0)

r.Undo_BeginBlock()

local i = 0
	repeat
	local retval, isrgn, start, fin, name, index, color = r.EnumProjectMarkers3(0, i)
		if isrgn and start <= curs_pos and fin >= curs_pos then
		local rd, gr, bl = r.ColorFromNative(color)
			if rd ~= R and gr ~= G and bl ~= B then
			r.SetProjectMarker3(0, index, true, start, fin, name, r.ColorToNative(R,G,B)|0x1000000) -- isrgn true
			break
			end
		end
	i = i + 1
	until i == num_regions -- or retval == 0


r.Undo_EndBlock('Set region color',-1)




