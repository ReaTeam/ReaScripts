--[[
ReaScript Name: Link two FX parameters via parameter modulation
Author: BuyOne
Version: 1.0
Changelog: Initial release
Author URL: https://forum.cockos.com/member.php?u=134058
Licence: WTFPL
REAPER: at least v5.962
About:  	The script automates the task of linking two FX parameters
		via parameter modulation properties.
		
		HOW TO USE
		
		1. Click/touch control of FX parameter which should be the Master.  
		2. Run the script once.  
		The parameter data will be stored to the clipboard,
		the script toggle state will be set to ON.  
		If the script is linked to a toolar button the button 
		will light up, if it's linked to a menu item, the latter
		will be checkmarked.  
		In the main menu at the position of Undo History, the last one
		after Help, the name of the touched parameter will be displayed
		for reference. Still it may prove not really informative because 
		in VST plugins these names of parameters may differ from their 
		names displayed in the plugin UI.  
		3. Click/touch control of another FX parameter which should be
		the Slave, the one to be controlled by the Master parameter.  
		4. Run the script again.  
		At this point the link will have been set up and the script will be reset.
		
		In case you forgot what has been linked to what, you can look up this 
		info in the name of the script Undo point in the Undo History. But the
		reservation about the parameter naming made above still applies.
		
		If Parameter modulation settings window of the Slave parameter is open 
		while the link is being created its UI won't be updated. In this case 
		to see changes, close the window and re-open it.
		
		To reset the script after step 2 without creating a linkage even if you're
		already at step 3, close the focused FX chain, perform step 4 and click 'YES'
		in the prompt which will pop up.  
		There're a few other options which you may encounter using the script but 
		those are less accessible.

		You may also be interested in the script   
		BuyOne_List all linked FX parameters in the project.lua
]]


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper

local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()


function EMERGENCY_TOGGLE(sect_ID, cmd_ID)
r.SetToggleCommandState(sect_ID, cmd_ID, 0)
end
---------------- EMERGENCY -------------------

-- EMERGENCY_TOGGLE(sect_ID, cmd_ID) do return end

---------------------------------------------


-- FUNCTIONS

function GetMonFXProps() -- get mon fx accounting for floating window, reaper.GetFocusedFX() doesn't detect mon fx in builds prior to 6.20
	local master_tr = r.GetMasterTrack(0)
	local src_mon_fx_idx = r.TrackFX_GetRecChainVisible(master_tr)
	local is_mon_fx_float = false -- only relevant for pasting stage to reopen the fx in floating window
		if src_mon_fx_idx < 0 then -- fx chain closed or no focused fx -- if this condition is removed floated fx gets priority
			for i = 0, r.TrackFX_GetRecCount(master_tr) do
				if r.TrackFX_GetFloatingWindow(master_tr, 0x1000000+i) then
				src_mon_fx_idx = i; is_mon_fx_float = true break end
			end
		end
	return src_mon_fx_idx, is_mon_fx_float
end


function Space(int)
return string.rep(' ', int)
end


function Get_Illegal_FX(retval, track_num, fx_num) -- input and Mon FX + no focused FX
local mon_fx = retval == 1 and track_num == 0 and fx_num >= 16777216
or retval == 0 and GetMonFXProps() >= 0 -- for builds older that 6.20 where GetFocusedFX() doesn't detect Monitor FX
local input_fx = retval == 1 and fx_num >= 16777216	-- since 6.20 covers both input and Mon FX // to differentiate track_num return value must be considered
local append = (mon_fx or input_fx) and ' don\'t support\n\n'..Space(8)..'parameter modulation.' or ''
return append, retval == 0 and not mon_fx and '\tNo focused FX.' or mon_fx and Space(6)..'Monitor FX' or input_fx and Space(4)..'Track Input FX'
end


function GetObjChunk(retval, obj) -- retval stems from r.GetFocusedFX(), value 0 is only considered at the pasting stage because in the copying stage it's error caught before the function
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua
		if not obj then return end
  -- Try standard function -----
	local t = retval == 1 and {r.GetTrackStateChunk(obj, '', false)} or {r.GetItemStateChunk(obj, '', false)} -- isundo = false
	local ret, obj_chunk = table.unpack(t)
		if ret and obj_chunk and #obj_chunk >= 4194303 and not r.APIExists('SNM_CreateFastString') then return 'err_mess'
		elseif ret and obj_chunk and #obj_chunk < 4194303 then return ret, obj_chunk -- 4194303 bytes = (4096 kb * 1024 bytes) - 1 byte
		end
