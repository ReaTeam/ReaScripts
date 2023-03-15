--[[
ReaScript name: FX presets menu
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.5
Changelog: #Fixed error on loading preset menu of plugins with embedded presets and no external preset file
Provides: [main] .
Licence: WTFPL
REAPER: at least v5.962
About:
	#### G U I D E

	- The script displays FX preset menu of the object (track or item/active take)
	either currently found under the mouse cursor or the last selected if 
	SEL_OBJ_IN_CURR_CONTEXT setting is enabled in the USER SETTINGS below, or of the 
	currently or last focused FX chain window. With regard to track FX, for REAPER 
	builds prior to 6.37 only TCP is supported.

	- It's only able to list presets available in REAPER plugin wrapper drop-down list
	including imported .vstpreset files.

	- Since in multi-take items the menu only lists active take FX presets, if you need
	FX presets from a take other then the active simply click on it to have it activated.

	- Track preset menu is divided into two sections, main FX menu (upper) and 
	input FX menu (lower) if both types of FX are present.   
	In the Master track FX preset menu instead of the preset menu for input FX a menu 
	for Monitor FX is displayed.

	- If there's active preset and plugin controls configuration matches the preset settings
	the preset name in the menu is checkmarked.

	- The script can be called in the following ways:  
	1) by placing the mouse cursor over the object or its FX chain window and calling
	the script with a shortcut assigned to it;  
	2) by assigning it to a Track AND an Item mouse modifiers under *Preferences -> Mouse modifiers*
	and actually clicking the object to call it;  
	If SEL_OBJ_IN_CURR_CONTEXT setting is enabled in the USER SETTINGS below:  
	3) from an object right click context menu (main menus are not reliable);  
	4) from a toolbar, the toolbar must either float over the Arrange or be docked in the top
	or bottom dockers; Main toolbar or other docker positions are not reliable;  
	5) from the Action list (which is much less practicable)  
	In cases 3)-5) the object must be selected as the mouse cursor is away from it.  
	All five methods can work in parallel.  
	Be aware that when SEL_OBJ_IN_CURR_CONTEXT setting is enabled and the script is run via 
	a keyboard shortcut,the menu will be called even when the mouse cursor is outside of the TCP 
	or Arrange and not over an FX chain window, like over the ruler, TCP bottom, empty Mixer area 
	or any other focused window, in which case it will display a list of the last selected object 
	FX presets.
	
	- LOCK_FX_CHAIN_FOCUS setting in the USER SETTINGS allows displaying presets menu for FX of the last 
	focused open FX chain even when the mouse cursor is outside of the FX chain window and it itself isn't 
	in focus and regardless of the last selected object in case SEL_OBJ_IN_CURR_CONTEXT setting is enabled.

	- To close the menu after it's been called, without selecting any preset, either click elsewhere
	in REAPER or pres Esc keyboard key.
	
	- Video processor preset menu is supported from REAPER build 6.26 onwards.
	
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable the option place any alphanumeric character between 
-- the quotation marks.
-- Try to not leave empty spaces.

-- If mouse cursor is outside of Arrange/TCP/MCP, 
-- i.e. docked toolbar button click, execution from the Action list
-- selected track or item will be targeted depending on the current mouse
-- cursor context;
-- to change the context click within the track list or within the Arrange;
-- only one object selection per context is supported.
local SEL_OBJ_IN_CURR_CONTEXT = ""

-- If FX chain window is open and was last focused
local LOCK_FX_CHAIN_FOCUS = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper

function StoreSelectedObjects()

