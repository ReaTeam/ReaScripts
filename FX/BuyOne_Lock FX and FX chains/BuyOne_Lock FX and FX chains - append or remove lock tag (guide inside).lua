-- @noindex

--[[

* ReaScript Name: BuyOne_Lock FX and FX chains - append or remove lock tag (guide inside).lua
* Description: meant to be used alongside BuyOne_Lock FX and FX chains.lua
* Instructions: included
* Author: Buy One
* Author URL: https://forum.cockos.com/member.php?u=134058
* Licence: WTFPL
* Forum Thread:
* Demo:
* Version: 1.0
* REAPER: at least v5.962
* Extensions: SWS/S&M (not obligatory but recommended)
* Changelog:
	+ v1.0 	Initial release

]]

--[[

The script appends lock tag to and removes from names of all FX on selected objects
(tracks and/or items).

The script will work provided the lock tag precedes the FX name and is followed by a
space, e.g. "TAG VST: My plugin".

The TAG setting in the USER SETTINGS is optional since this script takes its value from
the main script BuyOne_Lock FX and FX chains (guide inside).lua. Only if for any reason
it fails to fetch one does it look for the tag in this setting. If it throws an error
telling that the tag hasn't been defined look first of all in the main script.

If FOCUSED option is enabled in the USER SETTINGS section below then if FX chain is open
the lock tag set in the USER SETTINGS will only be appended to or removed from the name
of any currently focused plugin in the open FX chain regardless of object selection. If
FX chain is closed the script will work globally affecting all FX in selected objects.

If FOCUSED option is disabled the script will work globally for selected objects
regardless of the focused FX in the open FX chain.

With option INCLUDE_INPUT_MON_FX enabled in the USER SETTINGS section below the script
will also globally affect track input FX as well as Monitor FX if Master track is
selected.

The script only works in one direction, if the name of the focused FX or at least one FX
in selected objects contains the tag, the script removes it, if the focused FX does not
or no FX in the selected objects does contain the tag the script appends it.

If some plugins store lots of data (usually heavy commercial plugins) it may take a bit
longer for the script to finish. In such cases while the script is running REAPER may become
unresponsive.

The script doesn't support the Video processor plugin at the moment.

]]

--------------------------- USER SETTINGS ---------------------------
---------------------------------------------------------------------
 -- Any QWERTY keyboard symbol save for quotation mark " and %
 -- between the double square brackets

TAG = [[]] -- optional, only needed if
-- BuyOne_Lock FX and FX chains (guide inside).lua script is unavailable
FOCUSED = [[1]] -- if FX chain is open the script will only affect focused FX
INCLUDE_INPUT_MON_FX = [[1]] -- relevant when applying the lock tag in batch

---------------------------------------------------------------------
------------------------ END OF USER SETTINGS -----------------------


function Msg(param)
reaper.ShowConsoleMsg(tostring(param).."\n")
end

r = reaper

TAG = TAG:gsub('[%s]','')
INCLUDE_INPUT_MON_FX = INCLUDE_INPUT_MON_FX:gsub('[%s]','')
FOCUSED = FOCUSED:gsub('[%s]','')



local function Get_TAG_Val() -- fetch from the main script

local info = debug.getinfo(1,'S')
local fx_lock_script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
--Msg(fx_lock_script_path)
local f = io.open(fx_lock_script_path..'BuyOne_Lock FX and FX chains (guide inside).lua', 'r')
local content = f:read('*a')
f:close()
return content:match('TAG = \"(.-)\"'):gsub('[%s]','')

end


function DETECT_TAG(TAG) -- used with APPND_OR_REMOVE_IN_SEL_OBJ() function