-- If chunk_size >= max_size, use wdl fast string --
	local fast_str = r.SNM_CreateFastString('')
		if r.SNM_GetSetObjectState(obj, fast_str, false, false) then
		obj_chunk = r.SNM_GetFastString(fast_str)
		end
	r.SNM_DeleteFastString(fast_str)
		if obj_chunk then return true, obj_chunk end
end


function Err_mess(slave) -- if chunk size limit is exceeded and SWS extension isn't installed

	local sws_ext_err_mess = "              The size of data requires\n\n     the SWS/S&M extension to handle it.\n\nIf it's installed then it needs to be updated.\n\n         After clicking \"OK\" a link to the\n\n SWS extension website will be provided\n\n\tThe script will now quit"..(not slave and '.' or "\n\nand the data will be deleted from clipboard.")
	local sws_ext_link = 'Get the SWS/S&M extension at\nhttps://www.sws-extension.org/\n\n'

	local resp = r.MB(sws_ext_err_mess,'ERROR',0)
		if resp == 1 then r.ShowConsoleMsg(sws_ext_link, r.ClearConsole()) return end
end


function SetObjChunk(retval, obj, obj_chunk) -- retval stems from r.GetFocusedFX(), value 0 is only considered at the pasting stage because in the copying stage it's error caught before the function
		if not (obj and obj_chunk) then return end
	return retval == 1 and r.SetTrackStateChunk(obj, obj_chunk, false) or r.SetItemStateChunk(obj, obj_chunk, false)
end


function Esc(str)
return str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
end


function Process_FX_Chunk(...)

