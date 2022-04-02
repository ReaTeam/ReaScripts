--[[
ReaScript Name: Move selected FX envelope in track to top/bottom/upwards/downwards
Author: BuyOne
Version: 1.0
Changelog: Initial release
Author URL: https://forum.cockos.com/member.php?u=134058
Licence: WTFPL
REAPER: at least v5.962
Screenshots: https://raw.githubusercontent.com/Buy-One/screenshots/main/Move%20selected%20FX%20envelope%20in%20track%20to%20top_bottom_upwards_downwards.gif
Extensions: SWS/S&M extension (not mandatory but recommended)
About:  Moves selected FX envelope of a track to the top/bottom lane,
        upwards/downwards one lane depending on the script name.  
        Upwards/downwards movement is cyclic.  
        Reordering only affects active envelopes of the track FX
        the selected envelope belongs to, as all envelopes of a particular
        FX are grouped together and envelopes of different FX cannot be 
        mixed while TCP envelopes always precede any FX envelopes and themselves
        cannot be reordered. Hence the movement is not relative to ALL 
        active/visible track envelopes but only to those of the same FX
        as the selected envelope.  
		
	Screenshot: https://raw.githubusercontent.com/Buy-One/screenshots/main/Move%20selected%20FX%20envelope%20in%20track%20to%20top_bottom_upwards_downwards.gif
		
Metapackage: true
Provides:   [main] BuyOne_Move selected FX envelope/BuyOne_Move selected FX envelope in track to top lane.lua
            [main] BuyOne_Move selected FX envelope/BuyOne_Move selected FX envelope in track to bottom lane.lua
            [main] BuyOne_Move selected FX envelope/BuyOne_Move selected FX envelope in track upwards one lane.lua
            [main] BuyOne_Move selected FX envelope/BuyOne_Move selected FX envelope in track downwards one lane.lua
]]

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper

local function GetObjChunk(obj) -- retval stems from r.GetFocusedFX(), value 0 is only considered at the pasting stage because in the copying stage it's error caught before the function
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


function Err_mess() -- if chunk size limit is exceeded and SWS extension isn't installed
local err_mess = 'The size of track data requires\n\nSWS/S&M extension to handle them.\n\nIf it\'s installed then it needs to be updated.\n\nGet the latest build of SWS/S&M extension at\nhttps://www.sws-extension.org/\n\n'
r.ShowConsoleMsg(err_mess, r.ClearConsole())
end


local function SetObjChunk(obj, obj_chunk) -- retval stems from r.GetFocusedFX(), value 0 is only considered at the pasting stage because in the copying stage it's error caught before the function
	if not (obj and obj_chunk) then return end
local tr = r.ValidatePtr(obj, 'MediaTrack*')
local item = r.ValidatePtr(obj, 'MediaItem*')
	return tr and r.SetTrackStateChunk(obj, obj_chunk, false) or item and r.SetItemStateChunk(obj, obj_chunk, false) -- isundo is false
end


function Esc(str)
return str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
end

function Error_Tooltip(text)
local x, y = r.GetMousePosition()
r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- topmost true
end

function Move_Env_Up(env, env_GUID, fx_chunk, scr_name)

