-- @description Load FX chain on selected objects (guide inside)
-- @author BuyOne
-- @website https://forum.cockos.com/member.php?u=134058
-- @version 1.0
-- @changelog Initial release
-- @about Allows loading selected FX chain on selected objects. Detailed description is available inside the script.

--[[
	* Licence: WTFPL
	* REAPER: at least v5.962
	* Extensions: SWS/S&M (not obligatory but recommended)


By default the script works in add/replace mode adding FX chain to selected
objects which don't have any and replacing current FX chain in those which do.

When option ADD_APPEND is enabled in the USER SETTINGS below the script works
in add/append mode where instead of replacing current FX chain it appends it
with the FX chain being added, placing it downstream.

When both options DIALOGUE and ADD_APPEND are enabled in the USER SETTINGS below
the user is presented with the dialogue allowing them to choose between the two
modes every time the script is used.

The USER SETTINGS options TRACK_MAIN_FX, TRACK_INPUT_MON_FX, TAKE_FX allow to
enable/disable loading FX chain as a particular FX chain type.

If item has several takes the FX chain is only applied to the selected one.

It's advised to load FX chain preset to Monitor FX chain with the chain closed,
otherwise REAPER will freeze for a short while as the chain is being updated
and the arrange is being redrawn.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- To disable any of the options remove the character between the quotation
-- marks next to it.
-- Conversely, to enable one place any alphanumeric character between those.
-- Try to not leave empty spaces.

DIALOGUE = "" -- choose mode of operation at runtime when ADD_APPEND is enabled
ADD_APPEND = "" -- add/append mode instead of add/replace
TRACK_MAIN_FX = "1" -- load as track main FX chain
TRACK_INPUT_MON_FX = "1" -- load as track input FX and Master track Monitor FX chains
TAKE_FX = "1" -- load as take FX chain

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


function Msg(param)
reaper.ShowConsoleMsg(tostring(param)..'\n')
end


local r = reaper

local function GetObjChunk(retval, obj)
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua
		if not obj then return end
  -- Try standard function -----
	local t = retval == 1 and {r.GetTrackStateChunk(obj, '', false)} or {r.GetItemStateChunk(obj, '', false)} -- isundo = false
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


function Err_mess() -- if chunk size limit is exceeded and SWS extension isn't installed

	local sws_ext_err_mess = "              The size of data requires\n\n     the SWS/S&M extension to handle it.\n\nIf it's installed then it needs to be updated.\n\n         After clicking \"OK\" a link to the\n\n SWS extension website will be provided\n\n\tThe script will now quit."
	local sws_ext_link = 'Get the SWS/S&M extension at\nhttps://www.sws-extension.org/\n\n'

	local resp = r.MB(sws_ext_err_mess,'ERROR',0)
		if resp == 1 then r.ShowConsoleMsg(sws_ext_link, r.ClearConsole()) return end
end


local function SetObjChunk(retval, obj, obj_chunk) -- retval stems from r.GetFocusedFX(), value 0 is only considered at the pasting stage because in the copying stage it's error caught before the function
		if not (obj and obj_chunk) then return end
	return retval == 1 and r.SetTrackStateChunk(obj, obj_chunk, false) or r.SetItemStateChunk(obj, obj_chunk, false)
end


local function UpdateTempTrackChunk(tr_chunk, fx_ch_chunk)

local fx_chunk = tr_chunk:match('(<TRACK.-)\n>')
local fx_chunk_orig = fx_chunk:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
local fx_ch_chunk = (fx_chunk..'\n<FXCHAIN\n'..fx_ch_chunk..'\n>'):gsub('%%','%%%%')
return tr_chunk:gsub(fx_chunk_orig, fx_ch_chunk)

end


local DIALOGUE = DIALOGUE:gsub('[%s]','') ~= ''
local ADD_APPEND = ADD_APPEND:gsub('[%s]','') ~= ''
local TRACK_MAIN_FX = TRACK_MAIN_FX:gsub('[%s]','') ~= ''
local TRACK_INPUT_MON_FX = TRACK_INPUT_MON_FX:gsub('[%s]','') ~= ''
local TAKE_FX = TAKE_FX:gsub('[%s]','') ~= ''


local sel_trk_cnt = r.CountSelectedTracks2(0,true) -- incl. Master
local sel_itms_cnt = r.CountSelectedMediaItems(0)

	local err1 = (sel_trk_cnt == 0 and sel_itms_cnt == 0) and 'No selected objects.'
	local err2 = (sel_trk_cnt > 0 and not TRACK_MAIN_FX and not TRACK_INPUT_MON_FX) and 'Loading FX chain on tracks\n\nhas been disabled in the USER SETTINGS.' or ((sel_itms_cnt > 0 and not TAKE_FX) and 'Loading FX chain on items\n\nhas been disabled in the USER SETTINGS.')
	local err = err1 or err2
		if err then r.MB(err,'ERROR',0) r.defer(function() end) return end


local path = reaper.GetResourcePath()
local sep = r.GetOS():match('Win') and '\\' or '/'

::RETRY::
local retval, file = r.GetUserFileNameForRead(path..sep..'FXChains'..sep, 'Select and load FX chain', '.RfxChain')
	if not retval then r.defer(function() end) return end
	if not file:match('%.RfxChain$') then resp = r.MB('        The selected file desn\'t\n\n      appear to be an FX chain.\n\n            Click "OK" to retry.','ERROR',1)
		if resp == 1 then goto RETRY
		else r.defer(function() end) return end
	end


local file = io.open(file, 'r')
local fx_ch_chunk = file:read('*a')
file:close()
	if fx_ch_chunk == '' then resp = r.MB('The FX chain file is empty.\n\n   Click "OK" to retry.','ERROR',1)
		if resp == 1 then goto RETRY
		else r.defer(function() end) return end
	end

	if DIALOGUE and ADD_APPEND then resp = r.MB('Choose the mode of operation...\n\n"YES" - to add/replace     "NO" - to add/append.','PROMPT',3)
		if resp == 6 then ADD_APPEND = false
		elseif resp == 7 then ADD_APPEND = true
		else r.defer(function() end) return end
	end

r.PreventUIRefresh(1)

-- Insert temp track an load FX chain to it

	r.InsertTrackAtIndex(r.GetNumTracks(), false) -- insert new track at the end of track list and hide it
	local temp_track = r.GetTrack(0,r.CountTracks(0)-1)
	r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINMIXER', 0)
	r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINTCP', 0)
	-- load FX chain on the temp track
	local ret, tr_chunk = GetObjChunk(1, temp_track)
		if ret == 'err_mess' then Err_mess() r.defer(function() end) return end
	local tr_chunk = UpdateTempTrackChunk(tr_chunk, fx_ch_chunk)
	SetObjChunk(1, temp_track, tr_chunk)

r.Undo_BeginBlock()	
	
-- Copy FX from the temp track to selected objects

		if sel_trk_cnt > 0 then
			for i = 0, sel_trk_cnt-1 do
			local tr = r.GetSelectedTrack(0,i) or r.GetMasterTrack(0)
			local fx_cnt = r.TrackFX_GetRecCount(tr)
				if TRACK_MAIN_FX then
					if not ADD_APPEND then
						for i = fx_cnt-1,0,-1 do -- delete all fx
						r.TrackFX_Delete(tr, i)
						end
					end
					for i = 0, r.TrackFX_GetCount(temp_track)-1 do -- copy fx from temp track to mon fx chain
					local dest_idx = ADD_APPEND and i+fx_cnt or i
					r.TrackFX_CopyToTrack(temp_track, i, tr, dest_idx, false)
					end
				end
				if TRACK_INPUT_MON_FX then
				local fx_cnt = r.TrackFX_GetRecCount(tr)
					if not ADD_APPEND then
						for i = fx_cnt-1,0,-1 do -- delete all input/monitor fx
						r.TrackFX_Delete(tr, i+0x1000000) -- or i+16777216
						end
					end
					for i = 0, r.TrackFX_GetCount(temp_track)-1 do -- copy fx from temp track to mon fx chain
					local dest_idx = ADD_APPEND and i+fx_cnt or i
					r.TrackFX_CopyToTrack(temp_track, i, tr, dest_idx+0x1000000, false) -- or i+16777216
					end
					-- a crude means to update mon fx button coloration from grey to either green or red as it fails to update automatically
					if reaper.CSurf_TrackToID(tr, true) == 0 then -- if Master track and so Minitor FX chain
					local mon_fx_vis = r.TrackFX_GetRecChainVisible(tr) -- get index of fx open in the mon fx chain to reopen after update below
					r.TrackFX_Show(tr, 0x1000000, 1)
					r.TrackFX_Show(tr, 0x1000000, 0)
					local reopen_mon_fx = mon_fx_vis >= 0 and r.TrackFX_Show(tr, mon_fx_vis, 1)
					end
				end
			end
		end
	
		if sel_itms_cnt > 0 and TAKE_FX then
			for i = 0, sel_itms_cnt-1 do
			local take = r.GetActiveTake(r.GetSelectedMediaItem(0,i))
			local fx_cnt = r.TakeFX_GetCount(take)
				if not ADD_APPEND then
					for i = fx_cnt-1,0,-1 do -- delete all fx
					r.TakeFX_Delete(take, i)
					end
				end
				for i = 0, r.TrackFX_GetCount(temp_track)-1 do -- copy fx from temp track to mon fx chain
				local dest_idx = ADD_APPEND and i+fx_cnt or i
				r.TrackFX_CopyToTake(temp_track, i, take, dest_idx, false)
				end
			end
		end


-- Concatenate undo point caption

	local undo = 'Load FX chain on selected '
	local undo = (sel_trk_cnt > 0 and sel_itms_cnt > 0) and undo..'objects' or ((sel_trk_cnt > 0 and sel_itms_cnt == 0) and undo..'tracks' or ((sel_trk_cnt == 0 and sel_itms_cnt > 0) and undo..'items (takes)'))


r.Undo_EndBlock(undo,-1)

r.DeleteTrack(temp_track)
r.PreventUIRefresh(-1)



