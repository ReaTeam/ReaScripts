--[[
ReaScript Name: (Un)Tag FX with (in)active parameter modulation
Author: BuyOne
Version: 1.0
Changelog: Initial release
Author URL: https://forum.cockos.com/member.php?u=134058
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M extension (not mandatory but recommended)
About:  As the name suggests the script appends/clears tag 
	to/from track and take FX name if FX has/doesn't have
	active envelope.  
	The tag is added at the beginning of the FX name in the
	FX chain.  
	The script must be run manually.  
	To be aware: the tag won't be displayed in FX names in the 
	track FX button right click menu and in its tooltip
	if default FX names are used because these in REAPER are 
	truncated automatically.  
	So to check for them FX chain window will have to be opened.  
	Refer to USER SETTINGS below.

	!!! WARNING !!!   

	With 3d party plugins which store lots of data the FX name
	tagging may take a very long while and during the process 
	REAPER will freeze.  
	Just in case SAVE YOUR WORK BEFORE APPLYING THE SCRIPT so
	if you're forced to shut down the program you can resume 
	from where you've left off.  
	If you find that applying the script to FX in the entire 
	project does cause freezing, try applying it only to selected
	objects by enabling SELECTED_ONLY setting in the USER SETTINGS.

	ATTENTION  
	If you're going to use this script with  
	BuyOne_(Un)Tag FX with (in)active envelopes.lua  
	make sure that in the USER SETTINGS of these scripts the TAG 
	settings are different, otherwise you won't be able to add a 
	tag with one script after it's been added by another one.
]]
----------------------------------------------------
------------------- USER SETTINGS ------------------
----------------------------------------------------

-- Insert any QWERTY character or word(s)
-- between the quotes;
-- not advised to change the TAG setting
-- after applying the TAG, because the new one will
-- be added to the old one and the old one won't be
-- cleared from FX names when there's no envelope.
TAG = "!"

-- Insert any alphanumeric character
-- between the quotes to make the script
-- also target take FX names.
TAKEFX = ""

-- Insert any alphanumeric character
-- between the quotes to limit the script 
-- scope to selected objects only;
-- TAKEFX setting above still applies.
SELECTED_ONLY = ""

-----------------------------------------------------
---------------- END OF USER SETTINGS ---------------
-----------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper

local function GetObjChunk(obj)
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua
		if not obj then return end
local tr = r.ValidatePtr(obj, 'MediaTrack*')
local item = r.ValidatePtr(obj, 'MediaItem*')
  -- Try standard function -----
	local t = tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} -- isundo = false
	local ret, obj_chunk = table.unpack(t)
		if ret and obj_chunk and #obj_chunk >= 4194303 and not r.APIExists('SNM_CreateFastString') then return 'err_mess'
		elseif ret and obj_chunk and #obj_chunk < 4194303 then return ret, obj_chunk -- 4194303 bytes = (4096 kb * 1024 bytes) - 1 byte
		end
-- If chunk_size >= max_size, use wdl fast string --
	local fast_str = r.SNM_CreateFastString('')
		if r.SNM_GetSetObjectState(obj, fast_str, false, false) -- setnewvalue and wantminimalstate = false
		then obj_chunk = r.SNM_GetFastString(fast_str)
		end
	r.SNM_DeleteFastString(fast_str)
		if obj_chunk then return true, obj_chunk end
end


function Err_mess(err_cnt) -- if chunk size limit is exceeded and SWS extension isn't installed
local err_mess = 'The size of data of '..err_cnt..' object(s) requires\n\nSWS/S&M extension to handle them.\n\nIf it\'s installed then it needs to be updated.\n\nGet the latest build of SWS/S&M extension at\nhttps://www.sws-extension.org/\n\n'
r.ShowConsoleMsg(err_mess, r.ClearConsole())
end


local function SetObjChunk(obj, obj_chunk)
	if not (obj and obj_chunk) then return end
local tr = r.ValidatePtr(obj, 'MediaTrack*')
local item = r.ValidatePtr(obj, 'MediaItem*')
	return tr and r.SetTrackStateChunk(obj, obj_chunk, false) or item and r.SetItemStateChunk(obj, obj_chunk, false) -- isundo is false
end


function Esc(str)
return str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
end


function Get_Video_Proc_Preset_Name(TAKEFX, obj, fx_idx) -- current preset, in case it's not contained in the preset code
local GetPreset = TAKEFX and r.TakeFX_GetPreset or r.TrackFX_GetPreset
local retval, presetname = GetPreset(obj, fx_idx, '')
return presetname
end


function Error_Tooltip(text)
local x, y = r.GetMousePosition()
r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
end


function unTag_FX_Name(chunk, fx_GUID, prev_fx_GUID, name, name_upd, video_proc_preset_name)

local fx_GUID = Esc(fx_GUID)
local prev_fx_GUID = Esc(prev_fx_GUID)

