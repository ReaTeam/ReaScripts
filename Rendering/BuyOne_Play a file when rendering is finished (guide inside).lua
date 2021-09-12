--[[
ReaScript name: Play a file when rendering is finished
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Provides: [main] .
Licence: WTFPL
REAPER: at least v5.962
About: 	When launched before rendering starts, plays a file of your choice
		(including the one you just rendered) once rendering is finished.  
		Meant primarily to signal that rendering is over.  
		Inspired by a feature request https://forum.cockos.com/showthread.php?t=257349  
		See details inside the script.
]]
-----------------------------------------------------------------------------
-------------------------- USER GUIDE & SETTINGS ----------------------------
-----------------------------------------------------------------------------
--[[ 
	T H E  G U I D E
--	Launch it before rendering starts.
-- 	When rendering is finished it creates a new track, soloes it,
	loads a file of your choice and plays it for 10 minutes at the longest.
-- 	Once you stop the transport the track is auto-deleted.
-- 	The file to play may be the one you're going to render if you know in advance 
	what its path will be.
-- 	To stop the script launch it again, in the 'ReaScript task control' dialogue
	tick 'Remember my answer for this script' checkbox and click 'Terminate all instances'.
-- 	If you assign the script to a toolbar button it will be lit as long
	as the script is running.
	!!!!! I M P O R T A N T !!!!!
--	For the script to work the setting 
	'Automatically close render window when render has finished'
	must be enabled at Preferences -> Rendering.
	It can also be enabled after rendering starts in the "Rendering to file..." window 
	which displays rendering progress.
	Otherwise the render modal window will block the UI and the script will only fire up
	when the window is manually closed which defeats the whole purpose.
]]

-- T H E  S E T T I N G S
-- In the FILE setting insert a full path to your file between 
-- the double square brackets, e.g. [[C:\My folder\My file.wav]]
-- If the file is invalid or the path is empty, nothing happens.
-- In the TRACK_VOL_in_dB setting between the double square brackets
-- specify volume which the track playing the file will be set to. 
-- If empty the default volume will be used.

FILE = [[]] -- full file path

TRACK_VOL_in_dB = [[]] -- values between -inf and 0 to be on the safe side

-----------------------------------------------------------------------------
---------------------- END OF USER GUIDE & SETTINGS -------------------------
-----------------------------------------------------------------------------

local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

function Check_reaper_ini(key,value)
local f = io.open(r.get_ini_file(),'r')
local cont = f:read('a*')
f:close()
local val = cont:match(key..'=(%d+)') == value -- change to the target value being evaluated
return val
end

function space(n) -- number of repeats
return string.rep(' ',n)
end

-- renderclosewhendone -- 9 ON, 8 OFF
	if not Check_reaper_ini('renderclosewhendone','9') then resp = r.MB(space(13)..'The setting "Automatically close render\n'..space(19)..'window when render is finished"\n\n'..space(7)..'is  OFF at Preferences -> Audio -> Rendering.\n\n  Make sure to enable it for the script to work properly.\n\n'..space(5)..'It can also be enabled in the "Rendering to file..."\n\n'..space(19)..'window of the render progress.\n\n'..space(20)..'Click "OK" to launch the script.', 'REMINDER', 1)
		if resp == 2 then return r.defer(function() end) end
	end	


local TRACK_VOL_in_dB = tonumber(TRACK_VOL_in_dB)

local tr
local play
local rendering

function render_monitor()

r.PreventUIRefresh(1) -- meant to obscure TCP height decrease // only works if applied to the entire deferred function

local i = 0
	repeat
	retval = r.EnumProjects(i+0x40000000) -- looks for a project being rendered
		if retval then rendering = true break end
	i = i+1
	until not retval

	if not retval and rendering and r.file_exists(FILE) and r.GetPlayState() == 0 then -- rendering stopped and no playback/recording // the idea was to only run the routine when no transport action but when rendering is finished and rendering window is closed even if playback is active it halts for a split second and resumes which is enough to make the condition true
	r.InsertTrackAtIndex(r.GetNumTracks(), false) -- wantDefaults is false
	r.SetOnlyTrackSelected(r.GetTrack(0,r.GetNumTracks()-1))
	r.CSurf_GoStart() -- moves cursor to project start to insert item there
	r.InsertMedia(FILE, 0) -- 0 is add to current track
	r.CSurf_GoStart() -- returns cursor to project start since upon item insertion it has moved to the item end
	tr = r.GetSelectedTrack(0,0)
	r.SetMediaTrackInfo_Value(tr, 'I_SOLO', 1)
		if TRACK_VOL_in_dB then
		r.SetMediaTrackInfo_Value(tr, 'D_VOL', 10^(TRACK_VOL_in_dB/20)) -- formula source http://forum.cockos.com/showpost.php?p=1608719&postcount=6
		end
	r.SetMediaTrackInfo_Value(tr, 'I_HEIGHTOVERRIDE', 1)
	r.TrackList_AdjustWindows(true) -- isMinor is true // updates TCP only https://forum.cockos.com/showthread.php?t=208275
	local item = r.GetTrackMediaItem(tr,0)
	r.SetMediaItemInfo_Value(item, 'B_LOOPSRC', 1)
	r.SetMediaItemInfo_Value(item, 'D_LENGTH', 600) -- 10 minutes
	r.CSurf_OnPlay()
	play = true
	rendering = nil -- reset
	elseif not retval and play and r.GetPlayState() == 0 -- stopped
	then -- delete track; works even if the track has been deselected
	local del = r.ValidatePtr(tr, 'MediaTrack*') and r.DeleteTrack(tr) -- a safeguard from error in case track had been manually deleted before transport was stopped
	play = nil -- reset
	end

r.PreventUIRefresh(-1) -- meant to obscure TCP height decrease // only works if applied to the entire deferred function

r.defer(render_monitor)

end


local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()

r.SetToggleCommandState(sect_ID, cmd_ID, 1)
r.RefreshToolbar(cmd_ID)

render_monitor()

r.atexit(function() r.SetToggleCommandState(sect_ID, cmd_ID, 0); r.RefreshToolbar(cmd_ID) end)





