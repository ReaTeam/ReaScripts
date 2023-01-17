--[[
ReaScript Name: Move selected FX envelope in track to top/bottom/upwards/downwards (6 scripts)
Author: BuyOne
Version: 1.2
Changelog: #Fixed script crach when applying to the only envelope of a particular FX
Author URL: https://forum.cockos.com/member.php?u=134058
Licence: WTFPL
REAPER: at least v5.962
Screenshots: https://raw.githubusercontent.com/Buy-One/screenshots/main/Move%20selected%20FX%20envelope%20in%20track%20to%20top_bottom_upwards_downwards.gif
Extensions: SWS/S&M extension (not mandatory but recommended)
About:  Moves selected FX envelope of a track to the top/bottom lane,
	upwards/downwards one lane depending on the script name.  
	(cycle) in the script name means that all envelopes move 
	upwards/downwards in unison with the selected one.  
	(swap) in the script name means that the selected envelope 
	is swapped with the one immediately above/below it while other 
	envelopes maintain their lanes.  
	Upwards/downwards movement is cyclic, i.e. if an envelope is pushed
	past top/bottom lane its movement continues from the oppostite end.  
	Reordering only affects active envelopes of the track FX
	the selected envelope belongs to, as all envelopes of a particular
	FX are grouped together and envelopes of different FX cannot be 
	mixed while TCP envelopes always precede any FX envelopes and themselves
	cannot be reordered. Hence the movement is not relative to ALL 
	active/visible track envelopes but only to those of the same FX
	as the selected envelope.  

	Screenshot: https://raw.githubusercontent.com/Buy-One/screenshots/main/Move%20selected%20FX%20envelope%20in%20track%20to%20top_bottom_upwards_downwards.gif

Metapackage: true
Provides: 	[main] . > BuyOne_Move selected FX envelope/BuyOne_Move selected FX envelope in track to top lane.lua
		[main] . > BuyOne_Move selected FX envelope/BuyOne_Move selected FX envelope in track to bottom lane.lua
		[main] . > BuyOne_Move selected FX envelope/BuyOne_Move selected FX envelope in track up one lane (cycle).lua
		[main] . > BuyOne_Move selected FX envelope/BuyOne_Move selected FX envelope in track down one lane (cycle).lua
		[main] . > BuyOne_Move selected FX envelope/BuyOne_Move selected FX envelope in track up one lane (swap).lua
		[main] . > BuyOne_Move selected FX envelope/BuyOne_Move selected FX envelope in track down one lane (swap).lua
]]


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


function Err_mess() -- if chunk size limit is exceeded and SWS extension isn't installed
local err_mess = 'The size of track data requires\n\nSWS/S&M extension to handle them.\n\nIf it\'s installed then it needs to be updated.\n\nGet the latest build of SWS/S&M extension at\nhttps://www.sws-extension.org/\n\n'
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

function Error_Tooltip(text)
local x, y = r.GetMousePosition()
r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- topmost true
end

function Move_Sel_Envelope(env, env_GUID, fx_chunk, scr_name)

