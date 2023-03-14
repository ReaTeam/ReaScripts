--[[
ReaScript name: Automatically increase height of selected tracks, decrease others'
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About:	The script works similalrly to the combination of preference  
        'Always show full control panel on armed track' and option 
	'Automatic record-arm when track selected' for any track in that 
	it expands selected track TCP up to the size specified 
        in the USER SETTINGS and contracts any de-selected TCP down to the size specified 
        in the USER SETTINGS. 

        After launch the script runs in the background.  
        To stop it start it again and interact with the 'ReaScript task control' dialogue.

        C A V E A T S  &  N O T E S

        In the Arrange view track selection only works with a mouse click.

        Shift+Click for batch track selection doesn't work, for multi-selection 
        Ctrl+Click must be used, for a workaround see paragraph B) below.  

        The actions 'Track: Go to next/previous track [leaving other tracks selected]' 
        only work when MIN_HEIGHT setting is explicitly set to the theme specific 
        minimum track height, is empty, invalid or 0 in which case it defaults 
        to the theme specific minimum track height.

        There're two workarounds with regard to the actions:  
        A) using auxiliary Lua scripts with the code provided at the bottom of this script 
        bound to up/down arrow keys and optionally modifiers  
        B) using REAPER built-in Track Manager with options 'Mirror track selection' 
        and optionally 'Scroll to selected track when mirroring selection'. Navigation 
        with up/down arrow keys in the Track Manager and batch selection with Shift+Click 
        mimic the behavior unsupported in the Arrange view.

        If user defined MIN_HEIGHT value is smaller than the theme minimal track height, 
        the latter will be used.

        Children tracks in collapsed folders and tracks whose height is locked 
        are ignored as their height cannot be changed.

        If the script is linked to a toolbar button it will be lit while the script is running.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable this setting by inserting any alphanumeric
-- character between the quotation marks so the script can be used
-- then configure the settings below
ENABLE_SCRIPT = ""

-- Insert values for Max and Min track heights between the quotes
-- If empty, invalid or 0, default to 100
-- and the theme minimal track height respectively,
-- if fractional, is rounded down to the integer
-- and if rounding results in 0  or value smaller
-- than the theme minimal track height for MIN_HEIGHT,
-- then the 1st conditon applies
-- if the MAX_HEIGHT value happens to be smaller than or equal
-- to MIN_HEIGHT the script won't run

MAX_HEIGHT = "100"
MIN_HEIGHT = "30"


-- If parent folder track is selected
-- along with it, all its children and grandchildren
-- are expanded provided the folder and its subfolders
-- are uncollapsed
-- THE FEATURE IS PRETTY ADVENTEROUS THEREFORE PLEASE USE
-- AT YOUR OWN RISK, SAVE OFTEN, ESPECIALLY BEFORE SELECTING
-- ANY FOLDER TRACKS
-- Multi-selection of tracks which includes folder children
-- tracks is very prone to intense flickering;
-- if the code provided at the bottom of this file
-- is used in lieu of actions
-- 'Go to next/previous track leaving other tracks selected'
-- to create multi-selections, this problem can be avoided 
-- as the said code includes safeguards against it being  
-- tailored for use with this script;
-- Enable by inserting any alphanumeric character between the quotes.

INCLUDE_FOLDER_CHILDREN = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local r = reaper


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function Script_Not_Enabled(ENABLE_SCRIPT)
	if #ENABLE_SCRIPT:gsub(' ','') == 0 then
	local emoji = [[
		_(ツ)_
		\_/|\_/
	]]
	r.MB('  Please enable the script in its USER SETTINGS.\n\nSelect it in the Action list and click "Edit action...".\n\n'..emoji, 'PROMPT', 0)
	return true
	end
end

	if Script_Not_Enabled(ENABLE_SCRIPT) then return r.defer(function() do return end end) end

function Error_Tooltip(text)
local x, y = r.GetMousePosition()
--r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
end


function Get_Track_Minimum_Height() -- may be different from 24 px in certain themes

r.PreventUIRefresh(1)

