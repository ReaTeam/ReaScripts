--[[
ReaScript name: Select source object of a focused FX chain or FX window
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	Makes track/item of the focused track/take FX window selected.
	Works in either manual or auto modes, see USER SETTINGS.  

	Bridged FX floating windows don't work unless they only display 
	controls without the UI, which is a REAPER native object.  

	In auto mode to reselect the object (track or item/take) of the open 
	FX window after other objects were selected while the FX focus didn't 
	change, meaning other FX chain or FX floating windows weren't focused, 
	toggle currently visible FX bypass ON and OFF or momentarily switch 
	to another FX in the chain if there're several.	 

	See also BuyOne_Select track of the currently focused track FX window.lua		
]]

------------------------------------------------------------------
-------------------------- USER SETTINGS -------------------------
------------------------------------------------------------------
-- To enable the settings below insert any QWERTY alphanumeric
-- character between the quotation marks.

-- Enable this setting so the script can be used
-- then configure the settings below
ENABLE_SCRIPT = ""

---------------------------------------------

-- Enable so track is selected when track FX is in focus
TRACK_FX = "1"
-- only relevant if TRACK_FX is enabled
SCROLL_2TRACK = "1"

---------------------------------------------

-- Enable so item is selected when take FX is in focus
TAKE_FX = "1"

-- The following settings are only relevant if TAKE_FX is enabled.

-- Makes the Arrange scroll both horizontally to the item
-- and vertically to the item track
SCROLL_2ITEM = "1"
-- Enable to have the edit cursor move to the start
-- of the selected item;
-- only relevant if SCROLL_2ITEM is enabled
MOVE_EDIT_CURS = ""
-- Makes the Arrange scroll vertically to the item track;
-- only relevant if SCROLL_2ITEM is disabled
SCROLL_2ITEM_TRACK = "1"

--------------------------------------------

-- If enabled, selection of the FX source objects
-- occurs automatically when the FX chain or FX floating window
-- gets the focus;
-- if the focus didn't change but the object selection did,
-- to re-select the object the focused FX belongs to, toggle
-- the FX bypass or momentarily select another FX in the chain
-- if there're more than one
AUTO = ""

-------------------------------------------------------------------
----------------------- END OF USER SETTINGS ----------------------
-------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


local r = reaper


function validate_sett(sett) -- validate setting, can be either a non-empty string or any number
return type(sett) == 'string' and #sett:gsub(' ','') > 0 or type(sett) == 'number'
end


function GetFocusedFX() -- complemented with GetMonFXProps() to get Mon FX in builds prior to 6.20

	local function GetMonFXProps() -- get mon fx accounting for floating window, GetFocusedFX() doesn't detect mon fx in builds prior to 6.20

		local master_tr = r.GetMasterTrack(0)
		local mon_fx_idx = r.TrackFX_GetRecChainVisible(master_tr)
		local is_mon_fx_float = false -- only relevant for pasting stage to reopen the fx in floating window
			if mon_fx_idx < 0 then -- fx chain closed or no focused fx look for fx in a floating window // if this condition is removed floated fx gets priority
				for i = 0, r.TrackFX_GetRecCount(master_tr) do
					if r.TrackFX_GetFloatingWindow(master_tr, 0x1000000+i) then
					mon_fx_idx = i; is_mon_fx_float = true break end
				end
			end
		return mon_fx_idx, is_mon_fx_float -- expected >= 0, true
	end

local retval, tr_num, itm_num, fx_num = r.GetFocusedFX()
-- Returns 1 if a track FX window has focus or was the last focused and still open, 2 if an item FX window has focus or was the last focused and still open, 0 if no FX window has focus. tracknumber==0 means the master track, 1 means track 1, etc. itemnumber and fxnumber are zero-based. If item FX, fxnumber will have the high word be the take index, the low word the FX index.
-- if take fx, item number is index of the item within the track (not within the project) while track number is the track this item belongs to, if not take fx itm_num is -1, if retval is 0 the rest return values are 0 as well
-- if src_take_num is 0 then track or no object

local mon_fx_num = GetMonFXProps() -- expected >= 0 or > -1

local tr = retval > 0 and (r.GetTrack(0,tr_num-1) or r.GetMasterTrack()) or retval == 0 and mon_fx_num >= 0 and r.GetMasterTrack() -- prior to build 6.20 Master track has to be gotten even when retval is 0

local item = retval == 2 and r.GetTrackMediaItem(tr, itm_num)
-- high word is 16 bits on the left, low word is 16 bits on the right
local take_num, take_fx_num = fx_num>>16, fx_num&0xFFFF -- high word is right shifted by 16 bits (out of 32), low word is masked by 0xFFFF = binary 1111111111111111 (16 bit mask); in base 10 system take fx numbers starting from take 2 are >= 65536
local take = retval == 2 and r.GetMediaItemTake(item, take_num)
local fx_num = retval == 2 and take_fx_num or retval == 1 and fx_num or mon_fx_num >= 0 and 0x1000000+mon_fx_num -- take or track fx index (incl. input/mon fx) // unlike in GetLastTouchedFX() input/Mon fx index is returned directly and need not be calculated // prior to build 6.20 Mon FX have to be gotten when retval is 0 as well // 0x1000000+mon_fx_num is equivalent to 16777216+mon_fx_num

