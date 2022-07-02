--[[
ReaScript Name: Move, select, im- & explode, crop overlapping items in lanes (13 scripts) - only 6.53 and earlier
Author: BuyOne
Version: 1.0
Changelog: Initial release
Author URL: https://forum.cockos.com/member.php?u=134058
Licence: WTFPL
REAPER: at least v5.962 and not later than 6.53
Extensions: SWS/S&M, not mandatory but strongly recommended
About:  The script isn't compatible with REAPER builds 6.54 onward, because
	the logic governing overlapping items display in lanes was changed
	while the script was being developed.   
	https://forum.cockos.com/showthread.php?t=267390

	MOVE SELECTED TO TOP/BOTTOM LANE || ALL UP/DOWN ONE LANE

	In 'move selected to top/bottom lane' scripts, selection of multiple 
	items within the same overlapping items cluster doesn't make 
	sense, hence if multiple items are selected it's the first 
	(whose lane is the highest) or the last (whose lane is the lowest) 
	selected item per cluster which will be moved to the top/bottom 
	lane respectively.	
	'Cycle' in the script name means that all items change their lane 
	along with the selected one.  
	'Swap' means that only two items trade their lanes.  

	In 'move all up/down one lane' scripts the number of selected 
	overlapping items per cluster doesn't matter.  

	SELECT NEXT/PREVIOUS

	Select any number of overlapping items in a cluster and execute
	the script. Selection will be shifted down or up respectively.  
	If all items in a cluster are selected nothing changes.  

	IMPLODE

	* To implode items select them, point mouse cursor at an item 
	you want selected items to be placed underneath in lanes or select 
	its track and place the edit cursor over such item (designated item).  
	* If the designated item is already a part of an overlapping items 
	cluster, the imploded items will be placed in lanes immediately beneath
	such item provided it's selected, otherwise the imploded items 
	will be placed beneath the bottommost item of such overlapping items 
	cluster. If several items are selected in a cluster items are imploded 
	beneath the last selected.  
	* The designated item is always considered selected if the mouse cursor 
	points at it at the moment of the script execution, in which case it has
	to be run with a shortcut so the mouse cursor isn't enganged.   
	* Items are imploded in their global project order (left to right,
	top to bottom) beneath the designated item (one around which imploding 
	is performed).   
	* !!! After imploding, the originally selected items may end up in an 
	unexpected order if there're mutually fully overlapping items among 
	them, because in this case their global order isn't obvious, fully 
	overlapping items apparent lanes order isn't governed by their global 
	order in the project.  	
	* It's only possible to implode selected items into a single cluster 
	of overlapping items, meaning all selected items can either join an 
	already existing cluster or coalesce into a new one.

	EXPLODE || CROP

	To explode or crop overlapping items select any number of such
	overlapping items to have the rest exploded or removed respectively.
	If all items happen to be selected the action won't be executed.

	BEHAVIOR IN COLLAPSED LANES 

	When overlapping item lanes are collapsed, after a script is applied 
	generally the outermost (visible) item changes to reflect change 
	in item positions in lanes with the following caveats:  

	* When actions   
	'move selected to top/bottom lane', 'move all up/down one lane'   
	are applied to overlapping items whose lanes are collapsed, only 1 item 
	can stay selected per cluster which is the outermost (visible) one. 
	Change in selection is reflected in the change of the outermost item.  
	The outermost item lane isn't fixed and can be whatever.  		
	* In 'select next/prevous' scripts, the outermost (visible) item  
	only changes if it was selected before the script was applied.  
	* Even when all items in an overlapping items cluster are selected 
	before 'explode' or 'crop' script is executed all items will be
	respectively exploded or cropped leaving only the outermost item
	at its original position or intact respectively.  
	If the outermost item isn't selected, no exploding or cropping occurs 
	regardless of other items selection within the cluster.

	___________________________________________________________________
	Be aware that after duplicating overlapping items in a batch the order
	of their copies will likely be different. That's REAPER's quirk.
Metapackage: true
Provides: 	[main] . > BuyOne_Overlapping items/BuyOne_Overlapping items - move selected to top lane (cycle).lua
		[main] . > BuyOne_Overlapping items/BuyOne_Overlapping items - move selected to bottom lane (cycle).lua
		[main] . > BuyOne_Overlapping items/BuyOne_Overlapping items - move selected to top lane (swap).lua
		[main] . > BuyOne_Overlapping items/BuyOne_Overlapping items - move selected to bottom lane (swap).lua
		[main] . > BuyOne_Overlapping items/BuyOne_Overlapping items - move all up one lane.lua
		[main] . > BuyOne_Overlapping items/BuyOne_Overlapping items - move all down one lane.lua
		[main] . > BuyOne_Overlapping items/BuyOne_Overlapping items - select next.lua
		[main] . > BuyOne_Overlapping items/BuyOne_Overlapping items - select previous.lua
		[main] . > BuyOne_Overlapping items/BuyOne_Overlapping items - implode selected items as overlapping items in lanes.lua
		[main] . > BuyOne_Overlapping items/BuyOne_Overlapping items - explode on the same track (in place).lua
		[main] . > BuyOne_Overlapping items/BuyOne_Overlapping items - explode across tracks (to new tracks).lua
		[main] . > BuyOne_Overlapping items/BuyOne_Overlapping items - explode across tracks (to track duplicates).lua
		[main] . > BuyOne_Overlapping items/BuyOne_Overlapping items - crop to selected items.lua
]]

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


--============================ F U N C T I O N S ===============================

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


function Err_mess(inset) -- if chunk size limit is exceeded and SWS extension isn't installed
local err_mess = 'The size of '..inset..' requires\n\nSWS/S&M extension to handle them.\n\nIf it\'s installed then it needs to be updated.\n\nGet the latest build of SWS/S&M extension at\nhttps://www.sws-extension.org/\n\n'
r.ShowConsoleMsg(err_mess, r.ClearConsole())
end


local function SetObjChunk(obj, obj_chunk) -- retval stems from r.GetFocusedFX(), value 0 is only considered at the pasting stage because in the copying stage it's error caught before the function
	if not (obj and obj_chunk) then return end
local tr = r.ValidatePtr(obj, 'MediaTrack*')
local item = r.ValidatePtr(obj, 'MediaItem*')
	return tr and r.SetTrackStateChunk(obj, obj_chunk, false) or item and r.SetItemStateChunk(obj, obj_chunk, false) -- isundo is false
end


function ACT(comm_ID) -- both string and integer work
local act = comm_ID and r.Main_OnCommand(r.NamedCommandLookup(comm_ID),0)
end


function Toggle_Sel_Overlapping_Itm_UpDown() -- to create consistent IID sequence
r.PreventUIRefresh(1)
ACT(40068) -- Item lanes: Move item up one lane (when showing overlapping items in lanes)
ACT(40107) -- Item lanes: Move item down one lane (when showing overlapping items in lanes)
r.PreventUIRefresh(-1)
end


function Are_Two_Items_Overlapping(itm1, itm2)
	if not itm1 or not itm2 then return end -- false
local get_item_props = r.GetMediaItemInfo_Value
local get_track = r.GetMediaItemTrack
local st1 = get_item_props(itm1, 'D_POSITION')
local len1 = get_item_props(itm1, 'D_LENGTH')
local st2 = get_item_props(itm2, 'D_POSITION')
local len2 = get_item_props(itm2, 'D_LENGTH')
	return st2 < st1+len1 and st2+len2 > st1 and get_track(itm1) == get_track(itm2) -- true
end


function Esc(str)
return str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
end


function Space(int)
local int = not int and 0 or tonumber(int) and math.abs(math.floor(int)) or 0
return string.rep(' ', int)
end


function Error_Tooltip(text, upper) -- upper must be true
local x, y = r.GetMousePosition()
local text = text and type(text) == 'string' and (upper and text:upper():gsub('.','%0 ') or text) or 'not a valid "text" argument'
r.TrackCtl_SetToolTip(text, x, y, true) -- topmost true
end


function Are_Itms_Overlapping_Selected_Collapsed(t) -- t is an array storing selected items, optional, if no t selected items are evaluated
-- returns 5 boolean values:
-- true if there's at least one item overlapping each of those stored in the table or currently selected
-- true if there're no non-selected items among items overlapping each of those stored in the table or currently selected
-- first 2 return values must both be true to conclude that in all targeted clusters of overlapping items all items are selected
-- true if there're no items overlapping any of those stored in the table or currently selected
-- true if overlapping and non-overlapping items are all selected
-- true if selected item lanes are collapsed excluding non-overlapping items

local is_build_6_54_onward = tonumber(r.GetAppVersion():match('(.+)/')) >= 6.54
local lanes_collapsed_cnt = 0

