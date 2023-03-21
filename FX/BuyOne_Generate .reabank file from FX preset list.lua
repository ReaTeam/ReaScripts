--[[
ReaScript name: Generate .reabank file from FX preset list
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	The script allows creating .reabank files for individual plugins
	or one .reabank file for several plugins.

	Open FX browser and select plugins there or open an FX chain 
	and keeping it open, run the script. All types of FX chains 
	are supported.  
	The best way to create one .reabank for a number of plugins 
	is to insert an assortment of plugins in the desired order into 
	a track blank FX chain and run the script while the FX chain is open.  

	The .reabank file is placed in the /Data folder in the REAPER
	resource directory, where the stock GM.reabank file is located
	and which ReaControlMIDI plugin and Bank/Program Select MIDI events
	in MIDI items are by default pointed to.  

	Exporting Video processor presets is supported from REAPER build 6.26 
	onwards.

	All types of FX chains are supported.  

	If option 'Only allow one FX chain window open at a time' is enabled
	at Preferences -> Plug-ins the focused FX chain may jolt when the
	script is run, and the FX selected in the FX chain will switch to the
	focused FX if it's displayed in a floating window and wasn't selected
	initially. This is inevitable due to REAPER API peculiarities.

	In the .reabank file plugins will be listed by the name which appears in
	the FX browser even if in the focused FX chain they're named differently.

	You may also check out a similar script mpl_Generate reabank from focused FX.lua 
	which generates reabank code for an FX currently focused in a track FX chain
	with output to ReaScript console.

	Instructions on using .reabank files to switch presets in real time 
	is available in chapter 13.47 'Using MIDI CC Messages to Control FX Presets' 
	of the User Guide and/or in this video https://www.youtube.com/watch?v=216O6xGWCxU
	by Kenneth A of Crashwaggon Music

]]

local r = reaper


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function get_tog_state(sect_ID, comm_ID)
return r.GetToggleCommandStateEx(sect_ID, r.NamedCommandLookup(comm_ID))
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


function GetFocusedFX() -- complemented with GetMonFXProps() to get Mon FX in builds prior to 6.20

	local function GetMonFXProps() -- get mon fx accounting for floating window, GetFocusedFX() doesn't detect mon fx in builds prior to 6.20

		local master_tr = r.GetMasterTrack(0)
		local src_mon_fx_idx = r.TrackFX_GetRecChainVisible(master_tr)
		local is_mon_fx_float = false -- only relevant if there's need to reopen the fx in floating window
			if src_mon_fx_idx < 0 then -- fx chain closed or no focused fx -- if this condition is removed floated fx gets priority
				for i = 0, r.TrackFX_GetRecCount(master_tr) do
					if r.TrackFX_GetFloatingWindow(master_tr, 0x1000000+i) then
					src_mon_fx_idx = i; is_mon_fx_float = true break end
				end
			end
		return src_mon_fx_idx, is_mon_fx_float
	end

local retval, tr_num, itm_num, fx_num = r.GetFocusedFX()
-- Returns 1 if a track FX window has focus or was the last focused and still open, 2 if an item FX window has focus or was the last focused and still open, 0 if no FX window has focus. tracknumber==0 means the master track, 1 means track 1, etc. itemnumber and fxnumber are zero-based. If item FX, fxnumber will have the high word be the take index, the low word the FX index.
-- if take fx, item number is index of the item within the track (not within the project) while track number is the track this item belongs to, if not take fx itm_num is -1, if retval is 0 the rest return values are 0 as well

local mon_fx_num = GetMonFXProps() -- expected >= 0 or > -1

local tr = retval > 0 and (r.GetTrack(0,tr_num-1) or r.GetMasterTrack()) or retval == 0 and mon_fx_num >= 0 and r.GetMasterTrack() -- prior to build 6.20 Master track has to be gotten even when retval is 0

local item = retval == 2 and r.GetTrackMediaItem(tr, itm_num)
-- high word is 16 bits on the left, low word is 16 bits on the right
local take_num, take_fx_num = fx_num>>16, fx_num&0xFFFF -- high word is right shifted by 16 bits (out of 32), low word is masked by 0xFFFF = binary 1111111111111111 (16 bit mask); in base 10 system take fx numbers starting from take 2 are >= 65536
local take = retval == 2 and r.GetMediaItemTake(item, take_num)
local fx_num = retval == 2 and take_fx_num or retval == 1 and fx_num or mon_fx_num >= 0 and 0x1000000+mon_fx_num -- take or track fx index (incl. input/mon fx) // unlike in GetLastTouchedFX() input/Mon fx index is returned directly and need not be calculated // prior to build 6.20 Mon FX have to be gotten when retval is 0 as well // 0x1000000+mon_fx_num is equivalent to 16777216+mon_fx_num

