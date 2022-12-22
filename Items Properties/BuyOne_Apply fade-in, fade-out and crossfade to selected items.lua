--[[
ReaScript name: Apply fade-in, fade-out and crossfade to selected items
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About:	The script adds fades-in, fades-out and crossfades to selected audio items.  
	Adds fades to multi-take items containing mixed audio and MIDI takes 
	(whoever does that?) if the active take is audio.  
	See USER SETTINGS below in the script. 

	If crossfade setting is enabled in the USER SETTINGS, both sides of the created 
	crossfade will have the length of items intersection area, something REAPER does 
	when auto-crossfade is enabled.  
	Alternatively non-uniform crossfades can be created by applying fades the length
	of which might differ from the size of the items intersection area and from each
	other's provided ENABLE_XFADE setting is disabled and ALLOW_NON_UNIFORM_XFADES 
	setting is enabled.  

	The script is agnostic about fades already present in selected items and if any exist 
	they will be overwritten.  

	If selected item overlaps a non-selected item and the fade-in and/or fade-out are enabled
	in the USER SETTINGS, fade will only be applied to the non-overlapping end of the item. 
	For a crossfade to be applied both overlapping items must be selected.  

	Applying a crossfade replaces fade-in and fade-out which existed in items prior 
	to crossfading, if any. If auto-crossfade is not enabled in REAPER, when items are 
	separated their fade-in and fade-out used in the crossfade are retained, otherwise
	the lengths of original fade-in and fade-out are restored but not other properties.

	The script can be duplicated to create multiple instances and have different 
	settings in each instance so that those could be used as fade presets.  

	See also script BuyOne_Fade_presets.lua
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable this setting by inserting any alphanumeric
-- character between the quotation marks so the script can be used
-- then configure the settings below
ENABLE_SCRIPT = "1"

--_____________________
--F A D E - I N / O U T

-- To enable insert any alphanumeric character between the quotation marks
ENABLE_FADEIN = "1"
ENABLE_FADEOUT = "1"

-- If empty or invalid defaults to 10 ms
FADEIN_LENGTH = "10"
FADEOUT_LENGTH = "10"

-- Fade shapes:
-- These are REAPER stock shapes shown on pages
-- 64 (3.19 Recording multiple takes), 133 (7.26 Adjusing fades),
-- 135 (7.27 Crossfades and the Crossfade Editor) of the User Guide;
-- 1 - linear, 2 - faster start (in)/slower end (out),
-- 3 - slower start (in)/faster end (out)
-- 4 - fast start (in)/slow end (out),
-- 5 - slow start (in)/fast end (out),
-- 6 - S-shape smooth, 7 - S-shape sharp
-- length is in milliseconds
-- if empty or invalid defaults to 1 (linear)
FADEIN_SHAPE = "1"
FADEOUT_SHAPE = "1"

-- Curve between -3 and 3 (integers only):
-- -3 - the curve is shifted all the way to the left
-- 3 - the curve is shifted all the way to the right
-- 0 - no shift in the curve
-- if empty or invalid defaults to 0 (no shift in the curve)
-- REAPER default fade shape selected in FADEIN_SHAPE/FADEOUT_SHAPE
-- setting above is used
FADEIN_CURVE = "1"
FADEOUT_CURVE = "1"

-- To enable insert any alphanumeric character between the quotation marks.
-- Provided FADEIN_LENGTH and FADEOUT_LENGTH values suffice for the fades
-- to intersect, allows crossfades with one or both fades having length different
-- from items intersection area length and/or from each other's
-- unlike regular crossfades;
-- only relevant when ENABLE_XFADE setting below isn't enabled
ALLOW_NON_UNIFORM_XFADES = ""


--__________________
-- C R O S S F A D E

-- To enable insert any alphanumeric character between the quotation marks.
-- Creates crossfades both sides of which span items intersection area exactly,
-- i.e. fade-out and fade-in each have the length of the intersection area
ENABLE_XFADE = "1"

-- Crossfade length is determined automatically by the lenth of items overlap.
-- If after being crossfaded items are separated their respective fade-out and fade-in
-- will be preserved.
-- If auto-crossfade option is enabled on the Main toolbar or in the Options menu
-- manual change of the overlap length will result in adjustment of the crossfade
-- length, otherwise the set length won't change. After items are separated
-- their respective fade-out and fade-in will be auto-removed.

-- REAPER stock presets from 1 to 7
-- shown on page 148 (8.3 Crossfades with Takes) of the User Guide;
-- if a crossfade preset is selected it will be applied
-- if empty or invalid custom settings below will be used
-- crossfade length settings above apply to both, presets and custom settings below
XFADE_PRESET = "1"

-- Fade shapes from above apply.
-- Linear shape produces equal gain,
-- other shapes (logarithmic) produce equal power.
-- From the manual:
-- "Equal gain might be  preferred when both items contain similar material.
-- Equal power might be chosen when the crossfade is between two different
-- types of sound or different instruments"
-- if shape setting is empty or invalid defaults to 1 (linear)
XFADE_OUT_SHAPE = ""
XFADE_IN_SHAPE = ""

-- Fade curves from above apply.
XFADE_OUT_CURVE = ""
XFADE_IN_CURVE = ""

-- When crossfade preset setting isn't enabled above:
-- if crossfade curve settings aren't set, crossfade shape settings
-- will replicate REAPER default crossfade presets provided fade-out
-- and fade-in shapes are the same;
-- if none of crossfade shape and curve settings is set
-- REAPER default preset 1 will be replicated

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


function Error_Tooltip(text)
local x, y = r.GetMousePosition()
r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
end

function validate_sett(sett) -- validate setting, can be either a non-empty string or any number
return type(sett) == 'string' and #sett:gsub(' ','') > 0 or type(sett) == 'number'
end

function validate_len(len)
return tonumber(len) and len or 10
end

function validate_shape(shape)
return tonumber(shape) and shape+0 >= 1 and shape+0 <= 7 and math.floor(shape)-1 or 0 -- -1 to convert to 0-based count used by API
end

function validate_curve(curve)
return tonumber(curve) and curve+0 >= -3 and curve+0 <= 3 and math.floor(curve) or 0
end

function convert_curve_val(curve)
return curve == -3 and -1 or curve == -2 and -.6 or curve == -1 and -.2
or curve == 0 and 0 or curve == 1 and .2 or curve == 2 and .6 or curve == 3 and 1
end


	if Script_Not_Enabled(ENABLE_SCRIPT) then return r.defer(function() do return end end) end

local sel_itm_cnt = r.CountSelectedMediaItems(0)

	if sel_itm_cnt == 0 then
	Error_Tooltip('\n\n no selected items \n\n ')
	return r.defer(function() do return end end) end


ENABLE_FADEIN = validate_sett(ENABLE_FADEIN)
FADEIN_LENGTH = validate_len(FADEIN_LENGTH)
FADEIN_SHAPE = validate_shape(FADEIN_SHAPE)
FADEIN_CURVE = validate_curve(FADEIN_CURVE)
ENABLE_FADEOUT = validate_sett(ENABLE_FADEOUT)
FADEOUT_LENGTH = validate_len(FADEOUT_LENGTH)
FADEOUT_SHAPE = validate_shape(FADEOUT_SHAPE)
FADEOUT_CURVE = validate_curve(FADEOUT_CURVE)
ALLOW_NON_UNIFORM_XFADES = validate_sett(ALLOW_NON_UNIFORM_XFADES) and not validate_sett(ENABLE_XFADE)

ENABLE_XFADE = validate_sett(ENABLE_XFADE)
XFADE_PRESET = tonumber(XFADE_PRESET)
XFADE_PRESET = XFADE_PRESET and XFADE_PRESET >=1 and XFADE_PRESET <=7 and math.floor(XFADE_PRESET)
XFADE = XFADE_PRESET and
(XFADE_PRESET == 1 and {outshape=0, outcurve=0, inshape=0, incurve=0} -- both out and in, here and below
or XFADE_PRESET == 2 and {outshape=1, outcurve=0, inshape=1, incurve=0}
or XFADE_PRESET == 3 and {outshape=2, outcurve=-1, inshape=2, incurve=1}
or XFADE_PRESET == 4 and {outshape=3, outcurve=1, inshape=3, incurve=-1}
or XFADE_PRESET == 5 and {outshape=4, outcurve=-1, inshape=4, incurve=1}
or XFADE_PRESET == 6 and {outshape=5, outcurve=0, inshape=5, incurve=0}
or XFADE_PRESET == 7 and {outshape=6, outcurve=0, inshape=6, incurve=0})
or {outshape=validate_shape(XFADE_OUT_SHAPE), outcurve=validate_curve(XFADE_OUT_CURVE), inshape=validate_shape(XFADE_IN_SHAPE), incurve=validate_curve(XFADE_IN_CURVE)}


local Get, Set = r.GetMediaItemInfo_Value, r.SetMediaItemInfo_Value


FADEIN_LENGTH, FADEOUT_LENGTH = FADEIN_LENGTH/1000, FADEOUT_LENGTH/1000


r.Undo_BeginBlock()

	for i = 0, sel_itm_cnt-1 do
	local cur_fadein
	local itm = r.GetSelectedMediaItem(0,i)
	local midi_take = r.TakeIsMIDI(r.GetActiveTake(itm))
	local itm_tr = r.GetMediaItemTrack(itm)
	local pos = r.GetMediaItemInfo_Value(itm, 'D_POSITION')

	local itm_idx = Get(itm, 'IP_ITEMNUMBER')
	local prev_itm = r.GetTrackMediaItem(itm_tr, itm_idx-1)
	local prev_itm_tr = prev_itm and r.GetMediaItemTrack(prev_itm)
	local prev_itm_end = prev_itm and Get(prev_itm, 'D_POSITION') + Get(prev_itm, 'D_LENGTH')
	local prev_midi_take = prev_itm and r.TakeIsMIDI(r.GetActiveTake(prev_itm))
	local prev_itm_sel = prev_itm and r.IsMediaItemSelected(prev_itm)
	local non_uniform_xfade_prev = prev_itm and pos < prev_itm_end and prev_itm_sel and prev_itm_end-Get(prev_itm, 'D_FADEOUTLEN_AUTO') < pos+FADEIN_LENGTH and ALLOW_NON_UNIFORM_XFADES -- items overlap and their fade-in and out are expected to overlap

		if ENABLE_XFADE and not midi_take and not prev_midi_take
		and prev_itm_tr == itm_tr and pos < prev_itm_end and prev_itm_sel then -- crossfade fade in, only if overlapping item is selected
		Set(itm, 'D_FADEINLEN_AUTO', prev_itm_end-pos) -- length is calculated according to the size of the overlap
		Set(itm, 'C_FADEINSHAPE', math.abs(XFADE.inshape))
		Set(itm, 'D_FADEINDIR', XFADE_PRESET and XFADE.incurve or convert_curve_val(XFADE.incurve))
		xfade_undo = 'crossfade'
		elseif ENABLE_FADEIN and not midi_take and (prev_itm_tr ~= itm_tr or prev_itm_tr == itm_tr and ( pos >= prev_itm_end or non_uniform_xfade_prev) ) then -- regular fade-in only if the current item doesn't overlap the prev item // covers cases where there's no previous item
		Set(itm, non_uniform_xfade_prev and 'D_FADEINLEN_AUTO' or 'D_FADEINLEN', math.abs(FADEIN_LENGTH))
		Set(itm, 'C_FADEINSHAPE', math.abs(FADEIN_SHAPE-1))
		Set(itm, 'D_FADEINDIR', convert_curve_val(FADEIN_CURVE))
		fadein_undo = 'fade-in'
		end

	local fin = pos + Get(itm, 'D_LENGTH')
	prev_itm_end = fin
	local next_itm = r.GetTrackMediaItem(itm_tr, itm_idx+1)
	local next_itm_tr = next_itm and r.GetMediaItemTrack(next_itm)
	local next_itm_pos = next_itm and Get(next_itm, 'D_POSITION')
	local next_midi_take = next_itm and r.TakeIsMIDI(r.GetActiveTake(next_itm))
	local next_itm_sel = next_itm and r.IsMediaItemSelected(next_itm)
	local non_uniform_xfade_nxt = next_itm and next_itm_pos < fin and next_itm_sel and fin-FADEOUT_LENGTH <  next_itm_pos+FADEIN_LENGTH and ALLOW_NON_UNIFORM_XFADES -- items overlap and their fade-in and out are expected to overlap

		if ENABLE_XFADE and not midi_take and next_itm_pos and not next_midi_take
		and next_itm_pos < fin and next_itm_tr == itm_tr and  next_itm_sel then -- crossfade fade out, only if overlapping item is selected
		Set(itm, 'D_FADEOUTLEN_AUTO', fin-next_itm_pos) -- length is calculated according to the size of the overlap
		Set(itm, 'C_FADEOUTSHAPE', math.abs(XFADE.outshape))
		Set(itm, 'D_FADEOUTDIR', XFADE_PRESET and XFADE.outcurve or convert_curve_val(XFADE.outcurve))
		elseif ENABLE_FADEOUT and not midi_take and ( next_itm_tr ~= itm_tr or next_itm_tr == itm_tr and ( next_itm_pos >= fin or non_uniform_xfade_nxt) ) then -- regular fade-out only if the current item doesn't overlap the next item // covers cases where there's no next item
		Set(itm, non_uniform_xfade_nxt and 'D_FADEOUTLEN_AUTO' or 'D_FADEOUTLEN', math.abs(FADEOUT_LENGTH))
		Set(itm, 'C_FADEOUTSHAPE', math.abs(FADEOUT_SHAPE-1))
		Set(itm, 'D_FADEOUTDIR',convert_curve_val(FADEOUT_CURVE))
		fadeout_undo = 'fade-out'
		end

	r.UpdateItemInProject(itm)

	end


function concat(str1,str2)
return str1 and (str2 and str1..', ' or str1..' ') or ''
end

r.Undo_EndBlock('Apply '..concat(fadein_undo, fadeout_undo)..concat(fadeout_undo, xfade_undo)..concat(xfade_undo)..'to selected items', -1)



