--[[
ReaScript name: Exclusively solo or mute only selected grouped items
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About:
		When selected grouped items are soloed or muted, 
		other items of that group are respectively muted or unmuted.  
		Could be used to mimic take behavior but with sepatate 
		items where only the selected one can be played.
		
		Select any grouped item and run the script.  
		May need to start by deselecting all items 
		before first running the script so that the state 
		of wrong selected items doesn't change.  
		This will allow selecting items explicitly 
		before applying exclusive solo or mute.
		
		In AUTO mode there's no need to run the script to change item state, 
		its applied automatically to any selected grouped item.  
		When the script starts in AUTO mode while LOCK_GROUP setting
		is enabled, all items get deselected, so you can explicitly
		select those whose group you wish the script to lock to.  
		When the script runs in AUTO mode and is assigned to a toolbar button
		the button is lit until the script is stopped.
		
		For the script to work Item grouping option 
		doesn't have to be enabled.  
		Non-grouped items are ignored.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- EXCLUSIVE setting allows selecting the state which will be applied
-- exclusively to selected items of a group: 1 - solo; 2 - mute.
-- Enabled AUTO setting makes the script run constantly where grouped items
-- are soloed or muted (according to EXCLUSIVE setting) by mere selection.
-- When LOCK_GROUP setting is enabled the script stores groups of items
-- which were selected first after it was lauched in the AUTO mode and then
-- the state determined by EXCLUSIVE setting is only applied to items of such
-- group(s) until the script is restarted.
-- To enable AUTO and LOCK_GROUP settings insert any alphanumeric character
-- between the quotation marks.

EXCLUSIVE = "1" -- 1 - solo, 2 - mute
AUTO = ""
LOCK_GROUP = "" -- locks to the group(s) of the first selected item(s), only relevant in AUTO mode

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


local r = reaper

function solo_mute_sel_items(t)
local group_t = {}
	for i = 0, r.CountSelectedMediaItems(0)-1 do
	local item = r.GetSelectedMediaItem(0, i)
	local group = r.GetMediaItemInfo_Value(item, 'I_GROUPID')
	local t = t or {} -- when no table is available because LOCKED_GROUP setting isn't enabled, allow one loop cycle
		for i = 0, #t do
			if t[i+1] and group == t[i+1] then
			group_t[item] = group
			local act = EXCLUSIVE == 1 and r.SetMediaItemInfo_Value(item, 'C_MUTE_SOLO', -1) or EXCLUSIVE == 2 and r.SetMediaItemInfo_Value(item, 'B_MUTE', 1)
			elseif #t == 0 and group > 0 then -- exclude non-grouped items
			group_t[item] = group
			local act = EXCLUSIVE == 1 and r.SetMediaItemInfo_Value(item, 'C_MUTE_SOLO', -1) or EXCLUSIVE == 2 and r.SetMediaItemInfo_Value(item, 'B_MUTE', 1)
			end
		end

	end
return group_t
end


function index_group_table(t) -- extract group numbers and place into an indexed table
local locked_groups_t = {}
	for k, v in pairs(t) do
	locked_groups_t[#locked_groups_t+1] = v
	end
return locked_groups_t
end


function exclude_group_other_items(t)
	for i = 0, r.CountMediaItems(0)-1 do
	local item = r.GetMediaItem(0, i)
	local group = r.GetMediaItemInfo_Value(item, 'I_GROUPID')
	local act = false
		for k, v in pairs(t) do
			if group == v and item == k then act = false break
			elseif group == v then act = true
			end
		end
	local act = act and ( EXCLUSIVE == 1 and r.SetMediaItemInfo_Value(item, 'B_MUTE', 1) or EXCLUSIVE == 2 and r.SetMediaItemInfo_Value(item, 'B_MUTE', 0) )
	end
end



function RUN()

local group_t = solo_mute_sel_items(locked_groups_t)
exclude_group_other_items(group_t)

locked_groups_t = LOCK_GROUP and not locked_groups_t and group_t and index_group_table(group_t) or locked_groups_t and #locked_groups_t > 0 and locked_groups_t -- // OR LOCK_GROUP and #locked_groups_t > 0 and locked_groups_t // only populate table once and maintain it until the script is stopped: cond1 - only populate table when its var is nil, cond2 - maintain a table populated when cond1 was true, without allowing it to update, implicit cond3 is true when table is empty making its var false which is equal to nil in this case so cond1 can kick in

r.UpdateArrange() -- to update items

local run = AUTO and r.defer(RUN)

end

sect_ID = ({r.get_action_context()})[3]
cmd_ID = ({r.get_action_context()})[4]
EXCLUSIVE = type(EXCLUSIVE) == 'string' and tonumber(EXCLUSIVE) or type(EXCLUSIVE) == 'number' and EXCLUSIVE
AUTO = #AUTO:gsub(' ', '') > 0
LOCK_GROUP = #LOCK_GROUP:gsub(' ', '') > 0
local locked_groups_t

	if r.CountSelectedMediaItems(0) > 0 and (not EXCLUSIVE or (EXCLUSIVE ~= 1 and EXCLUSIVE ~= 2)) then r.MB('Invalid  EXCLUSIVE  setting.', 'ERROR', 0) return r.defer(function() end) end

r.Undo_BeginBlock()

	if AUTO then
		if LOCK_GROUP then r.SelectAllMediaItems(0, false) end -- unselect all so items whose group is to be locked could be selected explicitly
	r.SetToggleCommandState(sect_ID, cmd_ID, 1)
	r.RefreshToolbar(cmd_ID)
	end
	

RUN()

r.Undo_EndBlock('Exclusively '..(EXCLUSIVE == 1 and 'solo' or 'mute')..' selected grouped items',-1)


	if AUTO then r.atexit(function() r.SetToggleCommandState(sect_ID, cmd_ID, 0); r.RefreshToolbar(cmd_ID) end) end