local uppermost_tr, Y_init

	for i = 0, r.CountTracks(0)-1 do
	uppermost_tr = r.GetTrack(0,i)
	Y_init = r.GetMediaTrackInfo_Value(uppermost_tr, 'I_TCPY')
		if Y_init >= 0 -- store to restore scroll position after getting minimum track height because insertion of new track via API whether at the top or at the bottom makes the tracklist scroll to the end
		then break end
	end

local sel_tr_t = {} -- store currently selected tracks
	for i = 0, r.CountSelectedTracks(0)-1 do
	sel_tr_t[#sel_tr_t+1] = r.GetSelectedTrack(0,i)
	end

-- r.Main_OnCommand(40702, 0) -- Track: Insert new track at end of track list and hide it // creates undo point hence unsuitable
r.InsertTrackAtIndex(r.GetNumTracks(), false) -- wantDefaults false; insert new track at end of track list and hide it; action 40702 'Track: Insert new track at end of track list' creates undo point hence unsuitable
local temp_track = r.GetTrack(0,r.CountTracks(0)-1)
r.SetOnlyTrackSelected(temp_track)
r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINMIXER', 0) -- hide in Mixer
--r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINTCP', 0) -- hide in Arrange // must appear in TCP otherwise the action 'View: Decrease selected track heights' won't affect it

r.PreventUIRefresh(-1)

-- find minimum height by fully collapsing // must be outside of PreventUIRefresh() because it also prevents change in height
local H_min = r.GetMediaTrackInfo_Value(temp_track, 'I_TCPH')
	repeat
	r.Main_OnCommand(41326,0) -- View: Decrease selected track heights // does 8 px
	local H = r.GetMediaTrackInfo_Value(temp_track, 'I_TCPH')
		if H < H_min then H_min = H
		elseif H_min == H then break end -- can't be changed to any lesser value
	until H == 0 -- this condition is immaterial since the loop exits earlier once minimum height is reached which is always greater than 0

r.PreventUIRefresh(1)

r.DeleteTrack(temp_track)

	for _, tr in ipairs(sel_tr_t) do -- restore originally selected tracks
	r.SetTrackSelected(tr, true) -- selected true
	end

	repeat -- restore scroll
	r.CSurf_OnScroll(0, -1) -- scroll up because so the tracklist is scrolled down
	until r.GetMediaTrackInfo_Value(uppermost_tr, 'I_TCPY') >= Y_init

r.PreventUIRefresh(-1)

return H_min

end


function Re_Set_Toggle_State(sect_ID, cmd_ID, toggle_state, INCLUDE_FOLDER_CHILDREN) -- in deferred scripts can be used to set the toggle state on start and then with r.atexit and At_Exit_Wrapper() to reset it on script termination
r.SetToggleCommandState(sect_ID, cmd_ID, toggle_state)
r.RefreshToolbar(cmd_ID)
	if INCLUDE_FOLDER_CHILDREN then -- store on script launch to be used in custom Lua code found at the bottom of this file to prevent selecting folder children with 'leaving other tracks selected' scripts when this setting is enabled because it causes flickering
	r.SetExtState('EXPAND SELECTED TRACKS', 'INCLUDE_FOLDER_CHILDREN', INCLUDE_FOLDER_CHILDREN, false) -- persist false
	else -- delete on exit so the scripts can be used independently of this script without being hindered by its setting
	r.DeleteExtState('EXPAND SELECTED TRACKS', 'INCLUDE_FOLDER_CHILDREN', true) -- persist true, only deletes the key, the section will remain intact and it's required because it also contains 'DATA' key
	end
end


function At_Exit_Wrapper(func, ...) -- wrapper for a 3d function with arguments for r.atexit()
-- func is function name, the elipsis represents the list of function arguments
-- thanks to Lokasenna, https://forums.cockos.com/showthread.php?t=218805 -- defer with args
-- his code didn't work because func(...) produced an error without there being elipsis
-- in function() as well, but gave direction
local t = {...}
return function() func(table.unpack(t)) end
end


function Get_Sel_Tracks(INCLUDE_FOLDER_CHILDREN)

local GetValue = r.GetMediaTrackInfo_Value
local t = {}
	for i = 0, r.CountSelectedTracks(0)-1 do
	local tr = r.GetSelectedTrack(0,i)
	t[#t+1] = tr
		if INCLUDE_FOLDER_CHILDREN and GetValue(tr, 'I_FOLDERDEPTH') == 1 -- parent
		and GetValue(tr, 'I_FOLDERCOMPACT') == 0 -- not collapsed, collapsed children won't get expanded with actions
		then
		local depth = r.GetTrackDepth(tr)
		local tr_idx = r.CSurf_TrackToID(tr, false) -- mcpView false // tr_idx is 1-based index which corresponds to the 0-base index of the next track
			for k = tr_idx, r.CountTracks(0)-1 do -- start with the 1st child
			local tr = r.GetTrack(0,k)
				if r.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') == 1 then -- not hidden // OR r.IsTrackVisible(tr, false) -- mixer false
				local child_depth = r.GetTrackDepth(tr)
				local parent_tr = r.GetParentTrack(tr)
				local uncollapsed = parent_tr and GetValue(parent_tr, 'I_FOLDERCOMPACT') == 0
					if child_depth > depth and uncollapsed then -- only collect children in uncollapsed (sub)folders, reason see above
					r.SetTrackSelected(tr, true) -- selected true // children must become selected otherwise glitches occur
					t[#t+1] = tr
					elseif child_depth < depth or not parent_tr then break end -- (sub)folder exited
				end
			end
		end
	end
return t
end


function Selection_Changed(sel_tr_t)
	if r.CountSelectedTracks(0) ~= #sel_tr_t then return true end -- overall selection count changed
	for _, sel_tr in ipairs(sel_tr_t) do
		if r.ValidatePtr(sel_tr, 'MediaTrack*') and not r.IsTrackSelected(sel_tr) -- overall sel count didn't change but selection did // validation prevents error when project is closed while the script is running
		then return true
		end
	end
end


function Manage_Track_Heights(sel_tr_t, MIN_HEIGHT, MAX_HEIGHT, theme_min_tr_height)

local CUST_MIN_HEIGHT = MIN_HEIGHT > theme_min_tr_height

	local function All_Parent_Folders_Uncollapsed(tr)
	local tr_idx = r.CSurf_TrackToID(tr, false) -- mcpView false
		for i = tr_idx-2, 0, -1 do -- in reverse to the top
		local prev_tr = r.GetTrack(0,i)
			if r.GetParentTrack(tr) == prev_tr -- parent found
			and r.GetMediaTrackInfo_Value(prev_tr, 'I_FOLDERCOMPACT') > 0 then return false -- parent collapsed
			elseif r.GetMediaTrackInfo_Value(prev_tr, 'I_FOLDERDEPTH') == 0 -- the folder has been exited
			then break end
		end
	return true
	end

	local function Get_First_Sel_Track()
	-- retrieves 1st selected which isn't a child in collapsed folder and not a track with locked height
	-- because these cannot be expanded with actions and will make the loops below endless
		for i = 0, r.CountSelectedTracks(0)-1 do -- all are selected
		local tr = r.GetSelectedTrack(0,i)
		local parent_tr = r.GetParentTrack(tr)
			if (not parent_tr or All_Parent_Folders_Uncollapsed(tr)) -- All_Parent_Folders_Uncollapsed() prevents resize loop becoming endless when INCLUDE_FOLDER_CHILDREN is enabled and the child track immediate parent is uncollapsed while the grandparent is collapsed
			and r.GetMediaTrackInfo_Value(tr, 'B_HEIGHTLOCK') == 0 then return tr end
		end
	end

local first_sel_tr = r.GetSelectedTrack(0,0)

	for i = 0, r.CountTracks(0)-1 do
	uppermost_tr = r.GetTrack(0,i)
	local H = r.GetMediaTrackInfo_Value(uppermost_tr, 'I_TCPH') -- excl. envelopes as they seem useless
	Y_init = r.GetMediaTrackInfo_Value(uppermost_tr, 'I_TCPY')
		if Y_init >= 0 or Y_init < 0 and Y_init + H > 0 -- store to restore scroll position after setting all tracks to MIN_HEIGHT and expanding selected track(s) to MAX_HEIGHT when MIN_HEIGHT > 24 because this routine changes scroll position if track in the middle in the track list is selected // include tracks partly visible at the top of the tracklist
		then break end
	end

	r.PreventUIRefresh(1) -- helps flickering a little bit
	r.Main_OnCommand(40727,0) -- View: Minimize all tracks
	r.PreventUIRefresh(-1)

		if CUST_MIN_HEIGHT then -- actions 'Track: Go to next/previous track' don't work when this routine runs, i.e. when MIN_HEIGHT > theme specific min height // the routine must not be enclosed between PreventUIRefresh() because in this case actions 'View: Increase/decrease selected track heights' don't affect tracks

			-- select all
			for i = 0, r.CountTracks(0)-1 do
			r.SetTrackSelected(r.GetTrack(0,i), true) -- selected true
			end

		local first_sel_tr = Get_First_Sel_Track() -- must be re-initiated for this routine because if original first_sel_tr referred to a child in a collapsed folder or a track with locked height its size cannot be changed with the action and the resize loop below won't be able to exit as the size change condition will never become true

			if first_sel_tr and r.GetMediaTrackInfo_Value(first_sel_tr, 'I_TCPH') < MIN_HEIGHT then -- only if track heights are smaller than the user set minimum after 'View: Minimize all tracks'
				repeat -- set all to MIN_HEIGHT
				r.Main_OnCommand(41327,0) -- View: Increase selected track heights a little bit // does 2 px // this one is used instead of regular 'View: Increase selected track heights' which does 8 px, for the sake of greater precision
				until r.GetMediaTrackInfo_Value(first_sel_tr, 'I_TCPH') >= MIN_HEIGHT
			end

		-- restore originally selected tracks with exceptions
		r.SetOnlyTrackSelected(r.GetMasterTrack(0)) -- deselect all
			for _, tr in ipairs(sel_tr_t) do
			local parent_tr = r.GetParentTrack(tr)
				if (not parent_tr or r.GetMediaTrackInfo_Value(parent_tr, 'I_FOLDERCOMPACT') == 0) -- only if track is not a child track in a collapsed folder, when only such tracks are selected the loop to set to MAX_HEIGHT below cannot exit and will become endless because their size cannot be changed with the action and values which condition exit won't update // will be reselected after that loop
				and r.GetMediaTrackInfo_Value(tr, 'B_HEIGHTLOCK') == 0 -- and if track height isn't locked, same reason
				then
				r.SetTrackSelected(tr, true) -- selected true
				end
			end

		end

		if r.CountSelectedTracks(0) > 0 then -- if any left selected after filtering out children tracks in collapsed folders and tracks with locked height when 'MIN_HEIGHT > theme_min_tr_height' condition is true above, otherwise selection won't change
		local first_sel_tr = Get_First_Sel_Track() -- retrieves 1st selected which isn't a child in a collapsed folder and whose height isn't locked otherwise if such kind of track is the 1st or the only one selected the loop will become endless because it won't expand and the condition to exit the loop will never become true
			if first_sel_tr then -- may happen to be nil when 'MIN_HEIGHT > theme_min_tr_height' condition isn't true above which means all original selection is intact and there're only tracks non-supported by INCLUDE_FOLDER_CHILDREN setting in it
			local H_init = r.GetMediaTrackInfo_Value(first_sel_tr, 'I_TCPH')
				repeat -- set originally selected to MAX_HEIGHT // must not be enclosed between PreventUIRefresh() because the action won't affect tracks
				--r.Main_OnCommand(41325,0) -- View: Increase selected track heights // does 8 px
				r.Main_OnCommand(41327,0) -- View: Increase selected track heights a little bit // does 2 px
				local H = r.GetMediaTrackInfo_Value(first_sel_tr, 'I_TCPH')
					if H == H_init then break end -- if after the action had been applied the height didn't change, then either the track height is locked or it's a child in a collapsed folder, exit or the loop will become endless // may be required in edge unforeseen cases
				until H >= MAX_HEIGHT
			end
		end

	-- finally restore ALL originally selected tracks
	if CUST_MIN_HEIGHT then -- ensures that actions 'Track: Go to next/previous track [leaving other tracks selected]' can be used when MIN_HEIGHT > theme_min_tr_height isn't true, i.e. when theme specific MIN_HEIHT is used	
	r.SetOnlyTrackSelected(r.GetMasterTrack(0)) -- deselect all
		for _, tr in ipairs(sel_tr_t) do
		r.SetTrackSelected(tr, true) -- selected true
		end
	end

local Y = r.GetMediaTrackInfo_Value(uppermost_tr, 'I_TCPY')

	if CUST_MIN_HEIGHT and Y ~= Y_init then-- when min track height is used restoration of scroll state isn't needed	
	r.PreventUIRefresh(1)
	local dir = Y > Y_init and 1 or Y < Y_init and -1 -- 1 = 8, -1 = -8 px; 1 down so that tracklist moves up and vice versa
		if dir then
		local y_monitor = Y
			repeat -- restore sel tracks scroll position // not ideal due to the minimum scroll unit being 8 px which makes the scroll diviation from the target value accrue and gradually nudge the scroll bar
			r.CSurf_OnScroll(0, dir)
			local Y = r.GetMediaTrackInfo_Value(uppermost_tr, 'I_TCPY')
				if Y ~= y_monitor then y_monitor = Y
				else break end -- in case the scroll cannot go any further because after contraction of tracks the tracklist becomes shorter and the track cannot reach the original value, especially it it's close to the bottom, otherwise the loop will become endless and freeze REAPER
			until dir > 0 and Y <= Y_init or dir < 0 and Y >= Y_init
		end
	r.PreventUIRefresh(-1)
	end

end


MAX_HEIGHT = tonumber(MAX_HEIGHT) and math.floor(MAX_HEIGHT+0) > 0 and math.floor(MAX_HEIGHT+0) or 100
MIN_HEIGHT = tonumber(MIN_HEIGHT) and math.floor(MIN_HEIGHT+0) > 0 and math.floor(MIN_HEIGHT+0)
local stored_min_height, last_theme, incl_fold_children = r.GetExtState('EXPAND SELECTED TRACKS', 'DATA'):match('(.-);(.+)')
theme_min_tr_height = r.GetLastColorThemeFile() == last_theme and #stored_min_height > 0 and stored_min_height+0 or Get_Track_Minimum_Height()
	if not stored_min_height or last_theme ~= r.GetLastColorThemeFile()	then r.SetExtState('EXPAND SELECTED TRACKS', 'DATA', theme_min_tr_height..';'..r.GetLastColorThemeFile()..';'..INCLUDE_FOLDER_CHILDREN, false) end -- persist false // update if first run during session or if the theme changed since previous launch
MIN_HEIGHT = (not MIN_HEIGHT or MIN_HEIGHT < theme_min_tr_height) and theme_min_tr_height or math.floor(MIN_HEIGHT+0)

	if MAX_HEIGHT <= MIN_HEIGHT then
	Error_Tooltip('\n\n maximum height is smaller than \n\n    or equal to minimum height \n\n')
	return r.defer(function() do return end end) end

local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
Re_Set_Toggle_State(sect_ID, cmd_ID, 1, INCLUDE_FOLDER_CHILDREN)

INCLUDE_FOLDER_CHILDREN = #INCLUDE_FOLDER_CHILDREN:gsub(' ','') > 0 -- is stored and cleared as ext state with Re_Set_Toggle_State() function concurrently with toggle state setting to be accessible to the auxiliary scripts 'Go to next/previous track leaving other tracks selected' found at the bottom of this file


function MAIN()

--r.PreventUIRefresh(1) -- prevents monitoring track height change when actions are applied since prevents actual height change

	if r.CountSelectedTracks(0) > 0  and ( not t or t and Selection_Changed(t) )
	then
	t = Get_Sel_Tracks(INCLUDE_FOLDER_CHILDREN)
	Manage_Track_Heights(t, MIN_HEIGHT, MAX_HEIGHT, theme_min_tr_height)
	end

	if r.CountTracks(0) ~= tr_cnt_init then t = nil -- prevents error in Selection_Changed(t) after deletion of selected tracks because they cannot be found in the table // valiidating track pointer inside the function doesn't work because it doesn't condition table update like t being nil does
	tr_cnt_init = r.CountTracks(0)
	end

r.defer(MAIN)

end



MAIN()



r.atexit(At_Exit_Wrapper(Re_Set_Toggle_State, sect_ID, cmd_ID, 0))

do return r.defer(function() do return end end) end





--[=-[

-- C O D E  F O R  A U X I L I A R Y  L U A  S C R I P T S

--[[

INSTRUCTIONS:

Create 4 Lua files naming them as follows, character register is immaterial:
Go to next track
Go to previous track
Go to next track leaving other tracks selected
Go to previous track leaving other tracks selected

Basically the same as the native actions.

They can have different names as long as they contain the words:
next;
previous;
next, leaving, selected;
previous, leaving, selected;

Copy and paste the code found between 'SNIP' lines below
into each of the 4 files, place the files in the /Scripts folder
under REAPER resource directory, import them into the Action list,
bind to up/down arrow keys optionally with modifiers.

--]]

------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>> S N I P <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<--------

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- To have selected track scroll into view automatically
-- insert any alphanumeric character between the quotes;
-- for scripts 'Go to next/previous track'
-- the selected track is scrolled into view in the middle
-- of the tracklist,
-- for scripts
-- 'Go to next/previous track leaving other tracks selected'
-- the newly selected track is scrolled into view
-- at the top of the tracklist
SCROLL_TO_SELECTED_TRACK = "1"


-- FURTHER INFORMATION:
-- The flickering problem mentioned in connection with
-- INCLUDE_FOLDER_CHILDREN setting of the main script
-- BuyOne_Automatically increase height of selected tracks, decrease others'.lua
-- is addressed in this code by preventing creation
-- of multi-selections with scripts
-- 'Go to next/previous track leaving other tracks selected'
-- when INCLUDE_FOLDER_CHILDREN setting is enabled in the main
-- script and a multi-selection about to be created will contain
-- folder tracks of uncollapsed folders;
-- The scripts only create Undo point if 'track' option is enabled
-- in Preferences -> General -> Undo settings -> Include selection:

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper

function GetUndoSettings()
-- Checking settings at Preferences -> General -> Undo settings -> Include selection:
-- thanks to Mespotine https://mespotin.uber.space/Ultraschall/Reaper_Config_Variables.html
-- https://github.com/mespotine/ultraschall-and-reaper-docs/blob/master/Docs/Reaper-ConfigVariables-Documentation.txt
local f = io.open(r.get_ini_file(),'r')
local cont = f:read('*a')
f:close()
local undoflags = cont:match('undomask=(%d+)')
local cont -- clear
local t = {
1, -- item selection
2, -- time selection
4, -- full undo, keep the newest state
8, -- cursor pos
16, -- track selection
32 -- env point selection
}
	for k, bit in ipairs(t) do
	t[k] = undoflags&bit == bit
	end
return t
end

function Scroll_Track_To_Top(tr)
-- for previous first sel track is scrolled, for next - last
local GetValue = r.GetMediaTrackInfo_Value
local tr_y = GetValue(tr, 'I_TCPY')
local dir = tr_y < 0 and -1 or tr_y > 0 and 1 -- if less than 0 (out of sight above) the scroll must move up to bring the track into view, hence -1 and vice versa
r.PreventUIRefresh(1)
local Y_init -- to store track Y coordinate between loop cycles and monitor when the stored one equals to the one obtained after scrolling within the loop which will mean the scrolling can't continue due to reaching scroll limit when the track is close to the track list end or is the very last, otherwise the loop will become endless because there'll be no condition for it to stop
	if dir then
		repeat
		r.CSurf_OnScroll(0, dir) -- unit is 8 px
		local Y = GetValue(tr, 'I_TCPY')
			if Y ~= Y_init then Y_init = Y -- store
			elseif Y == Y_init then break end -- if scroll has reached the end before track has reached the destination to prevent loop becoming endless
		until dir > 0 and Y <= 0 or dir < 0 and Y >= 0
	end
r.PreventUIRefresh(-1)
end


local track_sel_undo = GetUndoSettings()[5]

local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()

local nxt, previous = scr_name:lower():match('next'), scr_name:lower():match('previous')
local leaving_other_selected = scr_name:lower():match('leaving') and scr_name:lower():match('selected')
local tr = (leaving_other_selected and previous or previous) and r.GetSelectedTrack(0,0)
	or (leaving_other_selected or nxt) and r.GetSelectedTrack(0,r.CountSelectedTracks(0)-1)
local tr_nxt_idx = r.CSurf_TrackToID(tr, false) -- mcpView false
local start, fin, dir = table.unpack(nxt and {tr_nxt_idx, r.CountTracks(0)-1, 1}
	or previous and {tr_nxt_idx-2, 0, -1} or {})

	if start then

	local INCLUDE_FOLDER_CHILDREN = #r.GetExtState('EXPAND SELECTED TRACKS', 'INCLUDE_FOLDER_CHILDREN'):gsub(' ','') > 0

		function Evaluate_Selection(tr, INCLUDE_FOLDER_CHILDREN)
			if not INCLUDE_FOLDER_CHILDREN then return true end
		local GetValue = r.GetMediaTrackInfo_Value
		local regular_tr, parent_tr
			for i = 0, r.CountSelectedTracks(0)-1 do
			local tr = r.GetSelectedTrack(0,i)
			local is_visible = GetValue(tr, 'B_SHOWINTCP') == 1
				if is_visible then
				local is_parent = GetValue(tr,'I_FOLDERDEPTH') == 1
					if is_parent and GetValue(tr,'I_FOLDERCOMPACT') == 0 -- folder uncollapsed
					then parent_tr = tr
					elseif not is_parent then regular_tr = tr
					end
				end
			end
			-- prevent presence of regular tracks and parents of uncollapsed folders within selection, that's when INCLUDE_FOLDER_CHILDREN is enabled
			if regular_tr and GetValue(tr,'I_FOLDERDEPTH') == 1 and GetValue(tr,'I_FOLDERCOMPACT') == 0 -- selection contains an a parent if uncollapsed folder and the track being selected currently is regular track
			or parent_tr and GetValue(tr,'I_FOLDERDEPTH') == 0 then -- vice versa, selection contains a regular track and the track being selected currently is a parent if uncollapsed folder
			return false
			end
		return true
		end

		if track_sel_undo then r.Undo_BeginBlock() end

			for i = start, fin, dir do
			local tr = r.GetTrack(0,i)
				if r.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') == 1 then -- not hidden // OR r.IsTrackVisible(tr, false) -- mixer false
				local sel = not leaving_other_selected and r.SetOnlyTrackSelected(tr)
				or Evaluate_Selection(tr, INCLUDE_FOLDER_CHILDREN) and r.SetTrackSelected(tr, true) -- selected true
					if #SCROLL_TO_SELECTED_TRACK:gsub(' ','') > 0 then
						if not leaving_other_selected then -- doesn't work for multi-selection
						r.Main_OnCommand(40913,0) -- Track: Vertical scroll selected tracks into view
						else -- if multi-selection
						local tr = nxt and r.GetSelectedTrack(0, r.CountSelectedTracks(0)-1) -- last
						or previous and r.GetSelectedTrack(0,0) -- first
						Scroll_Track_To_Top(tr)
						end
					end
				break end -- one at a time
			end

	local addendum = leaving_other_selected and 'leaving other tracks selected' or ''
		if track_sel_undo then r.Undo_EndBlock('Go to '..(nxt or previous)..' track '..addendum,-1) end

	return r.defer(function() do return end end) end


------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>> S N I P <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<--------


 --]=]