local chunk, retval, obj, take, fx_GUID, fx_num, parm_num, src_fx_num, src_parm_num = table.unpack({...}) -- src_fx_num and src_parm_num are only available at the slaving stage and also used as conditions to separate master routines from the slave ones

	if chunk and #chunk > 0 then -- evaluate master parameter
	local sel_env = r.GetSelectedTrackEnvelope(0) -- store selected env, because after chunk setting its selection is cleared
	local fx_chunk = chunk:match(Esc(fx_GUID)..'.-WAK') -- isolate fx chunk to prevent captrure below from spilling over to FX downstream in case current FX doesn't have PROGRAMENV data for this parameter number but the FX downstream do
	local PROGRAMENV = fx_chunk:match('<PROGRAMENV '..parm_num..'.->') -- if has param modul
	local PLINK = PROGRAMENV and PROGRAMENV:match('PLINK.-(%d+:%-?%d+ %-?%d+).->') -- master parm idx can be negative too (if link is disabled) hence double %-?
	local PARMENV = fx_chunk:match('<PARMENV '..parm_num..'.->')
	local ENV_VIS = PARMENV and PARMENV:match('VIS 1 1') -- if has active env displayed in its own lane and hence envcp is visible as well, to clear 'Modulate this parameter' (sinewave graphic) button below if conditions are met; if displayed in media item lane (VIS 1 0) this isn't required
	local resp
		if PROGRAMENV then -- if master or slave param have param modulation enabled, retrieve info about the master's param own master param to display to the user in a dialogue
		local master_fx_num, slave_fx_num, master_parm_num = PROGRAMENV:match('PLINK.-(%d+):(%-?%d+) (%-?%d+)') -- find if linked and get PLINK props
			if master_fx_num then -- if param linking section is enabled but there's no linkage master_fx_num value is -1 and hence will be false after above capture syntax is applied
				if src_fx_num then -- slave stage // check if the Slave parm is already linked to the Master
					if master_fx_num == tostring(src_fx_num) and master_parm_num == src_parm_num then -- same master, same slave // src_fx_num come in as 'number', after checking of source fx exists in the main routine; src_parm_num come in as 'string' extracted from extended state
					local open_parm_sett = retval == 1 and '\nOpen Parameter modulation settings,' or ''
					resp = r.MB('The Slave parameter is already linked to the Master parameter.\n\nY E S —  Re-apply the linkage.\nOther parameter moduation settings (if any) will be kept\n\nN O   —  Keep the linkage.'..open_parm_sett..' reset the script','ALERT',3) -- re-applying may make sense when the Master parm value has changed so it's used as the new base value for the Slave
						if resp == 2 then return 'cancel' -- Cancel without resetting
						elseif resp == 7 then return true, r.Main_OnCommand(41143, 0) -- rest and run FX: Show parameter modulation/link for last touched FX parameter // DOESN'T WORK FOR TAKE FX hence open_parm_sett var // when Main_OnCommand() is placed immedialtely after 'then' and before 'return' strangely 'return' does't work and the routine continues
						end
					end
				end

				if resp ~= 6 then -- if not slave stage or slave stage and not Re-apply
				local master_fx_num = tonumber(master_fx_num)
				local ret, master_fx_name = table.unpack(retval == 1 and {r.TrackFX_GetFXName(obj, master_fx_num, '')} or retval == 2 and {r.TakeFX_GetFXName(take, master_fx_num, '')}) -- get master fx name to display in the dialogue below
				local master_parm_num = tonumber(master_parm_num)
				local ret, master_parm_name = table.unpack(retval == 1 and {r.TrackFX_GetParamName(obj, master_fx_num, master_parm_num, '')} or retval == 2 and {r.TakeFX_GetParamName(take, master_fx_num, master_parm_num, '')}) -- get master param name to display in the dialogue below
				local master_fx_name = master_fx_name:match(':(.+)') or master_fx_name -- strip away plugin type prefix (VST, JS etc.)
				local master_fx_name = slave_fx_num == '0' and 'the same '..master_fx_name or master_fx_name
				local mess_intro = not src_fx_num and 'The Master parameter is itself ' or 'The Slave parameter is already '
				local mess_opt = not src_fx_num and 'Y E S —  Keep and continue\n\nN O   —  Disable and continue. Other parameter\nmodulation sources (if any) will be kept intact' or 'Y E S —  Replace current linkage\n\nN O   —  Reset the script'
				resp = r.MB(mess_intro..'linked to\n\n"'..master_parm_name..'" parameter\n\nof '..master_fx_name..' plugin.\n\n'..mess_opt, 'ALERT', 3) -- if there was no dialogue above at the slave stage, on the master stage the condition will always be true
				end

			end -- master_fx_num cond end

			if resp == 2 and not src_fx_num or resp == 7 and src_fx_num then return true -- Cancel storing Master parm data/Abort slaving, reset
			elseif resp == 2 and src_fx_num then return 'cancel' -- Cancel without resetting at the slave stage
			elseif not src_fx_num and resp == 7 or src_fx_num then -- delete current linkage either of the Master parm on the master stage or of the Slave parm on the slave stage

			-- PROGRAMENV data cannot be simply deleted from chunk with empty string or a dummy string if this parameter has an active envelope as PARMENV data (and vice versa)
			-- !!!!!!!!!!!!!!! If AUDIOCTL AND/OR LFO ARE ENABLED, THE WHOLE <PROGRAMENV SECTION ISN'T DELETED, STRANGEY ONLY PLINK IF IT'S THERE, THIS IS REGARDLESS OF WHETHER PARAM ENVELOPE IS ACTIVE OR NOT || IF THERE'S PLINK ONLY, THE ENTIRE SECTION DOES GET DELETED, ALSO REGARDLESS OF THE ENVELOPE
			local parm_mod_state = not src_fx_num and not PROGRAMENV:match('AUDIOCTL 1') and not PROGRAMENV:match('LFO 1') and '1' or '0' -- only disable param mod area ('Enable parameter modulation' checkbox) when storing Master param while Audio control and LFO sections are OFF // 1 disabled, 0 enabled
			local chunk_new = src_fx_num and chunk:gsub(Esc(PROGRAMENV), '<PROGRAMENV\n>') or chunk:gsub(Esc(PROGRAMENV), '<PROGRAMENV '..parm_num..' '..parm_mod_state..'\n>') -- if slave stage, delete the entire PROGRAMENV block which will be re-applied with changes below; if master stage only delete PLINK data which results in desabling Parameter linking option in the UI but the actual linking isn't removed; alternatively chunk:gsub(Esc(PLINK), 'PLINK -1') removes the actual linking while keeping PLINK data in the chunk and Parameter linking option enabled
				if chunk_new then SetObjChunk(retval, obj, chunk_new) end
			end -- resp cond end
		end -- PROGRAMENV cond end

		-- Link the Slave parameter
		if src_fx_num then -- slave stage // set new parameter link
		local fx_num_diff = tonumber(src_fx_num) - fx_num
		local PLINK = PROGRAMENV and PROGRAMENV:match('PLINK.-(%d+:%-?%d+ %-?%d+).->')
		local PROGRAMENV_new = PLINK and PROGRAMENV:gsub(Esc(PLINK), src_fx_num..':'..fx_num_diff..' '..src_parm_num) or
		PROGRAMENV and PROGRAMENV:gsub('>', 'PLINK 1 '..src_fx_num..':'..fx_num_diff..' '..src_parm_num..' 0\n>') or '<PROGRAMENV '..parm_num..' 0\nPARAMBASE 0\nLFO 0\nLFOWT 1 1\nAUDIOCTL 0\nAUDIOCTLWT 1 1\nPLINK 1 '..src_fx_num..':'..fx_num_diff..' '..src_parm_num..' 0\n>'
		local sub_chunk = PARMENV and PARMENV..'\n'..PROGRAMENV_new or fx_GUID..'\n'..PROGRAMENV_new -- attach param mod section to env section or to the FX GUID
		local chunk_new = PROGRAMENV and chunk:gsub(Esc(PROGRAMENV), PROGRAMENV_new) or PARMENV and chunk:gsub(Esc(PARMENV), sub_chunk) or chunk:gsub(Esc(fx_GUID), sub_chunk) -- either update <PROGRAMENV section if present or update having attached to the envelope if present or having attached to the FX GUID
		SetObjChunk(retval, obj, chunk_new)
		end

		-- Toggle hide/unhide track envelope
		if retval == 1 and ENV_VIS and (resp == 7 or src_fx_num) then -- if track FX and FX param has active envelope, toggle hide envelope to clear or activate param modulation button 'Modulate this parameter' (sinewave graphic) in the envcp whose state doesn't change when 'Enable parameter modulation' checkbox is (un)set via chunk above
		r.PreventUIRefresh(1)
		local env = r.GetFXEnvelope(obj, fx_num, parm_num, false) -- create false
		local ret, env_chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
		local chunk_new = env_chunk:gsub('VIS 1', 'VIS 0')
		r.SetEnvelopeStateChunk(env, chunk_new, false) -- isundo false // hide
		r.SetEnvelopeStateChunk(env, env_chunk, false) -- isundo false // un-hide
		r.SetCursorContext(2, sel_env) -- restore envelope selected originally which will be de-selected due to chunk setting
		r.PreventUIRefresh(-1)
		end

	end -- chunk cond. end

