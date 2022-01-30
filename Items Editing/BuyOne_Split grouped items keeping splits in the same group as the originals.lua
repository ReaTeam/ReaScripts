--[[
ReaScript name: Split grouped items keeping splits in the same group as the originals
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
Screenshots: https://raw.githubusercontent.com/Buy-One/screenshots/main/Split%20grouped%20items%20keeping%20splits%20in%20the%20same%20group%20as%20the%20originals.gif
REAPER: at least v5.962
About:	When items get split their grouping gets split as well.  
        The left and right parts of the split end up being grouped with 
        the items to the left and to the right of the split point (if any) 
        respectively.  
        The script allows splitting grouped items without losing grouping 
        of their split parts. Multiple groups are supported.  
	If the item(s) being split is/are not grouped, the split will still work.
]]

-----------------------------------------------------------------------
--------------------------- USER SETTINGS -----------------------------
-----------------------------------------------------------------------

-- When grouping is ON, all items vertically aligned and grouped
-- with the selected one will get split;
-- enable this option if you only need splitting the selected item(s);
SPLIT_IGNORING_GROUPING = ""

------------------------------------------------------------------------
----------------------- END OF USER SETTINGS ---------------------------
------------------------------------------------------------------------

local r = reaper


function store_selected_itms_group_ids()
local group_id_init
local t = {}
	for i = 0, r.CountSelectedMediaItems(0)-1 do
	local item = r.GetSelectedMediaItem(0,i)
	local group_id = r.GetMediaItemInfo_Value(item, 'I_GROUPID')
		if group_id ~= group_id_init and group_id > 0 then
		t[#t+1] = group_id
		group_id_init = group_id
		end
	end
return t
end


function tag_same_group_items(group_id)
	for i = 0, r.CountMediaItems(0)-1 do
	local item = r.GetMediaItem(0,i)
		if group_id > 0 and r.GetMediaItemInfo_Value(item, 'I_GROUPID') == group_id then
		r.GetSetMediaItemInfo_String(item, 'P_EXT:group', group_id, true) -- setNewValue true
		end
	end
end


function re_group_items(group_id)
r.SelectAllMediaItems(0, false) -- deselect all
	-- select all items and their splits which belonged to the original group
	for i = 0, r.CountMediaItems(0)-1 do
	local item = r.GetMediaItem(0,i)
	local retval, tag = r.GetSetMediaItemInfo_String(item, 'P_EXT:group', '', false) -- setNewValue false
		if retval and tag == tostring(group_id) then
		r.SetMediaItemSelected(item, true)
		r.GetSetMediaItemInfo_String(item, 'P_EXT:group', '', true) -- setNewValue true // remove tag
		end
	end
	-- group selected items
	if r.CountSelectedMediaItems(0) > 1 then
	r.Main_OnCommand(40032, 0) -- Item grouping: Group items
	end
end


function re_store_selected_items(t)
	if not t then
	local t = {}
		for i = 0, r.CountSelectedMediaItems(0)-1 do
		t[#t+1] = r.GetSelectedMediaItem(0,i)
		end
	return t
	else
	r.SelectAllMediaItems(0, false) -- deselect all
		for _, item in ipairs(t) do
		r.SetMediaItemSelected(item, true)
		end
	r.UpdateArrange() -- so selection restoration becomes visible
	end
end


local first_sel_item = r.GetSelectedMediaItem(0,0)

	if not first_sel_item then r.MB('No selected items.', 'ERROR', 0) return r.defer(function() do return end end) end

SPLIT_IGNORING_GROUPING = #SPLIT_IGNORING_GROUPING:gsub(' ','') > 0

r.Undo_BeginBlock()

local group_ids_t = store_selected_itms_group_ids() -- this can be undone, hence placed within the undo block

	for _, group_id in ipairs(group_ids_t) do
	tag_same_group_items(group_id) -- extented data is kept in all split parts
	end

local act = SPLIT_IGNORING_GROUPING and 40186 -- Item: Split items at edit or play cursor (ignoring grouping)
or 40012 -- Item: Split items at edit or play cursor

r.Main_OnCommand(act, 0)

local sel_t = re_store_selected_items() -- store // all split parts which end up being selected

	for _, group_id in ipairs(group_ids_t) do
	re_group_items(group_id)
	end

re_store_selected_items(sel_t) -- restore selection of splits


r.Undo_EndBlock('Split grouped items keeping splits in the same group', -1)