local fx_name
	if take then
	fx_name = select(2, r.TakeFX_GetFXName(take, fx_num))
	elseif tr then
	fx_name = select(2, r.TrackFX_GetFXName(tr, fx_num))
	end

return retval, tr_num-1, tr, itm_num, item, take_num, take, fx_num, mon_fx_num >= 0, fx_name -- tr_num = -1 means Master;

end


function Check_reaper_ini(key) -- the arg must be a string
local f = io.open(r.get_ini_file(),'r')
local cont = f:read('a*')
f:close()
return cont:match(key..'=(%d+)')
end


function Check_Selected_FX(take, track, fx_idx, one_chain) -- presence of arguments makes the function target the focused FX chain, otherwise selected plugins in the open FX browser are targeted // one_chain is boolean of whether 'Only allow one FX chain window at a time' option is enabled as it necessitates special accommodation, see below

r.PreventUIRefresh(1)
r.InsertTrackAtIndex(r.GetNumTracks(), false) -- insert new track at end of track list and hide it; action 40702 creates undo point
local temp_track = r.GetTrack(0,r.CountTracks(0)-1)
r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINMIXER', 0) -- hide in Mixer
r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINTCP', 0) -- hide in Arrange

-- Copy FX from the source track/take/FX browser to the temporary track

	if fx_idx then -- only copy if arguments are provided, without arguments instantiated from FX browser below
	-- take is evaluated first because if take is true track is true as well
	local GetFXCount, CopyToTrack, FX_Show, GetFloatingWindow = table.unpack(take and {r.TakeFX_GetCount, r.TakeFX_CopyToTrack, r.TakeFX_Show, r.TakeFX_GetFloatingWindow} or track and {fx_idx < 16777216 and r.TrackFX_GetCount or r.TrackFX_GetRecCount, r.TrackFX_CopyToTrack, r.TrackFX_Show, r.TrackFX_GetFloatingWindow} or {})
	local obj = take or track
	-- When the setting 'Preferences -> Only allow one FX chain window at a time' is enabled the functions Track/TakeFX_CopyToTrack/Take() close focused FX chain window, which requires its re-opening
	-- https://forum.cockos.com/showthread.php?t=277429 bug report
	local is_foc_float = one_chain and GetFloatingWindow(obj, fx_idx) -- if focused FX is open in a floating window
		
		for idx = 0, GetFXCount(obj)-1 do
		local src_idx = fx_idx < 16777216 and idx or 16777216+idx -- or 0x1000000+idx, input/monitoring fx
		CopyToTrack(obj, src_idx, temp_track, idx, false) -- is_move false // when copying FX envelopes don't follow, only when moving
		end
		
	-- When re-opening FX chain window after it's been closed with Track/TakeFX_CopyToTrack/Take() selection must be switched to the focused FX even if it wasn't selected originally which is possible with floating windows, because restoration of the originally selected FX if its window is also floating, will bring it in front of the originally focused floating FX window even if the latter is re-floated last, and it's impossible to change selection of FX in the chain while windows are floating
		if one_chain then
		FX_Show(obj, fx_idx, 1) -- showFlag 1 (show chain) with focused FX selected even if it wasn't selected originally which is possible with floating windows
			if is_foc_float then FX_Show(obj, fx_idx, 2) FX_Show(obj, fx_idx, 3) end -- showFlag 2 (hide) 3 (show floating), close and re-open floating window, if any, to bring it to the foreground
		end	
		
	else
	r.TrackFX_AddByName(temp_track, 'FXADD:', false, -1) -- recFX false, instantiate -1: specify a negative value for instantiate to always create a new effect
	end