end

-- SELECT MASTER PARAMETER

local toggle_state = r.GetToggleCommandStateEx(sect_ID, cmd_ID)
	if toggle_state == -1 or toggle_state == 0 then

	local retval, src_track_num, src_item_num, src_fx_num = r.GetFocusedFX() -- if take fx, item number is index of the item within the track (not within the project) while track number is the track this item belongs to, if not take fx src_item_num is -1, if retval is 0 the rest return values are 0 as well

	local append, err = Get_Illegal_FX(retval, src_track_num, src_fx_num) -- input and Mon FX + no focused FX
		if err then r.MB(err..append, 'ERROR', 0) return r.defer(function() do return end end) end

	local tr = retval > 0 and r.GetTrack(0,src_track_num-1) or r.GetMasterTrack()
	local item = retval == 2 and r.GetTrackMediaItem(tr, src_item_num)
	local take_num = retval == 2 and src_fx_num>>16 -- for undo point
	local take = retval == 2 and r.GetMediaItemTake(item, take_num)
	local fx_num = retval == 2 and src_fx_num&0xFFFF or src_fx_num -- take or track fx index (incl input/mon fx)
	local fx_GUID = retval == 1 and r.TrackFX_GetFXGUID(tr, fx_num) or r.TakeFX_GetFXGUID(take, fx_num)
	local obj = item or tr -- first item since track is available when take fx is in focus as well
	local ret, chunk = GetObjChunk(retval, obj)
		if ret == 'err_mess' then Err_mess()
		return r.defer(function() do return end end) end

	local ret, src_track, src_fx_num, parm_num = r.GetLastTouchedFX() -- doesn't support Mon FX // here we only need src_param_num as the rest has been retrieved with GetFocusedFX()

	local abort = Process_FX_Chunk(chunk, retval, obj, take, fx_GUID, fx_num, parm_num)

		if abort then return r.defer(function() do return end end) end -- if dialogue is cancelled

	local t = {retval, tostring(obj), fx_num, fx_GUID, parm_num} -- fx_num and parm_num are needed to concatenate PLINK string; fx_GUID is needed to allow locating it in the next stage if fx order in the chain was changed or throw an error if it was deleted

	r.SetExtState(sect_ID..cmd_ID, 'PLINK', table.concat(t, ';'), false) -- persist is false

	local state = r.GetExtState(sect_ID..cmd_ID, 'PLINK')

		if #state ~= 0 then
		local ret, parm_name = table.unpack(take and {r.TakeFX_GetParamName(take, fx_num, parm_num, '')} or {r.TrackFX_GetParamName(tr, fx_num, parm_num, '')})
		r.SetToggleCommandState(sect_ID, cmd_ID, 1)
		r.RefreshToolbar(cmd_ID)
		local x, y = r.GetMousePosition()
		r.TrackCtl_SetToolTip((' \n\n  the data has been stored. \n\n '):upper():gsub('.','%0 '), x, y, true) -- topmost
			if #parm_name > 0 then
			r.Undo_BeginBlock()
			r.Undo_EndBlock(parm_name, -1)
			end
		end

	return r.defer(function() do return end end) end
