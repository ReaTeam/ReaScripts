--[[
ReaScript name: Mute empty tracks with FX and optionally set their FX offline
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About:	Mutes tracks with FX and no items, optionally sets their FX offline
	and optionally unmutes and brings FX back online.
	Ignores empty tracks which are record armed, folder parent and have receives.
	Can work in manual and in auto modes.
]]
-----------------------------------------------------------------------------
--------------------------- USER GUIDE and SETTINGS -------------------------
--[[-------------------------------------------------------------------------

By default the script mutes all tracks with FX and without items as long as
they're not record armed, not folder parents and don't have receives.
If an empty track with FX is unmuted manually or otherwise, its mute will be
reinstated on the next run of the script manually or, if the script runs
in AUTO_RUN mode (see par. 3 below), as soon as any other track becomes
suitable for muting or unmuting with this script, depending on the settings,
and as long as such track status hasn't changed to being armed, folder parent
or to having receives.
When UNMUTE setting is not enabled the mute will be reinstated automatically
when another track with FX becomes empty or receives items or track total
count changes. When UNMUTE setting is enabled the mute will be also reinstated
when another track becomes armed, folder parent or gets receives.
If a track is no longer empty or no longer has FX its mute won't be reinstated.
In AUTO_RUN mode the mute can be persistent if MUTE_PERSIST setting
is enabled (see par. 4 below).

1. Enable SET_FX_OFFLINE setting to set FX of empty tracks offline in
addition to muting them. May be useful when 'Do not process muted tracks'
setting isn't enabled at Preferences -> Audio -> Mute/Solo.
Like mute, offline state of FX on a track without items, if disabled manually,
will be re-enabled on the next manual script run or when any other track
becomes suitable for muting or unmuting (depending on the settings) with
this script in AUTO_RUN mode.
How UNMUTE setting impacts reinstating FX offline state see paragraph above
mutatis mutandis.
This also applies to FX newly added to such track which aren't set offline
automatically. All this is true unless SET_FX_OFFLINE_PERSIST setting
is enabled (see par. 4 below).

2. Enable UNMUTE setting to unmute any tracks previously muted with this
script when their FX are removed, items are added to them, when they become
record armed, folder parent or get receives. If their FX where set offline,
these are brought back online along with unmuting. FX are being brought back
online regardless of whether they were originally set offline with this script
or manually or by other means.

3. When AUTO_RUN setting is enabled the script does its thing automatically,
otherwise to change the mute state of tracks with FX and no items the script
needs to be run manually.
When the script works in AUO_RUN mode and is assigned to a toolbar button
the button is lit.
Since in AUTO_RUN mode the script consumes some CPU resources, especially
with all settings enabled, it'd be prudent to ascertain that using it is
advantageous over simply leaving tracks unmuted and their FX online or
running the script manually.

4. Enable MUTE_PERSIST setting to prevent unmuting tracks with FX and no items
and/or SET_FX_OFFLINE_PERSIST to prevent bringing FX of such tracks online
on the one hand and to immediately put offline any newly added FX on the other
while SET_FX_OFFLINE setting is enabled.
These settings are only relevant for AUTO_RUN mode.

To enable a setting insert any alphanumeric character between quotation marks.

]]

SET_FX_OFFLINE = ""
UNMUTE = ""
AUTO_RUN = ""

-- Only in AUTO_RUN mode:

MUTE_PERSIST = ""
SET_FX_OFFLINE_PERSIST = "" -- only when SET_FX_OFFLINE is enabled

-----------------------------------------------------------------------------
------------------------ END OF USER GUDE and SETTINGS ----------------------
-----------------------------------------------------------------------------


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function Check_reaper_ini(key,value) -- the args must be strings
local f = io.open(r.get_ini_file(),'r')
local cont = f:read('a*')
f:close()
return cont:match(key..'=(%d+)') == value
end


