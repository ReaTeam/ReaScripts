--[[
ReaScript name: Reverse order of all takes in items
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About:	Reverses order of all takes in selected items 
		or in all items in the project if none is selected.
]]


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper

function GetItemChunk(item)
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua
	if not item then return end
-- Try standard function -----
local ret, item_chunk = r.GetItemStateChunk(item, '', false) -- isundo = false
	if ret and item_chunk and #item_chunk > 4194303 and not r.APIExists('SNM_CreateFastString') then return 'error'
	elseif ret and item_chunk and #item_chunk < 4194303 then return ret, item_chunk -- 4194303 bytes = (4096 kb * 1024 bytes) - 1 byte
	end
-- If chunk_size >= max_size, use wdl fast string --
local fast_str = r.SNM_CreateFastString('')
	if r.SNM_GetSetObjectState(item, fast_str, false, false) -- setnewvalue and wantminimalstate = false
	then item_chunk = r.SNM_GetFastString(fast_str)
	end
r.SNM_DeleteFastString(fast_str)
	if item_chunk then return true, item_chunk end
end


function Err_mess() -- if chunk size limit is exceeded and SWS extension isn't installed

	local sws_ext_err_mess = "              The size of data requires\n\n     the SWS/S&M extension to handle it.\n\nIf it's installed then it needs to be updated.\n\n         After clicking \"OK\" a link to the\n\n SWS extension website will be provided\n\n\tThe script will now quit."
	local sws_ext_link = 'Get the SWS/S&M extension at\nhttps://www.sws-extension.org/\n\n'

	local resp = r.MB(sws_ext_err_mess,'ERROR',0)
		if resp == 1 then r.ShowConsoleMsg(sws_ext_link, r.ClearConsole()) return end
end


function reverse_indexed_table(t)
	if not t then return end
	for i = 1, #t-1 do -- loop as many times as the table length less 1, since the last value won't need moving
	local v = t[#t-i] -- store value
	table.remove(t, #t-i) -- remove it
	t[#t+1] = v -- insert it as the last value
	end
return t
end


function REVERSE_TAKES_VIA_CHUNK(item)
local ret, chunk = GetItemChunk(item)
	if ret == 'error' then Err_mess() return end
local take_cnt = r.CountTakes(item)
	if take_cnt > 1 then
	local chunk_t = {chunk:match('(.+)(NAME[%W].-)'..string.rep('(TAKE[%W].-)', take_cnt-2)..'(TAKE[%W].+)>')} -- repeat as many times as take count -2 since first and last take chunks are different; [%W] makes sure that only 'TAKE' tag is captured disregarding words which contain it, of which there're a few, i.e. it must be followed by anything but alphanumeric characters
	local part_one = chunk_t[1] -- store item wide preceding take chunks
	table.remove(chunk_t,1) -- remove it
	local take_chunk_t = reverse_indexed_table(chunk_t) -- reverse
	table.insert(take_chunk_t, #take_chunk_t, 'TAKE\n') -- add to the formerly 1st take now being the last as 1st take doesn't have 'TAKE' tag
	local take_chunk = table.concat(take_chunk_t):match('TAKE.-\n(.+)') -- concatenate, removing TAKE tag from the formerly last take now being the 1st, as 1st take shouldn't have 'TAKE' tag
	r.SetItemStateChunk(item, part_one..take_chunk..'>', false) -- isundo is false // adding chunk closure since it wasn't stored in the table
--	r.UpdateItemInProject(item)
	end
end


function REVERSE_TAKES(sel_itm_cnt)

local sel_itm_t = {} -- need to store to deselect afterwards since SWS action affects all selected items simultaneously
	for i = 0, sel_itm_cnt-1 do
	sel_itm_t[i] = r.GetSelectedMediaItem(0,i)
	end

r.SelectAllMediaItems(0, false) -- deselect all media items

	for i = 0, r.CountMediaItems(0)-1 do
	local item = sel_itm_cnt == 0 and r.GetMediaItem(0,i) or sel_itm_t[i] -- instead of sel_itm_cnt #sel_itm_t could be evaluated
		if item and r.NamedCommandLookup('_S&M_MOVETAKE4') ~= 0 then -- if SWS extension is installed
		r.SetMediaItemSelected(item, true) -- select item so SWS action can affect it
		local cur_take_num = r.GetMediaItemInfo_Value(item, 'I_CURTAKE')
			for k = r.CountTakes(item)-1, 0, -1 do -- done in reverse becaue SWS action 'SWS/S&M: Takes - Move active down (cycling) in selected item' is used so each next take moves 1 position less than the previous and the 1st moves as many positions as the number of takes less 1 because it itself isn't counted; if counting were done in ascending order SWS function 'SWS/S&M: Takes - Move active up (cycling) in selected item' would have to be used and the last take set active
			r.SetActiveTake(r.GetTake(item, 0)) -- set 1st take as active so it can be moved down with the SWS action
			local it = 0
				while it ~= k do -- last take isn't moved (when k is 0) since it ends up at its intended position
				r.Main_OnCommand(r.NamedCommandLookup('_S&M_MOVETAKE4'),0) -- SWS/S&M: Takes - Move active down (cycling) in selected items
				it = it + 1
				end
			end
		local cur_take_new_num = math.abs(r.CountTakes(item)-1 - cur_take_num) -- formula to calc index of originally active take after reversal: take_count - 1 - active_take_original_number, ignoring number sign, take count-1 to match take counting system which is 0 based
		r.SetActiveTake(r.GetTake(item, cur_take_new_num))
		r.SetMediaItemSelected(item, false) -- deselect item so it's not affected by the SWS action after being processed
		elseif item then
		REVERSE_TAKES_VIA_CHUNK(item)
		end
	end

	for _, v in pairs(sel_itm_t) do -- restore initial item selection
	r.SetMediaItemSelected(v, true)
	end

end


local sel_itm_cnt = r.CountSelectedMediaItems(0)
local mess = r.CountMediaItems(0) == 0 and {'No items in the project.', 'ERROR', 0} or sel_itm_cnt == 0 and {'         Since no items are selected\n\ntake order will be reversed in all items.', 'PROMPT', 1}

	if mess then resp = r.MB(mess[1], mess[2], mess[3])
		if mess[3] == 0 or resp == 2 then return r.defer(function() end) end
	end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

REVERSE_TAKES(sel_itm_cnt)

r.PreventUIRefresh(-1)
r.Undo_EndBlock('Reverse order of all takes in '..(sel_itm_cnt > 0 and 'selected' or 'all')..' items', -1)