return retval, tr_num-1, tr, itm_num, item, take_num, take, fx_num, mon_fx_num >= 0 -- tr_num = -1 means Master;

end


local fx_idx_init, bypass_init, tr_init, item_init, obj_init


function SELECT()

local undo = not AUTO and r.Undo_BeginBlock()

r.PreventUIRefresh(1) -- to prevent flickering of take activation

local retval, tr_idx, tr, itm_idx, item, take_idx, take, fx_idx, mon_fx = GetFocusedFX()
local obj = item and 1 or track and 2
local bypass = item and r.TakeFX_GetEnabled(take, fx_idx) or tr and r.TrackFX_GetEnabled(tr, fx_idx)

	if TAKE_FX and item and (obj ~= obj_init or item ~= item_init or fx_idx ~= fx_idx_init or bypass ~= bypass_init) then -- item is ealier since when item is valid track is valid as well // obj ~= obj_init ensures selection of object when focus switches from track fx to take fx and vice versa, item ~= item_init allows a) selecting other items and b) re-selecting FX chain source item selection when switching from another FX chain or FX floating window, fx_idx ~= fx_idx_init and bypass ~= bypass_init allow when other items are selected without change in FX focus to re-select the source item and take by switching visible FX or by toggling its bypass (the bypass method is the only one which works with single FX in the chain and with floating FX windows), same for track FX
	r.SelectAllMediaItems(0, false) -- selected false // deselect all
	r.SetMediaItemSelected(item, true) -- selected true
	r.SetMediaItemInfo_Value(item, 'I_CURTAKE', take_idx) -- activate take
	r.UpdateArrange()
		if SCROLL_2ITEM then -- scroll horizontally
		local edit_cur_pos = r.GetCurorPosition() -- store current pos
		r.SetEditCurPos(r.GetMediaItemInfo_Value(item, 'D_POSITION'), true, false) -- moveview true, seekplay false // horiz scroll to the selected item; same as r.Main_OnCommand(41173,0) -- Item navigation: Move cursor to start of items
		local restore = not MOVE_EDIT_CURS and r.SetEditCurPos(edit_cur_pos, false, false) -- moveview, seekplay false
		end
		if SCROLL_2ITEM or SCROLL_2ITEM_TRACK then -- scroll vertically
		-- vertical TCP and horiz Mixer scroll as well:
		r.SetOnlyTrackSelected(tr)
		r.Main_OnCommand(40913, 0) -- Track: Vertical scroll selected tracks into view
		r.SetMixerScroll(tr) -- scroll mixer
		end
	-- update vars
	obj_init = obj
	item_init = item
	fx_idx_init = fx_idx
	bypass_init = bypass
	elseif TRACK_FX and tr and not item --and (TAKE_FX or not TAKE_FX and item)
	and (obj ~= obj_init or tr ~= tr_init or fx_idx ~= fx_idx_init or bypass ~= bypass_init) -- since tr var is valid when take FX is in focus as well 'not item' ensures no action when TAKE_FX is disabled otherwise vert scrolling happens
	then
	r.SetOnlyTrackSelected(tr)
		if SCROLL_2TRACK then
		-- borrowed from Edgemeal https://forums.cockos.com/showthread.php?t=249659#5
		local scroll = tr_idx == -1 and r.CSurf_OnScroll(0, -5000) -- if Master track, scroll up as far as possible
		or r.Main_OnCommand(40913, 0) -- Track: Vertical scroll selected tracks into view
		r.SetMixerScroll(tr) -- scroll mixer
		end
	-- update vars
	obj_init = obj
	tr_init = tr
	fx_idx_init = fx_idx
	bypass_init = bypass
	end


local run = AUTO and r.defer(SELECT)

r.PreventUIRefresh(-1)

local undo = not AUTO and r.Undo_EndBlock('Select source object of a focused FX chain or FX window', -1)
end

	if not validate_sett(ENABLE_SCRIPT) then
	local emoji = [[
		_(ツ)_
		\_/|\_/
	]]
	r.MB('  Please enable the script in its USER SETTINGS.\n\nSelect it in the Action list and click "Edit action...".\n\n'..emoji, 'PROMPT', 0)
	return r.defer(function() do return end end) end

TRACK_FX = validate_sett(TRACK_FX)
SCROLL_2TRACK = validate_sett(SCROLL_2TRACK)
TAKE_FX = validate_sett(TAKE_FX)
SCROLL_2ITEM = validate_sett(SCROLL_2ITEM)
MOVE_EDIT_CURS = validate_sett(MOVE_EDIT_CURS)
SCROLL_2ITEM_TRACK = validate_sett(SCROLL_2ITEM_TRACK)
AUTO = #AUTO:gsub(' ','') > 0

SELECT()







