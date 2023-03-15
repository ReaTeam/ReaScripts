--[[
ReaScript name: Exclusively solo or mute only selected grouped items
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.1
Changelog: #Added group locking in non-AUTO mode
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

		The functionaity can be replicated with custom actions   
		ACT 3 0 "ce55dc682200c84c93782dbdb16abd10" "Custom: Exclusively solo selected grouped items (1st deselect all items to avoid soloing random items)" _SWS_SAVEALLSELITEMS1 40034 40719 40289 _SWS_RESTALLSELITEMS1 40720   
		ACT 3 0 "2934c6ad6fe12f4989f10e75b2ae6010" "Custom: Exclusively mute selected grouped items (1st deselect all items to avoid muting random items)" _SWS_SAVEALLSELITEMS1 40034 40720 40289 _SWS_RESTALLSELITEMS1 40719   
		The bonus of the script is the AUTO mode and group lock.	

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- 1. EXCLUSIVE setting allows selecting the state which will be applied
-- exclusively to selected items of a group: 1 - solo; 2 - mute.
-- 2. Enabled AUTO setting makes the script run constantly where grouped items
-- are soloed or muted (according to EXCLUSIVE setting) by mere selection.
-- 3. When LOCK_GROUP setting is enabled the script stores groups of items
-- which were selected before the script was launched and then the state
-- determined by EXCLUSIVE setting is only applied to items of such group(s)
-- until the script is stopped if it runs in AUTO mode or until groups stored
-- in non-AUTO mode are excplicitly deleted by selecting any track, running
-- the script and confirming the prompt which pops up.
-- Unless deleted, groups stored in non-AUTO mode will be available for the
-- duration of REAPER session and won't intefere with groups stored in AUTO mode
-- but also won't be available in AUTO mode otherwise.
-- To enable AUTO and LOCK_GROUP settings insert any alphanumeric character
-- between the quotation marks.

EXCLUSIVE = "1" -- 1 - solo, 2 - mute
AUTO = ""
LOCK_GROUP = "" -- locks to the group(s) of the first selected item(s)

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
	local t = t and #t > 0 and t or {''} -- when no table is available because LOCKED_GROUP setting isn't enabled, allow one loop cycle with dummy table
		for i = 1, #t do
			if t[i] and group == tonumber(t[i]) then -- item group corresponds to one of locked groups stored in t, if not, the item is ignored; convert to number for when the table is populated from extended state whose data type is string
			group_t[item] = group -- store the item's group
			local act = EXCLUSIVE == 1 and r.SetMediaItemInfo_Value(item, 'C_MUTE_SOLO', -1) or EXCLUSIVE == 2 and r.SetMediaItemInfo_Value(item, 'B_MUTE', 1)
			elseif t[i] == '' and group > 0 then -- no stored locked groups, exclude all non-grouped items
			group_t[item] = group -- store the item's group
			local act = EXCLUSIVE == 1 and r.SetMediaItemInfo_Value(item, 'C_MUTE_SOLO', -1) or EXCLUSIVE == 2 and r.SetMediaItemInfo_Value(item, 'B_MUTE', 1)
			end
		end
	end
return group_t -- to evaluate the rest of items against
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
	local act = false -- ignore all if none of the below conditions is met
		for k, v in pairs(t) do
			if group == v and item == k then act = false break -- if the item which was just soloed or muted in solo_mute_sel_items()
			elseif group == v then act = true -- if any item of the same group as the one(s) just soled or muted in solo_mute_sel_items()
			end
		end
	local act = act and ( EXCLUSIVE == 1 and r.SetMediaItemInfo_Value(item, 'B_MUTE', 1) or EXCLUSIVE == 2 and r.SetMediaItemInfo_Value(item, 'B_MUTE', 0) )
	end
end

function string_2_table(str, pattern) -- pattern e.g. '(%d+);?' to extract semicolon delimited numbers
local counter = str -- a safety measure to avoid accidental ovewriting the orig. string, although this shouldn't happen thanks to %0
local counter = {counter:gsub(pattern, '%0')} -- 2nd return value is the number of replaced captures
local t = {str:match(string.rep(pattern, counter[2]))} -- captures the pattern as many times as there're pattern repetitions in the string
return t, counter[2] -- second return value holds number of captures
end


function RUN()

	if not AUTO and LOCK_GROUP and #r.GetExtState(cmd_ID, 'locked groups') > 0 then -- extract stored locked groups when in non-AUTO mode
	locked_groups_t, cnt = string_2_table(r.GetExtState(cmd_ID, 'locked groups'), '([%d%.]+);?') -- group number format is X.0
	end

local group_t = solo_mute_sel_items(locked_groups_t)
exclude_group_other_items(group_t)

locked_groups_t = LOCK_GROUP and not locked_groups_t and group_t and index_group_table(group_t) or locked_groups_t and #locked_groups_t > 0 and locked_groups_t -- // OR LOCK_GROUP and #locked_groups_t > 0 and locked_groups_t // only populate table once and maintain it until the script is stopped: cond1 - only populate table when its var is nil, cond2 - maintain a table populated when cond1 was true, without allowing it to update, implicit cond3 is true when table is empty making its var false which is equal to nil in this case so cond1 can kick in

local store_groups = not AUTO and locked_groups_t and #r.GetExtState(cmd_ID, 'locked groups') == 0 and r.SetExtState(cmd_ID, 'locked groups', table.concat(locked_groups_t, ';'), false) -- persist is false // when in non-AUTO mode

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

	if r.GetCursorContext2(true) == 0 and #r.GetExtState(cmd_ID, 'locked groups') > 0 then
	local resp = r.MB('You are about to delete stored locked item groups !!', 'WARNING', 1)
		if resp == 1 then r.DeleteExtState(cmd_ID, 'locked groups', true) end -- persist is true; delete stored lock groups
	return r.defer(function() end) end


r.Undo_BeginBlock()

	if AUTO then
		if LOCK_GROUP then r.SelectAllMediaItems(0, false) end -- unselect all so items whose group is to be locked could be selected explicitly
	r.SetToggleCommandState(sect_ID, cmd_ID, 1)
	r.RefreshToolbar(cmd_ID)
	end

RUN()

r.Undo_EndBlock('Exclusively '..(EXCLUSIVE == 1 and 'solo' or 'mute')..' selected grouped items',-1)

	if AUTO then r.atexit(function() r.SetToggleCommandState(sect_ID, cmd_ID, 0); r.RefreshToolbar(cmd_ID) end) end