local get_item_props = r.GetMediaItemInfo_Value
local overlap_cnt, non_selected = 0, 0
local cnt = t and #t or r.CountSelectedMediaItems(0) -- if t arg isn't supplied
	for i = 1, cnt do
	local sel_itm = t and t[i] or r.GetSelectedMediaItem(0, i-1)
	local start = get_item_props(sel_itm, 'D_POSITION')
	local length = get_item_props(sel_itm, 'D_LENGTH')
	local tr = r.GetMediaItemTrack(sel_itm)
	local prev_itm = r.GetSelectedMediaItem(0, i-2)
	local prev_itm_tr = t and t[i-1] and r.GetMediaItemTrack(t[i-1]) or prev_itm and r.GetMediaItemTrack(prev_itm)
	local overlap = true -- condition count of overlapping items below
	local I_LASTY_init = 0
		for i = 0, r.GetTrackNumMediaItems(tr)-1 do
		local tr_itm = r.GetTrackMediaItem(tr, i)
		local st = get_item_props(tr_itm, 'D_POSITION')
		local len = get_item_props(tr_itm, 'D_LENGTH')
		local I_LASTY = get_item_props(tr_itm, 'I_LASTY')
		local itms_overlapping = st < start+length and st+len > start
			if overlap and tr_itm ~= sel_itm and itms_overlapping then -- covers both full and partial overlap, excluding the actual item being evaluated
			overlap_cnt = overlap_cnt + 1 -- for each selected only 1 will be counted
			overlap = false -- one is enough; all next cycles will be ignored
			end
			if itms_overlapping then
			non_selected = not r.IsMediaItemSelected(tr_itm) and non_selected + 1 or non_selected -- accurate counting of selected items is problematic so it's easier to count non-selected
			I_LASTY_init = tr_itm ~= sel_itm and (not is_build_6_54_onward and (I_LASTY > 15 and I_LASTY or I_LASTY_init)) or I_LASTY_init -- seek the greatest, excluding non-overlapping items with tr_itm ~= sel_itm because otherwise they too satisfy itms_overlapping boolean
			end
		end
	lanes_collapsed_cnt = I_LASTY_init and I_LASTY_init <= 15 and lanes_collapsed_cnt+1 or lanes_collapsed_cnt -- if no greater than 15 is found then register
	end

local all_overlap, all_sel, all_non_overlap, mixed = overlap_cnt == cnt, non_selected == 0, overlap_cnt == 0, overlap_cnt ~= 0 and overlap_cnt < cnt and non_selected == 0 -- all_non_overlap return value is required because overlap_cnt == cnt being false doesn't necessarily mean that there're no items overlapping the selected, the selection could be mixed, likewise overlap_cnt > 0 for the same reason doesn't always mean that all items are being overlapped

local lanes_collapsed = not is_build_6_54_onward and lanes_collapsed_cnt > 0  -- relevant when overlapping item lanes are collapsed at certain TCP height or only 1 lane is set in Preferences -> Appearance in builds prior to 6.54

return all_overlap, all_sel, all_non_overlap, mixed, lanes_collapsed -- the last value will be used to offset all_sel because in collapsed lanes selection of all is allowed by design

end


function Overlapping_Itms_Props(itm, count_overlap, count_sel)
-- combines Are_Itms_Overlapping() and Count_Selected_Overlapping_Itms()
-- count_overlap and count_sel are booleans, return vals are integers
-- if both count_overlap and count_sel are true return val is boolean,
-- indicating whether all overlapping items are selected
	if not count_overlap and not count_sel then return end
--local count_overlap = not count_sel
--local count_sel = not count_overlap
local get_item_props = r.GetMediaItemInfo_Value
local start = get_item_props(itm, 'D_POSITION')
local length = get_item_props(itm, 'D_LENGTH')
local tr = r.GetMediaItemTrack(itm)
local cntr = 0 -- excluding the item in the argument
local selected_cntr = 0 -- including the item in the argument
	for i = 0, r.GetTrackNumMediaItems(tr)-1 do
	local tr_itm = r.GetTrackMediaItem(tr, i)
	local st = get_item_props(tr_itm, 'D_POSITION')
	local len = get_item_props(tr_itm, 'D_LENGTH')
	local itms_overlapping = st < start+length and st+len > start
		if count_overlap and itms_overlapping and tr_itm ~= itm then
		cntr = cntr+1
		end
		if count_sel and itms_overlapping and r.IsMediaItemSelected(tr_itm) then
		selected_cntr = selected_cntr+1
		end
	end
return count_overlap and count_sel and cntr > 0 and cntr+1 == selected_cntr
or count_overlap and not count_sel and cntr
or count_sel and not count_overlap and selected_cntr
end


function Count_Sel_Itms_Unique_Tracks(t)
local cnt = 0
local tr_init
local fin = t and #t or r.CountSelectedMediaItems(0)
	for i = 1, fin do
	local itm = t and t[i] or r.GetSelectedMediaItem(0,i-1)
	local tr = r.GetMediaItemTrack(itm)
	cnt = tr ~= tr_init and cnt + 1 or cnt
	tr_init = tr
	end
return cnt
end


function implode_Error_Messgs()

local get_item_props = r.GetMediaItemInfo_Value
local x, y = r.GetMousePosition()
local anch_itm = r.GetItemFromPoint(x, y, false) -- allow_locked false
local anch_tr

	if anch_itm then
	anch_tr = r.GetMediaItemTrack(anch_itm)
	start = get_item_props(anch_itm, 'D_POSITION')
	else -- if no item under mouse, find 1st item on 1st selected track under edit cursor (anchor item)
	local cur_pos = r.GetCursorPosition()
	anch_tr = r.GetSelectedTrack(0,0)
	local first_non_sel
		if anch_tr then
			for i = 0, r.GetTrackNumMediaItems(anch_tr)-1 do
			local itm = r.GetTrackMediaItem(anch_tr, i)
			start = get_item_props(itm, 'D_POSITION')
			local is_at_cursor = cur_pos >= start and cur_pos <= start + get_item_props(itm,'D_LENGTH')
			-- in case of imploding into an overlapping item cluster get either the very last selected or if none is selected get the very 1st non-selected
				if is_at_cursor and r.IsMediaItemSelected(itm) then
				anch_itm = itm
				elseif is_at_cursor then
				first_non_sel = not first_non_sel and itm or first_non_sel -- only the 1st non-selected
				end
			end
		end
	anch_itm = not anch_itm and first_non_sel or anch_itm
	end

	if not anch_itm then return Space(6)..'no item to implode  \n\n'..Space(9)..'selected items to.  \n\n  must be under mouse cursor  \n\n'..Space(7)..'or under edit cursor \n\n    on the 1st selected track.'  -- no item under edit cursor on the 1st selected track (no anchor item)
	elseif r.CountSelectedMediaItems(0) == 1 and r.IsMediaItemSelected(anch_itm) then return Space(8)..'the selected \n\n and the designated items \n\n'..Space(9)..'are the same'
	end

local anch_start = get_item_props(anch_itm, 'D_POSITION')
local anch_end = anch_start + get_item_props(anch_itm, 'D_LENGTH')

	for i = 0, r.CountSelectedMediaItems(0)-1 do -- find if selected items already overlap the anchor item
	local sel_itm = r.GetSelectedMediaItem(0,i)
	local tr = r.GetMediaItemTrack(sel_itm)
	local st = get_item_props(sel_itm, 'D_POSITION')
	local fin = st + get_item_props(sel_itm, 'D_LENGTH')
		if tr ~= anch_tr and st < anch_end and fin > anch_start -- at least 1 item on another track overlaps the anchor item which is OK
		or (fin <= anch_start or st >= anch_end) -- or at least 1 item doesn't overlap the anchor item and is either to the left of it or to the right on the same or on another track
		then return true end
	end

return Space(8)..'the selected  \n\n  and the designated items \n\n  are already overlapping' -- if not true above

end