-- Store selected items
local sel_itms_cnt = r.CountSelectedMediaItems(0)
local itm_sel_t = {}
	if sel_itms_cnt > 0 then
	local i = 0
		while i < sel_itms_cnt do
		itm_sel_t[#itm_sel_t+1] = r.GetSelectedMediaItem(0,i)
		i = i+1
		end
	end

-- Store selected tracks
local sel_trk_cnt = reaper.CountSelectedTracks2(0,1) -- plus Master
local trk_sel_t = {}
	if sel_trk_cnt > 0 then
	local i = 0
		while i < sel_trk_cnt do
		trk_sel_t[#trk_sel_t+1] = r.GetSelectedTrack2(0,i,1) -- plus Master
		i = i+1
		end
	end
return itm_sel_t, trk_sel_t
end


function RestoreSavedSelectedObjects(itm_sel_t, trk_sel_t)
-- if none were selected keep the latest selection

r.PreventUIRefresh(1)

	if #itm_sel_t > 0 then
	r.Main_OnCommand(40289,0) -- Item: Unselect all items
	local i = 0
		while i < #itm_sel_t do
		r.SetMediaItemSelected(itm_sel_t[i+1],1)
		i = i + 1
		end
	end

	if #trk_sel_t > 0 then -- not needed if Master track is being gotten without its selection
	r.Main_OnCommand(40297,0) -- Track: Unselect all tracks
	r.SetTrackSelected(r.GetMasterTrack(0),0) -- unselect Master
		for _,v in next, trk_sel_t do
		r.SetTrackSelected(v,1)
		end
	end

r.UpdateArrange()
r.TrackList_AdjustWindows(0)
r.PreventUIRefresh(-1)
end


local function GetObjChunk(obj, obj_type)
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua
		if not obj then return end
  -- Try standard function -----
	local t = obj_type == 0 and {r.GetTrackStateChunk(obj, '', false)} or {r.GetItemStateChunk(obj, '', false)} -- isundo = false
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


function FX_Chain_Chunk(chunk, path, sep, type, take_GUID) -- isolate object fx chain, for tracks exclude items, for items exclude takes other than the active one; type arg is set within the routine

	if chunk and #chunk > 0 then
		if take_GUID then -- take fx chain
		fx_chunk = chunk:match(take_GUID..'.-(<TAKEFX.->)\nTAKE') or chunk:match(take_GUID..'.-(<TAKEFX.->)\n<ITEM') or chunk:match(take_GUID..'.-(<TAKEFX.*>)\n>')
		else
			if type == 0 then -- track main fx chain
		fx_chunk = chunk:match('(<FXCHAIN.*>)\n<FXCHAIN_REC') or chunk:match('(<FXCHAIN.->)\n<ITEM') or chunk:match('(<FXCHAIN.*WAK.*>)\n>')
			elseif type == 1 then -- track input fx chain
				if chunk:match('<FXCHAIN_REC') then -- regular track input fx
				fx_chunk = chunk:match('(<FXCHAIN_REC.->)\n<ITEM') or chunk:match('(<FXCHAIN_REC.*WAK.*>)\n>')
				else -- monitor fx of the master track, extract fx chunk from reaper-hwoutfx.ini
				local f = io.open(path..sep..'reaper-hwoutfx.ini', 'r')
				fx_chunk = f:read('*a')
				f:close()
				end
			end
		end
	end

	return fx_chunk
end


function Collect_VideoProc_Instances(fx_chunk)

local video_proc_t = {} -- collect indices of video processor instances, because detection by fx name is unreliable as not all its preset names contain 'video processor' phrase due to length
local counter = 0 -- to store indices of video processor instances

	if fx_chunk and #fx_chunk > 0 then
		for line in fx_chunk:gmatch('[^\n\r]*') do -- all fx must be taken into account for video proc indices to be accurate
		local plug = line:match('<VST') or line:match('<AU') or line:match('<JS') or line:match('<DX') or line:match('<LV2') or line:match('<VIDEO_EFFECT')
			if plug then
				if plug == '<VIDEO_EFFECT' then
				video_proc_t[counter] = '' -- dummy value as we only need indices
				end
			counter = counter + 1
			end
		end
	end

	return video_proc_t

end


function Collect_FX_Preset_Names(obj, src_fx_cnt, src_fx_idx, pres_cnt)
-- getting all preset names in a roundabout way by travesring them in an instance on a temp track
-- cannot traverse in the source track as if plugin parameters haven't been stored in a preset
-- after traversing they will be lost and will require prior storage and restoration whose accuracy isn't guaranteed

r.PreventUIRefresh(1)
r.InsertTrackAtIndex(r.GetNumTracks(), false) -- insert new track at end of track list and hide it; action 40702 creates undo point
local temp_track = r.GetTrack(0,r.CountTracks(0)-1)
r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINMIXER', 0) -- hide in Mixer
r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINTCP', 0) -- hide in Arrange

	if r.ValidatePtr(obj, 'MediaTrack*') then
	r.TrackFX_CopyToTrack(obj, src_fx_idx, temp_track, 0, false) -- is_move false
	elseif r.ValidatePtr(obj, 'MediaItem_Take*') then
	r.TakeFX_CopyToTrack(obj, src_fx_idx, temp_track, 0, false) -- is_move false
	end

r.TrackFX_SetPresetByIndex(temp_track, 0, pres_cnt-1) -- start from the last preset in case user has a default preset enabled and advance forward in the loop below
local _, pres_cnt = r.TrackFX_GetPresetIndex(temp_track, 0)

local preset_name_t = {}

	for i = 1, pres_cnt do
	r.TrackFX_NavigatePresets(temp_track, 0, 1) -- forward
	local _, pres_name = r.TrackFX_GetPreset(temp_track, 0, '')
	preset_name_t[i] = pres_name..'|'
	end

r.DeleteTrack(temp_track)

r.PreventUIRefresh(-1)

	if src_fx_cnt > 1 then -- close submenu, otherwise no submenu
	table.insert(preset_name_t, #preset_name_t, '<') 
	end
	
	if #preset_name_t > 0 and 
	(#preset_name_t-1 == pres_cnt  -- one extra entry '<' if any
	or #preset_name_t == pres_cnt) -- when there's no submenu closure '<' because there's only one plugin in the chain
	then return preset_name_t end

end


function Collect_VideoProc_Preset_Names(fx_cnt, pres_cnt)
-- builtin_video_processor.ini file only stores user added presets to the exclusion of the stock ones
-- getting all preset names in a roundabout way by travesring them in an instance on a temp track

r.PreventUIRefresh(1)
r.InsertTrackAtIndex(r.GetNumTracks(), false) -- insert new track at end of track list and hide it; action 40702 creates undo point
local temp_track = r.GetTrack(0,r.CountTracks(0)-1)
r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINMIXER', 0) -- hide in Mixer
r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINTCP', 0) -- hide in Arrange
r.TrackFX_AddByName(temp_track, 'Video processor', 0, -1) -- insert video processor; this plugin name is unlikely to be changed by a user so can be relied upon
r.TrackFX_SetPresetByIndex(temp_track, 0, pres_cnt-1) -- start from the last preset in case user has a default preset enabled and advance forward in the loop below
local _, pres_cnt = r.TrackFX_GetPresetIndex(temp_track, 0)

local preset_name_t = {}

	for i = 1, pres_cnt do
	r.TrackFX_NavigatePresets(temp_track, 0, 1) -- forward
	local _, pres_name = r.TrackFX_GetPreset(temp_track, 0, '')
	preset_name_t[i] = pres_name..'|'
	end

r.DeleteTrack(temp_track)

r.PreventUIRefresh(-1)

	if fx_cnt > 1 then -- close submenu, otherwise no submenu
	table.insert(preset_name_t, #preset_name_t, '<') 
	end

	if #preset_name_t > 0 and 
	(#preset_name_t-1 == pres_cnt  -- one extra entry '<' if any
	or #preset_name_t == pres_cnt) -- when there's no submenu closure '<' because there's only one plugin in the chain
	then return preset_name_t end

end


function Collect_VST3_Instances(fx_chunk) -- replicates Collect_VideoProc_Instances()

-- required to get hold of .vstpreset file names stored in the plugin dedicated folder and list those in the menu

local vst3_t = {} -- collect indices of vst3 plugins instances, because detection by fx name is unreliable as it can be changed by user in the FX browser
local counter = 0 -- to store indices of vst3 plugin instances

	if fx_chunk and #fx_chunk > 0 then
		for line in fx_chunk:gmatch('[^\n\r]*') do -- all fx must be taken into account for vst3 plugin indices to be accurate
		local plug = line:match('<VST') or line:match('<AU') or line:match('<JS') or line:match('<DX') or line:match('<LV2') or line:match('<VIDEO_EFFECT')
			if plug then
				if line:match('VST3') then
				vst3_t[counter] = '' -- dummy value as we only need indices
				end
			counter = counter + 1
			end
		end
	end

	return vst3_t

end


function Collect_VST3_Preset_Names(obj, fx_idx, take_GUID, pres_cnt) -- replicates Collect_VideoProc_Preset_Names()

-- getting all preset names incuding .vstpreset file names in a roundabout way by travesring them in an instance on a temp track

r.PreventUIRefresh(1)
r.InsertTrackAtIndex(r.GetNumTracks(), false) -- insert new track at end of track list and hide it; action 40702 creates undo point
local temp_track = r.GetTrack(0,r.CountTracks(0)-1)
r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINMIXER', 0) -- hide in Mixer
r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINTCP', 0) -- hide in Arrange
local copy = take_GUID and r.TakeFX_CopyToTrack(obj, fx_idx, temp_track, 0, false) or not take_GUID and r.TrackFX_CopyToTrack(obj, fx_idx, temp_track, 0, false) -- difficult to work with r.TrackFX_AddByName() using plugin names as they can be renamed which will only be reflected in reaper-vstrenames(64).ini, not in the chunk; 'not take_GUID' cond is needed to avoid error when object is take which doesn't fit TrackFX_CopyToTrack() function
r.TrackFX_SetPresetByIndex(temp_track, 0, pres_cnt-1) -- start from the last preset in case user has a default preset enabled and advance forward in the loop below
local _, pres_cnt = r.TrackFX_GetPresetIndex(temp_track, 0)

local preset_name_t = {}

	for i = 1, pres_cnt do
	r.TrackFX_NavigatePresets(temp_track, 0, 1) -- forward
	local _, pres_name = r.TrackFX_GetPreset(temp_track, 0, '')
	local pres_name = pres_name:match('.+[\\/](.+)%.vstpreset$') or pres_name
	preset_name_t[i] = pres_name..'|'
	end

r.DeleteTrack(temp_track)

r.PreventUIRefresh(-1)

	if fx_cnt > 1 then -- close submenu, otherwise no submenu
	table.insert(preset_name_t, #preset_name_t, '<') 
	end

	if #preset_name_t > 0 and 
	(#preset_name_t-1 == pres_cnt  -- one extra entry '<' if any
	or #preset_name_t == pres_cnt) -- when there's no submenu closure '<' because there's only one plugin in the chain
	then return preset_name_t end

end


function Esc(str)
return str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
end

function Get_Object(LOCK_FX_CHAIN_FOCUS)

-- Before build 6.37 GetCursorContext() and r.GetTrackFromPoint(x, y) are unreliable in getting TCP since the track context and coordinates are true along the entire timeline as long as it's not another context
-- using edit cursor to find TCP context instead since when mouse cursor is over the TCP edit cursor doesn't respond to action 'View: Move edit cursor to mouse cursor' // before build 6.37 STOPS PLAYBACK WHILE GETTING TCP
-- Before build 6.37 no MCP support; when mouse is over the Mixer on the Arrange side the trick to detect track panel doesn't work, because with 'View: Move edit cursor to mouse cursor' the edit cursor does move to the mouse cursor

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

r.PreventUIRefresh(1)

local retval, tr, item = r.GetFocusedFX() -- account for focused FX chains and Mon FX chain in builds prior to 6.20
local fx_chain_focus = LOCK_FX_CHAIN_FOCUS or r.GetCursorContext() == -1

local obj, obj_type

	if (retval > 0 or GetMonFXProps() >= 0) and fx_chain_focus then -- (last) focused FX chain as GetFocusedFX() returns last focused which is still open
	obj, obj_type = table.unpack(retval == 2 and tr > 0 and {r.GetTrackMediaItem(r.GetTrack(0,tr-1), item), 1} or retval == 1 and tr > 0 and {r.GetTrack(0,tr-1), 0} or {r.GetMasterTrack(0), 0})
	else -- not FX chain
	local x, y = r.GetMousePosition()
		if tonumber(r.GetAppVersion():match('(.+)/')) >= 6.37 then -- SUPPORTS MCP
		local retval, info_str = r.GetThingFromPoint(x, y)
		obj, obj_type = table.unpack(info_str == 'arrange' and {({r.GetItemFromPoint(x, y, true)})[1], 1} -- allow locked is true
		or info_str:match('[mt]cp') and {r.GetTrackFromPoint(x, y), 0} or {nil})
		else
		-- First get item to avoid using edit cursor actions
		--[-[------------------------- WITHOUT SELECTION --------------------------------------------
		obj, obj_type = ({r.GetItemFromPoint(x, y, true)})[1], 1 -- get without selection, allow locked is true, the function returns both item and take pointers, here only item's is collected, works for focused take FX chain as well
		--]]
		--[[-----------------------------WITH SELECTION -----------------------------------------------------
		r.Main_OnCommand(40289,0) -- Item: Unselect all items;  -- when SEL_OBJ_IN_CURR_CONTEXT option in the USER SETTINGS is OFF to prevent getting any selected item when mouse cursor is outside of Arrange proper (e.g. at the Mixer or Ruler or a focused Window), forcing its recognition only if the item is under mouse cursor, that's because when cursor is within Arrange and there's no item under it the action 40528 (below) itself deselects all items (until their selection is restored at script exit) and GetSelectedMediaItem() returns nil so there's nothing to fetch the data from, but when the cursor is outside of the Arrange proper (e.g. at the Mixer or Ruler) this action does nothing, the current item selection stays intact and so GetSelectedMediaItem() does return first selected item identificator
		r.Main_OnCommand(40528,0) -- Item: Select item under mouse cursor
		obj, obj_type = r.GetSelectedMediaItem(0,0), 1
		--]]
			if not obj then -- before build 6.37, EDIT CURSOR ACTIONS MAKE RUNNING TRANSPORT STOP !!!!!
			local curs_pos = r.GetCursorPosition() -- store current edit curs pos
			local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0) -- isSet false, screen_x_start, screen_x_end are 0 to get full arrange view coordinates // get time of the current Arrange scroll position to use to move the edit cursor away from the mouse cursor
			r.SetEditCurPos(end_time+5, false, false) -- moveview, seekplay false // to secure against a vanishing probablility of overlap between edit and mouse cursor positions in which case edit cursor won't move just like it won't if mouse cursor is over the TCP // +5 sec to move edit cursor beyond right edge of the Arrange view to be completely sure that it's far away from the mouse cursor
			r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping) // more sensitive than with snapping
				if r.GetCursorPosition() == end_time+5 then -- the edit cursor stayed put at the pos set above since the mouse cursor is over the TCP
				--[-[------------------------- WITHOUT SELECTION --------------------------------------------
				obj, obj_type = r.GetTrackFromPoint(x, y), 0 -- get without selection, works for focused track FX chain as well
				--]]
				--[[-----------------------------WITH SELECTION -----------------------------------------------------
				r.Main_OnCommand(41110,0) -- Track: Select track under mouse
				obj, obj_type = r.GetSelectedTrack2(0,0, true), 0 -- account for Master is true
				--]]
				end
			local new_curs_pos = r.GetCursorPosition()
			local min_val, subtr_val = table.unpack(new_curs_pos == end_time+5 and {curs_pos, end_time+5} -- TCP found, edit cursor remained at end_time+5
			or new_curs_pos ~= end_time+5 and {curs_pos, new_curs_pos} -- TCP not found, edit cursor moved
			or {0,0})
			r.MoveEditCursor(min_val - subtr_val, false) -- dosel false = don't create time sel; restore orig. edit curs pos, greater subtracted from the lesser to get negative value meaning to move closer to zero (project start) // MOVES VIEW SO IS UNSUITABLE
		-- 	OR SIMPLY
			r.SetEditCurPos(curs_pos, false, false) -- moveview, seekplay false // restore orig. edit curs pos
			end
		end
	end

r.PreventUIRefresh(-1)

	return obj, obj_type

end


function MAIN(menu_t, action_t, FX_Chain_Chunk, Collect_VideoProc_Instances, Collect_VideoProc_Preset_Names, Collect_FX_Preset_Names, Esc, path, sep, obj, obj_chunk, fx_cnt, type, take_GUID) -- type 0 (track main fx) or 1 (track input fx), take fx are detected by evaluating take_GUID, either nil or an actual value

	local fx_chunk = FX_Chain_Chunk(obj_chunk, path, sep, type, take_GUID) -- needed for video processor and VST3 plugin instances detection with Collect_VideoProc_Instances() and Collect_VST3_Instances functions, detection video proc by fx name is unreliable as not all its preset names which are also instanse names contain 'video processor' phrase due to length, neither it's reliable for VST3 plugins for the sake of getting .vstpreset file names as it can be changed by user in the FX browser
	local video_proc_t = Collect_VideoProc_Instances(fx_chunk, fx_cnt)
	local vst3_t = Collect_VST3_Instances(fx_chunk, fx_cnt)
		for i = 0, fx_cnt-1 do
		local fx_idx = (take_GUID or type == 0) and i or i+0x1000000 -- either take or track main fx or track input/monitor fx
		local pres_cnt = take_GUID and select(2,r.TakeFX_GetPresetIndex(obj, fx_idx)) or select(2,r.TrackFX_GetPresetIndex(obj, fx_idx))
		local pres_fn = take_GUID and r.TakeFX_GetUserPresetFilename(obj, fx_idx, '') or r.TrackFX_GetUserPresetFilename(obj, fx_idx, '')
		local pres_fn = pres_fn:match('[^\\/]+$') -- isolate preset file name
		local fx_name = take_GUID and select(2,r.TakeFX_GetFXName(obj, fx_idx, '')) or select(2,r.TrackFX_GetFXName(obj, fx_idx, ''))
		local act, act_pres_name = table.unpack(take_GUID and {r.TakeFX_GetPreset(obj, fx_idx, '')} or {r.TrackFX_GetPreset(obj, fx_idx, '')})
		local div = #menu_t > 0 and i == 0 and '|||' or '' -- divider between main fx and input fx lists only if there're main fx and so menu_t table is already populated
			if pres_cnt == 0 then
			menu_t[#menu_t+1] = div..'#'..fx_name..' (n o  p r e s e t s)|'
			-- take the grayed out entry into account in the action_t as a disabled grayed out entry still counts against the total number of the menu entries
			action_t[1][#action_t[1]+1] = '' -- dummy value
			action_t[2][#action_t[2]+1] = '' -- same
			elseif pres_cnt > 0 then -- only plugins with presets
			local preset_name_t = video_proc_t[i] and Collect_VideoProc_Preset_Names(fx_cnt, pres_cnt) or vst3_t[i] and Collect_VST3_Preset_Names(obj, fx_cnt, fx_idx, take_GUID, pres_cnt) or Collect_FX_Preset_Names(obj, fx_cnt, fx_idx, pres_cnt)
			local preset_name_list = preset_name_t and table.concat(preset_name_t)
			local preset_name_list = preset_name_t and table.concat(preset_name_t)
				if preset_name_list then -- add active preset checkmark
					if act and act_pres_name ~= '' then -- if active preset matches the plug actual settings and not 'No preset'
					local act_pres_name = act_pres_name:match('.+%.vstpreset') and act_pres_name:match('([^\\/]+)%.%w+$') or act_pres_name
					local act_pres_name_esc = Esc(act_pres_name) -- escape special chars just in case
					preset_name_list = preset_name_list:gsub(act_pres_name_esc, '!'..act_pres_name) -- add checkmark to indicate active preset in the menu
					end
				local div = fx_cnt > 1 and div..'>' or '' -- only add submenu tag if more than 1 plugin in the chain because submenu only makes sense in this scenario, addition of the closure tag < is conditioned within collect preset names functions
				local fx_name = fx_cnt > 1 and fx_name..'|' or '' -- only include plugin name as submenu header if more than 1 plugin in the chain because submenu only makes sense in this scenario otherwise it counts agains the preset entry indices and disrupts their correspondence to preset indices
				menu_t[#menu_t+1] = div..fx_name..preset_name_list
					for j = 0, pres_cnt-1 do
					action_t[1][#action_t[1]+1] = fx_idx -- fx indices, repeated as many times as there're fx presets per fx to be triggered by the input form the menu
					action_t[2][#action_t[2]+1] = j -- preset indices, repeated as many times as there're fx presets, starts from 0 with every new fx index
					end
				end
			end
		end

return menu_t, action_t

end



------- START MAIN ROUTINE ------------

local itm_sel_t, trk_sel_t = StoreSelectedObjects()

local sep = r.GetOS():match('Win') and '\\' or '/' -- or r.GetResourcePath():match([\\/])
local path = r.GetResourcePath()
local SEL_OBJ_IN_CURR_CONTEXT = SEL_OBJ_IN_CURR_CONTEXT:gsub(' ','') ~= '' -- or #SEL_OBJ_IN_CURR_CONTEXT:gsub(' ','') > 0
local LOCK_FX_CHAIN_FOCUS = LOCK_FX_CHAIN_FOCUS:gsub(' ','') ~= ''

	if not SEL_OBJ_IN_CURR_CONTEXT then
	obj, obj_type = Get_Object(LOCK_FX_CHAIN_FOCUS)
	RestoreSavedSelectedObjects(itm_sel_t, trk_sel_t) -- only if they were deselected by Get_Object() function due to the use of 'WITH SELECTION' routine
	end

	if not obj and SEL_OBJ_IN_CURR_CONTEXT then -- if called via menu or from a toolbar after explicitly selecting the object e.g. by clicking it first
	local cur_ctx = r.GetCursorContext2(true) -- true is last context; unlike r.GetCursorContext() this function stores last context if current one is invalid; object must be clicked to change context
	local space = [[               ]]
		if cur_ctx == 0 then -- track
		local trk_cnt = r.CountSelectedTracks2(0, true) -- incl. Master
		mess = trk_cnt == 0 and '\n  NO SELECTED TRACKS  \n'..space or trk_cnt > 1 and '\n   MULTIPLE TRACK SELECTION  \n'..space
		obj, obj_type = r.GetSelectedTrack2(0,0, true), 0 -- incl. Master
		elseif cur_ctx == 1 then -- item
		local itm_cnt = r.CountSelectedMediaItems(0)
		mess = itm_cnt == 0 and '\n  NO SELECTED ITEMS  \n'..space or itm_cnt > 1 and '\n   MULTIPLE ITEM SELECTION  \n'..space
		obj, obj_type = r.GetSelectedMediaItem(0,0), 1
		end
	end

	if mess then
	local x, y = r.GetMousePosition(); r.TrackCtl_SetToolTip(mess:gsub('.', '%0 '), x, y-20, 1)
	return r.defer(function() do return end end) end -- prevent undo point creation

	
	if obj then -- prevent error when no item and when no track (empty area at bottom of the TCP, in MCP or the ruler or focused window) and prevent undo point creation

		if obj_type == 1 then
		local fx_chain_focus = LOCK_FX_CHAIN_FOCUS or r.GetCursorContext() == -1
			if r.GetFocusedFX() == 2 and fx_chain_focus then -- (last) focused take FX chain
			take = r.GetTake(obj,(select(4,r.GetFocusedFX()))>>16) -- make presets menu of focused take FX chain independent of the take being active
			else take = r.GetActiveTake(obj) end
		end

	local fx_cnt = obj_type == 0 and r.TrackFX_GetCount(obj) or obj_type == 1 and r.TakeFX_GetCount(take)

		if obj_type == 0 then rec_fx_cnt = r.TrackFX_GetRecCount(obj) end -- count input fx
		local space = [[               ]]
		if rec_fx_cnt then
			if fx_cnt + rec_fx_cnt == 0 then mess = '\n  NO FX IN THE TRACK FX CHAINS  \n'..space
			else
				if fx_cnt > 0 then -- find out if plugins contain any presets
				main_fx_pres = 0
					for i = 0, fx_cnt-1 do
					local retval, pres_cnt = r.TrackFX_GetPresetIndex(obj, i)
					main_fx_pres = main_fx_pres + pres_cnt
					end
				end
				if rec_fx_cnt and rec_fx_cnt > 0 then -- find out if plugins contain any presets
				rec_fx_pres = 0
					for i = 0, rec_fx_cnt-1 do
					local retval, pres_cnt = r.TrackFX_GetPresetIndex(obj, i+0x1000000)
					rec_fx_pres = rec_fx_pres + pres_cnt
					end
				end
			end
		else take_fx_cnt = r.TakeFX_GetCount(take)
			if take_fx_cnt == 0 then mess = '\n  NO FX IN THE TAKE FX CHAIN  \n'..space
			elseif take_fx_cnt > 0 then -- find out if plugins contain any ptresets
			take_fx_pres = 0
				for i = 0, take_fx_cnt-1 do
				local retval, pres_cnt = r.TakeFX_GetPresetIndex(take, i)
				take_fx_pres = take_fx_pres + pres_cnt
				end
			end
		end

		if not mess then -- additional conditions
		mess = ((fx_cnt > 0 and rec_fx_cnt and rec_fx_cnt > 0 and main_fx_pres + rec_fx_pres ==  0) or (fx_cnt > 0 and main_fx_pres == 0) or (rec_fx_cnt and rec_fx_cnt > 0 and rec_fx_pres == 0) or (take_fx_cnt and take_fx_cnt > 0 and take_fx_pres == 0)) and '\n  EITHER NO PRESETS OR NO PRESETS  \n\tACCESSIBLE TO THE SCRIPT\n'..space or nil
		end

		if mess then
		local x, y = r.GetMousePosition(); r.TrackCtl_SetToolTip(mess:gsub('.', '%0 '), x, y-20, 1) -- y-20 raise tooltip above mouse cursor by that many px
		return r.defer(function() do return end end) end


	local ret, obj_chunk = GetObjChunk(obj, obj_type) -- needed for video processor and VST3 plugin instances detection with Collect_VideoProc_Instances() and Collect_VST3_Instances() functions

		if ret == 'err_mess' then Err_mess() return r.defer(function() do return end end) end -- chunk size is over the limit and no SWS extention is installed to fall back on


	local action_t = {{},{}} -- stores fx and preset indices as values for each key matching a preset index
	local menu_t = {}


		if fx_cnt > 0 then
			if take then take_GUID = Esc(select(2,r.GetSetMediaItemTakeInfo_String(take, 'GUID', '', 0))) -- escape to use with string.match inside FX_Chain_Chunk()
			obj = r.GetActiveTake(obj)
			end
		menu_t, action_t = MAIN(menu_t, action_t, FX_Chain_Chunk, Collect_VideoProc_Instances, Collect_VideoProc_Preset_Names, Collect_FX_Preset_Names, Esc, path, sep, obj, obj_chunk, fx_cnt, 0, take_GUID) -- 0 is type, track main fx
		end

		if rec_fx_cnt and rec_fx_cnt > 0 then
		menu_t, action_t = MAIN(menu_t, action_t, FX_Chain_Chunk, Collect_VideoProc_Instances, Collect_VideoProc_Preset_Names, Collect_FX_Preset_Names, Esc, path, sep, obj, obj_chunk, rec_fx_cnt, 1, take_GUID) -- 1 is type, track input fx
		end


	gfx.init('FX Menu', 0, 0)
	-- open menu at the mouse cursor
	gfx.x = gfx.mouse_x
	gfx.y = gfx.mouse_y

	local input = gfx.showmenu(table.concat(menu_t))

		if input > 0 then
		local select_pres = obj_type == 0 and r.TrackFX_SetPresetByIndex(obj, action_t[1][input], action_t[2][input]) or obj_type == 1 and r.TakeFX_SetPresetByIndex(take, action_t[1][input], action_t[2][input])
		end

	end
	

-- Undo is unnesessary as it's created automatically on preset change



