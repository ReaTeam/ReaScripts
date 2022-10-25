--[[
ReaScript name: Select track of the currently focused track FX window
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: js_ReaScriptAPI
About: 	Makes track of the focused track FX window selected.
	Works in either manual or auto modes, see USER SETTINGS.   

	Bridged FX floating windows don't work unless they only display 
	controls without the UI, which is a REAPER native object.  

	See also BuyOne_Select source object of a focused FX chain or FX window.lua
		
]]

------------------------------------------------------------------
-------------------------- USER SETTINGS -------------------------
------------------------------------------------------------------
-- To enable the settings below insert any QWERTY alphanumeric
-- character between the quotation marks.

-- Enable this setting so the script can be used
-- then configure the settings below
ENABLE_SCRIPT = ""

---------------------------------------------------------------

SCROLL_2TRACK = "1"

-- If not enabled the script will only work if run with a shortcut,
-- because running from a toolbar or a menu changes window focus
-- and the API no longer detects FX window title from which track
-- data is fetched
AUTO = ""

-------------------------------------------------------------------
----------------------- END OF USER SETTINGS ----------------------
-------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function Script_Not_Enabled(ENABLE_SCRIPT)
	if #ENABLE_SCRIPT:gsub(' ','') == 0 then
	local emoji = [[
		_(ツ)_
		\_/|\_/
	]]
	r.MB('  Please enable the script in its USER SETTINGS.\n\nSelect it in the Action list and click "Edit action...".\n\n'..emoji, 'PROMPT', 0)
	return true
	end
end


local hwnd_init


function SELECT()

local undo = not AUTO and r.Undo_BeginBlock()

local hwnd = r.JS_Window_GetForeground()
local title = r.JS_Window_GetTitle(hwnd)

	if (title:match('Master Track') or title:match('Monitoring')) and (AUTO and hwnd ~= hwnd_init or not AUTO)
	then -- Master and Monitor FX windows
	local master_tr = r.GetMasterTrack(0)
	r.SetOnlyTrackSelected(master_tr)
		if SCROLL_2TRACK then
		r.CSurf_OnScroll(0, -5000) -- scroll up as far as possible
		r.SetMixerScroll(master_tr) -- scroll mixer
		end
	hwnd_init = hwnd
	elseif title:match('Track (%d+)') and (AUTO and hwnd ~= hwnd_init or not AUTO) then -- regular track FX windows
	local track_idx = title:match('Track (%d+)')
	local tr = r.GetTrack(0,track_idx-1)
	r.SetOnlyTrackSelected(tr)
		if SCROLL_2TRACK then
		-- borrowed from Edgemeal https://forums.cockos.com/showthread.php?t=249659#5
		r.Main_OnCommand(40913, 0) -- Track: Vertical scroll selected tracks into view
		r.SetMixerScroll(tr) -- scroll mixer
		end
	hwnd_init = hwnd
	else
	hwnd_init = hwnd
	end

local run = AUTO and r.defer(SELECT)

local undo = not AUTO and r.Undo_EndBlock('Select track of the currently focused track FX window', -1)

end


AUTO = #AUTO:gsub(' ','') > 0
SCROLL_2TRACK = #SCROLL_2TRACK:gsub(' ','') > 0

	if Script_Not_Enabled(ENABLE_SCRIPT) then
	return r.defer(function() do return end end)
	elseif r.APIExists('JS_Window_GetForeground') then
	r.MB('   The script requires js_ReaScriptAPI\n\n        which isn\'t currently installed.\n\nAfter clicking OK the link will be provided.','ERROR',0)
	Msg('https://github.com/juliansader/ReaExtensions/tree/master/js_ReaScriptAPI', r.ClearConsole())
	return r.defer(function() do return end end)
	end


SELECT()