local ret, chunk = GetObjChunk(temp_track)
local plugin_name_t = chunk and #chunk > 0 and Retrieve_Orig_Plugin_Names(chunk) -- to pevent error because when ret == 'err_mess' chunk isn't returned by GetObjChunk()
local fx_cnt = r.TrackFX_GetCount(temp_track)
local fx_list, valid_fx_cnt, _129 = '', 0

	-- Collect FX instances names, excluding duplicate plugin instances
	for fx_idx = 0, fx_cnt-1 do
	local retval, pres_cnt = r.TrackFX_GetPresetIndex(temp_track, fx_idx)
		if pres_cnt > 0 then
		local ret, fx_name = r.TrackFX_GetFXName(temp_track, fx_idx, '')
		local fx_name = (not plugin_name_t or plugin_name_t[fx_idx+1]) and '\n'..fx_name or '' -- if original names weren't retrieved from the chunk and so duplicates weren't filtered inside Retrieve_Orig_Plugin_Names() use all displayed names, it were retrieved only use names of unique instances, duplicates will have been set to nil in the plugin_name_t table
		valid_fx_cnt = #fx_name > 0 and valid_fx_cnt+1 or valid_fx_cnt -- counting plugins with presets only honoring unique instances
		_129 = #fx_name > 0 and pres_cnt > 128 and 1 or _129 -- verifying if any of the unique instances contains more than 128 presets
		fx_list = fx_list..fx_name
		end
	end

r.DeleteTrack(temp_track)
r.PreventUIRefresh(-1)