local fx_chunk = chunk:match(prev_fx_GUID..'.-(<VIDEO_EFFECT "Video processor".-'..fx_GUID..')') -- starting capture at custom name placeholder to avoid overwtiring preceding code in case custom name is also 'Video processor' or one of these words
or chunk:match(prev_fx_GUID..'.-(<JS.-'..fx_GUID..')') -- JS chunk is separate since the plugin displayed default name won't be reflected in the chunk, only the part within square brackets // works here also
or name:match('%s') and chunk:match(prev_fx_GUID..'.- ("'..Esc(name)..'" .-'..fx_GUID..')') -- if default name, that's what will be updated, otherwise custom multi-word name which is enclosed within quotes
or chunk:match(prev_fx_GUID..'.-<[AUDXLV2STi]+ ".-".- ('..Esc(name)..' .-'..fx_GUID..')') -- custom single word name

local is_JSFX = fx_chunk:match('<JS')
local is_default_name = is_JSFX and fx_chunk:match('""') or fx_chunk:match('"'..Esc(name)..'".-"".-""') -- when default name, custom name placeholder of a JS plugin is an empty string between quotes; chunks of other plugin types have two empty strings enclosed within quotes when default name
local is_single_word_custom_name = not is_default_name and not name:match('%s') -- not default and no spaces in the name, single word custom name isn't enclosed within quotes in the chunk
local JS_prefix = fx_chunk:match('(<JS .+ )"?'..Esc(name)) -- accounts for spaces in the JS file folder/file name and the FX name

local is_video_proc = fx_chunk:match('<VIDEO_EFFECT')
local video_proc_custom_name = fx_chunk:match('<VIDEO_EFFECT "Video processor" ("?'..Esc(name)..'"?)')
local video_proc_name = is_video_proc and (video_proc_custom_name or not fx_chunk:match('<VIDEO_EFFECT.-\n<CODE\n|//@') and fx_chunk:match('<VIDEO_EFFECT.-\n<CODE\n|(//.-)\n') or fx_chunk:match('<VIDEO_EFFECT.-\n(<CODE)')) -- custom name, or if there's commented out line in the preset code and it's not a control code which starts with ampersand, or there isn't such line or the code starts with the commented out control code
local video_proc_prefix = '<VIDEO_EFFECT "Video processor" ' -- used to extend video proc custom name below

local name = is_JSFX and is_default_name and '""'
or is_JSFX and Esc(fx_chunk:match(Esc(JS_prefix)..'"?'..Esc(name)..'"?')) -- extend name to avoid to avoid ovewriting other name instances in the default name in the code; accounting for multi-word custom name (quotes); 1st escape helps to capture name, 2nd - escapes characters in the captured name for the sake of replacement below
or video_proc_custom_name and Esc(fx_chunk:match(video_proc_prefix..'"?'..Esc(name)..'"?')) -- extend name to avoid ovewriting other name instances elsewhere in the preset code; accounting for multi-word custom name (quotes); re double escape see above
or is_video_proc and Esc(video_proc_name) -- instance name based on the preset code or the preset name
or is_single_word_custom_name and Esc(name) -- non-JSFX
or '"'..Esc(name)..'"' -- non-JSFX, within quotes in case it's multi-word to replicate chunk data

local name_upd = is_video_proc and video_proc_name:match(Esc(TAG)) and (video_proc_custom_name and video_proc_prefix..'"'..name_upd..'"' or video_proc_name:gsub('//'..Esc(TAG),'//')) -- if tag, remove it, adding quotes even if single word custom name to simplify capture afterwards; extend custom name string to match extended orig name above
or video_proc_name == '<CODE' and '<CODE\n|//'..TAG..' '..video_proc_preset_name -- no comment line in the preset code, use preset name
or video_proc_name and not video_proc_name:match(Esc(TAG)) and (video_proc_custom_name and video_proc_prefix..'"'..name_upd..'"' or video_proc_name:gsub('//','//'..TAG)) -- if no tag, add it, adding quotes even if single word custom name to simplify capture afterwards
or is_JSFX and not is_default_name and JS_prefix..'"'..name_upd..'"' -- extend custom name string to match extended orig name above
or '"'..name_upd..'"' -- all other cases, even if 'name' is a single word for which quotes aren't applied in the chunk, add quotes to simplify capture afterwards

local fx_chunk_upd = fx_chunk:gsub(name, name_upd):gsub('%%','%%%%') -- % must be commented out in a replacement string and outside of the chunk replacement function below so it works in all cases, inside the function below it only works for Video processor with % in the code

return chunk:gsub(Esc(fx_chunk), fx_chunk_upd):gsub('%%%%','%%') -- restore commented out %, if any, in the resulting chunk

end


function MAIN(chunk, obj, TAKEFX)

local CountFX = TAKEFX and r.TakeFX_GetCount or r.TrackFX_GetCount
local GetFXName = TAKEFX and r.TakeFX_GetFXName or r.TrackFX_GetFXName
local GetFXGUID = TAKEFX and r.TakeFX_GetFXGUID or r.TrackFX_GetFXGUID
local GetNumParams = TAKEFX and r.TakeFX_GetNumParams or r.TrackFX_GetNumParams
local GetFXEnvelope = TAKEFX and r.TakeFX_GetEnvelope or r.GetFXEnvelope

