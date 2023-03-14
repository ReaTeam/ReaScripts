-- @description Insert selected FX or FX chain presets in OR copy focused FX to selected objects
-- @author BuyOne
-- @website https://forum.cockos.com/member.php?u=134058
-- @version 1.4
-- @changelog
--    Fixed temporary track being left behind after aborting the script
--    Fixed a bug of copying FX to the same FX chain
-- @about Allows inserting multiple FX or FX chain presets from FX browser or copying FX focused in an FX chain or in a floating window to selected objects. Detailed description is available inside the script.

--[[
* Licence: WTFPL
* REAPER: at least v6.12c

—— To insert FX or FX chain preset in multiple objects (tracks and/or items) at once open the FX 
Browser, select FX or FX chain preset, as many as needed, select the destination objects and run 
the script.

—— To copy FX to multiple objects at once select an FX in an open and focused FX chain or focus
its floating window, select the destination objects and run the script

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
an unwanted type.

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

function Msg(param)
reaper.ShowConsoleMsg(tostring(param)..'\n')
end


local r = reaper


local function GetMonFXProps() -- get mon fx accounting for floating window, reaper.GetFocusedFX() doesn't detect mon fx

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


local TRACK_MAIN_FX = TRACK_MAIN_FX:gsub('[%s]','') ~= ''
local TRACK_INPUT_MON_FX = TRACK_INPUT_MON_FX:gsub('[%s]','') ~= ''
local TAKE_FX = TAKE_FX:gsub('[%s]','') ~= ''

	local retval, src_trk_num, src_item_num, src_fx_num = r.GetFocusedFX() -- if take fx, item number is index of the item within the track (not within the project) while track number is the track this item belongs to, if not take fx src_item_num is -1, if retval is 0 the rest return values are 0 as well
	local src_trk = r.GetTrack(0, src_trk_num-1) or r.GetMasterTrack(0)
	local src_item = src_trk_num ~= 0 and r.GetTrackMediaItem(src_trk, src_item_num)
	local src_take = retval == 2 and r.GetMediaItemTake(src_item, src_fx_num>>16) -- retval to avoid error when src_item_num = -1 due to track fx chain
	local same_take = src_take and r.GetMediaItemTakeInfo_Value(src_take, 'IP_TAKENUMBER') == r.GetMediaItemTakeInfo_Value(r.GetActiveTake(src_item), 'IP_TAKENUMBER') -- evaluation if focused fx chain belongs to the active take to avoid copying to the source, but allow copying to other takes, for error message below
	local src_mon_fx_idx = GetMonFXProps() -- get Monitor FX
	local sel_trk_cnt = r.CountSelectedTracks2(0,true) -- incl. Master
	local sel_itms_cnt = r.CountSelectedMediaItems(0)
	local fx_chain = retval > 0 or src_mon_fx_idx >= 0
	local app_ver = tonumber(r.GetAppVersion():match('(.+)/')) > 6.11
	local fx_brws = app_ver and r.GetToggleCommandStateEx(0, 40271) -- View: Show FX browser window
	or 0 -- disable FX browser routine in builds prior to 6.12c where the API doesn't support it

	-- Generate error messages
	local compat_note = not app_ver and '\n\n           Inserting from FX browser\n\n    is only supported since build 6.12c.' or ''
	local err1 = (retval == 0 and src_mon_fx_idx < 0 and fx_brws == 0) and '            No focused FX to insert.\n\nSelect FX in FX chain or in FX browser.'..compat_note or ((sel_trk_cnt + sel_itms_cnt == 0) and 'No selected objects.')
	local err2 = (sel_trk_cnt == 0 and sel_itms_cnt > 0 and not TAKE_FX) and 'Inserting FX in items is disabled\n\n       in the USER SETTINGS.' or ((sel_trk_cnt > 0 and sel_itms_cnt == 0 and not (TRACK_MAIN_FX and TRACK_INPUT_MON_FX)) and 'Inserting FX on tracks is disabled\n\n         in the USER SETTINGS.')
	local err = err1 or err2
		if err then r.MB(err,'ERROR',0) r.defer(function() end) return end

		-- Generate prompts
		if fx_brws == 1 and fx_chain then resp = r.MB('Both FX chain and FX browser are open.\n\n\"YES\" - to insert FX selected in the FX browser.\n\n\"NO\" - to insert FX selected in the focused FX chain.','PROMPT',3)
			if resp == 6 then fx_brws, fx_chain = 1, false
			elseif resp == 7 then fx_brws, fx_chain = 0, true
			else r.defer(function() end) return end
		end

	-- Generate error messages
	-- must follow prompts to only display error when fx_chain is the only one open or chosen, otherwise an option to insert from fx browser is blocked as well
	local err = 'FX cannot be copied back to the source '
	local err = (fx_chain and sel_trk_cnt == 1 and r.IsTrackSelected(src_trk) and sel_itms_cnt == 0) and err..'track.' or ((fx_chain and retval == 2 and sel_itms_cnt == 1 and r.IsMediaItemSelected(src_item) and sel_trk_cnt == 0) and err..'item.')	-- retval == 2 is meant to avoid error when src_item = -1 due to track fx being selected and the preceding cond being false
		if err then r.MB(err,'ERROR',0) r.defer(function() end) return end

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

	local src_fx_num = (src_mon_fx_idx >= 0 and src_fx_num == 0) and src_mon_fx_idx+0x1000000 or ((retval == 2 and src_fx_num >= 65536) and src_fx_num & 0xFFFF or src_fx_num) -- account for Mon fx chain fx and multiple takes

	local fx_name = (retval == 1 or src_mon_fx_idx >= 0) and select(2,r.TrackFX_GetFXName(src_trk, src_fx_num, '')) or (retval == 2 and select(2,r.TakeFX_GetFXName(src_take, src_fx_num, '')) or fx_list)
	local fx_name = (fx_name and fx_chain) and 'Copying '..fx_name..'\n\n' or (fx_brws == 1 and 'Inserting...\n'..fx_list..'\n\n')

	local resp = (fx_brws == 1 or fx_chain) and r.MB(fx_name..'\"YES\" - to insert at the top of the chain.\n\n\"NO\" - to insert at the bottom the chain.','PROMPT',3)
		if resp == 2 then r.defer(function() end) return end
	local pos = resp == 6 and -1000 or -1

r.Undo_BeginBlock()

		if fx_brws == 1 then
			if resp == 2 then r.defer(function() end) return end
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
			if sel_trk_cnt > 0 then
				for i = 0, sel_trk_cnt-1 do
				local dest_trk = r.GetSelectedTrack(0,i) or r.GetMasterTrack(0)
					if ((retval == 1 or src_mon_fx_idx >= 0) and dest_trk ~= src_trk) or retval == 2 then -- to prevent copying back to the source track only when src fx is track fx, without retval cond dest_trk ~= src_trk is true for the track of a src_item and prevents copying to such track
					local main_fx_pos = pos == -1 and r.TrackFX_GetCount(dest_trk) or 0
					local input_fx_pos = pos == -1 and r.TrackFX_GetRecCount(dest_trk)+0x1000000 or 0x1000000
					local insert = (retval <= 1 and TRACK_MAIN_FX) and r.TrackFX_CopyToTrack(src_trk, src_fx_num, dest_trk, main_fx_pos, false) or ((retval == 2 and TRACK_MAIN_FX) and r.TakeFX_CopyToTrack(src_take, src_fx_num, dest_trk, main_fx_pos, false))
					local insert = (retval <= 1 and TRACK_INPUT_MON_FX) and r.TrackFX_CopyToTrack(src_trk, src_fx_num, dest_trk, input_fx_pos, false) or ((retval == 2 and TRACK_INPUT_MON_FX) and r.TakeFX_CopyToTrack(src_take, src_fx_num, dest_trk, input_fx_pos, false)) -- retval <= 1 covers both track fx chain, incl input fx, and mon fx chain
					end
				end
			end
			if sel_itms_cnt > 0 then
				for i = 0, sel_itms_cnt-1 do
				local dest_item = r.GetSelectedMediaItem(0,i)
				local dest_take = r.GetActiveTake(r.GetSelectedMediaItem(0,i))
				local pos = pos == -1 and r.TakeFX_GetCount(dest_take) or 0
				local insert = (retval <= 1 and TAKE_FX) and r.TrackFX_CopyToTake(src_trk, src_fx_num, dest_take, pos, false) or ((retval == 2 and TAKE_FX) and r.TakeFX_CopyToTake(src_take, src_fx_num, dest_take, pos, false))
				end
			end
		end


-- Concatenate undo point caption
	local insert = 'Insert selected FX / FX chain preset '
	local insert = (fx_brws == 1 and sel_trk_cnt > 0 and sel_itms_cnt > 0) and insert..'in selected objects' or ((fx_brws == 1 and sel_trk_cnt > 0) and insert..'on selected tracks' or ((fx_brws == 1 and sel_itms_cnt > 0) and insert..'in selected items'))
	local copy = 'Copy focused FX '
	local copy = (fx_chain and sel_trk_cnt > 0 and sel_itms_cnt > 0) and copy..'to selected objects' or ((fx_chain and sel_trk_cnt > 0) and copy..'to selected tracks' or ((fx_chain and sel_itms_cnt > 0) and copy..'to selected items'))

r.Undo_EndBlock(insert or copy,-1)