local err = not fx_idx and (fx_cnt == 0 and 'No FX have been selected in the FX browser.' or fx_cnt > 0 and #fx_list == 0 and 'No presets in selected FX.')
local err = not err and fx_idx and fx_cnt > 0 and #fx_list == 0 and 'No presets in FX of the focused FX chain.' or err
	if err then
	r.MB(err, 'ERROR', 0)
	end

return fx_list:sub(2), valid_fx_cnt, _129 -- removing leading line break from fx_list

end


function Retrieve_Orig_Plugin_Names(chunk)
-- for non-JSFX plugins get name currently applied in the FX browser
-- which may differ from plugin original name
local t = {}
	for line in chunk:gmatch('[^\n\r]+') do
	local name = line and ( line:match('<.-"([ACDLPSTUVX23i:]+ .-)"') -- AU,CLAP,DX,LV2,VST
	or line:match('<JS "(.-)" ') or line:match('<JS (.-) ') -- spaces or no spaces in the path
	or line:match('<VIDEO_EFFECT "(Video processor)"') )
		if name then
			if line:match('<JS') then -- JSFX bank header will include the name from 'desc:' tag inside of the JSFX file and the file path or only the file path if the name couldn't be retrived
			local path = r.GetResourcePath()
			local sep = path:match('[\\/]')
				if name:match('<Project>') then -- JSFX local to the project only if project is saved; for the local JSFX to load presets its file in the /presets folder must be named js-_Project__(JSFX file name).ini
				local retval, proj_path = r.EnumProjects(-1) -- -1 active project
				local proj_path = proj_path:match('.+[\\/]') -- excluding the file name // OR proj_path:match('.+'..Esc(r.GetProjectName(0, '')))
				local file_name = name:match('<Project>/(.+)')
				local path = proj_path..'Effects'..sep..file_name -- proj_path includes the separator
					if r.file_exists(path) then
						for line in io.lines(path) do
						local name_local = line:match('^desc:') and line:match('desc:%s*(.+)') -- ignoring commented out 'desc:' tags if any // isolate name in this routine so that in case the actual name isn't found in the JSFX file the file name fetched from the chunk will be used
							if name_local then name = 'JS '..name_local..' ['..path..']' break end
						end
					end
				elseif r.file_exists(path..sep..'Effects'..sep..name) then -- JSFX at the regular location
				-- if JSFX name was changed in the plugin file but REAPER wasn't re-started
				-- or FX browser wasn't refreshed with F5, reaper-jsfx.ini will still contain the old name
					for line in io.lines(path..sep..'reaper-jsfx.ini') do
					local name_local = line and line:match(Esc(name)) and line:match('NAME.+ "(.+)"') -- name_local to prevent clash with name
						if name_local then name = name_local break end
					end
				end
			end
		t[#t+1] = name -- the table indexing must match FX indices in the FX chain so all must be collected with no skips
		end
	end
-- disable duplicate entries, will be evaluated in the preset extraction routine in Check_Selected_FX() and in Collect_FX_Preset_Names()
	for k1, v1 in pairs(t) do
		for k2, v2 in pairs(t) do -- pairs because the table will contain nils
			if v1 == v2 and k1 ~= k2 then
			t[k2] = nil -- keeping indices intact so that correspondence with fx indices in the FX chain is maintained
			end
		end
	end
return t
end


function Collect_FX_Preset_Names(reabank_type, take, track, fx_idx) -- presence of take, track and fx_idx arguments makes the function target the focused FX chain, otherwise selected plugins in the open FX browser are targeted

-- getting all preset names in a roundabout way by travesring them in an instance on a temp track
-- cannot traverse in the source track as if plugin parameters haven't been stored in a preset
-- after traversing they will be lost and will require prior storage and restoration whose accuracy isn't guaranteed

r.PreventUIRefresh(1)
r.InsertTrackAtIndex(r.GetNumTracks(), false) -- insert new track at end of track list and hide it; action 40702 creates undo point
local temp_track = r.GetTrack(0,r.CountTracks(0)-1)
r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINMIXER', 0) -- hide in Mixer
r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINTCP', 0) -- hide in Arrange

-- Copy FX from the source track/take/FX browser to the temporary track

	if fx_idx then -- only copy if arguments are provided, without arguments instantiated from FX browser below
	-- take is evaluated first because if take is true track is true as well
	local GetFXCount, CopyToTrack = table.unpack(take and {r.TakeFX_GetCount, r.TakeFX_CopyToTrack} or track and {fx_idx < 16777216 and r.TrackFX_GetCount or r.TrackFX_GetRecCount, r.TrackFX_CopyToTrack} or {})
	local obj = take or track
		for idx = 0, GetFXCount(obj)-1 do
		local src_idx = fx_idx < 16777216 and idx or 16777216+idx -- or 0x1000000+idx, input/monitoring fx
			if reabank_type == 3 and src_idx == fx_idx or reabank_type < 3 then
			CopyToTrack(obj, src_idx, temp_track, idx, false) -- is_move false // when copying FX envelopes don't follow, only when moving
			end
			if reabank_type == 3 and src_idx == fx_idx then break end -- break immediately after copying the focused FX
		end
	else
	r.TrackFX_AddByName(temp_track, 'FXADD:', false, -1) -- recFX false, instantiate -1: specify a negative value for instantiate to always create a new effect
	end

	local function lead_str(num, str)
	return (num < 10 and str..str or num > 9 and num < 100 and str or '')..num
	end

local ret, chunk = GetObjChunk(temp_track)
	if ret == 'err_mess' then -- the chunk exceeds 4 mb and the SWS extension isn't installed to fall back on
	local resp = r.MB('        Couldn\'t retrieve original plugin name(s).\n\nWant names displayed in the FX chain to be used?','PROMPT',1) -- in theory this problem may affect getting plugin names selected in the browser as well but less likely
		if resp == 2 then return end -- Cancel then
	end
local plugin_name_t = chunk and #chunk > 0 and Retrieve_Orig_Plugin_Names(chunk) -- to pevent error because when ret == 'err_mess' chunk isn't returned by GetObjChunk()

local preset_name_t = {}

local LSB = -1 -- start from -1 since LSB count is 0-based, only relevant for reabank_type 1, one reabank file for several plugins

	for fx_idx = 0, r.TrackFX_GetCount(temp_track)-1 do
	local cur_pres_idx, pres_cnt = r.TrackFX_GetPresetIndex(temp_track, fx_idx)
	local _, fx_name = r.TrackFX_GetFXName(temp_track, fx_idx, '') -- used when plugin names couldn't be retrieved from chunk and the user assented to using displayed names in the prompt above
	local fx_name = not plugin_name_t and fx_name or plugin_name_t[fx_idx+1] --and #plugin_name_t[fx_idx+1] > 0 -- only if excluding deleted JSFX whose name fields has been set to empty string in Retrieve_Orig_Plugin_Names()

		if pres_cnt > 0 and fx_name then
		r.TrackFX_SetPresetByIndex(temp_track, fx_idx, pres_cnt-1) -- start from the last preset in case user has a default preset enabled and advance forward in the loop below
		LSB = LSB+1 -- increment LSB bank value, only respecting plugins with presets
		local MSB = LSB <= 127 and 0 or LSB > 127 and LSB <= 254 and 1 or 2 -- when one reabank for all plugins, support 384 banks (3 MSB banks 128 LSB sub-banks each with 128 presets each, one sub-bank per plugin) probably should suffice, as per MIDI specs 16,384 banks are supported
		local header = reabank_type == 1 and 'Bank '..MSB..' '..LSB..'  '..fx_name -- one reabank file for all plugins
		or reabank_type > 1 and 'Bank 0 0  '..fx_name -- one reabank file per plugin
		preset_name_t[#preset_name_t+1] = '\n'..header..'\n'

			for i = 1, pres_cnt do -- not confining to 128 presets which is the supported limit, so that all presets are included, only 128 will be listed in the menus anyway
			r.TrackFX_NavigatePresets(temp_track, fx_idx, 1) -- forward
			local ret, pres_name = r.TrackFX_GetPreset(temp_track, fx_idx, '')
			local pres_name = pres_name:match('.+[\\/](.+)%.vstpreset$') or pres_name
			preset_name_t[#preset_name_t+1] = lead_str(i-1,' ')..(' '):rep(3)..lead_str(i,'0')..' '..pres_name -- LEADING ZEROS IN THE .reabank PROGRAM NUMBERS BREAK THE SEQUENCE AND SOME PROGRAMS GET SKIPPED, 9, 10 in particular, hence for alignment they're preceded by spaces instead
			end

		end
	end

r.DeleteTrack(temp_track)

r.PreventUIRefresh(-1)

return preset_name_t

end


function Write_To_File(path, content)
local f = assert(io.open(path, 'w'))
f:write(content)
f:close()
end


local retval, tr_num, tr, itm_num, item, take_num, take, fx_num, mon_fx, fx_name = GetFocusedFX()

local fx_chain = retval > 0 or mon_fx
local supported_build = tonumber(r.GetAppVersion():match('(.+)/')) > 6.11 -- inserting from FX browser is only supported since build 6.12c
local fx_brows_open = get_tog_state(0, 40271) == 1 -- View: Show FX browser window

-- Generate prompts

local err = not fx_brows_open and not fx_chain and '      No selected or focused FX \n\n or the focused FX chain is empty.' -- when FX chain is empty GetFocusedFX() doesn't detect it
local err = not err and fx_brows_open and not fx_chain and not supported_build and '        Selecting FX from FX browser\n\n    is only supported since build 6.12c.' or err
local err = not err and fx_brows_open and fx_chain and 'Both FX chain and FX browser are open.\n\n\"YES\" —  to use FX selected in the FX browser.\n\n\"NO\" —  to use FX selected in the focused FX chain.' or err
	if err then
	local title = err:match('Both') and 'PROMPT' or 'ERROR'
	local typ = err:match('Both') and 3 or 0
	local resp = r.MB(err, title, typ)
		if resp == 6 then fx_brows_open, fx_chain = fx_brows_open, nil
		elseif resp == 7 then fx_brows_open, fx_chain = nil, fx_chain
		else r.defer(function() do return end end) return end
	end


-- Thanks to mespotine for figuring out config variables
-- https://github.com/mespotine/ultraschall-and-reaper-docs/blob/master/Docs/Reaper-ConfigVariables-Documentation.txt
local one_chain = fx_chain and Check_reaper_ini('fxfloat_focus')&2 == 2 -- 'Only allow one FX chain window at a time' is enabled in Preferences -> Plug-ins	
	
local chain_fx_list, valid_fx_cnt_chain, _129_chain = table.unpack(fx_chain and {Check_Selected_FX(take, tr, fx_num, one_chain)} or {''})
local brows_fx_list, valid_fx_cnt_brows, _129_brows = table.unpack(fx_brows_open and {Check_Selected_FX()} or {''})

local fx_list = #chain_fx_list > 0 and chain_fx_list or #brows_fx_list > 0 and brows_fx_list
local valid_fx_cnt = valid_fx_cnt_chain or valid_fx_cnt_brows -- will condition reabank export options by only allowing two options if there're more than 1 plugin with presets because offering creation of one bank per plugin when there's only one plugin doesn't make sense
local excess = valid_fx_cnt > 1 and 'In some plugins preset' or 'Preset'
local _129 = (_129_chain or _129_brows) and '\n\n'..excess..' count exceeds 128.\nPresets 129 onwards won\'t be accessible.' or ''
local mess, typ = table.unpack(fx_list and (valid_fx_cnt > 1 and {'Creating .reabank for \n\n'..fx_list.._129..'\n\n\"YES\" —  one .reabank file for all the plugins\n\n\"NO\" —  one .reabank file per plugin', 3} or {'Creating .reabank for \n\n'..fx_list.._129, 1}) or {})

	if fx_list then

	local pres_cnt = take and select(2,r.TakeFX_GetPresetIndex(take, fx_num)) or tr and select(2,r.TrackFX_GetPresetIndex(tr, fx_num))

		if fx_chain and pres_cnt > 0 and valid_fx_cnt > 1 then -- for focused FX chain only and if the focused plugin has presets
		local resp = r.MB('\"YES\" —  reabank for the focused plugin only:\n => '..fx_name..'\n\n\"NO\" —  reabank(s) for all plugins in the FX chain', 'PROMPT', 3)
			if resp == 2 then -- Cancel
			r.defer(function() do return end end) return
			elseif resp == 6 then reabank_type = 3 -- OK, only reabank for the focused plugin (open in the FX chain or in a floating window)
			end
		end

		if not reabank_type then -- previous prompt wasn't triggered
		local resp = r.MB(mess, 'ONLY UNIQUE FX WITH PRESETS ARE LISTED', typ)
			if resp == 2 then -- Cancel
			r.defer(function() do return end end) return
			elseif resp == 1 or resp == 7 then reabank_type = 2 -- OK in type 1 prompt (one reabank file for a single plugin) and NO in type 3 prompt (one reabank file per each plugin)
			else reabank_type = 1 -- YES in type 3 prompt (one reabank file for all listed plugins)
			end
		end

-- Collect content to concatenate bank code

		if fx_chain then -- focused FX chain
		preset_name_t = Collect_FX_Preset_Names(reabank_type, take, tr, fx_num)
		elseif fx_brows_open and supported_build then -- open FX browser
		preset_name_t = Collect_FX_Preset_Names(reabank_type) -- no arguments to target plugin selection in the FX browser
		end

		if not preset_name_t then return r.defer(function() do return end end) end -- if original plugin names couldn't be rertieved from the chunk and the user declined using displayed plugin names in the dialogue

	local path = r.GetResourcePath()
	local sep = path:match('[\\/]')
	local path = path..sep..'Data'..sep
	local date = os.date('%H-%M-%S_%d.%m.%y') -- a convenient way to make file names unique and prevent clashes
-- the text must be flush with the left edge otherwise tab space is read and carried over to the file
	local header = [[
// .reabank files define MIDI bank/program (patch) information
// for specific hardware or software devices
// A bank entry lists the MSB, LSB, and bank name
// for all the patches that follow, until the next bank entry
// The program numbers on the left should not be padded
// with zeros because it will break the sequence
// To exclude an entry from the list, comment it out by preceding with double slash //
	]]
	local lb = ('\n'):rep(5) -- to add line breaks at the end of the content

		if reabank_type == 1 then -- one reabank file for all plugins
		local path = path..'PLUGIN_PRESET_BANK_'..date..'.reabank'
		Write_To_File(path, header..table.concat(preset_name_t,'\n')..lb)
		elseif reabank_type > 1 then -- one reabank file per plugin, either focused or all in the FX chain
		local bank, idx_init = ''
			for idx, line in ipairs(preset_name_t) do
				if idx_init and (line:match('Bank 0 0') or idx == #preset_name_t) then
				local name = preset_name_t[idx_init]:match('Bank %d+ %d+%s%s(.+)\n') -- getting plugin name from the stored field, it's exactly 2 spaces apart from the Bank data
				local name = name:gsub('<Project>',''):gsub('%[.+%]',''):gsub('[\\/?:%*"<>|]','') -- removing <Project> from file names of JSFX local to project, if any, JSFX paths and illegal characters in names
				local path = path..name..' '..date..'.reabank'
				local idx = idx == #preset_name_t and idx or idx-1 -- -1 to target the last line of the previous bank unless it's the last line in the table
				Write_To_File(path, header..table.concat(preset_name_t,'\n',idx_init,idx)..lb)
				idx_init = nil
				end
				if not idx_init and line:match('Bank 0 0') then
				idx_init = idx
				end
			end
		end

	end


do r.defer(function() do return end end) return end -- prevent undo point creation


