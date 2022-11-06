--[[
ReaScript name: Propagate items in current region to other regions by name, color or index
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
Screenshot: https://raw.githubusercontent.com/Buy-One/screenshots/main/Propagate%20items%20in%20current%20region%20to%20other%20regions%20by%20name%2C%20color%20or%20index.gif
About:	The script is aimed at simplifying the process of arrangement
	by helping to automatically propagate new parts to other composition
	segments on the time line.  

	E.g. when you have several copies of a chorus and wish to propagate
	new parts from one of its instances to all or some other instances.		
	It's also possible to overwrite old parts with new ones.  

	Since the script works based on regions, the source and the target 
	segments of the arrangement must be encompassed at least in part
	by a region. An item is considered to be within a region if it's
	crossed by either the start or the end of a region or sits between them.

	Items are propagated relative to the region start.

	HOW TO USE

	Place the edit cursor at the start, end of the source region 
	or inside it, select items to be propagated, run the script.  

	If MOUSE_CURSOR setting is enabled in the USER SETTINGS the
	mouse cursor can be used to point at the source region provided
	the mouse cursor is located within the Arrange area (the one 
	designated for items) and the Action list is closed. For this
	to work properly the script must be run with a shortcut, rather 
	than from a menu or a toolbar.  

	If no item is selected, all items within the source region 
	will be propagated.

	If the option 'Move envelope points with items' is ON envelope 
	curves will also be propagated.

	Make sure to configure the script USER SETTINGS to suit your preferences.

	Demo: https://raw.githubusercontent.com/Buy-One/screenshots/main/Propagate%20items%20in%20current%20region%20to%20other%20regions%20by%20name%2C%20color%20or%20index.gif
]]

------------------------------------------------------------------
-------------------------- USER SETTINGS -------------------------
------------------------------------------------------------------

-- Enable this setting by inserting any QWERTY alphanumeric
-- character between the quotation marks so the script can be used
-- then configure the settings below
ENABLE_SCRIPT = ""

-- This setting allows to configure the criterion
-- by which target regions will be selected:
-- 1 - by name (same as the source region's),
-- 2 - by color (same as the source region's),
-- empty - by index (loads a dialogue to type in target region indices)
-- You can override selection by name or color
-- and call the dialogue if you place the mouse cursor
-- within 100 px of the upper left hand corner of your screen
-- (lower left hand corner on Mac) and run the script
-- with a shortcut;
-- with the dialogue regions can be targeted by either name or indices:
-- A) to target by name specify between quotation marks the string
-- to be matched in the target regions name, e.g. "next region",
-- only one such string is supported per operation,
-- B) to target by indices list region indices separated by space,
-- e.g. 3 7 10 15;
-- if the source region has name the dialogue input field
-- is autofilled with its name enclosed in quotes for convenience;
-- with the dialogue, regions can be targeted by name
-- independently of the source region name
NAME_COLOR = "2"

-- The following settings are enabled by placing any aplhanumeric
-- character between the quotation marks

-- Only relevant if target regions are selected by name,
-- i.e. NAME_COLOR setting is 1 or a string is specified
-- in the dialogue as per option A) above
IGNORE_REGISTER = "1"

-- Enable to be able to use mouse cursor instead of the edit cursor
-- to point at the source region, edit cursor position will be ignored;
-- the mouse cursor position won't be respected if then Action list
-- is open, in which case edit cursor position will be used
MOUSE_CURSOR = ""

-------------------------------------------------------------------
----------------------- END OF USER SETTINGS ----------------------
-------------------------------------------------------------------


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function ACT(comm_ID) -- both string and integer work
local act = comm_ID and r.Main_OnCommand(r.NamedCommandLookup(comm_ID),0)
end

function Esc(str)
-- isolating the 1st return value so that if vars are initialized in a row
-- the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end

function Error_Tooltip(text)
local x, y = r.GetMousePosition()
r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- topmost true
end


