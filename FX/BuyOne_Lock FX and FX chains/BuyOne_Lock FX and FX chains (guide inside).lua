-- @noindex

--[[

* ReaScript Name: BuyOne_Lock FX and FX chains (guide inside).lua
* Description: Locks order of FX in the currently focused FX chain to prevent inadvertent reordering
* Instructions: included
* Author: Buy One
* Author URL: https://forum.cockos.com/member.php?u=134058
* Licence: WTFPL
* Forum Thread:
* Demo:
* Version: 1.2
* REAPER: at least v5.962
* Extensions:
* Changelog: Minor update of relational operator
]]

--[[

The script is meant to prevent inadvertent reordering of FX in the currently focused FX chain.
It stores FX positions and restores their order immediately once and if it has been dusturbed.

The script is set to auto-close Monitor FX chain once it loses focus because it may negatively
affect other FX chains locked status if stays open.

To to its job the script must run constantly. Just launch it from the 'Actions' window, with a
keyboard shorcut or from a toolbar button. On closure in REAPER's 'ReaScript task control'
dialogue checkmark 'Remember my answer for this script' checkbox and press 'Terminate instances'
button. Next time the script will be terminated without generating this dialogue.

The lock works in either global or in individual mode per FX chain.

The global mode is the default one and is initialized as soon as the script is started. In this
mode all FX in the chain are locked and their order can't be changed, but they can be removed
and new FX can be added. Once a new FX is added it becomes locked. To place a new FX at the position
of the existing one just drag and drop the new one from the FX browser over the list entry of the
existing one within the chain but not over its UI.

The individual mode is initialized by appending a tag, defined in the USER SETTINGS, to the FX
name displayed in the FX chain. It can be appended and removed while the script is running. In this
mode only the tagged FX can't be moved. When other FX are added and removed the tagged ones maintain
their position unless the number of FX upstream of the tagged FX is reduced in which case their
position is updated and they remain locked at their new position. When all FX in the chain are tagged,
new FX can only be inserted at the bottom of the chain.

While FX are locked in the track FX chain they can still be reordered in the Mixer FX insert slots if
the FX chain is hidden.

To add the lock tag to the Video processor name, insert it in the very first line of its preset code
(the first commented out line), e.g. //X De-interlace track/item
where X is the lock tag and hit Ctrl(Command)+S. Be aware that after that the tag will be burnt
into the code and will be displayed in the Video processor instance name each time the preset is loaded.
You can however delete it and again save the preset.

As the tag any QWERTY keyboard symbols can be used save for quotation mark " and percent sign %.

To be able to monitor the script on/off status you may want to assign it to a toolbar button which will
be lit while it's on.

If you want the script to run constantly and still be able to move FX inside an FX chain, load some 
dummy JS plugin which does nothing (create an empty .jsfx file) and lock only that with the lock tag, 
the rest of plugins will be unlocked.

There's an auxiliary script
BuyOne_Lock FX and FX chains - append or remove lock tag (guide inside).lua
which automates the task of appending and removing lock tags from FX names. If you append tags manually,
in order to be then able to remove them with this auxiliary script place the lock tag before the FX name
and separate them with space, e.g. "TAG VST: My plugin".
Since in the case of the Video processor the auxiliary script applies the lock tag to the first line of 
the Video processor preset code which is used by REAPER to name the Video processor instances in the FX 
chain, once you change the plugin preset the tag will be lost and it won't be restored once you return 
to the previously tagged preset because it wasn't explicitly saved. The only way to keep the tag in a 
Video processor preset code after applying it with the auxiliary script is to manually save it with 
Ctrl(Command)+S as described above.

]]

------------------------ USER SETTINGS -----------------------
--------------------------------------------------------------
 -- Any QWERTY keyboard symbol save for quotation mark " and %
 -- between the double square brackets

TAG = [[X]]

--------------------------------------------------------------
-------------------- END OF USER SETTINGS --------------------


function Msg(param)
reaper.ShowConsoleMsg(tostring(param).."\n")
end

r = reaper