function implode_Get_Anchor_Itm_Data(tr, cur_pos) -- collect all items overlapping the anchor item
--local cur_pos = r.GetCursorPosition()
--local get_item_props = r.GetMediaItemInfo_Value
local t = {}
	for i = 0, r.GetTrackNumMediaItems(tr)-1 do
	local itm = r.GetTrackMediaItem(tr, i)
	local start = r.GetMediaItemInfo_Value(itm, 'D_POSITION')
	local is_at_cursor = cur_pos >= start and cur_pos <= start + r.GetMediaItemInfo_Value(itm,'D_LENGTH')
		if is_at_cursor then t[#t+1] = itm
		elseif #t > 0 and not is_at_cursor then break -- the loop is past items at edit cursor // table will cetrainly contain at least one entry because cases when there's no item at the edit cursor are prevented by implode_Error_Messgs() function before the main loop
		end
	end
return t
end


function Check_reaper_ini(key,value) -- the args must be strings
local f = io.open(r.get_ini_file(),'r')
local cont = f:read('a*')
f:close()
return cont:match(key..'=(%d+)') == value
end


function Get_Script_Name(scr_name)
local t = {'top','bottom','all up','all down','next','previous','explode','implode','crop'}
local t_len = #t -- store here since with nils length will be harder to get
	for k, name in ipairs(t) do
	t[k] = scr_name:match(Esc(name)) --or false -- to avoid nils in the table, although still works with the method below
	end
-- return table.unpack(t) -- without nils
return table.unpack(t,1,t_len) -- not sure why this works, not documented anywhere, but does return all values if some of them are nil even without the n value (table length) as the 1st field
-- found mentioned at
-- https://stackoverflow.com/a/1677358/8883033
-- https://stackoverflow.com/questions/1672985/lua-unpack-bug
end

--============================ F U N C T I O N S  E N D ===============================



local build_6_53_and_earlier = tonumber(r.GetAppVersion():match('(.+)/')) > 6.53 and ('the script is only compatible \n\n  with builds 6.53 and earlier.'):upper():gsub('.','%0 ')
local not_overlapping_in_lanes = r.GetToggleCommandStateEx(0, 40507) ~= 1 -- Options: Show overlapping media items in lanes (when room) / Offset overlapping items vertically
and 'THE OPTION "Show overlapping media  \n\n        items in lanes"  IS NOT ENABLED.'
local err_mess = build_6_53_and_earlier or not_overlapping_in_lanes

	if err_mess then
	Error_Tooltip('\n\n   '..err_mess..' \n\n ')
	return r.defer(function() do return end end) end

local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local scr_name = scr_name:match('([^\\/]+)%.%w+')


--[[ NAME TESTING
local names_t = {'move to top cycle', 'move to bottom cycle', 'move to top', 'move to bottom', 'all up', 'all down', 'select next', 'select previous', 'explode on the same track', 'explode across new tracks', 'explode across track duplicates', 'implode', 'crop'}
--local scr_name = names_t[2]
--]]


local top, bottom, up, down, nxt, prev, explode, implode, crop = Get_Script_Name(scr_name)

local top_bott_up_down = top or bottom or up or down

	if not top_bott_up_down and not nxt and not prev and not explode and not implode and not crop then
	Error_Tooltip(' \n\n  wrong sctipt name  \n\n ', 1)
	return r.defer(function() do return end end) end

local no_overlap_err_cnt = 0
local all_sel_err_cnt = 0 -- to condition 'no undo' when all items are selected in all targeted clusters for 'move top/bottom', 'select next/prev', 'explode', 'crop' routines
local oversized_itm_chunk_cnt = 0
local oversized_tr_chunk_cnt, oversized_chunk_tr_init = 0
local top_bott_err_cnt = 0 -- 'move top/bottom' error mess counter
local explode_trk_cnt_total = 0 -- for 'explode across' routine to be able to reuse already created tracks for other items on the same track and not add new tracks unnecessarily


local sel_itm_cnt = r.CountSelectedMediaItems(0)
local sel_itms_t = {} -- won't be used by 'implode' routine

	-- Store selected items
	if sel_itm_cnt == 0 then
	Error_Tooltip('\n\n  no selected items  \n\n', 1)
	return r.defer(function() do return end end)
	else
		for i = 0, sel_itm_cnt-1 do -- store selected items to be able to deselect in the main loop and treat each such item separately
		local sel_itm = r.GetSelectedMediaItem(0,i)
		local sel_itm_prev = r.GetSelectedMediaItem(0,i-1)
			if not explode and not implode and not crop and not Are_Two_Items_Overlapping(sel_itm, sel_itm_prev) or explode or implode or crop then -- for 'implode' routine only needed once so there's at least 1 stored item to prevent errors in initialization of variable in the beginning of the main loop and to start it but isn't needed otherwise; for 'explode' and 'crop' routines all selected items need storing just so their selection is eventually restored, looping over selected items in these routines is handled inside the main loop; for the remaining routines only 1 selected item per overlapping items cluster is needed to continue
			sel_itms_t[#sel_itms_t+1] = sel_itm
			end
			if implode then break end -- for imploding 1 item is enough to launch the main loop, all processing is done in the implode routine
		end
	end


local unique_tr_cnt = Count_Sel_Itms_Unique_Tracks(sel_itms_t)


---------------- GENERATE ERROR MESSAGES & ABORT ------------------

-- to weed out invalid selections and avoid undo point creation,
-- otherwise as soon as Undo_BeginBlock() is called it will be unavoidable

local all_overlap, all_sel, all_non_overlap, mixed, lanes_collapsed = table.unpack(not implode and {Are_Itms_Overlapping_Selected_Collapsed(sel_itms_t)} or {x}) -- spare some runtime if not 'implode' // can be used without sel_itms_t and hence upstream of the table construction loop // alternative {x} is required to prevent error when the 1st cond is false

local err_mess = not implode and (all_non_overlap and 'no overlapping items' or not up and not down and (mixed and not lanes_collapsed and 'there\'re non-overlapping items; \n\n'..Space(7)..'in all clusters all items \n\n'..Space(9)..'happen to be selected.'
or all_overlap and all_sel and not lanes_collapsed and 'all items happen \n\n   to be selected') )
or implode and type(implode_Error_Messgs()) == 'string' and implode_Error_Messgs()

	if err_mess then
	Error_Tooltip('\n\n  '..err_mess..'  \n\n', 1)
	return r.defer(function() do return end end) end

-------------- GENERATE ERROR MESSAGES & ABORT END ---------------

local same_track = scr_name:match('same track')


r.Undo_BeginBlock()
r.PreventUIRefresh(1)

local st, fin, step = table.unpack(explode and same_track and {#sel_itms_t, 1, -1} or {1,#sel_itms_t,1}) -- when exploding on the same track, iteration over selected items table must be in reverse so that items downstream don't get new overlapping items while those upstream are being exploded, the result may still look ugly but it at least will be consistent with the design

---------------- M A I N  L O O P  S T A R T -----------------


	for idx = st, fin, step do

	if explode or crop then -- makes sure that the loop runs only as many times as there're targeted overlapping item clusters, rather than selected items, by modifying idx through addition/subtraction of the selected items count per cluster to skip entries, in order to avoid false positives at all_itms_sel error variable because after exploding/cropping non-selected items, only selected remain and the loop continues iterating over them
	idx_expcrop = idx_offset and idx_offset > 0 and idx_expcrop and (same_track and idx_expcrop - idx_offset or idx_expcrop + idx_offset) or idx -- idx only doesn't change on the very 1st cycle // stored for the next cycle // when exploding on the same track the loop runs in reverse
	sel_itm = sel_itms_t[idx_expcrop]
		if not sel_itm then break end -- when idx_expcrop becomes 0
	idx_offset = Overlapping_Itms_Props(sel_itm, count_overlap, true) -- count_overlap false, count_sel true // count selected items in a cluster and store for the next cycle
	else
	sel_itm = sel_itms_t[idx]
	end

	undo = undo and undo or '' -- to avoid accrual of undo point string during multiple loop cycles


	----- Get selected item props

	local get_item_props = r.GetMediaItemInfo_Value
	local start = sel_itm and get_item_props(sel_itm, 'D_POSITION') -- sel_itm can be nil if 'implode' is true and no item under mouse, here and below
	local length = sel_itm and get_item_props(sel_itm, 'D_LENGTH')
	local tr = sel_itm and r.GetMediaItemTrack(sel_itm)

	local itm_chunks_t = {} -- won't be used by 'implode' and 'crop' routines
	local err
	local overlap_cnt = 0
	local sel_cnt = 0
	local I_LASTY_cnt = 0
	local is_build_6_54_onward = tonumber(r.GetAppVersion():match('(.+)/')) >= 6.54
	local is_oversized_itm_chunk

		if not implode then -- for imploding the data of this entire block with error messages is useless

		----- Trigger selected item back and forth to create consistent IIDs sequence; covers cases when IIDs are identical in all overlapping items and other cases, a key element of the design

		Toggle_Sel_Overlapping_Itm_UpDown()

		-- Find all items overlapping the selected one on the track and collect their chunks

			for i = 0, r.GetTrackNumMediaItems(tr)-1 do -- chunks aren't needed for crop routine but the loop is allowed to run to collect other data, e.g. if lanes are collapsed
			local itm = r.GetTrackMediaItem(tr, i)
			local st = get_item_props(itm, 'D_POSITION')
			local len = get_item_props(itm, 'D_LENGTH')
				if st < start+length and st+len > start then -- covers both full and partial overlap as well as the selected item itself
				local ret, chunk = GetObjChunk(itm)
					if ret == 'err_mess' and not crop then -- for cropping chunks are useless so error is allowed
					is_oversized_itm_chunk = 1
					oversized_itm_chunk_cnt = oversized_itm_chunk_cnt == 0 and oversized_itm_chunk_cnt+1 or oversized_itm_chunk_cnt -- count only once per overlapping item cluster to match count in sel_itms_t table
					else
					local chunk = not chunk:match('\nIID %d+') and chunk:gsub('IGUID .-\n', '%0IID 0\n') or chunk -- replace nil IID with 0 so the sequence can be used for table sorting
					itm_chunks_t[#itm_chunks_t+1] = chunk
					end
				overlap_cnt = overlap_cnt+1
				sel_cnt = r.IsMediaItemSelected(itm) and sel_cnt+1 or sel_cnt
					if not is_build_6_54 and get_item_props(itm, 'I_LASTY') <= 15 then -- true when overlapping item lanes are collapsed or only 1 lane is set in Preferences -> Appearance in builds prior to 6.54
					I_LASTY_cnt = I_LASTY_cnt+1
					end
				end
			end


		itms_overlap = overlap_cnt > 1 -- > 1 to ignore the sel_itm itself

		all_itms_sel = itms_overlap and sel_cnt == overlap_cnt -- must stay global, used outside of the main loop

		are_lanes_collapsed = not is_build_6_54_onward and itms_overlap and overlap_cnt == I_LASTY_cnt  -- relevant when overlapping item lanes are collapsed at certain TCP height or only 1 lane is set in Preferences -> Appearance in builds prior to 6.54 // will be true for lone non-overlapping items but these will produce error anyway

			-- Generate oversized track chunk error message for next/prev and top/bottom/up/down routines

			if (nxt or prev) and are_lanes_collapsed or ((top or bottom) and not all_itms_sel or up or down) then -- for next/prev track chunk is only used when lanes are collapsed (are_lanes_collapsed ignores non-overlapping items) all selected are allowed because with collapsed lanes only the outermost is supposed to end up being selected, else ignore non-overlapping and all selected when top/bottom, for up/down all selected isn't a problem // other potentially error prone states (non-overlapping items, all selected) are prioritized over oversized track chunk
			is_oversized_tr_chunk = GetObjChunk(tr) == "err_mess"
				if is_oversized_tr_chunk then
				oversized_tr_chunk_cnt = tr ~= oversized_chunk_tr_init and oversized_tr_chunk_cnt+1 or oversized_tr_chunk_cnt -- only count unique tracks, ignoring overlapping items clusters on a track already counted
				oversized_chunk_tr_init = tr
				oversized_tr_chunk_mess = Space(8)..'the action couldn\'t \n\n'..Space(15)..'be executed \n\n   due to oversized track chunk  \n\n ' or oversized_tr_chunk_mess
				oversized_tr_chunk_mess = oversized_tr_chunk_cnt == unique_tr_cnt and oversized_tr_chunk_mess..Space(7)..'on all tracks involved' or oversized_tr_chunk_mess..' on some of the involved tracks'
				is_oversized_itm_chunk = nil -- if oversized track chunk, ignore oversized item chunk boolean if it's true, because in this case item chunk inaccessibility is immaterial
				nxt, prev = nil -- clear vars so the routines which require track chunk can't run downstream // top/bottom must run to collect error message on which oversized track chunk error message display depends // NOTE re next/prev: When lanes are collapsed only the outermost item can be selected as per the design, however when oversized track chunk error occurs, after change in selection the outermost item doesn't change because track chunk can't be safely set, thus the outermost item remains the same and as long as track chunk error persists all subsequent runs of the action end up inside a vicious circle where the same outermost item is re-selected over and over and the routine shuttles between re-selecting the same outermost item and immediately selecting the next one.
				end
			end

		oversized_chunk = is_oversized_itm_chunk or is_oversized_tr_chunk -- used in top/bottom/up/down routine

			-- Generate oversized item chunk or non-overlapping items error message

			if is_oversized_itm_chunk and itms_overlap then -- itms_overlap limits chunk error message to overlapping items only

			nxt, prev, explode = nil -- clear vars so the routines which require the itm_chunks_t table can't run downstream // top/bottom/up/down are handled in the routine itself to allow error message of items already being on at the top/bottom // true when no SWS extension is installed to handle oversized chunk // re-initialized at the end of the main loop
			oversized_itm_chunk_mess = oversized_itm_chunk_cnt == #sel_itms_t and Space(11)..'in all selected \n\n'..Space(6)..'overlapping item clusters \n\n there\'s an oversized item chunk \n\n'..Space(3)..'which couldn\'t be processed' or oversized_itm_chunk_cnt > 0 and 'there\'s an oversized item chunk \n\n'..Space(4)..'which couldn\'t be processed \n\n'..Space(8)..'in some of the selected \n\n'..Space(6)..'overlapping item clusters' -- for 'implode' the message is generated inside the routine itself
				if oversized_itm_chunk_cnt == #sel_itms_t then break end

			else

				if not itms_overlap then -- no items overlapping the one currently selected from sel_itms_t
				oversized_itm_chunk_cnt = 0 -- reset when oversized chunk and non-overlapped item happen in the same cycle to prevent double count for the same item and thus empty undo string
				no_overlap_err_cnt = no_overlap_err_cnt+1
				local mess = 'overlapping items'
				no_overlap_err_mess = no_overlap_err_cnt == #sel_itms_t and 'no '..mess or no_overlap_err_cnt > 0 and 'there\'re non-'..mess -- in this order because > 0 satisfies both conditions // THE 1st OPTION IS OBSOLETE AFTER USING Are_Itms_Overlapping_Selected_Collapsed() function at the start of the main routine
					if no_overlap_err_cnt == #sel_itms_t then break end

				end

			end -- is_oversized_itm_chunk cond end

		end -- 'implode' cond end


	local itm_chunks_orig = table.concat(itm_chunks_t):gsub('IID 0\n','') -- to be replaced in the track chunk, removing 0 with which nil IID was replaced in the loop above, so this string is identical to overlapping items subchunk within track chunk


		if are_lanes_collapsed then -- deselect all items except the outermost (visible) which is the last in the orig subchunk (items in collapsed lanes can be selected at once with marquee selection) and hence in the chunk table; in particular helps to prevent error message of item already being at the top/bottom but overall for consistency // placed AFTER concatenation of itm_chunks_orig above to avoid altering the orig subchunk
			for k, chunk in ipairs(itm_chunks_t) do
			itm_chunks_t[k] = k ~= #itm_chunks_t and chunk:gsub('SEL 1', 'SEL 0') or chunk:gsub('SEL 0', 'SEL 1')
			end
		-- Generate all items in cluster being selected error message
		elseif itms_overlap and not up and not down then -- generate error mess // when collapsed the selection is reduced to the outermost (visible) item above so the error mess isn't relevant, likewise when there're no overlapping items // for 'move up/down' selection of all items in a cluster isn't a problem
		all_sel_err_cnt = all_itms_sel and all_sel_err_cnt+1 or all_sel_err_cnt -- to condition 'no undo' when all items are selected in all targeted clusters for 'move top/bottom', 'select next/prev', 'explode', 'crop' routines
		all_sel_err_mess = all_sel_err_cnt > 0 and '  in some clusters \n\n    all items happen \n\n     to be selected'
		oversized_itm_chunk_mess = (not is_oversized_itm_chunk or not all_itms_sel) and oversized_itm_chunk_mess or is_oversized_itm_chunk and all_itms_sel and nil -- if in the came cycle all items are selected and chunk is oversized, prioritize the all selected error message discarding chunk error but keeping it if it was generated in previous cycles
		end


	----------------------------------------------------------------------------------------------------------
	----- A C T I O N S: Select next/previous item -----------------------------------------------------------
	----------------------------------------------------------------------------------------------------------

	function Select_Next_Prev_Overlap_Itm(t, nxt, prev, are_lanes_collapsed, all_itms_sel, tr, is_oversized_tr_chunk)

	local t_orig = {table.unpack(t)} -- store orig table for dealing with collapsed item lanes, because it might be changed in the routine below

		if are_lanes_collapsed then -- to complement routine at the beginning of the loop by deselecting all in Arrange except the outermost item in the cluster, because at the beginning of the loop selection of items in collapsed lanes is only changed in the stored chunks inside itm_chunks_t, and since on oversized track chunk error track chunk isn't set at the end of this function, other items end up remaining selected
			for k, chunk in ipairs(t) do
				if k ~= #t then -- not the outermost item
				local take_GUID = chunk:match('\nGUID (.-)\n')
				local itm = r.GetMediaItemTake_Item(r.GetMediaItemTakeByGUID(0, take_GUID))
				r.SetMediaItemSelected(itm, false) -- selected false // deselect current
				r.UpdateItemInProject(itm)
				end
			end
		end

	table.sort(t, function(a,b) return a:match('IID (%d+)') < b:match('IID (%d+)') end) --- crucial

		local function thin_out_table(t, nxt, prev) -- remove entries of selected items which follow the 1st found selected item in a row, either from the start or from the end, to simplify dealing with them by skipping and changing selection of only the 1st one found, because selection of the rest in a row won't change anyway
			for k, chunk in ipairs(t) do
				if chunk:match('SEL 1') and
				( nxt and k+1 <= #t and t[k+1]:match('SEL 1')
				or prev and k-1 >= 1 and t[k-1]:match('SEL 1') ) then
				local rem = nxt and table.remove(t, k+1) or prev and table.remove(t, k-1)
				thin_out_table(t, nxt, prev) -- go recursive
				end
			end
		end

		thin_out_table(t, nxt, prev)

		if #t == 1 then return end -- abort if all items are selected in which case only 1 table entry will remain after running the above function

	local st, fin, step = table.unpack(nxt and {1, #t, 1} or prev and {#t, 1, -1}) -- reverse direction of iteration depending on the direction
		for i = st, fin, step do
		local chunk = t[i]
			if chunk:match('SEL 1')	then
			local take_GUID = chunk:match('\nGUID (.-)\n')
			local sel_idx = nxt and (i+1 <= #t and i+1 or 1) or prev and (i-1 >= 1 and i-1 or #t) -- wrap around if i+1/i-1 is outside of the table range
			local take_GUID_new = t[sel_idx]:match('\nGUID (.-)\n')
			-- Select next/prev item
			local sel_itm = r.GetMediaItemTake_Item(r.GetMediaItemTakeByGUID(0, take_GUID))
			r.SetMediaItemSelected(sel_itm, false) -- selected false // deselect current
			r.UpdateItemInProject(sel_itm)
			local itm_new = r.GetMediaItemTake_Item(r.GetMediaItemTakeByGUID(0, take_GUID_new))
			r.SetMediaItemSelected(itm_new, true) -- selected true
			r.UpdateItemInProject(itm_new) -- to make change in selection instantly visible
			end
		end

	-- Handle collapsed lanes --------------------------------------------------------

		if are_lanes_collapsed and not is_oversized_tr_chunk then -- make selected item the outermost (visible), by placing its chunk last within the track chunk

		local IID_outermost = t_orig[#t_orig]:match('SEL 1') and t_orig[#t_orig]:match('IID (%d+)') -- if the outermost item was originally selected, get its IID // outermost item chunk sits in the end of overlapping items subchunk within tha track chunk

			if IID_outermost then -- if the outremost item was originally selected

			-- Get IID of the next/prev selected to find its chunk slot in the table and place last in the overlapping items subchunk to make the outermost

			local IID_new = nxt and (tonumber(IID_outermost)+1 > #t_orig-1 and 0 or tonumber(IID_outermost)+1) -- if beyond range wrap around to the 1st IID; -1 to convert to 0 based count of IIDs
			or prev and (tonumber(IID_outermost)-1 < 0 and #t_orig-1 or tonumber(IID_outermost)-1) -- if beyond range, wrap around to the last IID; -1 to convert to 0 based count of IIDs

			local outermost_idx_new
				for k, chunk in ipairs(t_orig) do -- replicate updated overlapping items subchunk by updating selection data
				local GUID = chunk:match('\nGUID (.-)\n')
				local item = r.GetMediaItemTake_Item(r.GetMediaItemTakeByGUID(0, GUID))
				t_orig[k] = r.IsMediaItemSelected(item) and chunk:gsub('SEL (%d+)','SEL 1') or chunk:gsub('SEL (%d+)','SEL 0')
				outermost_idx_new = chunk:match('IID '..IID_new) and k or outermost_idx_new -- get index of the item next/prev to the outermost to replace the former
				end

			local itm_chunks_orig = table.concat(t_orig):gsub('IID 0\n','') -- concatenate updated items subchunk to be overwritten in the track chunk, removing 0 with which nil IID was replaced in then loop collecting overlapping items
			table.insert(t_orig, #t_orig+1, t_orig[outermost_idx_new]) -- move to the last slot in the overlapping items subchunk making it the outermost
			table.remove(t_orig, outermost_idx_new) -- remove from the old slot

			local itm_chunks_upd = table.concat(t_orig):gsub('%%', '%%%%') -- escaping % sign just in case
			local ret, tr_chunk = GetObjChunk(tr) -- get track chunk
			local tr_chunk_upd = tr_chunk:gsub(Esc(itm_chunks_orig), itm_chunks_upd):gsub('%%%%', '%%') -- restoring escaped % signs
			SetObjChunk(tr, tr_chunk_upd)
			end
		end

	end

		if nxt or prev then
		Select_Next_Prev_Overlap_Itm(itm_chunks_t, nxt, prev, are_lanes_collapsed, all_itms_sel, tr, is_oversized_tr_chunk)
		undo = 'Select '..(nxt or prev)..' overlapping item(s)'
		end

	----------------------------------------------------------------------------------------------------------
	----- A C T I O N S: Select next/previous item E N D -----------------------------------------------------
	----------------------------------------------------------------------------------------------------------


	table.sort(itm_chunks_t, function(a,b) return a:match('IID (%d+)') < b:match('IID (%d+)') end) -- within track chunk chunks of overlapping items aren't listed in ascending order of their IIDs as they are displayed in lanes, but according to their global relative position expressed as IP_ITEMNUMBER parameter value of GetMediaItemInfo_Value() function and returned as the iterator value in items loop, hence has to be sorted in ascending order of the IIDs to mimic display in lanes and simplify calculation of the distance between items // MUST COME AFTER NEXT/PREV routine


	-----------------------------------------------------------------------------------------------------------
	----- A C T I O N S: Implode selected items as overlapping on the track of the 1st one --------------------
	-------------------  Explode explode to the same track (in place) / Explode across tracks -----------------
	-------------------  Crop to selected item ----------------------------------------------------------------

	function Get_Non_Selected_Itm(itm_chunk) -- for the explode routine
	local is_non_sel = itm_chunk:match('\nSEL 0')
		if is_non_sel then
		local take_GUID = itm_chunk:match('\nGUID (.-)\n')
		return r.GetMediaItemTake_Item(r.GetMediaItemTakeByGUID(0, take_GUID))
		end
	end


	function Get_Outermost_Overlapping_Item(are_lanes_collapsed, tr, start, length) -- for 'explode' and 'crop' when item lanes are collapsed
	local outermost_itm
	--local overlap_itm_cnt,  = 0
		if are_lanes_collapsed then	-- get the outermost item to be able to crop everything to it if it happens to be selected
			for i = 0, r.GetTrackNumMediaItems(tr)-1 do -- tr is sel_itm track
			local tr_itm = r.GetTrackMediaItem(tr, i)
			local st = get_item_props(tr_itm, 'D_POSITION')
			local len = get_item_props(tr_itm, 'D_LENGTH')
			local overlap = st < start+length and st+len > start -- start & length are sel_itm properties
				if overlap then outermost_itm = tr_itm end
			end
		end
	return outermost_itm, outermost_itm and r.IsMediaItemSelected(outermost_itm)--, overlap_itm_cnt > 1 and overlap_itm_cnt-1 or 0 -- accounting for the item against which evaluation is being done to exclude it
	end


	function Explode_Tracks_Cnt(sel_itms_t, idx_expcrop, sel_itm, itm_chunks_t, explode_trk_cnt_total, outermost_itm, is_outermost_sel) -- for 'explode across' routine to be able to reuse new tracks already created for previous cluster on the same track // only explode_trk_cnt_total argument is really necessary as it's constantly updated, the rest are accessible to the function from outside due to being identically named // the two last arguments outermost_itm & is_outermost_sel are for collapsed lanes scenario
	local explode_itm_cnt = 0 -- count number if tracks to be created for unselected items which are exploded
		if outermost_itm and is_outermost_sel then explode_itm_cnt = #itm_chunks_t-1 -- if item lanes are collapsed count all items in itm_chunks_t table, containing all overlaping items in a cluster, regardless of their selection bar the outermost if it's selected // #itm_chunks_t equals number of overlaping items in a cluster to which the item belongs // -1 to exclude the outermost item itself
		else
			for _, itm_chunk in ipairs(itm_chunks_t) do -- count non-selected items
			explode_itm_cnt = itm_chunk:match('SEL 0') and explode_itm_cnt+1 or explode_itm_cnt
			end
		end

		if sel_itms_t[idx_expcrop-1] -- previous overlapping items cluster
		and r.GetMediaItemTrack(sel_itm) == r.GetMediaItemTrack(sel_itms_t[idx_expcrop-1]) then -- previously exploded cluster was on the same track
		local explode_trk_cnt = explode_itm_cnt > explode_trk_cnt_total and explode_itm_cnt-explode_trk_cnt_total or 0
		return explode_trk_cnt, explode_trk_cnt_total -- explode_trk_cnt_total is returned as is and only incremented outside, it's only fed to the function to help calculate explode_trk_cnt and be reset for each new track via the next line
		else return explode_itm_cnt, 0 -- if no items were previously exploded on the same track
		end

	end


	function Explode_Crop_Helper(sel_itms_t, itm) -- itm arg is for 'crop' routine to find if item was originally selected and included in sel_itms_t, without it restores original item selection in both 'explode' and 'crop' routines
		for _, sel_itm in ipairs(sel_itms_t) do
			if itm and itm == sel_itm then return true -- returning non-selected
			elseif not itm and r.ValidatePtr(sel_itm, 'MediaItem*') then r.SetMediaItemSelected(sel_itm, true) -- selected true // validate in case collapsed lanes in which case all selected items will be deleted bar the outermost
			end
		end
	end


	function Implode()

	r.PreventUIRefresh(1)

	-- Get anchor item (the one selected items will be imploded to) -------

	local x, y = r.GetMousePosition() -- for imploding
	local anch_itm = r.GetItemFromPoint(x, y, false) -- allow_locked false

	local tr, is_anch_itm_overlapped, anch_itm_t

		local function Build_IID_Seq(anch_itm)
		local is_sel = r.IsMediaItemSelected(anch_itm) -- store selection state
		r.SetMediaItemSelected(anch_itm, true) -- selected true
		Toggle_Sel_Overlapping_Itm_UpDown()
		local deselect = not is_sel and r.SetMediaItemSelected(anch_itm, false) -- selected false // if wasn't originally selected
		end

		if anch_itm then
		Build_IID_Seq(anch_itm) -- if anchor item is part of overlapping items cluster in which item IIDs aren't sequential or are identical, if not the function will do nothing (here and below)
		tr = r.GetMediaItemTrack(anch_itm)
		else -- if no item under mouse, find 1st item on 1st selected track under edit cursor (anchor item)
		tr = r.GetSelectedTrack(0,0)
		local cur_pos = r.GetCursorPosition()
		anch_itm_t = implode_Get_Anchor_Itm_Data(tr, cur_pos) -- store all items overlapping the anchor item (if any), including itself
		local bot_itm
			if #anch_itm_t == 1 then -- lone anchor item with no overlapping items
			anch_itm = anch_itm_t[1]
			else -- table with more than one item, i.e. the anchor item is already a part of an overlapping items cluster
			Build_IID_Seq(anch_itm_t[1]) -- see above // any item from the overlapping items cluster will do for toggling
			is_anch_itm_overlapped = true -- condition for re-ordering routine below
			local max_IID_sel, max_IID = -1, -1 -- -1 to account for the topmost overlapping item with IID 0
				for _, itm in ipairs(anch_itm_t) do
				local ret, itm_chunk = GetObjChunk(itm)
					if ret == 'err_mess' then return 'executed' end
				local IID = tonumber(itm_chunk:match('\nIID (%d+)')) or 0 -- 0 in case there's no IID since the item is at the topmost lane
				anch_itm = r.IsMediaItemSelected(itm) and IID > max_IID_sel and itm or anch_itm -- find selected item with the highest IID
				max_IID_sel = anch_itm and IID > max_IID_sel and IID or max_IID_sel -- update IID to continue comparison
				bot_itm = IID > max_IID and itm or bot_itm -- find any item with the highest IID
				max_IID = IID > max_IID and IID or max_IID -- update IID to continue comparison
				end
			end
		anch_itm = anch_itm or bot_itm -- if no selected item, anchor item is the bottommost
		end
	local start = get_item_props(anch_itm, 'D_POSITION')


	local itm_t = {}
		for i = 0, r.CountSelectedMediaItems(0)-1 do -- collect the rest of the items (which are selected) bar the anchor item in case it is
		local itm = r.GetSelectedMediaItem(0,i)
		local st = get_item_props(itm, 'D_LENGTH')
		local itm_tr = r.GetMediaItemTrack(itm)
		local found
			for _, overlap_itm in ipairs(anch_itm_t) do
				if itm == overlap_itm then found = true end -- exclude all selected items which already overlap the anchor item if it's a part of an overlapping items cluster, and itself as well, so they're unaffected by the re-ordering routine further below
			end
			if not found --and (st ~= start or itm_tr ~= tr)
			then -- to only store and move if not already overlapping the anchor item on the same track
			itm_t[#itm_t+1] = itm
			end
		end


		for i = #anch_itm_t,1,-1 do -- thin out table to only keep selected items overlapping the anchor item (if any) including the anchor item itself in order to restore their selection after re-ordering routine
		local itm = anch_itm_t[i]
			if not r.IsMediaItemSelected(itm) then
			table.remove(anch_itm_t, i)
			end
		end

		-- Implode items // naturally results in order of imploded items in lanes (IID) not reflecting their global order, hence re-ordering loop below
		for _, itm in ipairs(itm_t) do
		r.MoveMediaItemToTrack(itm, tr)
		r.SetMediaItemInfo_Value(itm, 'D_POSITION', start) -- align with the anchor item (anch_itm)
		end

	r.UpdateArrange()

	table.insert(itm_t, 1, anch_itm) -- insert the anchor item as the 1st entry

	Toggle_Sel_Overlapping_Itm_UpDown() -- create consistent IID sequence to manage the items further

	-- Re-order imploded items in lanes according to their initial table order and thus global order // may not work as expected when there're mutually fully overlapping items among the selected ones, because in this case their global order isn't obvious
	local anch_IID
		for k, itm in ipairs(itm_t) do
		r.SelectAllMediaItems(0, false) -- deselect all
		local ret, itm_chunk = GetObjChunk(itm)
			if ret == 'err_mess' then return 'completed' end
			if itm == anch_itm then -- or k == 1
			anch_IID = tonumber(itm_chunk:match('\nIID (%d+)')) or 0 -- 0 in case there's no IID since the item is at the top which is the result of the usage of the above function to generate sequence, meaning 1st
				if anch_IID ~= 0 and not is_anch_itm_overlapped then -- place the anchor item at the top lane if it was a lone item, i.e. wasn't initially part of an overlapping items cluster
				r.SetMediaItemSelected(anch_itm, true) -- selected true
					for i = 1, anch_IID do
					ACT(40068) -- Item lanes: Move item up one lane (when showing overlapping items in lanes)
					end
				anch_IID = 0
				end
			else
			local itm_IID = tonumber(itm_chunk:match('\nIID (%d+)')) or 0 -- same as above
			local diff = anch_IID - itm_IID
			local comm_ID = diff < 0 and 40068 -- Item lanes: Move item up one lane (when showing overlapping items in lanes)
			or diff > 0 and 40107 -- Item lanes: Move item down one lane (when showing overlapping items in lanes)
			local offset = diff < 0 and -1 or 0 -- when moving imploded items up to place right beneath the anchor item or beneath other items placed there previously instead of replacing them hence diff must be less by 1; when moving imploded items down the anchor item and any imploded items already placed underneath it are replaced and shifted up one lane hence offset is 0
			-- when diff is 0 the next loop simply won't start so comm_ID being nil isn't a problem
			r.SetMediaItemSelected(itm, true) -- selected true
				for i = 1, math.abs(diff)+offset do
				ACT(comm_ID)
				end
			anch_IID = diff >= 0 and anch_IID or anch_IID+1 -- when imploded items are moved down to be placed undermeath the anchor item or beneath other items placed there previously they replace the latter and assume their IID so the original ahcnor item IID is kept; when imploded items are moved up they're placed underneath the anchor item or beneath other items placed there previously hence the reference IID for other items to be moved next must be increased by 1
			end
		end

	-- Restore original item selection

	r.SelectAllMediaItems(0, false) -- deselect all
		table.remove(itm_t,1) -- remove anchor item, it it was selected its selection will be restored in anch_itm_t loop
		for _, itm in ipairs(itm_t) do -- reselect originally selected items meant to be imploded
		r.SetMediaItemSelected(itm, true) -- selected true
		end
		for _, itm in ipairs(anch_itm_t) do -- reselect the anchor item and any items which already overlapped it if they were selected
		r.SetMediaItemSelected(itm, true) -- selected true
		end

	r.PreventUIRefresh(-1)

	end

		if implode or explode or crop then
		undo = implode and 'Implode selected items as overlapping items in lanes' or explode and 'Explode overlapping items ' or crop and 'Crop overlapping items to selected item(s)'
			if implode then
				if r.GetToggleCommandStateEx(0,41117) == 1 -- Options: Toggle trim content behind media items when editing
				then Error_Tooltip('\n\n     The option to trim content  \n\n       behind media items is ON.  \n\n   Which will result in deletion  \n\n of some of the overlapping items.  \n\n', 1)
				r.Undo_EndBlock('', -1) -- blank to prevent generic 'ReaScript: Run' message in the status bar
				return r.defer(function() do return end end)
				else
				local mess = Implode() -- doesn't use sel_itms_t and itm_chunks_t
					if mess then
					Error_Tooltip('\n\n     due to oversized item chunk \n\n the action couldn\'t be '..mess..' \n\n', 1)
					Err_mess('data in one of the items')
					return r.defer(function() do return end end) end
				end
			break -- implode doesn't support multiple anchor items hence exiting the main selected items loop
			elseif explode then
			-- get the outermost item to be able to explode all items it if it happens to be selected in collapsed state
			local outermost_itm, is_outermost_sel = Get_Outermost_Overlapping_Item(are_lanes_collapsed, tr, start, length)
				if scr_name:match('same') then -- on the same track
				undo = undo..'on the same track (in place)'
				local prev_end = not prev_end and start+length or prev_end -- the very 1st exploded item or all the rest, prev_end var is updated below
					for _, itm_chunk in ipairs(itm_chunks_t) do -- MUST USE CHUNKS TABLE TO EXPLODE IN THE ORDER IF THE IIDs (by which the table has been sorted before the start of this routine above), i.e. vertical order of the overlapping items, without chunks there's no way to get the IIDs
					local itm = Get_Non_Selected_Itm(itm_chunk)
					local explode = (outermost_itm and is_outermost_sel and itm and itm ~= outermost_itm or not outermost_itm and itm) and r.SetMediaItemInfo_Value(itm, 'D_POSITION', prev_end) -- set to the end of the prev item
					prev_end = itm and prev_end + get_item_props(itm, 'D_LENGTH') or prev_end -- update var
					end
				elseif scr_name:match('across') then -- across tracks // leaving the 1st of selected items on the current track
				local duplicates = scr_name:match('duplicates')
				undo = duplicates and undo..'across track duplicates' or undo..'across new tracks'
				explode_trk_cnt, explode_trk_cnt_total = Explode_Tracks_Cnt(sel_itms_t, idx_expcrop, sel_itm, itm_chunks_t, explode_trk_cnt_total, outermost_itm, is_outermost_sel) -- explode_trk_cnt_total is global and is fed back to the function on each cycle of the main loop
				explode_trk_cnt_total = explode_trk_cnt_total + explode_trk_cnt
				r.PreventUIRefresh(1)
				r.SetOnlyTrackSelected(tr)
				local tr_idx = r.CSurf_TrackToID(tr, false) -- mcpView false // 1 based index
				local add = 0 -- to avoid incrementing tr_idx value directly keeping the original for calculations in 'explode' loop further below
				explode_trk_cnt = outermost_itm and not is_outermost_sel and 0 or explode_trk_cnt -- prevent creation of tracks if the outermost item isn't selected in collapsed lanes scenario
					for i = 1, explode_trk_cnt do -- insert tracks
						if duplicates then
						ACT(40062) -- Track: Duplicate tracks
						ACT(40421) -- Item: Select all items in track
						ACT(40006) -- Item: Remove items
						else -- new tracks
						add = add+1
						r.InsertTrackAtIndex(tr_idx-1+add, true) -- wantDefaults true // i-1 to match 0 based count
						end
					end
				Explode_Crop_Helper(sel_itms_t) -- restore original item selection disturbed by the use of 'Item: Select all items in track' action above
					for k, itm_chunk in ipairs(itm_chunks_t) do -- explode
					local itm = Get_Non_Selected_Itm(itm_chunk)
					tr_idx = itm and tr_idx+1 or tr_idx -- accounting for table key of chunk of selected item which isn't supposed to move
					local track = r.CSurf_TrackFromID(tr_idx, false) -- mcpView false // 1 based index
					local explode = (outermost_itm and is_outermost_sel and itm and itm ~= outermost_itm or not outermost_itm and itm) and r.MoveMediaItemToTrack(itm, track) -- 'track' may be nil because the table will contain 1 entry more than the items to be exploded due to presence of the chunk of selected item which isn't supposed to move
					end
				r.PreventUIRefresh(1)
				end
			elseif crop then -- only the first of selected items is kept
			-- Get the outermost item to be able to crop everything to it if it happens to be selected in collapsed state
			local outermost_itm, is_outermost_sel = Get_Outermost_Overlapping_Item(are_lanes_collapsed, tr, start, length)
				for i = r.GetTrackNumMediaItems(tr)-1,0,-1 do -- in reverse since items are being deleted
				r.SelectAllMediaItems(0, false) -- selected false // deselect all
				local itm = r.GetTrackMediaItem(tr, i)
				local st = get_item_props(itm, 'D_POSITION')
				local len = get_item_props(itm, 'D_LENGTH')
				local overlap = st < start+length and st+len > start -- start & length are sel_itm properties
					if overlap and (outermost_itm and is_outermost_sel and itm ~= outermost_itm or not outermost_itm and not Explode_Crop_Helper(sel_itms_t, itm)) then -- covers both full and partial overlap excluding selected items stored in sel_itms_t if uncollapsed // when lanes are uncollapsed only removes originally unselected items which allows leaving any number of selected ones; when collapsed and the outermost is selected, delete all the rest regardless of their selection, if the outermost isn't selected delete nothing
					r.SetMediaItemSelected(itm, true) -- selected true
					ACT(40006) -- Item: Remove items
					end
				end
			Explode_Crop_Helper(sel_itms_t) -- restore original item selection disturbed by deselection of all above
			end
		end

	-----------------------------------------------------------------------------------------------------------
	----- A C T I O N S: Implode selected items as overlapping on the track of the 1st one --------------------
	-------------------  Explode explode to the same track (in place) / Explode across tracks -----------------
	-------- E N D ----  Crop to selected item ----------------------------------------------------------------



	-----------------------------------------------------------------------------------------------------------------------------
	----- A C T I O N S: Move selected up/down one lane (cycle) // moving by swapping is already implemented with native actions:
	------------------ 			Item lanes: Move item down one lane (when showing overlapping items in lanes)
	------------------			Item lanes: Move item up one lane (when showing overlapping items in lanes)
	------------------   Move selected to top/bottom (cycle/swap) ---------------------------------------------------------------

	local sel_itm_IID = table.concat(itm_chunks_t):match(bottom and '.+SEL 1\nIGUID .-\n(IID %d+)' or 'SEL 1\nIGUID .-\n(IID %d+)') -- if 'bottom', get IID of the last selected, otherwise of the 1st // needed for calculation of distance between the sel item and the top/bottom item if the action is move to top/bottom

		if itms_overlap and ((top or bottom) and (are_lanes_collapsed or not all_itms_sel) or up or down) then -- allowing 'move to top/bottom' when not collapsed only if not all are selected, allowing 'move up/down' always as long as there's overlap

		function swap_IIDs2(itm_chunks_t, up, down, top, bottom)
		local t = {} -- save to a new table because in the current table by the time the loop reaches the last slot, IID in the previous or next slot will have been changed and its original IID needed for replacing one in the last slot won't be available
		local donor_slot
			for k, itm_chunk in ipairs(itm_chunks_t) do
				if up or top then -- borrows IID from previous slot
				donor_slot = k-1 < 1 and #itm_chunks_t or k-1 -- wrap around if donor slot is out of range
				elseif down or bottom then -- borrows IID from next slot
				donor_slot = k+1 > #itm_chunks_t and 1 or k+1 -- wrap around if donor slot is out of range
				end
			local curr_itm_IID = itm_chunk:match('IID %d+')
			local prev_itm_IID = itm_chunks_t[donor_slot]:match('IID %d+')
			t[k] = itm_chunk:gsub(curr_itm_IID, prev_itm_IID)
			end
		return table.concat(t), t
		end

		local itm_chunks_upd = ''

			if (top or bottom) and not is_oversized_itm_chunk then
			local dist = 0
			local sel_idx = 0
				for k, itm_chunk in ipairs(itm_chunks_t) do -- calculate distance between selected item and the top/bottom ones
					if itm_chunk:match(sel_itm_IID) then
					dist = top and k-1 or bottom and #itm_chunks_t - k
					sel_idx = k
					break end
				end
				if scr_name:match('cycle') then
					-- reorder items by swapping their IIDs
					for i = 1, dist do -- repeat IIDs swap as many times as the distance between the selected and top/bottom items
					itm_chunks_upd, itm_chunks_t = swap_IIDs2(itm_chunks_t, up, down, top, bottom) -- returns updated table after each cycle of swapping to be fed back into the function for the next cycle // itm_chunks_upd is a resulting final string of reordered chunks // if dist is 0, because sel_item is already at the top/bottom, the loop doesn't start
					end
				elseif dist ~= 0 then -- swap // item isn't already at the top/bottom; possible to determine thanks to sorting the table above
				local IID_top = itm_chunks_t[1]:match('IID %d+')
				local IID_bottom = itm_chunks_t[#itm_chunks_t]:match('IID %d+')
				local IID_sel = itm_chunks_t[sel_idx]:match('IID %d+')
					if top then
					itm_chunks_t[1] = itm_chunks_t[1]:gsub('IID %d+', IID_sel)
					itm_chunks_t[sel_idx] = itm_chunks_t[sel_idx]:gsub('IID %d+', IID_top)
					else -- bottom
					itm_chunks_t[#itm_chunks_t] = itm_chunks_t[#itm_chunks_t]:gsub('IID %d+', IID_sel)
					itm_chunks_t[sel_idx] = itm_chunks_t[sel_idx]:gsub('IID %d+', IID_bottom)
					end
				itm_chunks_upd = table.concat(itm_chunks_t)
				end
			elseif (up or down) and not is_oversized_itm_chunk then -- cycle
			itm_chunks_upd, itm_chunks_t = swap_IIDs2(itm_chunks_t, up, down, top, bottom) -- single cycle swap
			end


			-- Concatenate error message of items already being at the top/bottom

			if (top or bottom) and not is_oversized_itm_chunk then -- for 'move up/down' action all items can be selected // when chunk is oversized and itm_chunks_t table contains flawed data it's impossible to determine whether an item is already at the top/bottom, so the top/bottom error message is discarded
			top_bott_mess_tmp = #itm_chunks_upd == 0 and (top or bottom)
			top_bott_err_cnt = top_bott_mess_tmp and top_bott_err_cnt+1 or top_bott_err_cnt -- to condition error message verbiage // top_bott_mess_tmp can be substituted with no_change
			top_bott_mess = top_bott_mess_tmp or top_bott_mess -- to condition blank undo string outside of the loop hence global // keeping top_bott_mess_tmp valid until the end of the loop if it's been valid at least once
				if top_bott_mess_tmp and is_oversized_tr_chunk then oversized_tr_chunk_cnt = oversized_tr_chunk_cnt-1 end -- prevent accretion of counts when both error messages are true within the same cycle, so that the sum total is equal #sel_itms_t and empty undo point condition works; also creates a condition to display track error chunk message if it didn't coincide with top/bottom error message, which is given priority, by evaluation of oversized_tr_chunk_cnt var which should in this case be greater than 0
			end


			-- 1. Prepare for selection of the outermost item if lanes are collapsed

			if are_lanes_collapsed and top_bott_up_down and not oversized_chunk then -- place the chunk of item, which has replaced the originally selected one in the IID sequence, at the end of the chunk to make it the outermost (visible) // placed here to allow error message above when item is already at the top/bottom to go through
				for k, itm_chunk in ipairs(itm_chunks_t) do
					if itm_chunk:match(sel_itm_IID) then -- must now belong to the item which replaced the originally selected one
					itm_chunks_t[#itm_chunks_t+1] = itm_chunk -- make last
					table.remove(itm_chunks_t, k) -- remove from previosuly occupied slot
					break end
				end
			itm_chunks_upd, vis_take_GUID = table.concat(itm_chunks_t), itm_chunks_t[#itm_chunks_t]:match('\nGUID (.-)\n') -- last item take GUID to be used to find the last (outermost, visible) item to select it // item cannot be found directly by item GUID
			end


		local itm_chunks_upd = itm_chunks_upd:gsub('%%%%', '%%')

		local ret, tr_chunk = GetObjChunk(tr) -- get track chunk

		local tr_chunk_upd = tr_chunk:gsub(Esc(itm_chunks_orig), itm_chunks_upd):gsub('%%%%', '%%') -- restore escaped % in the final chunk

		local set = not top_bott_mess_tmp and not oversized_chunk and SetObjChunk(tr, tr_chunk_upd) -- prevent chunk setting when there's error message, i.e. item is already at top/bottom or oversized chunk, otherwise if top/bottom error the entire overlapping items cluster will be deleted due to itm_chunks_upd being an empty string and if oversized chunk the same original track chunk will be set which is unnecessary // top_bott_mess_tmp is updated each loop cycle

			-- 2. Select the outermost item if lanes are collapsed

			if are_lanes_collapsed and not oversized_chunk then -- select the outermost (visible) item // placed after getting track chunk to avoid modifying originally retrieved data by change in selection which will cause failure in chunk replacement and after setting track chunk to not annul the selection made by such chunk setting if placing before it
				for _, chunk in ipairs(itm_chunks_t) do -- deselect all items in the same cluster as the stored item
				local GUID = chunk:match('\nGUID (.-)\n')
				local item = r.GetMediaItemTake_Item(r.GetMediaItemTakeByGUID(0, GUID))
				r.SetMediaItemSelected(item, false) -- selected false
				end
			local item = r.GetMediaItemTake_Item(r.GetMediaItemTakeByGUID(0, vis_take_GUID))
			r.SetMediaItemSelected(item, true) -- select the visible (outermost) item, which is and has been made the last one in the original track chunk // selected true
			r.UpdateItemInProject(item) -- to make change in selection instantly visible
			end

			if top_bott_up_down then -- to avoid overwriting 'select next/previous' action undo string
			undo = 'Move '..(top and 'first selected' or bottom and 'last selected' or 'all')..' overlapping item'..( ( ((top or bottom) and #sel_itms_t - top_bott_err_cnt - no_overlap_err_cnt > 1) or (up or down) ) and 's ' or ' ')
			local up_down = ' one lane'
			undo = top and undo..'to top lane' or bottom and undo..'to bottom lane' or up and undo..'up'..up_down or down and undo..'down'..up_down
			end

		end -- top/bottom/up/down cond end

		if is_oversized_itm_chunk or is_oversized_tr_chunk then -- re-initialize script name vars which were reset at chunk error
		_, _, _, _, nxt, prev, explode, implode, crop = Get_Script_Name(scr_name) -- top/bottom/up/down aren't used, in track chunk erro only next/prev are relevant
		end

	end


----------------- M A I N  L O O P  E N D -----------------


	-- Concatenate 'move top/bottom' error message

	if top_bott_mess then -- outside of the loop so that the error mess is only displayed once for all relevant overlapping items clusters
	local all = top_bott_err_cnt == #sel_itms_t and string.rep(' ', 3)
	local some = top_bott_err_cnt ~= #sel_itms_t and 'some'
	top_bott_mess = (scr_name:match('top') and ' ' or scr_name:match('bottom') and '   ')..(all or some)..' selected item(s)  \n\n  are already at the '..top_bott_mess -- scr_name capt is used because when is_oversized_itm_chunk is true top and bottom vars are reset to prevent top/bottom routine
	end

	-----------------------------------------------------------------------------------------------------------------------------
	----- A C T I O N S: Move selected up/down one lane (cycle) // moving by swapping is already implemented with native actions:
	------------------ 			Item lanes: Move item down one lane (when showing overlapping items in lanes)
	------------------			Item lanes: Move item up one lane (when showing overlapping items in lanes)
	--------- E N D ---  Move selected to top/bottom (cycle/swap) ---------------------------------------------------------------


oversized_tr_chunk_mess = oversized_tr_chunk_cnt > 0 and oversized_tr_chunk_mess -- true if track chunk error didn't coincide at least once with top/bottom error which is given priority in case of
oversized_tr_chunk_cnt = not nxt and not prev and oversized_tr_chunk_cnt or 0 -- for next/prev track chunk error doesn't prevent the action completely so meaniningful undo pount is needed

	if no_overlap_err_mess or all_sel_err_mess or oversized_itm_chunk_mess or oversized_tr_chunk_mess or top_bott_mess then -- combine error messages

	local ln_break = '. \n\n '

	no_overlap_err_mess = no_overlap_err_mess and no_overlap_err_mess..ln_break or ''
	all_sel_err_mess = all_sel_err_mess and Space(8)..all_sel_err_mess:gsub(' \n\n', Space(8)..'%0'..Space(8))..ln_break or ''
	oversized_itm_chunk_mess = oversized_itm_chunk_mess and oversized_itm_chunk_mess..ln_break or ''
	oversized_tr_chunk_mess = oversized_tr_chunk_mess and oversized_tr_chunk_mess..ln_break or ''
	top_bott_mess = top_bott_mess and Space(6)..top_bott_mess:gsub(' \n\n', '%0'..Space(top and 6 or 4))..ln_break..'  ' or ''

	local mess = no_overlap_err_mess..all_sel_err_mess..oversized_itm_chunk_mess..oversized_tr_chunk_mess..top_bott_mess

	Error_Tooltip('\n\n  '..mess, 1);
	local tracks = 'data in some of the tracks'
	local sws_mess = #oversized_itm_chunk_mess > 0 and #oversized_tr_chunk_mess > 0 and 'data in some of the items and tracks' or
	#oversized_itm_chunk_mess > 0 and 'data in some of the items' or #oversized_tr_chunk_mess > 0 and (oversized_tr_chunk_cnt < unique_tr_cnt and tracks or tracks:gsub('some of the', 'all'))
	local sws = sws_mess and Err_mess(sws_mess)
		if -- supposed to work because error counts are mutually exclusive, only one type is counted at a time, or offset
		no_overlap_err_cnt + all_sel_err_cnt + oversized_itm_chunk_cnt + oversized_tr_chunk_cnt == #sel_itms_t
		or not up and not down and no_overlap_err_cnt + all_sel_err_cnt + oversized_itm_chunk_cnt + oversized_tr_chunk_cnt + top_bott_err_cnt == #sel_itms_t
		then
		undo = '' -- ends up adding 1 undo point 'Change item lane' of the native actions 'Item lanes: Move item up one lane (when showing overlapping items in lanes)' used in the function Toggle_Sel_Overlapping_Itm_UpDown()
		end
	end


r.PreventUIRefresh(-1)
r.Undo_EndBlock(undo, -1)


--[[

Some stats

* All routines use item chunks except crop; implode routine uses chunks but autonomously from the main loop data
* Top/bottom/up/down and next/prev also use track chunks

* ERROR MESSAGES PER ACTION

* 'move to top/bottom': all items selected in some clusters, there're non-overlapping items, some are already at the top/bottom, oversized item chunk, oversized track chunk;
* 'move all up/down': there're non-overlapping items, oversized item chunk;
* 'select next/previous': all items selected in some clusters, there're non-overlapping items, oversized item chunk,
* oversized track chunk (when lanes are collapsed);
* 'explode': all items selected in some clusters, there're non-overlapping items, oversized item chunk;
* 'implode': oversized item chunk (on imploding stage or re-ordering according to the global order stage),
* no item to implode to (outside of the main loop), selected and designated items are the same (outside of the main loop), selected end designated items are already overlapping (outside of the main loop);
* 'crop': all items selected in some clusters, there're non-overlapping items.

* ACTIONS PER ERROR MESSAGE

* all items selected in a cluster: 'move to top/bottom', 'select next/previous', 'explode', 'crop';
* non-overlapping items: 'move to top/bottom', 'move all up/down', 'select next/previous', 'explode', 'crop';
* already at the top/bottom: 'move to top/bottom';
* oversized item chunk: 'move to top/bottom', 'move all up/down', 'select next/previous', 'explode', 'implode';
* oversized track chunk: 'move to top/bottom', 'select next/previous' when lanes are collapsed;
* no item to implode to (outside of the main loop): 'implode';
* selected and designated items are the same (outside of the main loop): 'implode';
* selected and designated items are already overlapping (outside of the main loop): 'implode'.

]]




