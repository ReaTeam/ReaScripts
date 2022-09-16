--[[ 
ReaScript name: Load FX chain on selected objects via file dialogue (guide inside)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.1
Changelog: #Added a setting for custom FXChains folder
	   #Fixed breaking plugin parameter link
About: 

  Allows loading selected FX chain on selected objects.

  The script had been developed before the option to add FX and FX chain preset
  to multiple tracks/takes at once was introduced in REAPER build 6.12c.  
  Still the script expands on this native feature in that it allows adding FX chain 
  preset to tracks and takes and to track main and input/Monitoring FX chain 
  in one go. It also provides a setting for configuring custom FXChains folder
  different from the default one located in the REAPER resourse directory.
  
  * By default the script works in add/replace mode adding FX chain to selected
  objects which don't have any and replacing current FX chain in those which do.

  * When option ADD_APPEND is enabled in the USER SETTINGS below the script works
  in add/append mode where instead of replacing current FX chain it appends it
  with the FX chain being added, placing it downstream.

  * When both options DIALOGUE and ADD_APPEND are enabled in the USER SETTINGS below
  the user is presented with the dialogue allowing them to choose between the two
  modes every time the script is used.

  * The USER SETTINGS options TRACK_MAIN_FX, TRACK_INPUT_MON_FX, TAKE_FX allow to
  enable/disable loading FX chain as a particular FX chain type.
  
  * The USER SETTINGS option CUSTOM_FX_CHAIN_DIR allows using a custom FXChains
  folder as a primary location for loading FX chain presets.

  * If an item has several takes the FX chain is only applied to the active one.
  
  * To include Monitor FX chain in selected objects select Master track. Be aware
  that if TRACK_MAIN_FX option is enabled the same FX chain will also be loaded
  as the Master track main FX chain.

  * It's advised to load FX chain preset to Monitor FX chain with the chain closed,
  otherwise REAPER will freeze for a short while as the chain is being updated
  and the arrange is being redrawn.

Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M (not obligatory but recommended)
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Insert full path to your custom FXChains folder between the double square
-- brackets;
-- if empty or malformed REAPER's default FXChains folder will be used
CUSTOM_FX_CHAIN_DIR = [[]]

-- To disable any of the following options remove the character between
-- the quotation marks next to it.
-- Conversely, to enable one place any alphanumeric character between those.
-- Try to not leave empty spaces.

DIALOGUE = "1" -- choose mode of operation at runtime when ADD_APPEND is enabled
ADD_APPEND = "1" -- add/append mode instead of add/replace
TRACK_MAIN_FX = "1" -- load as track main FX chain
TRACK_INPUT_MON_FX = "" -- load as track input FX and Master track Monitor FX chains
TAKE_FX = "1" -- load as take FX chain

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


function Msg(param)
reaper.ShowConsoleMsg(tostring(param)..'\n')
end


local r = reaper

-- Validate path supplied in the user settings
function Validate_Folder_Path(path) -- returns empty string if path is empty and nil if it's not a string
	if type(path) == 'string' then
	local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces
	-- return not path:match('.+[\\/]$') and path:match('[\\/]') and path..path:match('[\\/]') or path -- add last separator if none
-- more efficient:
	return path..(not path:match('.+[\\/]$') and path:match('[\\/]') or '') -- add last separator if none
	end
end

function Dir_Exists(path) -- short
local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces
local sep = path:match('[\\/]')
local path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- last separator is removed to return 1 (valid)
local _, mess = io.open(path)
return mess:match('Permission denied') and path..sep -- dir exists // this one is enough
end


local function GetObjChunk(retval, obj)
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


function Err_mess() -- if chunk size limit is exceeded and SWS extension isn't installed

	local sws_ext_err_mess = "              The size of data requires\n\n     the SWS/S&M extension to handle it.\n\nIf it's installed then it needs to be updated.\n\n         After clicking \"OK\" a link to the\n\n SWS extension website will be provided\n\n\tThe script will now quit."
	local sws_ext_link = 'Get the SWS/S&M extension at\nhttps://www.sws-extension.org/\n\n'

	local resp = r.MB(sws_ext_err_mess,'ERROR',0)
		if resp == 1 then r.ShowConsoleMsg(sws_ext_link, r.ClearConsole()) return end
end


local function SetObjChunk(retval, obj, obj_chunk)
		if not (obj and obj_chunk) then return end
	return retval == 1 and r.SetTrackStateChunk(obj, obj_chunk, false) or r.SetItemStateChunk(obj, obj_chunk, false)
end


function Error_Tooltip(text)
local x, y = r.GetMousePosition()
--r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
end


local function UpdateTrackMainFXChainChunk(tr_chunk, fx_ch_chunk, ADD_APPEND) -- track main fx

local fx_chunk = tr_chunk:match('(<FXCHAIN.-DOCKED%s%d)\n>') or -- residual data after main fx chain is deleted
tr_chunk:match('<FXCHAIN\n.-(BYPASS.-)\n<FXCHAIN_REC') or -- main fx and input fx; FXCHAIN\n- excludes input fx section name, here and elsewhere
tr_chunk:match('<FXCHAIN\n.-(BYPASS.-)\n<ITEM') or -- main fx, no input fx but items
tr_chunk:match('<FXCHAIN\n.-(BYPASS.-)\n>\n$') or -- main fx, no input fx & no items; \n$ accounts for trailing empty line
tr_chunk:match('(<TRACK.-)\n<FXCHAIN_REC') or -- no main fx but input fx
tr_chunk:match('(<TRACK.-)\n<ITEM') or -- neither main fx nor input fx but items
tr_chunk:match('(<TRACK.-)\n>\n<TRACK') or -- neither fx nor items
tr_chunk:match('(<TRACK.-)\n>') -- neither fx nor items and last track
-- OR
-- tr_chunk:sub(1,-4) -- 4 because the chunk is returned with trailing empty line, so 1 = \n, 2 = >, 3 = \n and 4 = last character on the last track chunk line before >
local fx_chunk_orig = fx_chunk:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
local fx_ch_chunk1 = fx_ch_chunk:gsub('%%','%%%%')..'\n>' -- ADD_REPLACE

	if ADD_APPEND then
	local fx_ch_chunk = fx_chunk:match('<FXCHAIN_REC') and fx_chunk:match('(BYPASS.*WAK[%s%d]*)\n>\n<FXCHAIN_REC')..fx_ch_chunk..'\n>' or (fx_chunk:match('BYPASS') and fx_chunk:match('(BYPASS.*WAK[%s%d]*)[\n>]*')..fx_ch_chunk..'\n>' or fx_ch_chunk)
	fx_ch_chunk1 = fx_ch_chunk:gsub('%%','%%%%')
	end

local fx_ch_chunk2 = (fx_chunk..'\n'..fx_ch_chunk):gsub('%%','%%%%')
local fx_ch_chunk3 = (fx_chunk..'\n<FXCHAIN\n'..fx_ch_chunk..'\n>'):gsub('%%','%%%%')
local tr_chunk = fx_chunk:match('BYPASS') and tr_chunk:gsub(fx_chunk_orig, fx_ch_chunk1) or fx_chunk:match('FXCHAIN') and tr_chunk:gsub(fx_chunk_orig, fx_ch_chunk2) or ((fx_chunk:match('<TRACK') and tr_chunk:gsub(fx_chunk_orig, fx_ch_chunk3)))

return tr_chunk

end


function UpdateTrackInputFXChainChunk(tr_chunk, fx_ch_chunk, ADD_APPEND) -- track input fx

local fx_chunk = tr_chunk:match('<FXCHAIN_REC.-(BYPASS.-)\n<ITEM') or -- input fx and items
tr_chunk:match('<FXCHAIN_REC.-(BYPASS.-)\n>\n$') or -- input fx & no items; \n$ accounts for trailing empty line
tr_chunk:match('(<TRACK.-)[\n>]*\n<ITEM') or -- no input fx and items, accounting for main fx
tr_chunk:match('(<TRACK.-)\n>[\n>]*\n$') -- neither input fx nor items, accounting for main fx incl. residual data after main fx chain is deleted
local fx_chunk_orig = fx_chunk:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
local fx_ch_chunk1 = fx_ch_chunk:gsub('%%','%%%%')..'\n>' -- ADD_REPLACE

	if ADD_APPEND then
	local fx_ch_chunk = (fx_chunk:match('BYPASS') and not fx_chunk:match('TRACK')) and fx_chunk:match('(BYPASS.*WAK[%s%d]*)[\n>]*')..fx_ch_chunk..'\n>' or fx_ch_chunk
	fx_ch_chunk1 = fx_ch_chunk:gsub('%%','%%%%')
	end

local closure1 = fx_chunk:match('<FXCHAIN\n') and '\n>' or ''
local closure2 = closure1 == '\n>' and '' or '\n>'
local fx_ch_chunk2 = (fx_chunk..closure1..'\n<FXCHAIN_REC\n'..fx_ch_chunk..closure2):gsub('%%','%%%%')
local tr_chunk = not fx_chunk:match('TRACK') and tr_chunk:gsub(fx_chunk_orig, fx_ch_chunk1) or tr_chunk:gsub(fx_chunk_orig, fx_ch_chunk2)

return tr_chunk

end


function UpdateMasterTrackFXChainChunk(tr_chunk, fx_ch_chunk, ADD_APPEND) -- Master track fx

local fx_chunk = tr_chunk:match('<FXCHAIN.-(BYPASS.*WAK[%s%d]*)\n>') or -- fx chain; \n$ accounts for trailing empty line
tr_chunk:match('<FXCHAIN\n(.-)\n>\n$') or -- residual data after fx chain is deleted; \n$ accounts for trailing empty line
tr_chunk:sub(1,-4) -- no fx chain and no residual fx chain but other data or no other data; 4 because the chunk is returned with trailing empty line, so 1 = \n, 2 = >, 3 = \n and 4 = last character on the last track chunk line before >

local fx_chunk_orig = fx_chunk:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
local fx_ch_chunk1 = fx_ch_chunk:gsub('%%','%%%%')..'\n>'

	if ADD_APPEND then
	local fx_ch_chunk = fx_chunk:match('BYPASS') and fx_chunk..fx_ch_chunk..'\n>' or fx_ch_chunk
	fx_ch_chunk1 = fx_ch_chunk:gsub('%%','%%%%')
	end

local fx_ch_chunk2 = (fx_chunk..'\n<FXCHAIN\n'..fx_ch_chunk..'\n>'):gsub('%%','%%%%')
local tr_chunk = fx_chunk:match('BYPASS') and tr_chunk:gsub(fx_chunk_orig, fx_ch_chunk1) or tr_chunk:gsub(fx_chunk_orig, fx_ch_chunk2)

return tr_chunk

end


function UpdateTakeFXChainChunk(item_chunk, take_GUID, fx_ch_chunk, ADD_APPEND) -- take fx

local fx_chunk = item_chunk:match('('..take_GUID..'.-)\nTAKE') or -- there's next take
item_chunk:match('('..take_GUID..'.*)') -- there's no next take

local fx_chunk_orig = fx_chunk:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
local fx_ch_chunk_1 = fx_ch_chunk:gsub('%%','%%%%') -- to be used when there're take fx

	if ADD_APPEND then
	fx_ch_chunk_1 = fx_chunk:match('BYPASS') and (fx_chunk:match('BYPASS.*WAK[%s%d]-')..fx_ch_chunk):gsub('%%','%%%%')
	end

local fx_ch_chunk_2 = (fx_chunk:match(take_GUID..'.->')..'\n<TAKEFX\n'..fx_ch_chunk..'>'):gsub('%%','%%%%') -- to be used when there're no take fx
local upd_fx_chunk = fx_chunk:match('BYPASS') and fx_chunk:gsub('BYPASS.*WAK[%s%d]-', fx_ch_chunk_1) or
fx_chunk:gsub(take_GUID..'.->', fx_ch_chunk_2)

local upd_fx_chunk = upd_fx_chunk:gsub('%%','%%%%')
local item_chunk = item_chunk:gsub(fx_chunk_orig, upd_fx_chunk)

return item_chunk

end


local DIALOGUE = DIALOGUE:gsub('[%s]','') ~= ''
local ADD_APPEND = ADD_APPEND:gsub('[%s]','') ~= ''
local TRACK_MAIN_FX = TRACK_MAIN_FX:gsub('[%s]','') ~= ''
local TRACK_INPUT_MON_FX = TRACK_INPUT_MON_FX:gsub('[%s]','') ~= ''
local TAKE_FX = TAKE_FX:gsub('[%s]','') ~= ''
local CUSTOM_FX_CHAIN_DIR = #CUSTOM_FX_CHAIN_DIR:gsub('[%s]','') > 0 and CUSTOM_FX_CHAIN_DIR

local sel_trk_cnt = r.CountSelectedTracks2(0,true) -- incl. Master
local sel_itms_cnt = r.CountSelectedMediaItems(0)

	local err1 = (sel_trk_cnt == 0 and sel_itms_cnt == 0) and 'No selected objects.'
	local err2 = (sel_trk_cnt > 0 and not TRACK_MAIN_FX and not TRACK_INPUT_MON_FX) and 'Loading FX chain on tracks\n\nhas been disabled in the USER SETTINGS.' or ((sel_itms_cnt > 0 and not TAKE_FX) and 'Loading FX chain on items\n\nhas been disabled in the USER SETTINGS.')
	local err = err1 or err2
		if err then r.MB(err,'ERROR',0) r.defer(function() end) return end


local path = reaper.GetResourcePath()
local sep = r.GetOS():match('Win') and '\\' or '/'

local fx_chain_dir = CUSTOM_FX_CHAIN_DIR and Dir_Exists(Validate_Folder_Path(CUSTOM_FX_CHAIN_DIR)) or path..sep..'FXChains'..sep

	if CUSTOM_FX_CHAIN_DIR and fx_chain_dir == path..sep..'FXChains'..sep then
	Error_Tooltip('\n\n        custom fx chain \n\n     directory isn\'t valid \n\n opening default directory \n\n')
	end

::RETRY::
local retval, file = r.GetUserFileNameForRead(fx_chain_dir, 'Select and load FX chain', '.RfxChain')
	if not retval then r.defer(function() end) return end
	if not file:match('%.RfxChain$') then resp = r.MB('        The selected file desn\'t\n\n      appear to be an FX chain.\n\n            Click "OK" to retry.','ERROR',1)
		if resp == 1 then goto RETRY
		else r.defer(function() end) return end
	end


local file = io.open(file, 'r')
local fx_ch_chunk = file:read('*a')
file:close()
	if fx_ch_chunk == '' then resp = r.MB('The FX chain file is empty.\n\nClick "OK" to retry.','ERROR',1)
		if resp == 1 then goto RETRY
		else r.defer(function() end) return end
	end

	if DIALOGUE and ADD_APPEND then resp = r.MB('Choose the mode of operation...\n\n"YES" - to add/replace     "NO" - to add/append.','PROMPT',3)
		if resp == 6 then ADD_APPEND = false
		elseif resp == 7 then ADD_APPEND = true
		else r.defer(function() end) return end
	end

r.PreventUIRefresh(1)
r.Undo_BeginBlock()

		if sel_trk_cnt > 0 then
			for i = 0, sel_trk_cnt-1 do
			local tr = r.GetSelectedTrack(0,i) or r.GetMasterTrack(0) -- or r.GetSelectedTrack2(0,i,1) -- incl. Master
			local ret, tr_chunk = GetObjChunk(1, tr)
				if ret == 'err_mess' then Err_mess() r.defer(function() end) return -- if chunk size limit is exceeded
				elseif ret and tr_chunk ~= '' then
				-- extract main fx chunk
					if reaper.CSurf_TrackToID(tr, true) ~= 0 then -- if not Master track
						if TRACK_MAIN_FX then -- track main fx chain
						tr_chunk = UpdateTrackMainFXChainChunk(tr_chunk, fx_ch_chunk, ADD_APPEND)
						end
						if TRACK_INPUT_MON_FX then -- track input fx chain
						tr_chunk = UpdateTrackInputFXChainChunk(tr_chunk, fx_ch_chunk, ADD_APPEND)
						end
					-- Master track
					elseif r.CSurf_TrackToID(tr, true) == 0 then -- if Master track
						if TRACK_MAIN_FX then -- Master track main fx
						tr_chunk = UpdateMasterTrackFXChainChunk(tr_chunk, fx_ch_chunk, ADD_APPEND)
						end
						if TRACK_INPUT_MON_FX then -- monitor fx chain
						r.InsertTrackAtIndex(r.GetNumTracks(), false) -- insert new track at the end of track list and hide it
						local temp_track = r.GetTrack(0,r.CountTracks(0)-1)
						r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINMIXER', 0)
						r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINTCP', 0)
						-- insert FX chain on the temp track
						local ret, tr_chunk = GetObjChunk(1, temp_track)
						local tr_chunk = UpdateTrackMainFXChainChunk(tr_chunk, fx_ch_chunk)
						SetObjChunk(1, temp_track, tr_chunk)
						local mon_fx_cnt = r.TrackFX_GetRecCount(tr)
						local mon_fx_vis = r.TrackFX_GetRecChainVisible(tr)
							if not ADD_APPEND then
								for i = mon_fx_cnt-1,0,-1 do -- delete all mon fx
								r.TrackFX_Delete(tr, i+0x1000000) -- or i+16777216
								end
							end
							for i = 0, r.TrackFX_GetCount(temp_track)-1 do -- copy fx from temp track to mon fx chain
							local dest_idx = ADD_APPEND and i+mon_fx_cnt or i
							r.TrackFX_CopyToTrack(temp_track, i, tr, dest_idx+0x1000000, false) -- or i+16777216
							end
						r.DeleteTrack(temp_track)
						-- a crude means to update mon fx button coloration from grey to either green or red as it fails to update automatically
						r.TrackFX_Show(tr, 0x1000000, 1)
						r.TrackFX_Show(tr, 0x1000000, 0)
						local reopen_mon_fx = mon_fx_vis >= 0 and r.TrackFX_Show(tr, mon_fx_vis, 1)
						end
					end
				local ret = SetObjChunk(1, tr, tr_chunk)
				end -- chunk ret cond end
			end -- track loop end
		end

		if sel_itms_cnt > 0 and TAKE_FX then
			for i = 0, sel_itms_cnt-1 do
			local item = r.GetSelectedMediaItem(0,i)
			local ret, item_chunk = GetObjChunk(2, item)
				if ret == 'err_mess' then Err_mess() r.defer(function() end) return -- if chunk size limit is exceeded
				elseif ret and item_chunk ~= '' then
				local take = r.GetActiveTake(item)
				local take_GUID = select(2,r.GetSetMediaItemTakeInfo_String(take, 'GUID', '', false)):gsub('[%-]','%%%0')
				local item_chunk = UpdateTakeFXChainChunk(item_chunk, take_GUID, fx_ch_chunk, ADD_APPEND)
				local ret = SetObjChunk(2, item, item_chunk)
				end
			end
		end


-- Concatenate undo point caption

	local undo = 'Load FX chain on selected '
	local undo = (sel_trk_cnt > 0 and sel_itms_cnt > 0) and undo..'objects' or ((sel_trk_cnt > 0 and sel_itms_cnt == 0) and undo..'tracks' or ((sel_trk_cnt == 0 and sel_itms_cnt > 0) and undo..'items (takes)'))


r.Undo_EndBlock(undo,-1)

r.PreventUIRefresh(-1)