local added, removed

	for fx_idx = 0, CountFX(obj)-1 do
	local ret, name = GetFXName(obj, fx_idx, '')
	local video_proc_preset_name = Get_Video_Proc_Preset_Name(TAKEFX, obj, fx_idx)
	local is_tag = name:match('^'..Esc(TAG))
	local fx_GUID = GetFXGUID(obj, fx_idx)
	local prev_fx_GUID = GetFXGUID(obj, fx_idx-1) or ''
	local subchunk = chunk:match(Esc(fx_GUID)..'.-WAK'):match('<PROGRAMENV .-\n')
	local is_parm_mod = subchunk and subchunk:match('<PROGRAMENV .+ 0') -- 0 stands for 'Enable parameter modulation' checkbox being enabled in the Parameter modulation dialogue; if the checkbox is unchecked the flag is 1; if no parameter modulation, that is no param modulation section is engaged for any parameter even if the aforementioned checkbox is checked, the <PROGRAMENV block doesn't exist at all // at least one param moduation per FX is enough
	
	local name_upd

		if is_parm_mod and not is_tag then -- add
		added = 1
		name_upd = TAG..' '..name
		elseif not is_parm_mod and is_tag then -- remove // no param has envelope
		removed = 1
		name_upd = name:gsub(Esc(TAG)..'%s','')
		end

		if name_upd then
		chunk = unTag_FX_Name(chunk, fx_GUID, prev_fx_GUID, name, name_upd, video_proc_preset_name)
		end
	end

return added, removed, chunk -- to condition undo and fetch chunk for setting

end


-- M A I N  R O U T I N E

TAKEFX = #TAKEFX:gsub(' ','') > 0
SELECTED_ONLY = #SELECTED_ONLY:gsub(' ','') > 0

local err = #TAG:gsub(' ','') == 0 and 'empty tag' or SELECTED_ONLY and TAKEFX and not r.GetSelectedMediaItem(0,0) and not r.GetSelectedTrack2(0,0, true) and 'no selected objects' or SELECTED_ONLY and not TAKEFX and not r.GetSelectedTrack2(0,0, true) and 'no selected tracks'

	if err then
	Error_Tooltip(('\n\n  '..err..'  \n\n'):gsub('.','%0 '))
	return r.defer(function() do return end end) end

r.Undo_BeginBlock()

local err_cnt = 0

local tr_cnt = SELECTED_ONLY and r.CountSelectedTracks2(0, true) -- wantmaster true
or r.CountTracks(0)
local itm_cnt = SELECTED_ONLY and r.CountSelectedMediaItems(0) or r.CountMediaItems(0)

	for tr_idx = -1, tr_cnt-1 do -- -1 to account for the master track when not SELECTED_ONLY
	local tr = SELECTED_ONLY and r.GetSelectedTrack2(0,tr_idx, true) or not SELECTED_ONLY and (r.GetTrack(0,tr_idx) or r.GetMasterTrack(0)) -- wantmaster true; master track if not SELECTED_ONLY; 'not SELECTED_ONLY' must be explicit so the alternative isn't used when iterator is -1 while SELECTED_ONLY
		if tr then -- can be nil due to -1 in the iteratior when SELECTED_ONLY
		local ret, chunk = GetObjChunk(tr)
			if ret ~= 'err_mess' then
			local a, b, chunk_upd = MAIN(chunk, tr)
			SetObjChunk(tr, chunk_upd)
				-- create conditions for Undo verbiage
				if a then added1 = 1 end
				if b then removed1 = 1 end
			else err_cnt = err_cnt + 1 -- cond for SWS absence warning mess
			end
		end
	end

	if TAKEFX then
		for itm_idx = 0, itm_cnt-1 do
		local item = not SELECTED_ONLY and r.GetMediaItem(0, itm_idx) or r.GetSelectedMediaItem(0, itm_idx)
		local ret, chunk = GetObjChunk(item)
			for take_idx = 0, r.CountTakes(item)-1 do
			local take = r.GetTake(item, take_idx)				
				if ret ~= 'err_mess' then
				local a, b, chunk_upd = MAIN(chunk, take, TAKEFX)
				SetObjChunk(item, chunk_upd)
					-- create conditions for Undo verbiage
					if a then added2 = 1 end
					if b then removed2 = 1 end
				else err_cnt = err_cnt + 1 -- cond for SWS absence warning mess
				end
			end
		end
	end


	if err_cnt > 0 then Err_mess(err_cnt) end -- SWS error message

local undo = ' FX envelope tags were '
local undo = (added1 or removed1) and (added2 or removed2) and 'Track and Take'..undo or (added1 or removed1) and 'Track'..undo or (added2 or removed2) and 'Take'..undo
local undo = (added1 or added2) and (removed1 or removed2) and undo..'added & removed' or (added1 or added2) and undo..'added' or (removed1 or removed2) and undo..'removed'

	if undo then
	r.Undo_EndBlock(undo, -1)
	else r.Undo_EndBlock('', -1) end -- no undo point; empty undo string to avoid 'ReaSript: Run' message even in the status bar