local tagged
local TAG = TAG:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')..' '

	for i = 0, r.CountSelectedTracks2(0, true)-1 do -- incl. Master
	local tr = r.GetSelectedTrack(0,i) or r.GetMasterTrack(0)
		if r.TrackFX_GetCount(tr) > 0 then
			for i = 0, r.TrackFX_GetCount(tr)-1 do
			local retval, name = r.TrackFX_GetFXName(tr, i, '')
			if name:match('^'..TAG) then tagged = true return tagged end
			end
			if INCLUDE_INPUT_MON_FX ~= '' and r.TrackFX_GetRecCount(tr) > 0 then
				for i = 0, r.TrackFX_GetRecCount(tr)-1 do
				local retval, name = r.TrackFX_GetFXName(tr, i+0x1000000, '')
				if name:match('^'..TAG) then tagged = true return tagged end
				end
			end
		end
	end
	if r.CountSelectedMediaItems(0) > 0 then
		for i = 0, r.CountSelectedMediaItems(0)-1 do
		local item = r.GetSelectedMediaItem(0,i)
		local take = r.GetActiveTake(item)
			if r.TakeFX_GetCount(take) > 0 then
				for i = 0, r.TakeFX_GetCount(take)-1 do
				local retval, name = r.TakeFX_GetFXName(take, i, '')
				if name:match('^'..TAG) then tagged = true return tagged end
				end
			end
		end
	end
end


local function GetObjChunk(obj_type, obj)
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua
		if not obj then return end
  -- Try standard function -----
	local t = obj_type == 1 and {r.GetTrackStateChunk(obj, '', false)} or {r.GetItemStateChunk(obj, '', false)} -- isundo = false
	local ret, obj_chunk = table.unpack(t)
		if ret and obj_chunk and #obj_chunk > 4194303 and not r.APIExists('SNM_CreateFastString') then return 'err_mess'
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

local function SetObjChunk(obj_type, obj, obj_chunk)
		if not (obj and obj_chunk) then return end
	return obj_type == 1 and r.SetTrackStateChunk(obj, obj_chunk, false) or r.SetItemStateChunk(obj, obj_chunk, false)
end

function Err_mess() -- if chunk size limit is exceeded and SWS extension isn't installed

	local sws_ext_err_mess = "              The size of data requires\n\n     the SWS/S&M extension to handle it.\n\nIf it's installed then it needs to be updated.\n\n         After clicking \"OK\" a link to the\n\n SWS extension website will be provided\n\n\tThe script will now quit."
	local sws_ext_link = 'Get the SWS/S&M extension at\nhttps://www.sws-extension.org/\n\n'

	local resp = r.MB(sws_ext_err_mess,'ERROR',0)
		if resp == 1 then r.ShowConsoleMsg(sws_ext_link, r.ClearConsole()) return end
end


