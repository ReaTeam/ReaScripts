--[[
ReaScript name: Navigate to track send destination or receive source track via menu
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	As far as going to send destination track is concerned 
        the script is an alternative to the native feature 
        accessible in the TCP/MCP send slot right click menu. 
        It lists all send destinations in a single menu along 
        with their basic information.

        In addition the script provides a facility to go to 
        receive source tracks which isn't available natively.

        The menu lists send destination / receive source track
        index, name (if any), number of sends/receives routed
        from/to the given track, whether send destination / receive 
        source track is a child in a collapsed folder (-c) and 
        whether it's hidden in the currently active context (-h) 
        which is either the Arrange view or the Mixer.

        The currently active context is determined by the Mixer
        visibility. If visible the target track will be scrolled
        to in the Mixer, otherwise it will be scrolled to in 
        the Arrange view.

        When the script is run via a shortcut, it displays
        sends/receives menu of a track under mouse cursor.
        A click on the send or receive menu item makes the tracklist
        scroll to the corresponding track and select it.
        In the Mixer such track ends up at the leftmost position,
        in the Arrange view - in the middle of the tracklist. 

        If the send destination / receive source track happens to 
        be inside a collapsed folder in the Mixer, its parent or the 
        leftmost visible grandparent track of a collapsed folder its 
        parent is a child in (if any) is scrolled into view instead.  
        If the track is visible in the Mixer and happens to be in a
        collapsed folder whose parent track is hidden, the leftmost
        visible grandparent track of a collapsed folder its parent
        is a child in (if any) is scrolled into view.  
        The send destination / receive source track is selected even
        if its (grand)parents are scrolled into view, so in case it's 
        inside a collapsed folder it's easy to pick it out after 
        uncollapsing the folder.  

        If there's no track under mouse cursor the script looks 
        for the first selected track. Thus it can also be run from 
        a toolbar or a menu in which case the relevant track must 
        be selected.

        If there're more than one send to or receive from 
        a particular track, the total of such sends/receives 
        is displayed in square brackets next to the destination 
        track entry in the menu. This if purely for information.

        To close the menu without action click elsewhere with 
        the mouse or click 'Esc' key on the keyboard or click 
        'close' menu item at the bottom.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- To enable the following settings insert any alphanumeric character
-- between the quotes.

-- Enable this setting to permanently 
-- prevent USER SETTINGS reminder pop-up
REMINDER_OFF = ""

-- Both settings are valid if both are filled out or both are empty;
-- it's recommended to have both valid because this will allow easy
-- navigation between send/receive source and destination tracks
LIST_SENDS = ""
LIST_RECEIVES = ""

-- The following settings are supported in REAPER builds 6.37 and later;

-- if enabled, when the Mixer context is active
-- the menu will only be called if the mouse cursor
-- hovers over the MCP send list,
-- in all other cases it's enough that it hover over the track
DISPLAY_OVER_SEND_LIST = ""

-- if enabled, when the Arrange view context is active
-- the menu will only be called if the mouse cursor
-- hovers over the TCP I/O button,
-- in all other cases it's enough that it hover over the track
DISPLAY_OVER_IO_BUTTON = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function Reminder_Off(REMINDER_OFF)
	local function gap(n) -- number of repeats, integer
	local n = not n and 0 or tonumber(n) and math.abs(math.floor(n)) or 0
	return string.rep(' ',n)
	-- return (' '):rep(n)
	end
local _, scr_name, scr_sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local scr_name = scr_name:match('([^\\/]+)%.%w+') -- without path and extension
--local cmd_ID = r.ReverseNamedCommandLookup(cmd_ID) -- to use instead of scr_name // just an idea
local ret, state = r.GetProjExtState(0, scr_name, 'REMINDER_OFF')
	if #REMINDER_OFF:gsub(' ','') == 0 and ret == 0 then
	local resp = r.MB('\t'..gap(7)..'This is to make you aware\n\n'..gap(12)..'that the script includes USER SETTINGS\n\n'..gap(10)..'you might want to tailor to your workflow.\n\n'..gap(17)..'Clicking "OK" disables this prompt\n\n'..gap(8)..'for the current project (which will be saved).\n\n\t'..gap(6)..'To disable it permanently\n\n change the REMINDER_OFF setting inside the script.\n\n   Select it the the Action list and click "Edit action..."', 'REMINDER', 1)
		if resp == 1 then
		r.SetProjExtState(0, scr_name, 'REMINDER_OFF', '1')
		r.Main_SaveProject(0, false) -- forceSaveAsIn false
		return true
		end
	else return true
	end
end



function Error_Tooltip(text)
local x, y = r.GetMousePosition()
--r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
local tr = r.GetTrackFromPoint(x, y)
local time_init = r.time_precise()
r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
	repeat
	until tr and r.time_precise()-time_init >= 0.7 or not tr
end


function Collect_Snds_Rcvs(tr, cat, mixer_vis) -- cat is number: < 0 receives, 0 sends; mixer_vis is booleand
local parm = cat < 0 and 'P_SRCTRACK' or cat == 0 and 'P_DESTTRACK'
local t, menu_t = {}, {''} -- empty string as a placeholder for menu titles, without it table.insert() would have to be used outside of the function instead of simply assigning the title to the field
local dest_tr_init, dest_snd_cnt = nil, 0
	for i = 0, r.GetTrackNumSends(tr, cat)-1 do
	local dest_tr = r.GetTrackSendInfo_Value(tr, cat, i, parm)
--	local mute = r.GetTrackSendInfo_Value(tr, cat, i, 'B_MUTE') == 1 and ' -m' or ''
	local child_of_collapsed_folder = Track_Is_Child_Of_Collapsed_Folder(dest_tr, mixer_vis) and ' -c' or ''
	local is_hidden = not r.IsTrackVisible(dest_tr, mixer_vis) and ' -h' or ''
	local data = child_of_collapsed_folder..is_hidden
		if dest_tr ~= dest_tr_init then
		t[#t+1] = dest_tr
	--	local tr_idx = r.CSurf_TrackToID(dest_tr, true) -- mpcView true // unsuitable since doesn't return index of tracks hidden within collapsed folders
		local tr_idx = (r.GetMediaTrackInfo_Value(dest_tr, 'IP_TRACKNUMBER')..''):match('(.+)%.') -- truncate trailing decimal 0
		local ret, name_generic = r.GetTrackName(dest_tr) -- difficult to evaluate alone since ret is true even without custom name
		local ret, name = r.GetSetMediaTrackInfo_String(dest_tr, 'P_NAME', '', false) -- setNewValue false
		local name = #name > 0 and tr_idx..'  '..name or name_generic -- if no name the format is "Track N"
		menu_t[#menu_t+1] = name..'|'
		dest_tr_init = dest_tr
		dest_snd_cnt = 1
		else -- update count for the dest track in the menu entry
		dest_snd_cnt = dest_snd_cnt+1
		local entry = menu_t[#menu_t]
		local name = entry:match('(.+) %[') or entry:match('(.+)|') -- entry with snd/rcv count or the very first entry
		menu_t[#menu_t] = name..' ['..dest_snd_cnt..']'..(data or '')..'|' -- the data is always added to the end of the menu entry
		end

	end

	if #t > 0 then return t, menu_t end

end


local function GetObjChunk(obj)
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua
		if not obj then return end
local tr = r.ValidatePtr(obj, 'MediaTrack*')
local item = r.ValidatePtr(obj, 'MediaItem*')
local env = r.ValidatePtr(obj, 'TrackEnvelope*') -- works for take envelope as well
  -- Try standard function -----
	local t = tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
	local ret, obj_chunk = table.unpack(t)
	-- OR
	-- local ret, obj_chunk = table.unpack(tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} or {x,x}) -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
		if ret and obj_chunk and #obj_chunk >= 4194303 and not r.APIExists('SNM_CreateFastString') then return 'err_mess'
		elseif ret and obj_chunk and #obj_chunk < 4194303 then return ret, obj_chunk -- 4194303 bytes (4.194303 Mb) = (4096 kb * 1024 bytes) - 1 byte // since build 4.20 http://reaper.fm/download-old.php?ver=4x
		end
-- If chunk_size >= max_size, use wdl fast string --
	local fast_str = r.SNM_CreateFastString('')
		if r.SNM_GetSetObjectState(obj, fast_str, false, false) -- setnewvalue and wantminimalstate = false
		then obj_chunk = r.SNM_GetFastString(fast_str)
		end
	r.SNM_DeleteFastString(fast_str)
		if obj_chunk then return true, obj_chunk end
end


function Get_Parent_Of_MCP_First_Uncollapsed_Folder(tr)
-- tr argument is a pointer of a track to scroll to, if it happens to be a child of a collapsed folder
-- return its parent track or first (from the left) uncollapsed parent of a nested folder
-- (which itself is a parent of a collapsed folder)
-- relies on GetObjChunk() function

-- Collect all parents of the found track to then find the first (leftmost) uncollapsed if any
local parent = r.GetParentTrack(tr)
local parents_t = {}
	for i = r.CSurf_TrackToID(tr, false)-2, 0, -1 do -- in reverse // mcpView false, allows to get it even if it's hidden in a collapsed folder // -2 to start from immediatedly preceding track as CSurf_TrackToID returns 1-based track index which is greater than the 0-based by 1
	local tr = r.GetTrack(0,i)
		if tr == parent --and r.IsTrackVisible(tr, true) -- mixer true
		then -- and itself has a parent
		parents_t[#parents_t+1] = tr -- in the table the leftmost track is at the end
		parent = r.GetParentTrack(tr)
		end
	end
	-- Find the leftmost uncollapsed parent, if any ((un)collapsing Mixer tracks must be done via chunk which is too cumbersome and isn't worth the effort for this script)
	for i = #parents_t, 1, -1 do -- in reverse since parent tracks were stored from right to left; if the table is empty the loop won't start
	local parent_tr = parents_t[i]
	local ret, chunk = GetObjChunk(parent_tr)
		if ret ~= 'err_mess' -- if parent track chunk is larger than 4.194303 Mb and no SWS extension to handle that to find out if it's collapsed
		and chunk:match('BUSCOMP %d (%d)') == '1' then -- collapsed
		return parent_tr -- as soon as uncollapsed parent is found
		end
	end

end


function Track_Is_Child_Of_Collapsed_Folder(tr, wantMixer) -- wantMixer is boolean // in the script is only used for Arrange track evaluation
	local function get_first_collapsed_tcp_fldr(tr)
	local parent = r.GetParentTrack(tr)
		if parent and r.GetMediaTrackInfo_Value(parent, 'I_FOLDERCOMPACT') == 2 -- tiny children
		then return parent -- found // for the Mixer the return value is only used as a boolean to then run Get_First_MCP_Uncollapsed_ParentTrack(), for the Arrange the return value is used for scrolling to the parent
		elseif parent then -- continue evaluation
		return get_first_collapsed_tcp_fldr(parent)
		end
	end
return wantMixer and r.CSurf_TrackToID(tr, true) == -1 -- mcpView true // when the track is inside a collaped MCP folder the function doesn't return its index // r.GetMediaTrackInfo_Value(tr, 'IP_TRACKNUMBER') doesn't work this way so not suitable
or not wantMixer and get_first_collapsed_tcp_fldr(tr)
end


	if not Reminder_Off(REMINDER_OFF) then return r.defer(function() do return end end) end


LIST_SENDS = #LIST_SENDS:gsub(' ','') > 0
LIST_RECEIVES = #LIST_RECEIVES:gsub(' ','') > 0
BOTH = not LIST_SENDS and not LIST_RECEIVES or LIST_SENDS and LIST_RECEIVES
DISPLAY_OVER_SEND_LIST = #DISPLAY_OVER_SEND_LIST:gsub(' ','') > 0
DISPLAY_OVER_IO_BUTTON = #DISPLAY_OVER_IO_BUTTON:gsub(' ','') > 0
local supported_build = tonumber(r.GetAppVersion():match('(.+)/')) >= 6.37

local mixer_vis = r.GetToggleCommandStateEx(0,40078) == 1 -- View: Toggle mixer visible // when docked and the docker is closed the state is OFF so 'View: Show docker' toggle state doesn't need to be additionally evaluated
local x, y = r.GetMousePosition()
local tr, idx = r.GetTrackFromPoint(x, y)
local tr_pointer, elm = table.unpack(supported_build and {r.GetThingFromPoint(x, y)} or {nil})
local over_sendlist = elm == 'mcp.sendlist'
local over_io_button = elm == 'tcp.io'
local tr = not tr and r.GetSelectedTrack(0,0) or tr

	if not tr then Error_Tooltip('\n\n no valid track \n\n') return r.defer(function() do return end end)
	elseif r.GetTrackFromPoint(x, y) and supported_build and (mixer_vis and DISPLAY_OVER_SEND_LIST and not over_sendlist
	or not mixer_vis and DISPLAY_OVER_IO_BUTTON and not over_io_button)
	then return r.defer(function() do return end end)
	end

	if LIST_SENDS or BOTH then
	snd_t, snd_menu_t = Collect_Snds_Rcvs(tr, 0, mixer_vis)
		if snd_menu_t then snd_menu_t[1] = 'Sends:||' end
	end

	if LIST_RECEIVES or BOTH then
	rcv_t, rcv_menu_t = Collect_Snds_Rcvs(tr, -1, mixer_vis)
		if rcv_menu_t then rcv_menu_t[1] = 'Receives:||' end
	end

local sep = snd_menu_t and rcv_menu_t and '|' or ''
local esc = (snd_menu_t or rcv_menu_t) and '|c l o s e' or ''
local menu = (snd_menu_t and table.concat(snd_menu_t) or '')..sep..(rcv_menu_t and table.concat(rcv_menu_t) or '')..esc

	if #menu > 0 then
	local tr_idx = math.floor(r.GetMediaTrackInfo_Value(tr, 'IP_TRACKNUMBER')) -- to truncate decimal 0 // OR (r.GetMediaTrackInfo_Value(tr, 'IP_TRACKNUMBER')..''):match('(.+)%.')
	gfx.init('',0,0)
	gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
	local idx = gfx.showmenu('#Track # '..tr_idx..'||'..menu)
		if idx > 2 then -- 2 to account for 'Track #' menu title and a submenu title which don't have corresponding fields in snd_t and rcv_t tables, otherwise click on these menu entrues may produce an error
		local idx = idx-2 -- -2 to restore the index count valid for snd_t and rcv_t tables
		local tr = snd_t and rcv_t and (idx <= #snd_t and snd_t[idx] or idx > #snd_t and rcv_t[idx-#snd_t-1]) -- when idx > #snd_t it's either corresponds to receive menu title or to rcv_t fields hence -1 to explude the title
		or snd_t and snd_t[idx] or rcv_t and rcv_t[idx]

			if tr then -- tr var can be nil if 'close' menu item has been selected

			local tr_upd = mixer_vis and (Get_Parent_Of_MCP_First_Uncollapsed_Folder(tr) or tr) or not mixer_vis and (Track_Is_Child_Of_Collapsed_Folder(tr) or tr) -- if track is a folder child scroll to its leftmost uncollapsed parent (to the leftmost parent of a collapsed folder who itself is not collapsed) if it's a child of a nested collapsed folder in the Mixer, in Arrange even when the folder is collapsed to tiny children selected track is still visible hence in Arrange scrolls to the actual track in the middle of the tracklist // tr_upd can be either the same tr or its parent

			local tr_vis = r.IsTrackVisible(tr, mixer_vis)
			local tr_upd_vis = r.IsTrackVisible(tr_upd, mixer_vis)
			local parent = r.GetParentTrack(tr)
			local tr_parent_vis = parent and r.IsTrackVisible(parent, true) -- mixer true

			-- IF TRACK IS HIDDEN AND A CHILD IN ARRANGE OR IN A COLLAPSED FOLDER IN MIXER NO SCROLLING TO ITS PARENT OR FIRST VISIBLE COLLAPSED GRANDPARENT
			-- otherwise always select the original track even if scrolling to its parent, so that when the folder is uncollapsed it's clear what the destinaition track is
				if mixer_vis and tr_vis then -- only scroll to the track be it the target track or its parent if it's visible in the Mixer; if the track is visible while being a child in a collapsed folder whose parent is hidden (wich hides all its children), scroll to the first visible grandparent whose folder is collapsed
					if tr ~= tr_upd and not tr_upd_vis --or not tr_parent_vis
					then
					Error_Tooltip('\n\n the track parent is hidden \n\n') -- track is visible and inside a collapsed folder whose parent is hidden, unlike in the Arrange in the Mixer such children tracks aren't visible
					return r.defer(function() do return end end) end
				r.SetMixerScroll(tr_upd)
				r.SetOnlyTrackSelected(tr)
				elseif not mixer_vis and tr_vis then
					if tr ~= tr_upd and not tr_upd_vis then Error_Tooltip('\n\nthe track (grand)parent is hidden\n\n') end -- track is visible and inside a collapsed folder whose parent is hidden
				r.SetOnlyTrackSelected(tr)
				r.Main_OnCommand(40913,0) -- Track: Vertical scroll selected tracks into view
				end

				if err and tr ~= tr_upd and (not tr_upd_vis or not tr_parent_vis) then
				local err = mixer_vis and 'the track and its parent \n\n          are hidden' or 'the track parent is hidden'
				Error_Tooltip('\n\n '..err..' \n\n') -- when parent of a collapsed folder is hidden
				elseif not tr_vis then Error_Tooltip('\n\n the track is hidden \n\n') end

			end
		end
	gfx.quit()
	else
		if BOTH then mess = 'no sends and no receives'
		else
			if LIST_SENDS then mess = 'no sends'
			elseif LIST_RECEIVES then mess = 'no receives'
			end
		end
	Error_Tooltip('\n\n '..mess..' \n\n')
	end


do return r.defer(function() do return end end) end