-------------------------------------------------------------------------------

-- SELECT SLAVE PARAMETER

local state = r.GetExtState(sect_ID..cmd_ID, 'PLINK')

	if #state == 0 then r.SetToggleCommandState(sect_ID, cmd_ID, 0) return r.defer(function() do return end end)
	elseif r.GetToggleCommandStateEx(sect_ID, cmd_ID) == 1 then

	function Reset(sect_ID, cmd_ID)
	r.SetToggleCommandState(sect_ID, cmd_ID, 0)
	r.RefreshToolbar(cmd_ID)
	r.DeleteExtState(sect_ID..cmd_ID, 'PLINK', true) -- persist true
	end

	local dest_retval, dest_track_num, dest_item_num, dest_fx_num = r.GetFocusedFX() -- if take fx, item number is index of the item within the track (not within the project) while track number is the track this item belongs to, if not take fx src_item_num is -1, if dest_retval is 0 the rest return values are 0 as well

	local append, err = Get_Illegal_FX(dest_retval, dest_track_num, dest_fx_num) -- -- input and Mon FX + no focused FX // not really necessary because this can be handled by error traps below, but the verbiage is more descriptive
		if err then resp = r.MB(err..append..'\n\n     Should the script be reset?', 'ERROR', 4)
			if resp == 6 then Reset(sect_ID, cmd_ID) end
		return r.defer(function() do return end end) end

	local tr = dest_retval > 0 and r.GetTrack(0, dest_track_num-1) or r.GetMasterTrack()
	local item = dest_retval == 2 and r.GetTrackMediaItem(tr, dest_item_num)
	local take_num = dest_retval == 2 and dest_fx_num>>16
	local take = take_num and r.GetMediaItemTake(item, take_num)
	local fx_num = dest_retval == 2 and dest_fx_num&0xFFFF or dest_fx_num
	local fx_GUID = dest_retval == 1 and r.TrackFX_GetFXGUID(tr, fx_num) or r.TakeFX_GetFXGUID(take, fx_num)
	local obj = item or tr -- first item since track is available when take fx is in focus as well
	local ret, track, fx, slave_parm_num = r.GetLastTouchedFX() -- doesn't support Mon FX // here we only need src_param_num as the rest has been retrieved with GetFocusedFX() // could have be used instead of GetFocusedFX() to allow closing the FX chain after touching the param

	local src_retval, src_obj, src_fx_num, src_fx_GUID, master_parm_num = state:match('(.+);(.+);(.+);(.+);(.+)') --state:match(string.rep('(%w+);?', 5)) -- this craps out at getting object pointer

	local append = '\n\n'..Space(12)..'Should the Master parameter data\n\n\t    be kept in the clipboard?'
	local tr_or_item = dest_retval == 1 and 'track.' or 'item/take.'
	local space = dest_retval == 1 and Space(9) or Space(5)
	local err = dest_retval ~= tonumber(src_retval) and Space(9)..'Destination object type isn\'t compatible\n\n\t  with the source object type.\n\n'..Space(17)..'Track FX are only compatible\n\n'..Space(15)..'with track FX, likewise take fx.'..append or tostring(obj) ~= src_obj and '  Destination object differs from the source object.\n\n\t'..space..'Not the same '..tr_or_item..append

	-- check if the source fx has been moved or deleted
	local fx_cnt = take and r.TakeFX_GetCount(take)-1 or r.TrackFX_GetCount(tr)-1
	local src_fx_exists
		for i = 0, fx_cnt do
		local fx_GUID = take and r.TakeFX_GetFXGUID(take, i) or r.TrackFX_GetFXGUID(tr, i)
			if fx_GUID == src_fx_GUID then src_fx_num, src_fx_exists = i, 1 break end -- locate source fx in case fx order has changed or it was deleted
		end

	local err = err or not src_fx_exists and ' The source FX could not be found.\n\nLikely because it had been deleted.\n\n      The script will now be reset.' or fx_num == tonumber(src_fx_num) and slave_parm_num == tonumber(master_parm_num) and Space(6)..'Master and Slave parameters are the same.\n\n\t'..Space(9)..'Can\'t link to itself.'..append

	local mode = err and err:match('found') and 0 or err and 4

		if err then resp = r.MB(err, 'ERROR', mode) -- and reset all
			if resp == 1 or resp == 7 then -- OK or NO
			Reset(sect_ID, cmd_ID)
			end
		return r.defer(function() do return end end) end


	local ret, chunk = GetObjChunk(dest_retval, obj)
		if ret == 'err_mess' then Err_mess(true) -- true arg is to condition error verbiage specific to the slave stage
		Reset(sect_ID, cmd_ID)
		return r.defer(function() do return end end) end

	r.Undo_BeginBlock()

	local abort = Process_FX_Chunk(chunk, dest_retval, obj, take, fx_GUID, fx_num, slave_parm_num, src_fx_num, master_parm_num) -- src_fx_num, master_parm_num are used to evaluate if the slave parm is already linked to the master parm and as conditions to separate master routines from the slave ones // master_parm_num is named src_parm_num within the function because it already had master_parm_num var
		if abort then
		local reset = abort ~= 'cancel' and Reset(sect_ID, cmd_ID) -- if cancel, simply abort without resetting the script
		return r.defer(function() do return end end) end -- if dialogue is declined or cancelled

	local FX_NAME = dest_retval == 1 and r.TrackFX_GetFXName or r.TakeFX_GetFXName
	local PARM_NAME = dest_retval == 1 and r.TrackFX_GetParamName or r.TakeFX_GetParamName
	local obj = take or tr

	local ret, src_fx_name = FX_NAME(obj, src_fx_num, '')
	local src_fx_name = src_fx_name:match(':(.+)') or src_fx_name -- strip away plugin type prefix (VST, JS etc.)
	local ret, master_parm_name = PARM_NAME(obj, src_fx_num, master_parm_num, '')
	local ret, dest_fx_name = FX_NAME(obj, fx_num, '')
	local dest_fx_name = dest_fx_name:match(':(.+)') or src_fx_name -- strip away plugin type prefix (VST, JS etc.)
	local ret, slave_parm_name = PARM_NAME(obj, fx_num, slave_parm_num, '')

	r.SetToggleCommandState(sect_ID, cmd_ID, 0)
	r.Undo_EndBlock('Link '..slave_parm_name..' of '..dest_fx_name..' to '..master_parm_name..' of '..src_fx_name, -1)

	end