function store_empty_tracks()
local t = {}
	for i = 0, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
	local no_items_and_fx = r.GetTrackNumMediaItems(tr) == 0 and r.TrackFX_GetCount(tr) + r.TrackFX_GetRecCount(tr) > 0
	local armed = r.GetMediaTrackInfo_Value(tr, 'I_RECARM') == 1
	local folder = r.GetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH') == 1 and i ~= r.CountTracks(0)-1 -- not last track
	local has_receives = r.GetTrackNumSends(tr, -1) > 0 -- -1 stands for receives
		if not UNMUTE and no_items_and_fx -- makes sure unmuted empty tracks aren't muted automatically when other tracks become armed, folder parent or get receives, that's what the next condition does when UNMUTE setting is on
		or no_items_and_fx and not armed and not folder and not has_receives 
		then
		t[#t+1] = tostring(tr) -- to match extended state table values data type
		end
	end
local set_state = not AUTO_RUN and r.SetExtState(cmd_ID, 'muted_tracks', table.concat(t, ';'), false) -- persist is false
return AUTO_RUN and t or list_2_table(r.GetExtState(cmd_ID, 'muted_tracks'),'(userdata: [%w]+);?')
end


function list_2_table(str, pattern) -- pattern e.g. '(%d+);?' to extract semicolon delimited numbers;
local counter = str -- a safety measure to avoid accidental ovewriting the orig. string, although this shouldn't happen thanks to %0
local counter = {counter:gsub(pattern, '%0')} -- 2nd return value is the number of replaced captures
local t = {str:match(string.rep(pattern, counter[2]))} -- captures the pattern as many times as there're pattern repetitions in the string
return t, counter[2] -- second return value holds number of captures
end


function toggle_track_fx_off_online(tr, ON) -- ON arg is provisional, only used to set fx online
local set = not ON -- set to OFF else to ON
local change_cntr = 0
	for i = 0, r.TrackFX_GetCount(tr)-1 do
		if r.TrackFX_GetOffline(tr, i) ~= set then r.TrackFX_SetOffline(tr, i, set); change_cntr = change_cntr + 1 end
	end
	for i = 0, r.TrackFX_GetRecCount(tr)-1 do
		if r.TrackFX_GetOffline(tr, 0x1000000+i) ~= set then r.TrackFX_SetOffline(tr, 0x1000000+i, set); change_cntr = change_cntr + 1 end
	end
return change_cntr > 0 -- to condition undo in the main function
end


function persist(t) -- for updating tracks
	for i = 0, r.CountTracks(0)-1 do -- have to traverse all tracks since track pointer in the table is a string to match extended state data type used for manual mode, so a track can't be gotten by using the table value as it is
	local tr = r.GetTrack(0,i)
		for k, v in ipairs(t) do
			if tostring(tr) == v then
			local armed = r.GetMediaTrackInfo_Value(tr, 'I_RECARM') == 1 -- record armed
			local folder = r.GetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH') == 1 and i ~= r.CountTracks(0)-1 -- folder parent and not last track // OR has_child_tracks(tr) which is more expensive
			local has_receives = r.GetTrackNumSends(tr, -1) > 0 -- got receives // -1 stands for receives
				if MUTE_PERSIST and not armed and not folder and not has_receives and r.GetMediaTrackInfo_Value(tr, 'B_MUTE') == 0 then
				r.SetMediaTrackInfo_Value(tr, 'B_MUTE', 1) -- mute
				end
				if SET_FX_OFFLINE and SET_FX_OFFLINE_PERSIST then
					for i = 0, r.TrackFX_GetCount(tr)-1 do
						if not r.TrackFX_GetOffline(tr, i) then r.TrackFX_SetOffline(tr, i, true) end -- fx have been added or set online
					end
					for i = 0, r.TrackFX_GetRecCount(tr)-1 do
						if not r.TrackFX_GetOffline(tr, 0x1000000+i) then r.TrackFX_SetOffline(tr, 0x1000000+i, true) end -- fx have been added or set online
					end
				end
			end
		end
	end
end


function MUTE()

	if AUTO_RUN then
		if r.CountTracks(0) ~= tr_cnt then -- track total count changes
		tr_cnt = r.CountTracks(0); update = true
		elseif #store_empty_tracks() ~= #stored -- store empty tracks with fx // items are added/removed, track becomes armed, folder parent, gets receives, fx are removed or new fx are added
		then update = true
		elseif SET_FX_OFFLINE_PERSIST or MUTE_PERSIST then persist(stored)
		end
	end


	if update then
	local undo	
	r.Undo_BeginBlock()
	local change_cnt = r.GetProjectStateChangeCount(0)
		for i = 0, r.CountTracks(0)-1 do
		local tr = r.GetTrack(0,i)
		local fx = r.TrackFX_GetCount(tr) + r.TrackFX_GetRecCount(tr) > 0
		local no_items = r.GetTrackNumMediaItems(tr) == 0
		local armed = r.GetMediaTrackInfo_Value(tr, 'I_RECARM') == 1
		local folder = r.GetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH') == 1 and i ~= r.CountTracks(0)-1 -- not last track
		local has_receives = r.GetTrackNumSends(tr, -1) > 0 -- -1 stands for receives
			 if no_items and fx and not armed and not folder and not has_receives then
				if r.GetMediaTrackInfo_Value(tr, 'B_MUTE') == 0 then r.SetMediaTrackInfo_Value(tr, 'B_MUTE', 1); undo = true end
				if SET_FX_OFFLINE then change = toggle_track_fx_off_online(tr) -- set fx offline
				undo = change or undo end
			 end
			 if UNMUTE then
				for k, v in ipairs(stored) do
					if tostring(tr) == v and (not no_items or not fx or armed or folder or has_receives) then -- unmute track previously muted with the script if fx are removed or items are added or it becomes armed, folder parent or gets receives
						if r.GetMediaTrackInfo_Value(tr, 'B_MUTE') == 1 then r.SetMediaTrackInfo_Value(tr, 'B_MUTE', 0); undo = true end
						if SET_FX_OFFLINE then change = toggle_track_fx_off_online(tr, 1) -- 1 is ON // set fx online
						undo = change or undo end
					end
				end
			end
		end
	-- only register undo when something has changed
	local undo = undo and string.format('Mute%s empty tracks with FX %s', (UNMUTE and '/unmute' or ''), (SET_FX_OFFLINE and string.format('and set their FX offline%s', (UNMUTE and '/online' or '')) or '')) or ''
	r.Undo_EndBlock(undo,-1)
	stored = (AUTO_RUN and update or not AUTO_RUN) and store_empty_tracks() or stored -- update the table when update is true otherwise maintain it
	update = false -- reset initial value so it can be set to true when conditions are met; must be global
	end

local run = AUTO_RUN and r.defer(MUTE)

end


SET_FX_OFFLINE = #SET_FX_OFFLINE:gsub(' ','') > 0


	if not Check_reaper_ini('norunmute','1') and not SET_FX_OFFLINE then resp = r.MB('\tREAPER isn\'t currently set to NOT process\n\n        muted tracks at Preferences -> Audio -> Mute/Solo.\n\nNeither is "SET_FX_OFFLINE" setting enabled inside the script.\n\n\t    So muting may not be of much use.\n\n\t     Do you still wish to run the script?', 'PROMPT', 4)
		if resp == 7 then return r.defer(function() end) end
	end


sect_ID = ({r.get_action_context()})[3]
cmd_ID = ({r.get_action_context()})[4]
AUTO_RUN = #AUTO_RUN:gsub(' ','') > 0
UNMUTE = #UNMUTE:gsub(' ','') > 0
MUTE_PERSIST = #MUTE_PERSIST:gsub(' ','') > 0
SET_FX_OFFLINE_PERSIST = #SET_FX_OFFLINE_PERSIST:gsub(' ','') > 0

local ext_state = r.GetExtState(cmd_ID, 'muted_tracks')
stored = not AUTO_RUN and #ext_state > 0 and list_2_table(ext_state,'(userdata: [%w]+);?') or store_empty_tracks() -- store muted tracks in a table; when not in auto run mode, get table from extended state as long as there's one to avoid creating new table each time which will prevent evaluation of tracks for unmute if enabled
tr_cnt = r.CountTracks(0)
update = true -- to facilitate initial mute when AUTO_RUN is on before any other conditions are true and affect tracks in manual mode

	if AUTO_RUN then
	r.SetToggleCommandState(sect_ID, cmd_ID, 1)
	r.RefreshToolbar(cmd_ID)
	end

MUTE()

	if AUTO_RUN then r.atexit(function() r.SetToggleCommandState(sect_ID, cmd_ID, 0); r.RefreshToolbar(cmd_ID) end) end


