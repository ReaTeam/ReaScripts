--[[
ReaScript name: Randomize active take in items
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About:	Randomizes active take in selected items 
		or in all items in the project if none is selected.
		
		Thanks to the fact that only active take in an item
		can be played back, randomization can be used as a creative tool 
		to try different combinations of performance variations
		reprsented as takes combined into items at will.
		
		An even greater degree of randomization can be achieved
		by using this script within a custom action with the actions:   
		SWS/S&M: Takes - Move active down (cycling) in selected items AND/OR   
		SWS/S&M: Takes - Move active up (cycling) in selected items  
		having a single or several instances of each or both.
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable a setting insert any alphanumeric character between the quotes

-- same take can be active several times in a row
ALLOW_REPEATS = ""

-- mouse click won't change actve take in the affected items
LOCK_ACTIVE_TAKE = ""

-- display prompt when about to randomize active take in ALL items because
-- none is selected, to forestall mistake
PROMPT = ""

-- every script run will create an undo point; with many runs undo history
-- may get inundated with the script undo points pushing more meaningful
-- undo points away from immediate reach; on the other hand this will allow
-- revisiting previous randomization results
CREATE_UNDO_POINT = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


local sel_itm_cnt = r.CountSelectedMediaItems(0)
local mess = r.CountMediaItems(0) == 0 and {'No items in the project.', 'ERROR', 0} or sel_itm_cnt == 0 and #PROMPT:gsub(' ','') > 0 and {'         Since no items are selected\n\nactive take will be randomized in all items.', 'PROMPT', 1}

	if mess then resp = r.MB(mess[1], mess[2], mess[3])
		if mess[3] == 0 or resp == 2 then return r.defer(function() end) end
	end


function rand_take_idx(take_cnt, cur_take_idx)

	repeat
	cur_take_new_idx = math.random(take_cnt)
	until ALLOW_REPEATS and cur_take_new_idx or cur_take_new_idx-1 ~= cur_take_idx

return cur_take_new_idx-1 -- -1 since math.random's range begins with 1 while take count is 0 based

end


CREATE_UNDO_POINT = #CREATE_UNDO_POINT:gsub(' ','') > 0

local undo = CREATE_UNDO_POINT and r.Undo_BeginBlock()
r.PreventUIRefresh(1)


ALLOW_REPEATS = #ALLOW_REPEATS:gsub(' ','') > 0
LOCK_ACTIVE_TAKE = #LOCK_ACTIVE_TAKE:gsub(' ','') > 0

math.randomseed(math.floor(r.time_precise()*1000)) -- seems to facilitate greater randomization at fast rate thanks to milliseconds count

local cnt = sel_itm_cnt > 0 and sel_itm_cnt or r.CountMediaItems(0)

	for i = 0, cnt-1 do
	local item = r.GetSelectedMediaItem(0,i) or r.GetMediaItem(0,i)
	local take_cnt = r.CountTakes(item)
	local cur_take_idx = r.GetMediaItemInfo_Value(item, 'I_CURTAKE')
	local set = take_cnt > 1 and r.SetMediaItemInfo_Value(item, 'I_CURTAKE', rand_take_idx(take_cnt, cur_take_idx))
	local lock = LOCK_ACTIVE_TAKE and r.Main_OnCommand(41340,0) -- Item properties: Lock to active take (mouse click will not change active take)
	r.UpdateItemInProject(item)
	end


r.PreventUIRefresh(-1)
	if CREATE_UNDO_POINT then r.Undo_EndBlock('Randomize active take in '..(sel_itm_cnt > 0 and 'selected' or 'all')..' items', -1)
	else return r.defer(function() end) end