local t = {}

	for block in fx_chunk:gmatch('<.->') do
		if block then t[#t+1] = block end -- collect all blocks separately, <PARAMENV and <PROGRAMENV
		if t[#t]:match('<PROGRAMENV') then -- if <PROGRAMENV block, merge it with the previous block in one table slot, because this block always follows <PARAMENV block for the same fx parameter
		t[#t-1] = t[#t-1]..'\n'..t[#t]
		table.remove(t, #t) -- remove separate slot for <PROGRAMENV block
		end
	end

local env_block_orig = table.concat(t,'\n')

	for k, env_block in ipairs(t) do
		if env_block:match(Esc(env_GUID)) then
			if scr_name:match('top') then
			table.insert(t, 1, env_block) -- copy to top
			table.remove(t, k+1) -- delete old slot, +1 since the table lengthens after insert above
			break
			elseif scr_name:match('bottom') then
			table.insert(t, #t+1, env_block) -- copy to after the last slot
			table.remove(t, k) -- delete old slot
			break
			elseif scr_name:match('upwards') then
			table.insert(t, #t+1, t[1]) -- copy 1st slot to after the last
			table.remove(t, 1) -- delete old 1st slot
			break
			elseif scr_name:match('downwards') then
			table.insert(t, 1, t[#t]) -- copy last slot to 1st
			table.remove(t, #t) -- delete old last slot
			break
			end
		end
	end	

local env_block_upd = table.concat(t,'\n')
local no_change = env_block_orig == env_block_upd
local mess = no_change and scr_name:match('top') and 'top' or no_change and scr_name:match('bottom') and 'bottom' or no_change and not scr_name:match('top') and not scr_name:match('bottom') and not scr_name:match('upwards') and not scr_name:match('downwards') and 'wrong script name' -- last option in case neither of the 4 direction words is found in the script name

return env_block_orig, env_block_upd, mess -- orig and updated versions + string for err message

end


local sel_env = r.GetSelectedTrackEnvelope(0)

	if not sel_env then 	
	Error_Tooltip(('\n\n  no selected track envelope  \n\n'))
	return r.defer(function() do return end end) end


local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local scr_name = scr_name:match('([^\\/]+)%.%w+')

--local scr_name = '_downwards' --------------- TESTING
	
local tr, fx_idx, parm_idx = r.Envelope_GetParentTrack(sel_env)

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

	if fx_idx == -1 then
	Error_Tooltip(('\n\n  not a track FX envelope  \n\n'))
	return r.defer(function() do return end end)
	else
	local retval, env_chunk = r.GetEnvelopeStateChunk(sel_env, '', false) -- isundo false
	local env_GUID = env_chunk:match('EGUID (.-)\n')
	local fx_GUID = r.TrackFX_GetFXGUID(tr, fx_idx)
	local next_fx_GUID = r.TrackFX_GetFXGUID(tr, fx_idx+1)
	local ret, chunk = GetObjChunk(tr)
		if ret == 'err_mess' then
		Err_mess()
		return r.defer(function() do return end end) end
	local capt1 = Esc(fx_GUID)..'.-<PARMENV.+<PROGRAMENV.+>' -- <PROGRAMENV block follows <PARMENV block of the same effect, hence must be evaluated first // covers code from the 1st <PARMENV to the last <PROGRAMENV block
	local capt2 = Esc(fx_GUID)..'.-<PARMENV.+<PARMENV.+>'
	local fx_chunk = next_fx_GUID and ( chunk:match('('..capt1..').-WAK.-'..Esc(next_fx_GUID)) 
	or chunk:match('('..capt2..').-WAK.-'..Esc(next_fx_GUID)) ) -- if there's main track fx downstream
	or chunk:match('('..capt1..').-WAK.-<FXCHAIN_REC') or chunk:match('('..capt2..').-WAK.-<FXCHAIN_REC') -- if there's input fx block downstream
	or chunk:match('('..capt1..').-WAK.-<ITEM') or chunk:match('('..capt2..').-WAK.-<ITEM') -- if there's item block downstream
	or chunk:match('('..capt1..').-WAK.+') or chunk:match('('..capt2..').-WAK.+') -- if the fx is the last in the chunk
	
	local env_block_orig, env_block_upd, mess = Move_Env_Up(env, env_GUID, fx_chunk, scr_name)
		if mess then
		mess = mess:match('wrong') and mess or 'the selected envelope  \n\n  is already at the '..mess
		Error_Tooltip(('\n\n  '..mess..'  \n\n'))
		r.Undo_EndBlock('',-1) -- to prevent generic 'ReaScript: Run' message in the status bar
		return r.defer(function() do return end end) end
	local chunk_no_env = chunk:gsub(Esc(env_block_orig), '') -- remove envelopes
	SetObjChunk(tr, chunk_no_env) -- set without envelopes
	local chunk1, chunk2 = chunk:match('(.+'..Esc(fx_GUID)..')(.+)')
	local chunk_upd = chunk1..'\n'..env_block_upd..chunk2
	SetObjChunk(tr, chunk_upd) -- set with reordered envelopes
	end

local sel_env = r.GetFXEnvelope(tr, fx_idx, parm_idx, false) -- create false // after setting the chunk and reordering envelopes, originally selected envelope pointer ends up belonging to another envelope, so in order to keep the original envelope selected its new pointer must be retrieved because now it will differ from the originally selected envelope pointer

r.SetCursorContext(2, sel_env) -- restore env selection
	

r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr_name:match('_(.+)'),-1)







