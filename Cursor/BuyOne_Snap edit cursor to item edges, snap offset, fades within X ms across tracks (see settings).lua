--[[
ReaScript name: Snap edit cursor to item edges, snap offset, fades within X ms across tracks
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
Screenshot: https://git.io/JXcGu
About:	
		Either run with a shortcut or bind to a mouse click action at 
		'Preferences -> Mouse modifiers'
		under Context: Media Item, Track or Ruler.   
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
-- 100 seems optimal;
-- If empty or contains anything but a number, sensitivity is relative 
-- to the zoom level
-- the more the view is zoomed out the lower the sensitivty and vice versa
SENSITIVITY = ""

--********** SNAP TARGETS: ***********
-- To enbale insert any alphanumeric character between the quotes
-- to disable leave blank
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

-- Select item the edit cursor is currently snapped to as a visual reference;
-- any alphanumeric character to have item added to current selection  
-- OR "ex" (in any register) to exclusively select it;
SELECT_ITEM = "ex" 

-- Only snap to items on tracks as many tracks away up and down from
-- currently selected track as the inserted number, e.g. "4" - four tracks away;
-- only if one track is selected; 
-- takes precendence over the option ON_SEL_TRACKS if it's enabled 
-- and only one track is selected;
TRACK_RANGE = ""

-- Only snap to items on selected tracks;
-- any alphanumeric character;
ON_SEL_TRACKS = ""

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

r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping)

local curs_pos = r.GetCursorPosition()

local itm_cnt = r.CountMediaItems(0)

	if itm_cnt == 0 then return r.defer(function() end) end -- no media items

SENS = SENSITIVITY
scale = r.GetHZoomLevel()/100 -- 100 represents the number of ms and as a baseline seems optimal here and on the next line; based on behavior exhibited at zoom ~ 100px/1000ms; so when zoom per 1000 ms decreases below 100 px (zoom out), milliseconds are added to the baseline of 100 (the resolution decreases), when it increases over 100 px (zoom in) milliseconds are subtracted from 100 (the resolution increases)
SENS = tonumber(SENS) and math.abs(SENS/1000) or 100/1000/scale -- distance in sec from the target
ITEM_EDGE_L = #ITEM_EDGE_L:gsub(' ','') > 0
ITEM_EDGE_R = #ITEM_EDGE_R:gsub(' ','') > 0
ITEM_SNAPOFFSET_MARKER = #ITEM_SNAPOFFSET_MARKER:gsub(' ','') > 0
FADE_IN = #FADE_IN:gsub(' ','') > 0
FADE_OUT = #FADE_OUT:gsub(' ','') > 0
X_FADE_IN = #X_FADE_IN:gsub(' ','') > 0
X_FADE_OUT = #X_FADE_OUT:gsub(' ','') > 0
FADE_MIN_LENGTH = tonumber(FADE_MIN_LENGTH) and math.abs(FADE_MIN_LENGTH/1000) or .010
SELECT_ITEM = #SELECT_ITEM:gsub(' ','') > 0 and SELECT_ITEM:gsub(' ',''):lower()
TRACK_RANGE = tonumber(TRACK_RANGE) and math.floor(math.abs(TRACK_RANGE))
ON_SEL_TRACKS = #ON_SEL_TRACKS:gsub(' ','') > 0
SEEK_PLAY = #SEEK_PLAY:gsub(' ','') > 0


function select_item(item)
local unselect = SELECT_ITEM == 'ex' and r.SelectAllMediaItems(0, false)
r.SetMediaItemSelected(item, true)
r.UpdateItemInProject(item)
r.UpdateArrange()
end

r.PreventUIRefresh(1)

local sel_tr_idx = TRACK_RANGE and r.CountSelectedTracks() == 1 and r.CSurf_TrackToID(r.GetSelectedTrack(0,0), false) -- mcpView false

	for i = 0, itm_cnt-1 do
	local exit
	local item = r.GetMediaItem(0,i)
	
local tr_within_range = sel_tr_idx and math.abs(r.CSurf_TrackToID(r.GetMediaItem_Track(item), false) - sel_tr_idx) <= TRACK_RANGE -- mcpView false
	
	local item = tr_within_range and item or ON_SEL_TRACKS and r.IsTrackSelected(r.GetMediaItem_Track(item)) and item or not ON_SEL_TRACKS and not TRACK_RANGE and item
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
			if snap then r.SetEditCurPos(snap, false, SEEK_PLAY); exit = 1 end		
			if exit then 
			local sel = SELECT_ITEM and select_item(item) 
			break end
		end
	end
	
r.PreventUIRefresh(-1)

local bla = 1
do r.defer(function() if bla then return end end) end -- to avoid defer being stuck and display ReaScript task control dialogue on successive runs