function re_store_sel_trks(t) -- with deselection; t is the stored tracks table to be fed in at restoration stage
	if not t then
	local sel_trk_cnt = reaper.CountSelectedTracks2(0,true) -- plus Master, wantmaster true
	local trk_sel_t = {}
		if sel_trk_cnt > 0 then
		local i = sel_trk_cnt -- in reverse because of deselection
			while i > 0 do -- not >= 0 because sel_trk_cnt is not reduced by 1, i-1 is on the next line
			local tr = r.GetSelectedTrack2(0,i-1,true) -- plus Master, wantmaster true
			trk_sel_t[#trk_sel_t+1] = tr
			r.SetTrackSelected(tr, 0) -- unselect each track
			i = i-1
			end
		end
	return trk_sel_t
	elseif t and #t > 0 then
	r.PreventUIRefresh(1)
	r.Main_OnCommand(40297,0) -- Track: Unselect all tracks
	r.SetTrackSelected(r.GetMasterTrack(0), false) -- unselect Master
		for _,v in next, t do
		r.SetTrackSelected(v,1)
		end
	r.UpdateArrange()
	r.TrackList_AdjustWindows(0)
	r.PreventUIRefresh(-1)
	end
end


function GetSrcRegion(MOUSE_CURSOR)

	local function get_region(cur_pos)
	local i = 0
		repeat
		local retval, isrgn, pos, rgnend, name, idx, color = r.EnumProjectMarkers3(0, i)
			if isrgn and cur_pos >= pos and cur_pos <= rgnend then
			return {name=name:match('%s*(.+[%w%p]+)') or name, color=color, pos=pos, rgnend=rgnend} -- trimming leading and trailing spaces from the name
			end
		i = i+1
		until retval == 0 -- until no more markers/regions
	end

local cur_pos_init, t = r.GetCursorPosition() -- t is nil

	if not MOUSE_CURSOR or r.GetToggleCommandStateEx(0, 40605) == 1 -- Show action list
	then
	t = get_region(cur_pos_init)
	else
	ACT(40514) -- View: Move edit cursor to mouse cursor (no snapping)
	local cur_pos = r.GetCursorPosition()
	t = get_region(cur_pos)
	r.SetEditCurPos(cur_pos_init, false, false) -- moveview, seekplay false // restore orig edit curs pos
	end

return t -- If returns nil, no region was found, generate error message

end


function GetItemsAndStartOffset(src_rgn_t)

local start, itm_t = math.huge, {}

	for i = 0, r.CountSelectedMediaItems(0)-1 do
	local item = r.GetSelectedMediaItem(0,i)
	local pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
	local fin = pos + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
		if pos < src_rgn_t.rgnend and fin > src_rgn_t.pos then
		start = pos < start and pos or start -- getting the smallest item start
		itm_t[#itm_t+1] = item
		end
	end

	if #itm_t == 0 then -- OR start == math.huge; if no selected items within src region, collect all items within the src region
		for i = 0, r.CountMediaItems(0)-1 do
		local item = r.GetMediaItem(0,i)
		local pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
		local fin = pos + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
			if pos < src_rgn_t.rgnend and fin > src_rgn_t.pos then
			start = pos < start and pos or start -- getting the smallest item start
			itm_t[#itm_t+1] = item
			end
		end
	end

return itm_t, start < math.huge and start - src_rgn_t.pos -- get diff between the smallest item start and src region start to offset the paste position at target regions

end



function GetTargetRegions_Start(NAME_COLOR, IGNORE_REGISTER, src_rgn_t) -- src_rgn_t is returned by GetSrcRegion()

	local function get_regions(NAME_COLOR, IGNORE_REGISTER, DIALOGUE, src_rgn_t, idx_targ, t) -- empty t is fed from the main function
	local name, color = NAME_COLOR == 1, NAME_COLOR == 2
	local name_src, color_src, pos_src, end_src = not IGNORE_REGISTER and src_rgn_t.name or src_rgn_t.name:lower(), src_rgn_t.color, src_rgn_t.pos, src_rgn_t.rgnend
	local name_src = #name_src > 0 and name_src
	local idx_targ = DIALOGUE and (type(idx_targ) == 'number' and idx_targ or idx_targ:match('%s*(.+[%w%p]+)')) -- idx_targ is only used in dialogue routine and is nil otherwise // idx_targ can contain the src region name fed into the dialogue,  trimming leading and trailing empty spaces just in case
	local i = 0
		repeat
		local retval, isrgn, pos, rgnend, name_targ, idx, color_targ = r.EnumProjectMarkers3(0, i)
		local name_targ = not IGNORE_REGISTER and name_targ or name_targ:lower()
			if isrgn and pos ~= pos_src and rgnend ~= end_src and
			(DIALOGUE and (idx == idx_targ or name_targ:match(idx_targ))
			or not DIALOGUE and
			(name and name_src and name_src and name_targ:match(Esc(name_src))
			or color and color_src == color_targ))
			then
			t[#t+1] = pos
			end
		i = i+1
		until retval == 0 -- until no more markers/regions
	return t
	end

local rgn_start_t = {}

local x, y = r.GetMousePosition()
local DIALOGUE = x <= 100 and y <= 100

	if NAME_COLOR and not DIALOGUE then
	return get_regions(NAME_COLOR, IGNORE_REGISTER, DIALOGUE, src_rgn_t, idx_targ, rgn_start_t) -- idx_targ is nil here, only used in dialogue routine below
	else
	DIALOGUE = 1
	local retval, output = r.GetUserInputs('List region indices space separated, or name inside quotes', 1, 'Target region indices or name:,extrawidth=120', (src_rgn_t.name:match('%w') and '"'..src_rgn_t.name..'"' or '') ) -- only autofill if src region has name
		if not retval or #output:gsub(' ','') == 0 then return end
		if not output:match('[%a]+') then -- if no alphabetic characters, assume that it's a region indices list
			for idx_targ in output:gmatch('%d+') do
				if idx_targ then
				rgn_start_t = get_regions(NAME_COLOR, IGNORE_REGISTER, DIALOGUE, src_rgn_t, tonumber(idx_targ), rgn_start_t)
				end
			end
		elseif #rgn_start_t == 0 or output:match('[%a]+') then -- no region indices found, try region name
		local output = output:match('"(.+)"')
		rgn_start_t = output and get_regions(NAME_COLOR, IGNORE_REGISTER, DIALOGUE, src_rgn_t, Esc(IGNORE_REGISTER and output:lower() or output), rgn_start_t) -- here Esc(output) instead of tonumber(idx_targ)
		or rgn_start_t
		end
	end
return rgn_start_t, DIALOGUE -- dialogue is to condition error message if src region has no name

end



function Propagate(rgn_start_t, itm_t, offset)

local trim_behind_itms = r.GetToggleCommandStateEx(0, 41117) == 1 -- Options: Trim content behind media items when editing
local trim_behind_AI = r.GetToggleCommandStateEx(0, 42206) == 1 -- Options: Trim content behind automation items when editing or writing automation
local set_ON = not trim_behind_itms and ACT(41117) -- set to ON
local set_ON = not trim_behind_AI and ACT(42206) -- set to ON

r.SelectAllMediaItems(0, false) -- deselect all; selected false

	for _, item in ipairs(itm_t) do -- re-select the src items
	r.SetMediaItemSelected(item, true) -- selected true
	end

local sel_tr_t = re_store_sel_trks()

r.SetOnlyTrackSelected(r.GetMediaItemTrack(itm_t[1])) -- the track of the topmost item must be selected so the items are pasted on the same tracks

ACT(40698) -- Edit: Copy items

	for _, start in ipairs(rgn_start_t) do
	r.SetEditCurPos(start+offset, true, false) -- moveview true, seekplay false
	ACT(42398) -- Item: Paste items/tracks
	end

local restore = not trim_behind_itms and ACT(41117) -- set back to OFF
local restore = not trim_behind_AI and ACT(42206) -- set back to OFF
re_store_sel_trks(sel_tr_t) -- restore orig track selection

end

-- MAIN ROUTINE START

	if #ENABLE_SCRIPT:gsub(' ','') == 0 then
	local emoji = [[
		_(ツ)_
		\_/|\_/
	]]
	r.MB('  Please enable the script in its USER SETTINGS.\n\nSelect it in the Action list and click "Edit action...".\n\n'..emoji, 'PROMPT', 0)	
	return r.defer(function() do return end end) end
	

NAME_COLOR = tonumber(NAME_COLOR)
IGNORE_REGISTER = #IGNORE_REGISTER:gsub(' ', '') > 0
MOUSE_CURSOR = #MOUSE_CURSOR:gsub(' ', '') > 0

local src_rgn_t = GetSrcRegion(MOUSE_CURSOR)

	if not src_rgn_t then -- source region hasn't been defined ERROR MESSAGE
	local err = MOUSE_CURSOR and 'the mouse' or ' the edit'
	Error_Tooltip(' \n\n '..err..' cursor doesn\'t \n\n point at a source region \n\n')
	return r.defer(function() do return end end) end

local rgn_start_t, dialogue = GetTargetRegions_Start(NAME_COLOR, IGNORE_REGISTER, src_rgn_t)

	if not rgn_start_t or #rgn_start_t == 0 then -- dialogue aborted or no target regions respectively
	local err = not dialogue and #src_rgn_t.name == 0 and NAME_COLOR == 1 and 'the source region has no name' or 'no target regions \n\n  to propagate to'
	local err = rgn_start_t and Error_Tooltip(' \n\n '..err..' \n\n')
	return r.defer(function() do return end end) end

local itm_t, offset = GetItemsAndStartOffset(src_rgn_t)

	if not offset then -- no items within the src region, ERROR MESSAGE
	Error_Tooltip(' \n\n no items to propagate \n\n')
	return r.defer(function() do return end end) end


r.PreventUIRefresh(1)
r.Undo_BeginBlock()

Propagate(rgn_start_t, itm_t, offset)

r.Undo_EndBlock('Propagate items to regions',-1)
r.PreventUIRefresh(-1)





