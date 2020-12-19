-- @description Switch unlocked items only to previous take (grouped items with a locked item in their group do not switch)
-- @author amagalma
-- @version 1.00
-- @about Like native Take: Switch items to previous take, but without switching takes for items that are locked or that they belong to a group with a locked item


local item_cnt = reaper.CountMediaItems( 0 )
local sel_item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt == 0 or sel_item_cnt == 0 then return reaper.defer(function() end) end


-- Get groups with locked items
local locked_groups = {}
for i = 0, item_cnt-1 do
	local item = reaper.GetMediaItem( 0, i )
	local group = reaper.GetMediaItemInfo_Value( item, "I_GROUPID" )
	if group ~= 0 then
		if reaper.GetMediaItemInfo_Value( item, "C_LOCK" ) & 1 == 1 then
			locked_groups[group] = true
		end
	end
end

-- Get items to unselect
local items = {}
local count = 0

for i = 0, sel_item_cnt-1 do
	local item = reaper.GetSelectedMediaItem( 0, i )
	local group = reaper.GetMediaItemInfo_Value( item, "I_GROUPID" )
	if reaper.GetMediaItemInfo_Value( item, "C_LOCK" ) & 1 == 1 or locked_groups[group] then
		count = count + 1
		items[count] = item
	end
end

if count == sel_item_cnt then return reaper.defer(function() end) end


reaper.PreventUIRefresh( 1 )

-- Unselect
for i = 1, count do
	reaper.SetMediaItemSelected( items[i], false )
end

reaper.Main_OnCommand(40126, 0) -- Switch items to previous take

-- Restore selection
for i = 1, count do
	reaper.SetMediaItemSelected( items[i], true )
end

reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()

reaper.Undo_OnStateChange( "Switch unlocked items only to previous take" )
