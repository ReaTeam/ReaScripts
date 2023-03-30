--[[
ReaScript Name: Insert selected FX or FX chain preset in OR copy focused FX to selected objects
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.5
Licence: WTFPL
REAPER: v6.12c+ recommended
Changelog:	#Fixed a bug of copying take FX to the same FX chain
		#Added support for copying FX envelopes along with FX
		#Implemented a workround to the API bug which causes an FX chain window to close when 
		'Only allow one FX chain window at a time' setting is enabled in Preferences
		#Added support for accessing FX from a menu
About:		——  To insert FX or FX chain preset in multiple objects (tracks and/or items) at once open the FX 
		Browser, select FX or FX chain preset, as many as needed, select the destination objects and run 
		the script. <<<< This feature exists natively since build 6.12c, in this respect the script is
		only useful when inserting FX or FX chain in input/Monitoring FX chains which aren't supported
		by the native feature.

		—— To copy FX to multiple objects at once select an FX in an open and focused FX chain or focus
		its floating window, select the destination objects and run the script.  
		Alternatively run the script with a shortcut pointing the mouse cursor at a track or a take, 
		in which case it will evoke a menu of FX currently present in the FX chain of the object under mouse 
		cursor and click the menu item holding the name of the FX which needs to be copied.   
		FX menu takes precedence over the open FX chain.  
		In the track FX menu if both main and input FX chains are populated their FX are separated 
		by a divider.

		—— If a destination item contains more than one take the FX is copied to its active take FX chain.
		Take FX of multi-take items can be copied to the active take of the same item.

		—— Inserting FX or FX chain preset in / copying FX to Monitor FX chain cannot be undone because 
		the data gets written by the program to an external file and stored there.

		—— In the USER SETTINGS you can disable objects which you don't want FX or FX chain preset to be 
		inserted in or FX copied to.
		This is useful for avoiding accidental adding FX or FX chain presets to objects which were 
		unintentionally selected.
		You can create a copy of the script with a slightly different name and dedicate each copy to
		inserting FX or FX chain preset in / copying FX to objects of specific kind determined by the 
		USER SETTINGS.
		If default settings are kept it may be useful to run actions 'Item: Unselect all items' or
		'Track: Unselect all tracks' after destination object has been selected, to exclude objects of
		an unwanted type. On the other hand when inserting/copying FX on/to selected objects of different
		types it may be useful to run the abovementioned actions before making the selection.

		—— Track main and input FX chains are treated by the script independently. So each one can be
		disabled without another being affected. It's only when they both are turned off in the USER
		SETTINGS that FX cannot be inserted in or copied to any track.

		—— TRACK_INPUT_MON_FX option affects both Input and Monitor FX chains.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- To disable any of the options remove the character between the quotation
-- marks next to it.
-- Conversely, to enable one place any alphanumeric character between those.
-- Try to not leave empty spaces.

TRACK_MAIN_FX = "1"
TRACK_INPUT_MON_FX = "1"
TAKE_FX = "1"

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


local r = reaper


function Check_reaper_ini(key) -- the arg must be a string
local f = io.open(r.get_ini_file(),'r')
local cont = f:read('a*')
f:close()
return cont:match(key..'=(%d+)')
end


local function GetMonFXProps() -- get mon fx accounting for floating window, reaper.GetFocusedFX() doesn't detect mon fx in builds prior to 6.20

-- r.TrackFX_GetOpen(master_tr, integer fx)
	local master_tr = r.GetMasterTrack(0)
	local src_mon_fx_idx = r.TrackFX_GetRecChainVisible(master_tr)
	local is_mon_fx_float
		if src_mon_fx_idx < 0 then -- fx chain closed or no focused fx -- if this condition is removed floated fx gets priority
			for i = 0, r.TrackFX_GetRecCount(master_tr) do
				if r.TrackFX_GetFloatingWindow(master_tr, 0x1000000+i) then
				src_mon_fx_idx = i; is_mon_fx_float = true break end
			end
		end
	return src_mon_fx_idx, is_mon_fx_float
end


function FX_menu(tr, take)
local FXCount, GetFXName = table.unpack(take and {r.TakeFX_GetCount, r.TakeFX_GetFXName}
or tr and {r.TrackFX_GetCount, r.TrackFX_GetFXName} or {})
local obj = take or tr
	if obj then
	local menu = ''
		for i=0, FXCount(obj)-1 do
		local ret, name = GetFXName(obj, i, '')
		local name = name:match(': (.+)[%(%[]') or name -- strip off plugin prefix and dev or path (for JSFX) suffix of default name format
		menu = menu..(i == 0 and '' or '|')..name
		end
		if tr and r.TrackFX_GetRecCount(tr) > 0 then
		menu = menu..(#menu > 0 and '||' or '|')
			for i=0,r.TrackFX_GetRecCount(tr)-1 do
			local ret, name = GetFXName(obj, i+0x1000000, '')
			local name = name:match(': (.+)[%(%[]') or name
			menu = menu..'|'..name
			end
		end
		if #menu > 0 then
		local x, y = r.GetMousePosition()
		gfx.init('',0,0)
		gfx.x, gfx.y = x, y
		local output = gfx.showmenu(menu)
			if output == 0 then return end
		local main_fx_cnt = FXCount(obj)
		local fx_idx = output > main_fx_cnt and output-main_fx_cnt-1+0x1000000 or output-1 -- regular fx or input/monitoring; -1 to convert 1-based menu index to fx 0-base fx index
		return fx_idx
		end
	end
end



function FX_Has_Envelopes(take, tr, fx_idx)
local obj = take or tr
local GetNumParams, GetFXEnvelope = table.unpack(take and
{r.TakeFX_GetNumParams,r.TakeFX_GetEnvelope}
or tr and {r.TrackFX_GetNumParams, r.GetFXEnvelope})
	for i = 0, GetNumParams(obj,fx_idx)-1 do
	local env = GetFXEnvelope(obj, fx_idx, i, false) -- create false
		if env and (r.ValidatePtr(env, 'TrackEnvelope*')
		or r.CountEnvelopePoints(env) > 0)
		then return true
		end
	end
end


function re_store_obj_selection(t1, t2)
	if not t1 and not t2 then
	local t1, t2 = {}, {}
		for i = 0, r.CountSelectedTracks2(0,true) do -- plus Master, wantmaster true
		t1[#t1+1] = r.GetSelectedTrack2(0,i,true) -- plus Master, wantmaster true
		end
		for i = 0, r.CountSelectedMediaItems(0)-1 do
		t2[#t2+1] = r.GetSelectedMediaItem(0,i)
		end
	return #t1 > 0 and t1, #t2 > 0 and t2
	else
		r.SetOnlyTrackSelected(r.GetMasterTrack(0))
		r.SetTrackSelected(r.GetMasterTrack(0),false) -- unselect Master
		if t1 then
			for _, tr in ipairs(t1) do
			r.SetTrackSelected(tr, true) -- selected true
			end
		end
		r.SelectAllMediaItems(0, false) -- selected false // deselect all
		if t2 then
			for _, itm in ipairs(t2) do
			r.SetMediaItemSelected(itm, true) -- selected true
			end
		end
	end
end


function Re_Store_Options_Togg_States(state1, state2) -- to disable and store run without the args to be on the safe side
	if not state1 and not state2 then
	local state1 = r.GetToggleCommandStateEx(0,40070) == 1 -- Options: Move envelope points with media items
		if state1 then r.Main_OnCommand(40070,0) end -- disable
	local state2 = r.GetToggleCommandStateEx(0,41117) == 1 -- Options: Trim content behind media items when editing
		if state2 then r.Main_OnCommand(41117,0) end -- disable
	return state1, state2
	else
	local re_enable = state1 and r.Main_OnCommand(40070,0)
	local re_enable = state2 and r.Main_OnCommand(41117,0)
	end
end


function Multiply_Src_And_MoveFX_plus_Envelopes(take, tr, fx_idx, sel_trk_cnt, sel_itms_cnt, pos)

local obj = take or tr
r.PreventUIRefresh(1)

local sel_tr_t, sel_itm_t = re_store_obj_selection() -- store current track/item selection since duplication interferes with selection

-- insert temp track
r.InsertTrackAtIndex(r.GetNumTracks(), false) -- wantDefaults false; insert new track at end of track list and hide it; action 40702 'Track: Insert new track at end of track list' creates undo point hence unsuitable
local temp_tr = r.GetTrack(0,r.CountTracks(0)-1)
r.SetMediaTrackInfo_Value(temp_tr, 'B_SHOWINMIXER', 0) -- hide in Mixer
r.SetMediaTrackInfo_Value(temp_tr, 'B_SHOWINTCP', 0) -- hide in Arrange

-- Duplicate source object to move the fx instance with env to a temp track from it
-- because copying with envelope isn't supported by the API
local src_itm = take and r.GetMediaItemTake_Item(take)
	if take then
	r.SelectAllMediaItems(0, false) -- selected false // deselect all
	r.SetMediaItemSelected(src_itm, true) -- selected true
	local state1, state2 = Re_Store_Options_Togg_States() -- disable if enabled
	local edit_curs_pos = r.GetCursorPosition() -- store, because item duplication may move it if Preferences -> Editing Behavor -> Move edit cursor when pasting/insering media is enabled
	r.Main_OnCommand(41295,0) -- Item: Duplicate items
	local temp_itm = r.GetSelectedMediaItem(0,0)
	local temp_take = r.GetActiveTake(temp_itm)
	r.TakeFX_CopyToTrack(temp_take, fx_idx, temp_tr, 0, true) -- is_move true
	r.DeleteTrackMediaItem(r.GetMediaItemTrack(temp_itm), temp_itm)
	Re_Store_Options_Togg_States(state1, state2) -- re-enable if were enabled
	r.SetEditCurPos(edit_curs_pos, false, false) -- moveview, seekplay false // restore
	elseif tr then
	r.SetOnlyTrackSelected(tr) -- deselect all
	r.Main_OnCommand(40062, 0) -- Track: Duplicate tracks
	local tr = r.GetSelectedTrack(0,0)
	r.SetMediaTrackInfo_Value(temp_tr, 'B_SHOWINMIXER', 0) -- hide in Mixer
	r.SetMediaTrackInfo_Value(temp_tr, 'B_SHOWINTCP', 0) -- hide in Arrange
	r.TrackFX_CopyToTrack(tr, fx_idx, temp_tr, 0, true) -- is_move true
	r.DeleteTrack(tr)
	end


re_store_obj_selection(sel_tr_t, sel_itm_t) -- restore original track/item selection

-- duplicate temp track as many time as there're selected objects to which FX should be moved to simulate copying with envelopes
r.SetOnlyTrackSelected(temp_tr)
local sel_trk_cnt = TRACK_MAIN_FX and TRACK_INPUT_MON_FX and sel_trk_cnt*2
or not TRACK_MAIN_FX and not TRACK_INPUT_MON_FX and 0 or sel_trk_cnt -- multiply by 2 to cover both main and input/monitoring FX chains or disregard if none of the track related settings is enabled
local sel_trk_cnt = r.IsTrackSelected(tr) and sel_trk_cnt-1 or sel_trk_cnt -- exclude source track in case it's selected
local sel_itms_cnt = src_itm and r.IsMediaItemSelected(src_itm) and r.GetActiveTake(src_itm) == take and sel_itms_cnt-1 or sel_itms_cnt -- only exclude selected source item if the source track is active so that in multi-take items FX can be copied to other takes
local tmp_tr_t = {temp_tr} -- store all duplicate tracks to be able to traverse them for moving FX and for convenient deletion
	for i = 1, sel_trk_cnt+sel_itms_cnt do
	r.Main_OnCommand(40062,0) -- Track: Duplicate tracks
	tmp_tr_t[#tmp_tr_t+1] = r.GetSelectedTrack(0,0) -- after duolication the new track is the only selected
	end

re_store_obj_selection(sel_tr_t, sel_itm_t) -- restore original track/item selection

-- move to selected tracks // easier in two loops for targeting the temp tracks
	if TRACK_MAIN_FX then
	local is_move = tr and not take and true -- tr is always valid when take FX is focused as well as the track of the take parent item returned by GetFocusedFX() hence must be validated with take to determine if genuine track FX
		for i = 1, r.CountSelectedTracks2(0,true) do -- wantmaster true
		local sel_tr = r.GetSelectedTrack2(0,i-1,true) -- plus Master, wantmaster true
			if not take and sel_tr ~= tr or take then -- if copying from a track not the source track to prevent copying to itself
			local main_fx_pos = pos == -1 and r.TrackFX_GetCount(sel_tr) or 0
			r.TrackFX_CopyToTrack(tmp_tr_t[i], 0, sel_tr, main_fx_pos, is_move) -- is_move is only true if track FX was originally focused, if take FX - only copy (tr is false) instead of moving with envelopes
			end
		end
	end
	if TRACK_INPUT_MON_FX then
	local sel_tr_cnt = r.CountSelectedTracks2(0,true)
		for i = 1, sel_tr_cnt do -- wantmaster true
		local sel_tr = r.GetSelectedTrack2(0,i-1,true) -- plus Master, wantmaster true
			if not take and sel_tr ~= tr or take then -- if copying from a track not the source track to prevent copying to itself
			local input_fx_pos = pos == -1 and r.TrackFX_GetRecCount(sel_tr)+0x1000000 or 0x1000000
			local tmp_tr = tmp_tr_t[i+sel_tr_cnt] -- if TRACK_MAIN_FX is enabled first temp tracks will be bust because the FX will have been removed from them in the above loop hence offset the table index by the number of bust tracks
			r.TrackFX_CopyToTrack(tmp_tr, 0, sel_tr, input_fx_pos, true) -- is_move true // envelopes are irrelevant here because input/Monitoring FX don't support them
			end
		end
	end
-- move to active takes in selected items
	if TAKE_FX then
	local is_move = take ~= nil and true -- OR 'take and true or false' // 'take ~= nil' or 'or false' is needed because when take is invalid mere 'take and true' produces nil rather than false
		for i = 1, r.CountSelectedMediaItems(0) do
		local act_take = r.GetActiveTake(r.GetSelectedMediaItem(0,i-1))
			if act_take ~= take then -- preventing copying back to the same FX chain it source is a take FX
			local pos = pos == -1 and r.TakeFX_GetCount(act_take) or 0
			local tmp_tr = tmp_tr_t[i+sel_trk_cnt] -- offsetting by the number of selected tracks because if there're selected destination tracks, previous temp tracks stored in the table will be bust after moving FX from them in the loop above
			r.TrackFX_CopyToTake(tmp_tr, 0, act_take, pos, is_move) -- is_move is only true if take FX was originally focused, if track FX - only copy (take is false) instead of moving with envelopes
			end
		end
	end

	-- delete temp tracks
	for _, tr in ipairs(tmp_tr_t) do
	r.DeleteTrack(tr)
	end

r.PreventUIRefresh(-1)

end


local TRACK_MAIN_FX = TRACK_MAIN_FX:gsub('[%s]','') ~= ''
local TRACK_INPUT_MON_FX = TRACK_INPUT_MON_FX:gsub('[%s]','') ~= ''
local TAKE_FX = TAKE_FX:gsub('[%s]','') ~= ''


	local retval, src_trk_num, src_item_num, src_fx_num_focus = r.GetFocusedFX() -- if take fx, item number is index of the item within the track (not within the project) while track number is the track this item belongs to, if not take fx src_item_num is -1, if retval is 0 the rest return values are 0 as well
	local src_trk_focus = r.GetTrack(0, src_trk_num-1) or r.GetMasterTrack(0)
	local src_item_focus = src_trk_num ~= 0 and r.GetTrackMediaItem(src_trk_focus, src_item_num)

	local src_take_focus = retval == 2 and r.GetMediaItemTake(src_item_focus, src_fx_num_focus>>16) -- retval to avoid error when src_item_num = -1 due to track fx chain -- NEW
	local src_mon_fx_idx = GetMonFXProps() -- get Monitor FX
	local sel_trk_cnt = r.CountSelectedTracks2(0,true) -- incl. Master
	local sel_itms_cnt = r.CountSelectedMediaItems(0)
--	local fx_chain = retval > 0 or src_mon_fx_idx >= 0
	local app_ver = tonumber(r.GetAppVersion():match('(.+)/')) > 6.11
	local fx_brws = app_ver and r.GetToggleCommandStateEx(0, 40271) -- View: Show FX browser window
	or 0 -- disable FX browser routine in builds prior to 6.12c where the API doesn't support it

	local x, y = r.GetMousePosition()
	local src_trk = r.GetTrackFromPoint(x,y) or (retval == 1 or src_mon_fx_idx >= 0) and src_trk_focus
	local src_item, src_take = r.GetItemFromPoint(x, y, true) -- allow_locked true
	local src_item, src_take = table.unpack(not src_take and {src_item_focus, src_take_focus} or {src_item, src_take})
	local same_take = src_take and src_take == r.GetActiveTake(src_item) -- evaluation if focused fx chain belongs to the active take to avoid copying to the source, but allow copying to other takes, for error message below

	local obj_under_mouse = r.GetTrackFromPoint(x,y) or r.GetItemFromPoint(x, y, true) -- allow_locked true
	local src_fx_num = obj_under_mouse and FX_menu(src_trk, src_take) or (retval > 0 or src_mon_fx_idx >= 0) and src_fx_num_focus
		if not src_fx_num then return r.defer(function() do return end end) end -- this will be true if the menu was closed without selection
	local fx_chain = src_fx_num

	-- Generate error messages
	local compat_note = not app_ver and '\n\n           Inserting from FX browser\n\n    is only supported since build 6.12c.' or ''
	local err1 = (not src_trk and not src_take and src_mon_fx_idx < 0 and fx_brws == 0) and '            No focused FX to insert.\n\nSelect FX in FX chain or in FX browser.'..compat_note or ((sel_trk_cnt + sel_itms_cnt == 0) and 'No selected objects.')
	local err2 = (sel_trk_cnt == 0 and sel_itms_cnt > 0 and not TAKE_FX) and 'Inserting FX in items is disabled\n\n       in the USER SETTINGS.' or ((sel_trk_cnt > 0 and sel_itms_cnt == 0 and not (TRACK_MAIN_FX and TRACK_INPUT_MON_FX)) and 'Inserting FX on tracks is disabled\n\n         in the USER SETTINGS.')
	local err = err1 or err2
		if err then r.MB(err,'ERROR',0) return r.defer(function() do return end end) end

		-- Generate prompts
		if fx_brws == 1 and fx_chain then resp = r.MB('Both FX chain and FX browser are open.\n\n\"YES\" - to insert FX selected in the FX browser.\n\n\"NO\" - to insert FX selected in the focused FX chain.','PROMPT',3)
			if resp == 6 then fx_brws, fx_chain = 1, false
			elseif resp == 7 then fx_brws, fx_chain = 0, true
			else return r.defer(function() do return end end) end
		end

	-- Generate error messages
	-- must follow prompts to only display error when fx_chain is the only one open or chosen, otherwise an option to insert from fx browser is blocked as well
	local err = 'FX cannot be copied back to the source '
	local err = fx_chain and (sel_trk_cnt == 1 and src_trk and r.IsTrackSelected(src_trk) and sel_itms_cnt == 0 and err..'track.' or src_take and sel_itms_cnt == 1 and r.IsMediaItemSelected(src_item) and same_take and sel_trk_cnt == 0 and err..'take.')
		if err then r.MB(err,'ERROR',0) return r.defer(function() do return end end) end

	-- Check if fx are selected in the fx browser and collect their names
		if fx_brws == 1 then
		r.PreventUIRefresh(1)
		r.InsertTrackAtIndex(r.GetNumTracks(), false) -- insert new track at end of track list and hide it
		local temp_track = r.GetTrack(0,r.CountTracks(0)-1)
		r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINMIXER', 0)
		r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINTCP', 0)
		r.TrackFX_AddByName(temp_track, 'FXADD:', false, -1)
			if r.TrackFX_GetCount(temp_track) == 0 then
			r.DeleteTrack(temp_track)
			r.MB('No FX have been selected in the FX browser.', 'ERROR', 0) r.defer(function() do return end end) return
			else
			fx_list = ''
				for i = 0, r.TrackFX_GetCount(temp_track)-1 do
				fx_list = fx_list..'\n'..select(2,r.TrackFX_GetFXName(temp_track, i, ''))
				end
			end
		r.DeleteTrack(temp_track)
		r.PreventUIRefresh(-1)
		end

	local src_fx_num = src_mon_fx_idx >= 0 and src_fx_num == 0 and src_mon_fx_idx+0x1000000 or retval == 2 and src_fx_num >= 65536 and src_fx_num & 0xFFFF or src_fx_num -- account for Mon fx chain fx and multiple takes -- NEW

	local fx_name = src_take and select(2,r.TakeFX_GetFXName(src_take, src_fx_num, '')) or src_trk and select(2,r.TrackFX_GetFXName(src_trk, src_fx_num, '')) or fx_list
	local fx_name = (fx_name and fx_chain) and 'Copying '..fx_name..'\n\n' or (fx_brws == 1 and 'Inserting...\n'..fx_list..'\n\n')

	local resp = (fx_brws == 1 or fx_chain) and r.MB(fx_name..'\"YES\" - to insert at the top of the chain.\n\n\"NO\" - to insert at the bottom the chain.','PROMPT',3)
		if resp == 2 then return r.defer(function() do return end end) end
	local pos = resp == 6 and -1000 or -1

	local unidir = sel_trk_cnt > 0 and src_take and (sel_itms_cnt == 0 or sel_itms_cnt == 1 and r.IsMediaItemSelected(src_item)) or sel_itms_cnt > 0 and src_trk and not src_take and (sel_trk_cnt == 0 or sel_trk_cnt == 1 and r.IsTrackSelected(src_trk))
	local mixed_sel_note = sel_trk_cnt > 0 and sel_itms_cnt > 0 and '\n\n'..(' '):rep(8)..'(only applies to objects of the same type)' or ''
	local resp = fx_chain and not unidir and FX_Has_Envelopes(src_take, src_trk, src_fx_num) and r.MB((' '):rep(13)..'The selected FX has active envelopes.\n\n\t'..(' '):rep(11)..'Copy them as well?'..mixed_sel_note,'PROMPT',3) -- only display in cases where envelopes can be copied, excluding cases where track FX are only copied to takes and vice versa
		if resp == 2 then return r.defer(function() do return end end) end
	local incl_envs = resp == 6


r.Undo_BeginBlock()

		if fx_brws == 1 then
			if resp == 2 then return r.defer(function() do return end end) end
			if sel_trk_cnt > 0 then
				for i = 0, sel_trk_cnt-1 do
				local tr = r.GetSelectedTrack(0,i) or r.GetMasterTrack(0)
				local insert = TRACK_MAIN_FX and r.TrackFX_AddByName(tr, 'FXADD:', false, pos)
				local insert = TRACK_INPUT_MON_FX and r.TrackFX_AddByName(tr, 'FXADD:', true, pos)
				end
			end
			if sel_itms_cnt > 0 then
				for i = 0, sel_itms_cnt-1 do
				local take = r.GetActiveTake(r.GetSelectedMediaItem(0,i))
				local insert = TAKE_FX and r.TakeFX_AddByName(take, 'FXADD:', pos)
				end
			end
		elseif fx_chain then

		-- GET SELECTION AND FLOATING STATE
		-- When the setting 'Preferences -> Only allow one FX chain window at a time' is enabled the functions Track/TakeFX_CopyToTrack/Take() close focused FX chain window, which requires its re-opening
		-- https://forum.cockos.com/showthread.php?t=277429 bug report
		-- Thanks to mespotine for figuring out config variables
		-- https://github.com/mespotine/ultraschall-and-reaper-docs/blob/master/Docs/Reaper-ConfigVariables-Documentation.txt
		local one_chain = (src_take_focus and src_take_focus == src_take or src_trk_focus and src_trk_focus == src_trk) and Check_reaper_ini('fxfloat_focus')&2 == 2 -- 'Only allow one FX chain window at a time' is enabled in Preferences -> Plug-ins // only relevant when inserting from an open FX chain or when the FX menu stems from the same object as the focused FX chain 
		local is_foc_float = one_chain and (src_take and r.TakeFX_GetFloatingWindow(src_take, src_fx_num) or src_trk and r.TrackFX_GetFloatingWindow(src_trk, src_fx_num)) -- if focused FX is open in a floating window

			if incl_envs then

			Multiply_Src_And_MoveFX_plus_Envelopes(src_take, src_trk, src_fx_num, sel_trk_cnt, sel_itms_cnt, pos)

			else -- without envelopes

				if sel_trk_cnt > 0 then
					for i = 0, sel_trk_cnt-1 do
					local dest_trk = r.GetSelectedTrack(0,i) or r.GetMasterTrack(0)
						if ((src_trk or src_mon_fx_idx >= 0) and dest_trk ~= src_trk) or src_take then -- to prevent copying back to the source track fx chain only when src fx is track fx, without src_trk cond dest_trk ~= src_trk is true for the track of a src_item and prevents copying to such track
						local main_fx_pos = pos == -1 and r.TrackFX_GetCount(dest_trk) or 0
						local input_fx_pos = pos == -1 and r.TrackFX_GetRecCount(dest_trk)+0x1000000 or 0x1000000
						local insert = src_take and TRACK_MAIN_FX and r.TakeFX_CopyToTrack(src_take, src_fx_num, dest_trk, main_fx_pos, false) or src_trk and TRACK_MAIN_FX and r.TrackFX_CopyToTrack(src_trk, src_fx_num, dest_trk, main_fx_pos, false) -- is_move false // src_take is evaluated first because src_trk is always valid when fx chain is focused and will produce false positives when take fx is focused, here and elsewhere
						local insert = src_take and TRACK_INPUT_MON_FX and r.TakeFX_CopyToTrack(src_take, src_fx_num, dest_trk, input_fx_pos, false) or src_trk and TRACK_INPUT_MON_FX and r.TrackFX_CopyToTrack(src_trk, src_fx_num, dest_trk, input_fx_pos, false) -- is_move false
						end
					end
				end
				if sel_itms_cnt > 0 then
					for i = 0, sel_itms_cnt-1 do
					local dest_item = r.GetSelectedMediaItem(0,i)
					local dest_take = r.GetActiveTake(r.GetSelectedMediaItem(0,i))
						if src_take and dest_take ~= src_take or src_trk and not src_take then -- prevent copying to the source fx chain when src is take fx
						local pos = pos == -1 and r.TakeFX_GetCount(dest_take) or 0
						local insert = src_take and TAKE_FX and r.TakeFX_CopyToTake(src_take, src_fx_num, dest_take, pos, false) or src_trk and TAKE_FX and r.TrackFX_CopyToTake(src_trk, src_fx_num, dest_take, pos, false) -- is_move false
						end
					end
				end

			end -- envelopes cond end

			-- RESTORE SELECTION AND FLOATING STATE
			-- When re-opening FX chain window after it's been closed with Track/TakeFX_CopyToTrack/Take(), selection must be switched to the focused FX even if it wasn't selected originally which is possible with floating windows, because restoration of the originally selected FX if its window is also floating, will bring it in front of the originally focused floating FX window even if the latter is re-floated last, and it's impossible to change selection of FX in the chain while windows are floating
			if one_chain then  -- only relevant when inserting from an open FX chain
			local FX_Show = src_take_focus and r.TakeFX_Show or r.TrackFX_Show
			local obj = src_take_focus or src_trk_focus
			FX_Show(obj, src_fx_num_focus, 1)
				if is_foc_float then FX_Show(obj, src_fx_num_focus, 2) FX_Show(obj, src_fx_num_focus, 3) end
			end

		end

-- Concatenate undo point caption
	local insert = 'Insert selected FX / FX chain preset '
	local insert = (fx_brws == 1 and sel_trk_cnt > 0 and sel_itms_cnt > 0) and insert..'in selected objects' or ((fx_brws == 1 and sel_trk_cnt > 0) and insert..'on selected tracks' or ((fx_brws == 1 and sel_itms_cnt > 0) and insert..'in selected items'))
	local copy = 'Copy focused FX '
	local copy = (fx_chain and sel_trk_cnt > 0 and sel_itms_cnt > 0) and copy..'to selected objects' or ((fx_chain and sel_trk_cnt > 0) and copy..'to selected tracks' or ((fx_chain and sel_itms_cnt > 0) and copy..'to selected items'))

r.Undo_EndBlock(insert or copy,-1)