TAG = TAG:gsub('[%s]','')


-- Chunks are employed for global lock mode to make FX chain update smoother, with as little GUI redraw and update as possible

local function GetObjChunk(retval, obj)
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua

	if retval == 0 and r.TrackFX_GetRecChainVisible(r.GetMasterTrack(0)) >= 0
	then
	local sep = reaper.GetOS():match('Win') and '\\' or '/'
	local f = assert(io.open(reaper.GetResourcePath()..sep..'reaper-hwoutfx.ini', 'r'))
	obj_chunk = f:read('*a') -- read the entire content
	io.close(f)
	elseif retval > 0 then
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
	end
		if obj_chunk then return true, obj_chunk end
end


local function SetObjChunk(retval, obj, obj_chunk)
	if not (obj and obj_chunk) then return end
	return retval == 1 and r.SetTrackStateChunk(obj, obj_chunk, false) or r.SetItemStateChunk(obj, obj_chunk, false)
end


local function Restore_Chunk(retval, obj, fx_num, ref_chunk)

	local ret, cur_chunk = GetObjChunk(retval, obj)
	if retval == 2 then -- TAKE FX
	local retval, take_GUID = r.GetSetMediaItemTakeInfo_String(r.GetTake(obj,fx_num>>16), 'GUID', '', false)
	local take_GUID = r.guidToString(take_GUID, ''):gsub('[%-]', '%%%0')
	ref_fx_chunk = ref_chunk:match(take_GUID..'.-(<TAKEFX.->)\nTAKE') or ref_chunk:match(take_GUID..'.-(<TAKEFX.->)\n<ITEM') or ref_chunk:match(take_GUID..'.-(<TAKEFX.*>)\n>')
	cur_fx_chunk = cur_chunk:match(take_GUID..'.-(<TAKEFX.->)\nTAKE') or cur_chunk:match(take_GUID..'.-(<TAKEFX.->)\n<ITEM') or cur_chunk:match(take_GUID..'.-(<TAKEFX.*>)\n>')
	last_sel_fx = tonumber(cur_fx_chunk:match('LASTSEL%s(%d*)')) -- extract last sel fx to reopen its UI after fx order is restored
	elseif retval == 1 and r.TrackFX_GetRecChainVisible(r.GetMasterTrack(0)) >= 0 then -- MONITOR FX (retval 1 stems from the argument passed in Restore_FX_Chain() function)
		cur_fx_chunk = cur_chunk:match('(<TRACK.*MAINSEND.-)\n>') -- temporary track chunk
		ref_fx_chunk = cur_fx_chunk..'\n<FXCHAIN\n'..ref_chunk..'\n>'
	elseif retval == 1 then -- TRACK FX
		if fx_num < 16777216 then -- regular track fx, including master
		ref_fx_chunk = ref_chunk:match('(<MASTERFXCHAIN.*>)\n<TRACK') or ref_chunk:match('(<FXCHAIN.*>)\n<FXCHAIN_REC') or ref_chunk:match('(<FXCHAIN.->)\n<ITEM') or ref_chunk:match('(<FXCHAIN.*WAK.*>)\n>')
		cur_fx_chunk = cur_chunk:match('(<MASTERFXCHAIN.*>)\n<TRACK') or cur_chunk:match('(<FXCHAIN.*>)\n<FXCHAIN_REC') or cur_chunk:match('(<FXCHAIN.->)\n<ITEM') or cur_chunk:match('(<FXCHAIN.*WAK.*>)\n>')
		last_sel_fx = tonumber(cur_fx_chunk:match('LASTSEL%s(%d*)')) -- extract last sel fx to reopen its UI after fx order is restored
		else -- input fx
		ref_fx_chunk = ref_chunk:match('(<FXCHAIN_REC.->)\n<ITEM') or ref_chunk:match('(<FXCHAIN_REC.*>)\n>')
		cur_fx_chunk = cur_chunk:match('(<FXCHAIN_REC.->)\n<ITEM') or cur_chunk:match('(<FXCHAIN_REC.*>)\n>')
		last_sel_fx = tonumber(cur_fx_chunk:match('LASTSEL%s(%d*)')) + 0x1000000-- extract last sel fx to reopen its UI after fx order is restored
		end
	end

	local ref_fx_chunk = ref_fx_chunk:match('[%%]') and ref_fx_chunk:gsub('%%','%%%%') or ref_fx_chunk -- escape in replacement string with subsequent reversal after replacement is mainly for Video processor chunks

	local rest_chunk = cur_chunk:gsub(cur_fx_chunk:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0'), ref_fx_chunk):gsub('%%%%','%%')
	local val = SetObjChunk(retval, obj, rest_chunk)

	return last_sel_fx -- if reordering involves last sel fx then its UI is reopened otherwise the UI of fx which is involved in reordering will reopen (either of the one being dragged or the one sought to be replaced, hard to perdict which exactly); for mon fx last selected fx is only updated in reaper-hwoutfx.ini after mon. fx chain is closed or closed and reopened, wasn't successful in reliably store and extract that value, opted for another mechanism employed in the Restore_FX_Chain() function which at least produces consistent results
end

function If_Tagged_FX(retval, track_num, item, fx_num, fx_names_t) -- find if there're tagged fx and count them

local tagged
local tagged_num = 0
local TAG = TAG:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')..' ' -- escapes in case needed
local name_changed

	if retval == 2 then -- take FX chain
	local take = r.GetTake(item, fx_num>>16)
	fx_cnt = r.TakeFX_GetCount(take)
		for i = 0, fx_cnt-1 do -- find if there're any tagged FX in the chain
		local retval, name = r.TakeFX_GetFXName(take, i, '')
			if name:match('^'..TAG) then tagged = true tagged_num = tagged_num + 1  end
			if fx_names_t and fx_names_t[r.TakeFX_GetFXGUID(take, i)] ~= name then name_changed = true end
		end
	elseif retval == 1 then -- track FX chain
	local tr = r.GetTrack(0,track_num-1) or r.GetMasterTrack(0)
	fx_cnt = fx_num < 16777216 and r.TrackFX_GetCount(tr) or r.TrackFX_GetRecCount(tr)
		for i = 0, fx_cnt-1 do
		local fx_idx = fx_num < 16777216 and i or i+0x1000000
		local retval, name = r.TrackFX_GetFXName(tr, fx_idx, '')
			if name:match('^'..TAG) then tagged = true tagged_num = tagged_num + 1 end
			if fx_names_t and fx_names_t[r.TrackFX_GetFXGUID(tr, fx_idx)] ~= name then name_changed = true end
		end
	elseif retval == 0 and r.TrackFX_GetRecChainVisible(r.GetMasterTrack(0)) >= 0 then -- Monitor FX chain
	local tr = r.GetMasterTrack(0)
	fx_cnt = r.TrackFX_GetRecCount(tr)
		for i = 0, fx_cnt-1 do
		local retval, name = r.TrackFX_GetFXName(tr, i+0x1000000, '')
			if name:match('^'..TAG) then tagged = true tagged_num = tagged_num + 1 end
			if fx_names_t and fx_names_t[r.TrackFX_GetFXGUID(tr, i+0x1000000)] ~= name then name_changed = true end
		end
	end

	return tagged, tagged_num, fx_cnt, name_changed

end


function Store_FX_Chain(retval, track_num, item, fx_num)

	local fx_t = {}
	local fx_names_t = {} -- store names to evaluate their correspondence with GUID when they change and trigger chunk update
	local tagged
	local TAG = TAG:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')..' ' -- escapes in case needed

		-- Take FX chain
		if retval == 2 then -- starting with item because track_num is also returned when take fx is in focus
		local take = r.GetTake(item, fx_num>>16)
			for i = 0, r.TakeFX_GetCount(take)-1 do -- find if there're any tagged FX in the chain
			local retval, name = r.TakeFX_GetFXName(take, i, '')
			if name:match('^'..TAG) then tagged = true break end
			end
			for i = 0, r.TakeFX_GetCount(take)-1 do	-- store
			local retval, name = r.TakeFX_GetFXName(take, i, '')
			local fx_GUID = r.TakeFX_GetFXGUID(take, i)
			fx_names_t[fx_GUID] = name
				if tagged and name:match('^'..TAG) then
				fx_t[i+1] = fx_GUID -- table for when at least one plugin is tagged
				elseif not tagged then fx_t[#fx_t+1] = fx_GUID end -- table for when none is tagged
			end
		-- Track FX chain
		elseif retval == 1 then -- main FX chain
		local tr = r.GetTrack(0,track_num-1) or r.GetMasterTrack(0)
		local fx_cnt = fx_num < 16777216 and r.TrackFX_GetCount(tr)-1 or r.TrackFX_GetRecCount(tr)-1
			for i = 0, fx_cnt do -- find if there're any tagged FX in the chain
			local fx_idx = fx_num < 16777216 and i or i+0x1000000 -- main or input fx
			local retval, name = r.TrackFX_GetFXName(tr, fx_idx, '')
				if name:match('^'..TAG) then tagged = true break end
			end
			for i = 0, fx_cnt do
			local fx_idx = fx_num < 16777216 and i or i+0x1000000 -- main or input fx
			local retval, name = r.TrackFX_GetFXName(tr, fx_idx, '')
			local fx_GUID = r.TrackFX_GetFXGUID(tr, fx_idx)
			fx_names_t[fx_GUID] = name
				if tagged and name:match('^'..TAG) then
				fx_t[i+1] = fx_GUID
				elseif not tagged then
				fx_t[#fx_t+1] = fx_GUID end
			end
		elseif retval == 0 and r.TrackFX_GetRecChainVisible(r.GetMasterTrack(0)) >= 0 then -- Monitor FX chain
		local tr = r.GetMasterTrack(0)
		local mon_fx_cnt = r.TrackFX_GetRecCount(tr)-1
			for i = 0, mon_fx_cnt do -- find if there're any tagged FX in the chain
			local retval, name = r.TrackFX_GetFXName(tr, i+0x1000000, '')
				if name:match('^'..TAG) then tagged = true break end
			end
			for i = 0, mon_fx_cnt do
			local retval, name = r.TrackFX_GetFXName(tr, i+0x1000000, '')
			local fx_GUID = r.TrackFX_GetFXGUID(tr, i+0x1000000)
			fx_names_t[fx_GUID] = name
				if tagged and name:match('^'..TAG) then
				fx_t[i+1] = fx_GUID
				elseif not tagged then
				fx_t[#fx_t+1] = fx_GUID
				end
			end
		end
	return fx_t, fx_names_t
end


function Restore_FX_Chain(retval, track_num, item, fx_num, ref_fx_chain, ref_chunk, tagged, tagged_num)
-- checks if fx indices correspond to the reference table keys which store fx GUIDs as values
-- to trigger order restoration

local mon_fx_upd

	-- Take FX chain
	if retval == 2 then
	local take = r.GetTake(item, fx_num>>16)
	local act_take = r.GetActiveTake(item) -- get active take to restore later
	local fx_cnt = r.TakeFX_GetCount(take)
		for i = 0, fx_cnt-1 do
		local fx_GUID = r.TakeFX_GetFXGUID(take, i)
			for k,v in pairs(ref_fx_chain) do  -- pairs here and elsewhere to accomodate tagged fx table which is non-indexed
				if i ~= k-1 and fx_GUID == v then -- explanation of the double method see in the Track FX chain routine below
					if tagged then
					r.TakeFX_CopyToTake(take, i, take, k-1, true)
					r.TakeFX_SetOpen(take, fx_num&0xffff, true)
					else
					local last_sel_fx = Restore_Chunk(retval, item, fx_num, ref_chunk)
					r.TakeFX_SetOpen(take, last_sel_fx, true) -- reopen UI of fx which was open last before reordering
					r.SetActiveTake(act_take) -- restore active take
					end
				end
			end
		end
	-- Track main and input FX chains, including master main fx chain
	elseif retval == 1 then
	local tr = r.GetTrack(0,track_num-1) or r.GetMasterTrack(0)
	local fx_cnt = fx_num < 16777216 and r.TrackFX_GetCount(tr) or r.TrackFX_GetRecCount(tr)
		for i = 0, fx_cnt-1 do
		local fx_idx = fx_num < 16777216 and i or i+0x1000000
		local fx_GUID = r.TrackFX_GetFXGUID(tr, fx_idx)
			for k,v in pairs(ref_fx_chain) do
				if i ~= k-1 and fx_GUID == v then -- different mechanisms for with and without tags, chunk setting prevents moving fx past the tagged ones because the reference chunk isn't updated at reorder attempt to keep the stored data for restoration and as such contains old data, only suitable for restoration of the entire chain
					if tagged then
					local dest_fx_idx = fx_num < 16777216 and k-1 or k-1+0x1000000
					r.TrackFX_CopyToTrack(tr, fx_idx, tr, dest_fx_idx, true)
					r.TrackFX_SetOpen(tr, fx_num, true)
					else
					local last_sel_fx = Restore_Chunk(retval, tr, fx_num, ref_chunk)
					r.TrackFX_SetOpen(tr, last_sel_fx, true) -- reopen UI of fx which was open last before reordering
					end
				end
			end
		end
	-- Monitor FX chain
	elseif retval == 0 and r.TrackFX_GetRecChainVisible(r.GetMasterTrack(0)) >= 0 then
--	local reordered
	local master_tr = r.GetMasterTrack(0)
	local fx_cnt = r.TrackFX_GetRecCount(master_tr)-1
		for i = 0, fx_cnt do
		local fx_GUID = r.TrackFX_GetFXGUID(master_tr, i+0x1000000)
			for k,v in pairs(ref_fx_chain) do
				if i ~= k-1 and fx_GUID == v then -- explanation of the double method see at the Track FX chain routine above
					if tagged then
					r.TrackFX_CopyToTrack(master_tr, i+0x1000000, master_tr, k-1+0x1000000, true)
					r.TrackFX_SetOpen(master_tr, fx_num+0x1000000, true)
					else
					r.InsertTrackAtIndex(r.GetNumTracks(), false) -- Insert new track at end of track list and hide it
					local temp_track = r.GetTrack(0,r.CountTracks(0)-1)
					r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINMIXER', 0)
					r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINTCP', 0)
					Restore_Chunk(1, temp_track, fx_num, ref_chunk) -- retval == 1 to address temp track chunk
						for i = r.TrackFX_GetRecCount(r.GetMasterTrack())-1,0,-1 do -- delete all minitor fx
						r.TrackFX_Delete(master_tr, i+0x1000000)
						end
						for i = 0, r.TrackFX_GetCount(temp_track)-1 do -- copy over from the temp track
						r.TrackFX_CopyToTrack(temp_track, i, master_tr, i+0x1000000, false)
						end
					r.TrackFX_SetOpen(master_tr, fx_num+0x1000000, true) -- reopen the most recently sel. fx UI which happens to be the one which was sought to be replaced before reordering
					r.DeleteTrack(temp_track)
					mon_fx_upd = true return mon_fx_upd -- to trigger updating GUIDs in the ref table since they change after restoration
					end
				end
			end
		end
	end
end



local values_t = {-5,-5,-5,-5} -- placeholders for item pointer, track index and fx type (main, input or monitor), initialized to force the reference table population on initial load, the values are immaterial, i chose those which are unlikely to be returned by GetFocusedFX() function to make them differ, the reference table is updated when the last stored values change at runtime


function LOCK_FX_CHAIN()

r.PreventUIRefresh(1)

local retval, track_num, item_num, fx_num = r.GetFocusedFX() -- item_num is number within the track whose index is returned as track_num

	local track = r.GetTrack(0,track_num-1) or r.GetMasterTrack(0)
	local item = retval == 2 and r.GetTrackMediaItem(track, item_num)
	local mon_fx = retval == 0 and r.TrackFX_GetRecChainVisible(r.GetMasterTrack(0)) >= 0
	local fx_type = (retval == 1 and fx_num < 16777216) and 0 or ((retval == 1 and fx_num >= 16777216) and 1 or (mon_fx and 2)) -- either track main = 0 or input fx = 1 or mon fx = 2, for evaluation below
	local fx_num = mon_fx and r.TrackFX_GetRecChainVisible(r.GetMasterTrack(0)) or fx_num -- store mon fx most recently selected fx index to be reopened after reordering inside Restore_FX_Chain() function

		-- Autoclose Mon FX window once it loses focus to prevent glitches in using other fx chains while it's open in the background since it tends to momentarily get focus while other fx chains are updating and thereby disables their locked state
		if values_t[3] == 2 and fx_type ~= values_t[3] then
		r.TrackFX_SetOpen(r.GetMasterTrack(0), fx_num < 16777216 and fx_num+0x1000000 or fx_num, false)
		end

	local tagged, tagged_num, fx_cnt, name_changed = If_Tagged_FX(retval, track_num, item, fx_num, fx_names_t) -- find if there're tagged fx and count them, count fx and get name/GUID correspondence for conditions below
	local table_len = 0
		if ref_fx_chain then -- find length of the table when it's non-indexed due to storage of tagged fx GUIDs
			for k in next, ref_fx_chain do
			table_len = table_len + 1
			end
		end

	-- Condition reference table and chunks update
	-- accounting for changing FX chain between two items with identical indices on different tracks, for changing focused FX chain between track and take FX within one track, for presence of lock tags and change in count of tagged FX, for deleted/added FX (change in fx count), including deletion non-tagged FX which requires changing positions of the remaining tagged FX, for fx name change, for change in monitor FX GUIDs after their order restoration by copying from a temp track
	if (retval == 1 or retval == 2 or mon_fx) and (item ~= values_t[1] or track_num ~= values_t[2] or fx_type ~= values_t[3] or (not tagged and (fx_cnt ~= #ref_fx_chain or name_changed)) or (tagged and tagged_num ~= table_len) or fx_cnt < values_t[4]) or mon_fx_upd
	then
	ref_fx_chain, fx_names_t = Store_FX_Chain(retval, track_num, item, fx_num) -- table
	-- names need to be stored to trigger chunk update on name change thereby avoiding their reinstation in global lock mode i.e. when chunk is used to restore fx chain, because otherwise stored chunk wouldn't contain the new fx name
	ret, ref_chunk = GetObjChunk(retval, retval == 1 and track or (retval == 2 and item))
	values_t[1] = item; values_t[2] = track_num; values_t[3] = fx_type; values_t[4] = fx_cnt end


mon_fx_upd = Restore_FX_Chain(retval, track_num, item, fx_num, ref_fx_chain, ref_chunk, tagged, tagged_num) -- condition update of GUIDs in the table for mon fx since they change after order restoration

r.defer(LOCK_FX_CHAIN)
r.PreventUIRefresh(-1)

end


local err = TAG == '' and 'The lock tag hasn\'t been defined.' or ((TAG == '"' or TAG == '%') and '        Illegal tag. Quotation mark \"\n\nand percent sign % aren\'t supported.')
	if err then r.MB(err,'ERROR',0) r.defer(function() end) return end

local _, _, sect_ID, cmd_ID, _,_,_ = r.get_action_context()

local toggle_state = r.GetToggleCommandStateEx(sect_ID, cmd_ID)
	if toggle_state == -1 or toggle_state == 0 then
	r.SetToggleCommandState(sect_ID, cmd_ID, 1)
	r.RefreshToolbar2(sect_ID, cmd_ID) end

LOCK_FX_CHAIN()

function Toggle_Off()
r.SetToggleCommandState(sect_ID, cmd_ID, 0)
	r.RefreshToolbar2(sect_ID, cmd_ID)
end

r.atexit(Toggle_Off)


