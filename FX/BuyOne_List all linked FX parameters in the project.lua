--[[
ReaScript Name: List all linked FX parameters in the project
Author: BuyOne
Version: 1.0
Changelog: Initial release
Author URL: https://forum.cockos.com/member.php?u=134058
Licence: WTFPL
REAPER: at least v5.962
About: 		Either displays in the ReaScript console the list of FX parameters 
		linked via parameter modulation or, if the list is too long
		to fit within one console output, saves it to a dump file either
		in the directory specified in the USER SETTINGS of in REAPER
		resource directory if custom one isn't provided, malformed
		or doesn't exist. Of this the user is notified with a dialogue.
		
		The dump file will be overwritten every time the list is saved 
		to it. So if you need to keep the last saved list for future 
		reference, rename the file or remove it from the directory it's in.
		
		The list may take a few seconds or longer to get compiled depending on
		the number of tracks and items with FX in the project as all are being
		analyzed for linked parameters. During that time REAPER will freeze. 
		Unfortunately couldn't find a way to prevent that, if such exists. 

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- If enabled, track FX linked parameters will be listed first,
-- then take FX linked parameters;
-- Otherwise linked parameters of take FX on a particular track
-- will be listed after track FX linked parameters of such track

SEPARATE_TAKE_FX_LIST = "1" -- any alphanumeric character


-- If the list exceeds 16,380 bytes it won't fit
-- entirely within ReaScript console due to character limit
-- and instead will be saved to a file named 'FX PARAMETER LINK LIST.TXT'
-- in the directory the path to which is specified in this setting between
-- the double square brackets;
-- If empty or malfomed, the file will be saved to REAPER
-- resource directory or overwritten there if already present

PATH_DO_DUMP_FILE = [[]]

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


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


function Esc(str)
return str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
end


function GetParmLinkProps(...)
local chunk, obj, obj_idx, fx_idx, parm_idx, is_track = table.unpack({...})
local tr = is_track
local fx_GUID = tr and r.TrackFX_GetFXGUID(obj, fx_idx) or r.TakeFX_GetFXGUID(obj, fx_idx)
local fx_chunk = chunk:match(Esc(fx_GUID)..'.-WAK')
local PROGRAMENV = fx_chunk:match('<PROGRAMENV '..parm_idx..'.->')

	if not PROGRAMENV then return '' end

local master_fx_idx, diff, master_parm_idx = table.unpack(PROGRAMENV and {PROGRAMENV:match('PLINK.-(%d+):(%-?%d+) (%-?%d+).->')} or {x,x,x}) -- x is the same as nil

	if not master_fx_idx or tonumber(master_parm_idx) < 0 then return '' end -- if (not found) while Parameter linking section is enabled

local ret, obj_name = table.unpack(tr and {r.GetSetMediaTrackInfo_String(obj, 'P_NAME', '', false)} or {r.GetSetMediaItemTakeInfo_String(obj, 'P_NAME', '', false)}) -- set false
local obj_name = obj == r.GetMasterTrack(0) and 'Master track' or obj_name
local func = tr and r.TrackFX_GetFXName or r.TakeFX_GetFXName
local ret, master_fx_name = func(obj, master_fx_idx, '')
local ret, slave_fx_name = func(obj, fx_idx, '')
local func = tr and r.TrackFX_GetParamName or r.TakeFX_GetParamName
local ret, master_parm_name = func(obj, master_fx_idx, master_parm_idx, '')
local ret, slave_parm_name = func(obj, fx_idx, parm_idx, '')
local obj_type = tr and 'Track ' or ''
local item = not tr and r.GetMediaItemTake_Item(obj)
local item_idx = not tr and r.GetMediaItemInfo_Value(item, 'IP_ITEMNUMBER') -- 0 based
local item_tr = not tr and r.GetMediaItemTrack(item)
local obj_idx = not tr and 'Track '..r.CSurf_TrackToID(item_tr, false).. -- mcpView false
' Item '..math.floor(item_idx+1)..' Take '..math.floor(r.GetMediaItemTakeInfo_Value(obj, 'IP_TAKENUMBER')+1) or obj_name == 'Master track' and '' or obj_idx + 1 -- math.floor to get rid of decimal 0

return obj_type..obj_idx..' "'..obj_name..'"\nSLAVE:  '..slave_parm_name..' / '..slave_fx_name..'\nMASTER: '..master_parm_name.. ' / '..master_fx_name..'\n\n'

end

function Dir_Exists(path) -- short
local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces
local sep = path:match('[\\/]')
local path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- last separator is removed to return 1 (valid)
local _, mess = io.open(path)
return mess:match('Permission denied') and path..sep -- dir exists // this one is enough
end


function open_dir_in_file_browser(dir)
local OS = r.GetOS():sub(1,3)
local command = OS == 'Win' and {'explorer'} or (OS == 'OSX' or OS == 'mac') and {'open'} or {'nautilus', 'dolphin', 'gnome-open', 'xdg-open', 'gio open', 'caja', 'browse'}
-- https://askubuntu.com/questions/31069/how-to-open-a-file-manager-of-the-current-directory-in-the-terminal
	for k,v in ipairs(command) do
	local result = r.ExecProcess(v..' '..dir, -1) -- timeoutmsec is -1 = no wait/terminate
		if result then return end
	end
end



SEPARATE_TAKE_FX_LIST = #SEPARATE_TAKE_FX_LIST:gsub(' ', '') > 0


local listed = {{}, {}}
local failed = {{}, {}}

	for tr_idx = -1, r.CountTracks(0)-1 do
	local skip_to_next_tr
	local tr = r.GetTrack(0,tr_idx) or r.GetMasterTrack(0)
	local ret, chunk = GetObjChunk(1, tr)
		if ret == 'err_mess' then
		skip_to_next_tr = 1
		end
		for fx_idx = 0, r.TrackFX_GetCount(tr)-1 do
			if skip_to_next_tr then -- placed in fx loop to only count tracks with fx
			failed[1][#failed[1]+1] = 1 -- just a dummy entry
			break end
			for parm_idx = 0, r.TrackFX_GetNumParams(tr, fx_idx)-1 do
			local data = GetParmLinkProps(chunk, tr, tr_idx, fx_idx, parm_idx, true) -- true is track object type
				if #data > 0 then listed[1][#listed[1]+1] = data end
			end
		end


		for item_idx = 0, r.CountTrackMediaItems(tr)-1 do
		local skip_to_next_itm
		local item = r.GetTrackMediaItem(tr,item_idx)
		local ret, chunk = GetObjChunk(2, item)
			for take_idx = 0, r.CountTakes(item)-1 do
				if skip_to_next_itm then break end
			local take = r.GetTake(item, take_idx)
				for fx_idx = 0, r.TakeFX_GetCount(take)-1 do
					if ret == 'err_mess' then -- placed in fx loop to only count items with fx
					failed[2][#failed[2]+1] = 1 -- just a dummy entry
					skip_to_next_itm = 1
					break end
					for parm_idx = 0, r.TakeFX_GetNumParams(take, fx_idx)-1 do
					local data = GetParmLinkProps(chunk, take, take_idx, fx_idx, parm_idx) -- 1 is track object type
						if #data > 0 then
							if SEPARATE_TAKE_FX_LIST then
							listed[2][#listed[2]+1] = data
							else
							listed[1][#listed[1]+1] = data
							end
						end
					end
				end
			end
		end
	end


	-- Insert headings

	if not SEPARATE_TAKE_FX_LIST then

	local total = #listed[1] + #listed[2]
	local add = total > 0 and table.insert(listed[1], 1, ('Total FX parameter links : '..total..'\n\n'):upper() )

	else -- separated list

	local add = #listed[1] > 0 and table.insert(listed[1], 1, ('Track FX param links total : '..#listed[1]..'\n\n'):upper() )
	local nl = #listed[1] > 0 and '\n' or ''
	local add = #listed[2] > 0 and table.insert(listed[2], 1, (nl..'Take FX param links total : '..#listed[2]..'\n\n'):upper() )

	end

local listed = table.concat(listed[1])..table.concat(listed[2])
local failed_tracks_or_both = not SEPARATE_TAKE_FX_LIST and (#failed[1] > 0 and #failed[2] > 0 and (#failed[1]+#failed[2])..' tracks and items combined ' or #failed[1] > 0 and #failed[1]..' tracks ' or #failed[2] > 0 and #failed[2]..' items ')
or #failed[1] > 0 and #failed[1]..' tracks ' or ''
local failed_items = SEPARATE_TAKE_FX_LIST and #failed[2] > 0 and #failed[2]..' items ' or ''
local And = #failed_items > 0 and #failed[1] > 0 and 'and ' or ''
local failed = (#failed_items > 0 or #failed_tracks_or_both > 0) and 'The data couldn\'t be retrieved from '..failed_tracks_or_both..And..failed_items..'due to REAPER limitations.\nTo safeguard against possible failures install SWS Extension from https://www.sws-extension.org/\n\n' or ''


	if #listed <= 16380 then -- print to ReaConsole
	-- https://forum.cockos.com/showthread.php?t=216979
	Msg(listed..failed)
	else -- dump to a file because ReaScript Console won't display the whole list
	local dir = Dir_Exists(PATH_DO_DUMP_FILE)
		if not dir then -- if dir is empty or othwrwise invalid dump into the REAPER resource directory
		dir = r.GetResourcePath()..r.GetResourcePath():match('[\\/]') end
	local f = io.open(dir..'FX PARAMETER LIST LINKS.TXT', 'w')
	f:write(listed..failed)
	f:close()
	local f_exists = r.file_exists(dir..'FX PARAMETER LIST LINKS.TXT')
		if f_exists then
		local path = (dir == PATH_DO_DUMP_FILE or dir:sub(1,-2) == PATH_DO_DUMP_FILE) and 'designated' -- user dir either with or without the last separator
		or 'REAPER resource'
		local space = path == 'designated' and (' '):rep(5) or ''
		local resp = r.MB(' The list has been saved to a file\n\n'..space..'in the '..path..' directory.\n\n       Open the directory now?', 'PROMPT', 4)
			if resp == 6 then open_dir_in_file_browser(dir) end
		end
	end



do return r.defer(function() do return end end) end -- undo point and generic undo placeholder (ReaScript:Run) aren't needed