function Edit_Chunk(TAG, obj_chunk, prev_GUID, fx_GUID, name, tagged)

	local tag = name:match('^'..TAG:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')..'%s')
	local fx_chunk = obj_chunk:match(prev_GUID..'.-BYPASS.-(<.-'..fx_GUID..')')

		if not tag and not tagged then -- append

-- in FX chunks FX custom name is only enclosed within quotes if it contains spaces, but placing them within quotes arbitrarily doesn't cause problems
-- without custom name TrackFX_GetFXName() function returns default name, the first one within quotes which features in the chunk for non-JS plugins and the one defined in the code for JS plugins, which doesn't feature in the chunk by default, but is fetched from reaper-jsfx.ini

			if fx_chunk:match('<JS')
			then
			local targ_str = fx_chunk:match('\"\"') and '\"\"' or name -- without a custom name it only contains ""
			local repl_str = targ_str == name and TAG..' '..name or '\"'..TAG..' '..name..'\"'
			local upd_fx_chunk = fx_chunk:gsub(targ_str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0'), repl_str)
			obj_chunk = obj_chunk:gsub(fx_chunk:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0'), upd_fx_chunk)
			elseif not fx_chunk:match('<VIDEO_EFFECT') then
				local name_esc = name:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
				local targ_str = fx_chunk:match('<.-\".-(0%s'..name_esc..')') or fx_chunk:match('<.-\".-(0%s\"'..name_esc..'\")') or '0 \"\"' -- when name is either without spaces and so without quotes, within quotes, or not set at all
				local repl_str = '0 \"'..TAG..' '..name..'\"'
				local upd_fx_chunk = fx_chunk:gsub(targ_str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0'), repl_str)
				obj_chunk = obj_chunk:gsub(fx_chunk:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0'), upd_fx_chunk)
			else -- Video processor
			local targ_str = fx_chunk:match('(<CODE\n|//.-)\n')
			local eval_tag = TAG:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')..' '
			local repl_str = (targ_str and not targ_str:match('^'..eval_tag)) and '<CODE\n|//'..TAG..' '..targ_str:match('//(.-)$') or (not targ_str and '<CODE\n|//'..TAG..' ') -- evaluate if there's commented out line in the preset code
			local upd_fx_chunk = fx_chunk:gsub(targ_str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0'), repl_str):gsub('%%', '%%%%') -- escape % which may be present in the Video processor code
			obj_chunk = obj_chunk:gsub(fx_chunk:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0'), upd_fx_chunk):gsub('%%%%', '%%')	-- restore original single % signs in the chunk
			end
		else -- remove
		local TAG = TAG:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')..' '
			if not fx_chunk:match('<VIDEO_EFFECT') then
			local targ_str = fx_chunk:match(name:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')) or '' -- the empty string is to address cases of batch removal when there's JS plugin for which lock tag has never been set and so whose name cannot be found in the chunk and would return nil otherwise
			local repl_str = targ_str:gsub(TAG, '')
			upd_fx_chunk = fx_chunk:gsub(targ_str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0'), repl_str)
			else -- Video processor
			local targ_str = fx_chunk:match('(<CODE\n|//'..TAG..')')
			local repl_str = targ_str:gsub(TAG, '') -- targ string without the tag
			upd_fx_chunk = fx_chunk:gsub(targ_str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0'), repl_str):gsub('%%', '%%%%') -- escape % which may be present in the Video processor code
			end
		obj_chunk = obj_chunk:gsub(fx_chunk:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0'), upd_fx_chunk):gsub('%%%%', '%%') -- restore original single % signs in the chunk
		end
	return obj_chunk, tagged_focused_fx
end


function APPND_OR_REMOVE_IN_FOCUS(TAG, retval, track_num, item_num, fx_num, mon_fx)

local tagged
local tag = TAG:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')..' ' -- only for the sake of evaluation here, to the function Edit_Chunk() original TAG is being passed

	if retval == 1 then -- track FX incl input and Master main FX
	local tr = r.GetTrack(0,track_num-1) or r.GetMasterTrack(0)
	local ret, tr_chunk = GetObjChunk(1, tr)
		if ret == 'err_mess' then Err_mess() r.defer(function() end) return end
		if ret then
		local retval, name = r.TrackFX_GetFXName(tr, fx_num, '')
			if name:match('^'..tag) then tagged = true end
		local fx_GUID = r.TrackFX_GetFXGUID(tr, fx_num):gsub('[%-]','%%%0')
		local prev_GUID = r.TrackFX_GetFXGUID(tr, fx_num-1) or ''
		local prev_GUID = prev_GUID:gsub('[%-]','%%%0')
		local tr_chunk = Edit_Chunk(TAG, tr_chunk, prev_GUID, fx_GUID, name, tagged)
		SetObjChunk(1, tr, tr_chunk)
		end
	elseif retval == 2 then -- take FX
	local item = r.GetTrackMediaItem(r.GetTrack(0,track_num-1), item_num)
	local ret, item_chunk = GetObjChunk(2, item)
		if ret == 'err_mess' then Err_mess() r.defer(function() end) return end
		if ret then
		local take = r.GetActiveTake(item)
		local retval, name = r.TakeFX_GetFXName(take, fx_num, '')
			if name:match('^'..tag) then tagged = true end
		local fx_GUID = r.TakeFX_GetFXGUID(take, fx_num):gsub('[%-]','%%%0')
		local prev_GUID = r.TakeFX_GetFXGUID(take, fx_num-1) or ''
		local prev_GUID = prev_GUID:gsub('[%-]','%%%0')
		local item_chunk = Edit_Chunk(TAG, item_chunk, prev_GUID, fx_GUID, name, tagged)
		SetObjChunk(2, item, item_chunk)
		end
	elseif mon_fx then -- Monitor FX
	r.InsertTrackAtIndex(r.GetNumTracks(), false) -- Insert new track at end of track list and hide it
	local tr = r.GetTrack(0,r.CountTracks(0)-1)
	r.SetMediaTrackInfo_Value(tr, 'B_SHOWINMIXER', 0)
	r.SetMediaTrackInfo_Value(tr, 'B_SHOWINTCP', 0)
	local master_tr = r.GetMasterTrack(0)
	local fx_num = r.TrackFX_GetRecChainVisible(master_tr)+0x1000000
	r.TrackFX_CopyToTrack(master_tr, fx_num, tr, 0, false) -- copy instead of removing to keep fx in case of an error below
	local ret, tr_chunk = GetObjChunk(1, tr)
		if ret == 'err_mess' then Err_mess() r.DeleteTrack(tr) r.defer(function() end) return end
		if ret then
		local retval, name = r.TrackFX_GetFXName(tr, 0, '')
			if name:match('^'..tag) then tagged = true end -- to avoid doing the following routine unnecessarily
		local fx_GUID = r.TrackFX_GetFXGUID(tr, 0):gsub('[%-]','%%%0')
		local prev_GUID = '' -- because it's the first FX on the temp track
		local tr_chunk = Edit_Chunk(TAG, tr_chunk, prev_GUID, fx_GUID, name, tagged)
		SetObjChunk(1, tr, tr_chunk)
		r.TrackFX_Delete(master_tr, fx_num) -- delete monitor fx
		r.TrackFX_CopyToTrack(tr, 0, master_tr, fx_num, false) -- copy over from the temp track
		r.DeleteTrack(tr)
		end
	end
	return tagged
end


function APPND_OR_REMOVE_IN_SEL_OBJ(TAG, tagged)

	local sel_tr_cnt = r.CountSelectedTracks2(0, true) -- incl. Master
		if sel_tr_cnt > 0 then
			for i = 0, sel_tr_cnt-1 do
			local tr = r.GetSelectedTrack(0,i) or r.GetMasterTrack(0)
			local ret, tr_chunk = GetObjChunk(1, tr)
			if ret == 'err_mess' then Err_mess() r.defer(function() end) return end
				if ret then
				local fx_cnt = r.TrackFX_GetCount(tr)
				local fx_GUID -- CRUCIAL ELEMENT ALONG WITH prev_GUID, must be outside of both main and input fx loops so on the one hand last GUID of main fx is considered when parsing 1st input fx chunk and on the other last GUID of the previous object chunk isn't used as prev_GUID for the 1st fx chunk of then next object but is reset
					if fx_cnt > 0 then
						for i = 0, fx_cnt-1 do
						local prev_GUID = fx_GUID or ''
						local retval, name = r.TrackFX_GetFXName(tr, i, '')
						fx_GUID = r.TrackFX_GetFXGUID(tr, i):gsub('[%-]','%%%0')
						tr_chunk = Edit_Chunk(TAG, tr_chunk, prev_GUID, fx_GUID, name, tagged)
						end -- main fx loop end
					end -- main fx count cond end

					if INCLUDE_INPUT_MON_FX ~= '' and r.TrackFX_GetRecCount(tr) > 0 then
						if select(2,r.GetTrackName(tr)) ~= 'MASTER' then
						local mon_fx
							for i = 0, r.TrackFX_GetRecCount(tr)-1 do
							local prev_GUID = fx_GUID or ''
							local retval, name = r.TrackFX_GetFXName(tr, i+0x1000000, '')
							fx_GUID = r.TrackFX_GetFXGUID(tr, i+0x1000000):gsub('[%-]','%%%0')
							tr_chunk = Edit_Chunk(TAG, tr_chunk, prev_GUID, fx_GUID, name, tagged)
							end
						else mon_fx = true
						SetObjChunk(1, tr, tr_chunk) -- set Master track chunk to be able to reuse the variables for the temp track chunk, could've been done by alternatively assigning the temp track chunk different vars and then setting its chunk separately from the main chunk setting below
						r.InsertTrackAtIndex(r.GetNumTracks(), false) -- Insert new track at end of track list and hide it
						tr = r.GetTrack(0,r.CountTracks(0)-1)
						r.SetMediaTrackInfo_Value(tr, 'B_SHOWINMIXER', 0)
						r.SetMediaTrackInfo_Value(tr, 'B_SHOWINTCP', 0)
						master_tr = r.GetMasterTrack(0)
							for i = 0, r.TrackFX_GetRecCount(master_tr)-1 do -- copy to temp track
							r.TrackFX_CopyToTrack(master_tr, i+0x1000000, tr, i, false)
							end
						ret, tr_chunk = GetObjChunk(1, tr)
							if ret == 'err_mess' then Err_mess() r.defer(function() end) return end
								if ret then
								local fx_GUID -- reset so the last prev GUID for the temp track fx chunk isn't carried over from the chunk of the prev object
									for i = 0, r.TrackFX_GetCount(tr)-1 do -- edit chunk of the temp track
									local prev_GUID = fx_GUID or ''
									local retval, name = r.TrackFX_GetFXName(tr, i, '')
									fx_GUID = r.TrackFX_GetFXGUID(tr, i):gsub('[%-]','%%%0')
									tr_chunk = Edit_Chunk(TAG, tr_chunk, prev_GUID, fx_GUID, name, tagged)
									end
								end -- temp track chunk ret cond end
							end -- regular/master track cond end
						end -- input/mon included cond end
				SetObjChunk(1, tr, tr_chunk) -- main ret cond level
					if mon_fx then
						for i = r.TrackFX_GetRecCount(master_tr)-1,0,-1 do -- delete all monitor fx
						r.TrackFX_Delete(master_tr, i+0x1000000)
						end
						for i = 0, r.TrackFX_GetCount(tr)-1 do -- copy over from the temp track
						r.TrackFX_CopyToTrack(tr, i, master_tr, i+0x1000000, false)
						end
					r.DeleteTrack(tr)
					end -- mon fx cond end
				end -- track ret chunk cond end
			end -- track loop end
		end -- track count cond end

	local sel_itms_cnt = r.CountSelectedMediaItems(0)
		if sel_itms_cnt > 0 then
			for i = 0, sel_itms_cnt-1 do
			local item = r.GetSelectedMediaItem(0,i)
			local take = r.GetActiveTake(item)
			local fx_cnt = r.TakeFX_GetCount(take)
				if fx_cnt > 0 then
				local ret, item_chunk = GetObjChunk(2, item)
					if ret == 'err_mess' then Err_mess() r.defer(function() end) return end
				local fx_GUID -- see explanation in the track loop
					if ret then
						for i = 0, fx_cnt-1 do
						local prev_GUID = fx_GUID or ''
						local retval, name = r.TakeFX_GetFXName(take, i, '')
						fx_GUID = r.TakeFX_GetFXGUID(take, i):gsub('[%-]','%%%0')
						item_chunk = Edit_Chunk(TAG, item_chunk, prev_GUID, fx_GUID, name, tagged)
						end
					SetObjChunk(2, item, item_chunk)
					end
				end
			end
		end

end


r.Undo_BeginBlock()
r.PreventUIRefresh(1)

TAG = Get_TAG_Val() ~= '' and Get_TAG_Val() or TAG

local err = TAG == '' and 'The lock tag hasn\'t been defined.' or ((TAG == '"' or TAG == '%') and '        Illegal tag. Quotation mark \"\n\nand percent sign % aren\'t supported.')
	if err then r.MB(err,'ERROR',0) r.defer(function() end) return end

local retval, track_num, item_num, fx_num = r.GetFocusedFX() -- item_num is number within the track whose index is returned as track_num
local mon_fx = retval == 0 and r.TrackFX_GetRecChainVisible(r.GetMasterTrack(0)) >= 0

	if FOCUSED ~= '' and (retval > 0 or mon_fx) then
	local tagged = APPND_OR_REMOVE_IN_FOCUS(TAG, retval, track_num, item_num, fx_num, mon_fx)
	undo_inset1 = not tagged and 'Append tag to' or 'Remove tag from'
	undo_inset2 = ' the name of the focused FX'
	else
	local tagged = DETECT_TAG(TAG)
	undo_inset1 = not tagged and 'Append tag to' or 'Remove tag from'
	undo_inset2 = ' FX names in selected objects'
	Msg(tagged)
	APPND_OR_REMOVE_IN_SEL_OBJ(TAG, tagged)
	end

r.PreventUIRefresh(-1)
r.Undo_EndBlock(undo_inset1..undo_inset2, -1)