local t = {}
local str = ''
local vis_env_cnt = 0
	for block in fx_chunk:gmatch('<.->') do -- construct a table merging <PROGRAMENV block with preceding <PARMENV block of the same fx param in one table slot and only adding new slots when a block of a visible envelope has been found, thereby attaching to them blocks of hidden envelopes to prevent hidden envelopes being accounted for in reordering below
	str = #str > 0 and str..'\n'..block or str..block -- concatenate a string as long as there're no blocks of visible envelopes
		if str:match('\nVIS 1 ') then t[#t+1] = str -- once a block of a visible evelope, dump the string concatenated above into the table
		str = '' -- reset the string
		vis_env_cnt = vis_env_cnt+1 -- count visible envelopes to condition error mess
		end
		if #t > 0 and block:match('<PROGRAMENV') and t[#t]:match('\nVIS 1 ') then -- merge <PROGRAMENV block with preceding <PARMENV block of either a visible or a hidden envelope because these will still be included within the same table slot
		t[#t] = t[#t]..'\n'..str
		str = '' -- reset the string
		end
	end

	if vis_env_cnt == 1 then return _, _, '    the selected envelope is  \n\n  the only visible in relevant fx' end -- abort when the sel env is the only FX env visible // 3 return values to match those at the end of the function

local env_block_orig = table.concat(t,'\n')

	for k, env_block in ipairs(t) do -- reorder
		if env_block:match(Esc(env_GUID)) then -- if matches selected env GUID
			if scr_name:match('top') then
			table.insert(t, 1, env_block) -- copy to top
			table.remove(t, k+1) -- delete old slot, +1 since the table lengthens after insert above
			elseif scr_name:match('bottom') then
			table.insert(t, #t+1, env_block) -- copy to after the last slot
			table.remove(t, k) -- delete old slot
			elseif scr_name:match(' up ') then
				if scr_name:match('cycle') then
				table.insert(t, #t+1, t[1]) -- copy 1st slot to after the last
				table.remove(t, 1) -- delete old 1st slot
				else -- swap
				local dest = k-1 == 0 and #t+1 or k-1 -- destination slot to insert
				local rem = k-1 == 0 and 1 or k+1 -- slot to remove
				table.insert(t, dest, env_block)
				table.remove(t, rem)
				end
			elseif scr_name:match(' down ') then
				if scr_name:match('cycle') then
				table.insert(t, 1, t[#t]) -- copy last slot to 1st
				table.remove(t, #t) -- delete old last slot
				else -- swap
				local dest = k == #t and 1 or k+2 > #t and #t+1 or k+2 -- destination slot to insert // when the envelope is the last, penultimate or other
				local rem = k == #t and #t or k -- slot to remove // when the envelope is the last or other
				table.insert(t, dest, env_block)
				table.remove(t, rem)
				end
			end
		break end
	end

local env_block_upd = table.concat(t,'\n')

local no_change = env_block_orig == env_block_upd
local mess = no_change and scr_name:match('top') and 'top' or no_change and scr_name:match('bottom') and 'bottom' or no_change and not scr_name:match('top') and not scr_name:match('bottom') and not scr_name:match(' up ') and not scr_name:match(' down ') and 'wrong script name' -- last option in case neither of the 4 direction words is found in the script name

return env_block_orig, env_block_upd, mess -- orig and updated versions + string for err message

end


local sel_env = r.GetSelectedTrackEnvelope(0)

	if not sel_env then
	Error_Tooltip(('\n\n  no selected track envelope  \n\n'))
	return r.defer(function() do return end end) end


local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local scr_name = scr_name:match('([^\\/]+)%.%w+')

	-- local scr_name = '_ down ' --------------- SCRIPT NAME TESTING

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
	local capt3 = Esc(fx_GUID)..'.-<PARMENV.->'
	local fx_chunk = next_fx_GUID and ( chunk:match('('..capt1..').-WAK.-'..Esc(next_fx_GUID))
	or chunk:match('('..capt2..').-WAK.-'..Esc(next_fx_GUID)) ) -- if there's main track fx downstream
	or chunk:match('('..capt1..').-WAK.-<FXCHAIN_REC') or chunk:match('('..capt2..').-WAK.-<FXCHAIN_REC') -- if there's input fx block downstream
	or chunk:match('('..capt1..').-WAK.-<ITEM') or chunk:match('('..capt2..').-WAK.-<ITEM') -- if there's item block downstream
	or chunk:match('('..capt1..').-WAK.+') or chunk:match('('..capt2..').-WAK.+') -- if the fx is the last in the chunk
	or chunk:match('('..capt3..').-WAK.+') -- the only envelope in fx
	--	if fx_chunk and #fx_chunk > 0 then -- fixes crash when applied to the only envelope in fx, but a better solution is using capt3 above
		local env_block_orig, env_block_upd, mess = Move_Sel_Envelope(env, env_GUID, fx_chunk, scr_name)
			if mess then
			mess = not env_block_orig and mess or mess:match('wrong') and mess or 'the selected envelope  \n\n  is already at the '..mess
			Error_Tooltip(('\n\n  '..mess..'  \n\n'))
			r.Undo_EndBlock('',-1) -- to prevent generic 'ReaScript: Run' message in the status bar
			return r.defer(function() do return end end) end
		local chunk_no_env = chunk:gsub(Esc(env_block_orig), '') -- remove envelopes
		SetObjChunk(tr, chunk_no_env) -- set without envelopes
		local chunk1, chunk2 = chunk:match('(.+'..Esc(fx_GUID)..')(.+)')
		local chunk_upd = chunk1..'\n'..env_block_upd..chunk2
		SetObjChunk(tr, chunk_upd) -- set with reordered envelopes
	--	end
	end

local sel_env = r.GetFXEnvelope(tr, fx_idx, parm_idx, false) -- create false // after setting the chunk and reordering envelopes, originally selected envelope pointer ends up belonging to another envelope, so in order to keep the original envelope selected its new pointer must be retrieved because now it will differ from the originally selected envelope pointer

r.SetCursorContext(2, sel_env) -- restore env selection


r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr_name:match('_(.+)'),-1)







