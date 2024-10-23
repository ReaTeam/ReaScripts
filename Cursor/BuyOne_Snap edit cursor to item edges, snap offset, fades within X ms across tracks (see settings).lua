--[[
ReaScript name: Snap edit cursor to item edges, snap offset, fades within X ms across tracks
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.1
Changelog: 	#Now 'ReaScript task control' doesn't pop up when a shortcut is held down continuously
		#Made 'About' text a little more descriptive
		#Corected SENSITIVITY setting description
Licence: WTFPL
REAPER: at least v5.962
Screenshot: https://git.io/JXcGu
About:	
	Position the mouse cursor over the snap target and run.  		
	Either run with a shortcut or bind to a mouse click action at 
	'Preferences -> Mouse modifiers'
	under Context: Media Item, Track or Ruler. 
	Because the script responds to the mouse cursor position.  
	To modify the script behavior in terms of item selection combine 
	it within a custom action with such actions as:  
	Item: Select item under mouse cursor; Item: Unselect all items   
	and bind this custom action to a mouse click action.

	In this script the edit cursor is not affected by the global Snap settings.
	You'd still want to have the regular behavior in another slot under Mouse modifiers.
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Distance of the edit cursor from target in ms (1 ms = 0.001 sec)
-- the greater the number the higher the sensitivity and vice versa
-- 100 seems optimal but it's quite lax;
-- noticeable change occurs when the setting is changed by 50 ms and 100 ms;
-- if preceded by 'R' or 'r' e.g. "r100", sensitivity is relative
-- to the zoom level; the specified numeric value is valid for zoom resolution
-- of ~100 px per 1000 ms (or 1 sec); as the zoom resolution changes
-- so does the minimum snap distance between the edit cursor and the target;
-- the more the view is zoomed in the lower the sensitivity
-- (the shorter the distance) and vice versa;
-- If 0, empty or invalid the sensitivity defaults to constant 100 ms;
SENSITIVITY = "100"

--********** SNAP TARGETS: ***********
-- To enbale insert any alphanumeric character between the quotes
-- to disable leave blank (here and elsewhere);
ITEM_EDGE_L = "1"
ITEM_EDGE_R = "1"
ITEM_SNAPOFFSET_MARKER = "1"
FADE_IN = "1"
FADE_OUT = "1"
X_FADE_IN = "1"
X_FADE_OUT = "1"
--------------------------------------
FADE_MIN_LENGTH = "10" -- in ms (1 ms = 0.001 sec) // if empty defaults to 10 ms
--**********************************

-- Select items the edit cursor is currently snapped to as a visual reference;
-- if it ends up being snapped to several targets at once, all items involved
-- will be selected;
-- any alphanumeric character;
SELECT_ITEMS = ""

-- Only snap to items on selected tracks;
-- any alphanumeric character;
ON_SEL_TRACKS = ""

-- Only snap to items on tracks as many tracks away up and down from
-- THE FIRST SELECTED track as the inserted number, e.g. "4" - four tracks away;
-- 0 value makes the cursor only snap to items on THE FIRST SELECTED track if
-- ON_SEL_TRACKS option is disabled;
-- ** takes precendence over the option ON_SEL_TRACKS if the latter is enabled
-- and only one track is selected, otherwise ON_SEL_TRACKS option prevails;
TRACK_RANGE = ""

-- When either or both options ON_SEL_TRACKS and TRACK_RANGE are enabled
-- but there're no selected tracks the edit cursor snaps to items on all
-- tracks just as if these options were disabled;

-- Move play cursor to the edit cursor when snapped and playback is ON;
-- any alphanumeric character;
SEEK_PLAY = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local itm_cnt = r.CountMediaItems(0)

	if itm_cnt == 0 then return r.defer(function() end) end -- no media items

r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping)

local curs_pos = r.GetCursorPosition() -- can be either here, outside of the main loop, or inside it at the very beginning

SENS = not SENSITIVITY:match('^[0]+') and not SENSITIVITY:match('[Rr]+[0]+') and SENSITIVITY -- exclude zeros
scale = r.GetHZoomLevel()/100 -- 100 represents the number of ms and as a baseline seems optimal; it's based on behavior exhibited at zoom ~100px/1000ms which corresponds to ~100 ms of snap distance per 1 sec; when zoom per 1000 ms decreases below 100 px (zoom out), milliseconds are added to the user value (the resolution decreases), when it increases over 100 px (zoom in) milliseconds are subtracted from the user value (the resolution increases)
SENS = tonumber(SENS) and math.abs(SENS/1000) -- abs to ignore negative entries
or SENS and SENS:match('^[Rr]') and tonumber(SENS:match('[^Rr]+$')) and math.abs(SENS:match('%d+')/1000)/scale or 0.1
ITEM_EDGE_L = #ITEM_EDGE_L:gsub(' ','') > 0
ITEM_EDGE_R = #ITEM_EDGE_R:gsub(' ','') > 0
ITEM_SNAPOFFSET_MARKER = #ITEM_SNAPOFFSET_MARKER:gsub(' ','') > 0
FADE_IN = #FADE_IN:gsub(' ','') > 0
FADE_OUT = #FADE_OUT:gsub(' ','') > 0
X_FADE_IN = #X_FADE_IN:gsub(' ','') > 0
X_FADE_OUT = #X_FADE_OUT:gsub(' ','') > 0
FADE_MIN_LENGTH = tonumber(FADE_MIN_LENGTH) and math.abs(FADE_MIN_LENGTH/1000) or .010
SELECT_ITEMS = #SELECT_ITEMS:gsub(' ','') > 0
ON_SEL_TRACKS = #ON_SEL_TRACKS:gsub(' ','') > 0
TRACK_RANGE = tonumber(TRACK_RANGE) and math.floor(math.abs(TRACK_RANGE))
SEEK_PLAY = #SEEK_PLAY:gsub(' ','') > 0


r.PreventUIRefresh(1)

local sel_tr_idx = TRACK_RANGE and r.CSurf_TrackToID(r.GetSelectedTrack(0,0), false) -- mcpView false

local selection_t = {}

	for i = 0, itm_cnt-1 do
--	local curs_pos = r.GetCursorPosition() -- can be either here, inside the main loop, or outside of it
	local item = r.GetMediaItem(0,i)
	local itm_tr = r.GetMediaItem_Track(item)
	local tr_within_range = sel_tr_idx and math.abs(r.CSurf_TrackToID(itm_tr, false) - sel_tr_idx) <= TRACK_RANGE -- mcpView false
	local item = tr_within_range and item or ON_SEL_TRACKS and r.IsTrackSelected(itm_tr) and item
	or (tr_within_range or ON_SEL_TRACKS) and r.CountSelectedTracks() == 0 and item
	or not TRACK_RANGE and not ON_SEL_TRACKS and item
		if item then
		local item_start = r.GetMediaItemInfo_Value(item, 'D_POSITION')
		local item_end = item_start + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
		local snapoffset = item_start + r.GetMediaItemInfo_Value(item, 'D_SNAPOFFSET')
		local fadeA = r.GetMediaItemInfo_Value(item, 'D_FADEINLEN')
		local fadeB = r.GetMediaItemInfo_Value(item, 'D_FADEOUTLEN')
		local x_fadeA = r.GetMediaItemInfo_Value(item, 'D_FADEINLEN_AUTO')
		local x_fadeB = r.GetMediaItemInfo_Value(item, 'D_FADEOUTLEN_AUTO')
		local fadein = item_start + fadeA
		local fadeout = item_end - fadeB
		local x_fadein = item_start + x_fadeA
		local x_fadeout = item_end - x_fadeB
		local snap = ITEM_EDGE_L and math.abs(curs_pos - item_start) <= SENS and item_start
		or ITEM_EDGE_R and math.abs(curs_pos - item_end) <= SENS and item_end
		or ITEM_SNAPOFFSET_MARKER and math.abs(curs_pos - snapoffset) <= SENS and snapoffset
		or FADE_IN and fadeA >= FADE_MIN_LENGTH and math.abs(curs_pos - fadein) <= SENS and fadein
		or FADE_OUT and fadeB >= FADE_MIN_LENGTH and math.abs(curs_pos - fadeout) <= SENS and fadeout
		or X_FADE_IN and x_fadeA >= FADE_MIN_LENGTH and math.abs(curs_pos - x_fadein) <= SENS and x_fadein
		or X_FADE_OUT and x_fadeB >= FADE_MIN_LENGTH and math.abs(curs_pos - x_fadeout) <= SENS and x_fadeout
			if snap then r.SetEditCurPos(snap, false, SEEK_PLAY); -- moveview false since clicking is always performed within visible area, so nowhere to move
				if not SELECT_ITEMS then break
				else selection_t[#selection_t+1] = item -- store items the cursor could have snapped to
				end
			end
		end
	end


	if #selection_t > 0 then -- only runs if SELECT_ITEMS is enabled
	r.SelectAllMediaItems(0, false) -- deselect all items
		for _, item in ipairs(selection_t) do -- re-evaluate snap to stored items to avoid selection of items which were stored
		-- due to cursor's jolts and bounces at low resolution but at which the cursor doesn't eventually park
		local item_start = r.GetMediaItemInfo_Value(item, 'D_POSITION')
		local item_end = item_start + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
		local params = {
		item_start, item_end,
		item_start + r.GetMediaItemInfo_Value(item, 'D_SNAPOFFSET'),
		item_start + r.GetMediaItemInfo_Value(item, 'D_FADEINLEN'),
		item_end - r.GetMediaItemInfo_Value(item, 'D_FADEOUTLEN'),
		item_start + r.GetMediaItemInfo_Value(item, 'D_FADEINLEN_AUTO'),
		item_end - r.GetMediaItemInfo_Value(item, 'D_FADEOUTLEN_AUTO')
		}
			for _, param in ipairs(params) do
				if r.GetCursorPosition() == param then
				r.SetMediaItemSelected(item, true)
				r.UpdateItemInProject(item)
				end
			end
		end
	r.UpdateArrange()
	end


r.PreventUIRefresh(-1)


