--[[
ReaScript name: Scroll horizontally and/or move loop and/or time selection by user defined interval
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About:	Designed for either horizontal scrolling or moving loop
	or time selection by the custom increments set in the 
	USER SETTINGS either in seconds or in musical intervals.  

	Both functions can be combined so that loop and/or time
	selection are kept in view during scrolling.

	Besides the incerement defined in the USER SETTINGS,
	the script provides for an ad-hoc interval which overrides
	that setting for the duration of the REAPER session or until
	changed or cleared.   
	1) To call an ad-hoc interval creation dialogue move
	the mouse cursor to the upper left hand corner of your screen 
	on Windows (bottom left hand corner on MacOS) (whether REAPER 
	program window is fully open or not) and execute the script.  
	In the dialogue type in the new interval value in format explained  
	in the annotation to the INCREMENT setting of the USER SETTINGS, 
	and click 'OK'.  
	In the dialogue type in the new interval value in format explained  
	in the annotation to the INCREMENT setting of the USER SETTINGS, 
	and click 'OK'.  
	2) To clear an ad-hoc interval to be able to return to using
	the one defined in the INCREMENT setting, type in x or X 
	and click 'OK'.  

	Be aware that scrolling distance is not 100% precise
	because it's measured in pixels and conversion from time
	units such as seconds and musical intervals to pixels is
	always an approximation, but it's within the ballpark.
	The greater the zoom-in the more accurate the scrolling.

	To use effectively bind the script to the mousewheel.


	► M u s i c a l  i n t e r v a l s  s y n t a x  

	Syntax of supported straight and triplet musical intervals:   
	1/256, 1/192, 1/128, 1/96, 1/64, 1/48, 1/36, 1/24, 1/16, 1/12, 
	1/8, 1/6, 1/4, 1/3, 1/2, 1, 2 etc.

	The fraction numerator can be greater than 1, e.g. 10/16, 
	5/12, and greater than the denominator, which is useful when 
	an interval longer than 1 whole note is required, e.g.   
	3/2 is 1.5 notes, 5/2 is 2.5 notes, 
	4/3 is 1 + 1/3 notes (a whole + 1/2 triplet), 
	5/3 is 1 + 2/3 notes (a whole + two 1/2 triplets).

	Length of a dotted note is equivalent to the length of 3 notes 
	of a shorter duration, e.g. 1 dotted = 3/2, 1/2 dotted = 3/4, 
	1/4 dotted = 3/8 etc. To combine several dotted notes multiply 
	the nominator by the number of such notes, e.g. 
	9/2 = 3 dotted whole notes (3 x 3/2), 
	12/4 = 4 dotted half notes (4 x 3/4), 
	6/8 = 2 dotted quarter notes (2 x 3/8). 

	Appending dotted notes to whole notes:   
	1 whole note + 1/2 dotted = 4/4 + 3/4 = 7/4, 
	2 whole notes + three 1/16 dotted = 64/32 + 3 x 3/32 = 64/32 + 9/32 = 73/32.
		
]]

------------------------------------------------------------------
-------------------------- USER SETTINGS -------------------------
------------------------------------------------------------------

-- To enable, place any QWERTY character between
-- the quotation marks;
-- if you only need to move loop and/or time selection
-- by the INCREMENT amount, disable this setting
-- and only enable KEEP_LOOP_TIME_IN_VIEW below.
HORIZ_SCROLL = "1"

-- Either musical inretval (see 'Musical intervals syntax' paragraph
-- in About: section above) or seconds;
-- to indicate seconds, suffix the numeric value
-- with the letter s, regardless of the register,
-- e.g. "10s" or "3S";
-- the finer the value the greater the Arrange zoom-in
-- must be to ensure sufficient resolution,
-- if the resolution is too low no scrolling occurs
-- so the Arrange must be zoomed in (see AUTO_ZOOM_IN below);
-- if empty or 0 or is not a numeral, defaults to 1 beat (1/4).
INCREMENT = ""

-- If the INCREMENT setting above is fine and the Arrange
-- zoom-in level is low, the resolution might not
-- be sufficient to trigger scrolling;
-- enable this setting to automatically zoom in
-- until the resolution fits the INCREMENT setting;
-- to enable, place any QWERTY character between
-- the quotation marks;
-- only relevant if HORIZ_SCROLL setting is enabled above.
AUTO_ZOOM_IN = "1"

-- Enable to keep loop and/or time selection in view
-- while scrolling if HORIZ_SCROLL setting is enabled above
-- and if it's not, to move them along the timeline
-- by INCREMENT amounts;
-- 1 - to keep the loop; 2 - to keep time selection
-- 3 - to keep both;
-- any other numeral or character renders the setting disabled;
-- having started out within view, loop/time selection
-- cannot be moved beyond the visible portion of the timeline.
KEEP_LOOP_TIME_IN_VIEW = ""

-- The default mousewheel direction is:
-- upward movement scrolls rightwards,
-- downward movement scrolls leftwards;
-- enable to reverse;
-- to enable, place any QWERTY character between
-- the quotation marks.
REVERSE_MOUSEWHEEL_DIRECTION = ""


-------------------------------------------------------------------
----------------------- END OF USER SETTINGS ----------------------
-------------------------------------------------------------------


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


local r = reaper


function Music_Div_To_Sec(val)
local val = tonumber(val)
-- val is either integer (whole bars/notes) or quotient of a fraction x/x, i.e. 1/2, 1/3, 1/4, 2/6 etc
	if not val or val == 0 then return end
local tempo = r.Master_GetTempo()
return 60/tempo*4*val -- multiply crotchet's length by 4 to get full bar length and then multiply the result by the note division
end


function Validate_Value(INCREMENT) -- only returns positive value in sec or musical division
local num, denom = INCREMENT:match('^(%d+)/(%d+)')
	if not num then -- not fractional musical division
	local value = INCREMENT:match('^[%d%.]+')
		if tonumber(value) and tonumber(value) > 0 then return value
		end
	else
	return tonumber(num)/tonumber(denom)
	end
end


function round(num) -- if decimal part is greater than or equal to 0.5 round up else round down; rounds to the closest integer
	if math.floor(num) == num then return num end -- if number isn't decimal
return math.ceil(num) - num <= num - math.floor(num) and math.ceil(num) or math.floor(num)
end


function Error_Tooltip(text)
local x, y = r.GetMousePosition()
r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
end


-- Get 'val' to determine scroll direction
local is_new_value,filename,sectionID,cmdID,mode,resolution,val = r.get_action_context() -- if mouse scrolling up val = 15 - righwards, if down then val = -15 - leftwards


-- Evoke dialogue to allow the user to manage ad-hoc INCREMENT setting

	-- Validate INCREMENT setting before autofilling with it ad-hoc dialogue input field
local incr_default = INCREMENT:gsub(' ','')
local incr_default = (incr_default == '' -- empty
or incr_default:match('^[%D]+') -- no numerals
or incr_default:match('^.*/.*') and (incr_default:match('^0/') or incr_default:match('^.*/0[%D]')) -- 0 in the numerator or denominator
or incr_default:match('^[%d%.]*') and tonumber(incr_default:match('^[%d%.]*')) == 0 -- accounting for decimal numbers
)
and '1/4' -- fallback value
or incr_default


-- Manage ad-hoc increment setting

INCREMENT = #r.GetExtState(cmdID, 'INCREMENT') > 0 and r.GetExtState(cmdID, 'INCREMENT') or incr_default -- use either user ad-hoc setting or the one defined in the script // the dialogue input field will be autofilled with the stored ad-hoc setting

local x, y = r.GetMousePosition()

	if x <= 100 and y <= 100 then
	local retval, output = r.GetUserInputs('AD-HOC INCREMENT SETTING, default: '..incr_default, 1, 'extrawidth=25,Type in value ( musical or sec )', (INCREMENT ~= incr_default and INCREMENT or '')) -- only autofill if the value is different from the default set in the USER SETTINGS
	local output = output:gsub(' ','')
		if #output > 0 then
			if output:match('^[Xx]+') then -- remove ad-hoc INCREMENT setting to go back to the one defined in the script
			r.DeleteExtState(cmdID, 'INCREMENT', true) -- persist true
			else
			output = output:match('^[1-9/]+') and output or '1/4' -- if 0 or non-numeric input use default which is 1 beat
				if output ~= INCREMENT then -- only store if different from the default or previously stored ad-hoc INCREMENT setting
				r.SetExtState(cmdID, 'INCREMENT', output, false) -- store ad-hoc increment setting // persist false
				end
			end
		end
	return r.defer(function() do return end end) end


-- Validate variables
local SEC = INCREMENT:match('[%d%.]+[Ss]')
local VALUE = Validate_Value(INCREMENT)
HORIZ_SCROLL = Validate_Value(HORIZ_SCROLL)
AUTO_ZOOM_IN = #AUTO_ZOOM_IN:gsub(' ','') > 0
REVERSE_MOUSEWHEEL_DIRECTION = #REVERSE_MOUSEWHEEL_DIRECTION:gsub(' ','') > 0


-- Get current px per sec value

function Scroll_Distance(SEC, VALUE)
local px_per_sec = r.GetHZoomLevel()
return SEC and VALUE and px_per_sec*VALUE or -- seconds
VALUE and px_per_sec*Music_Div_To_Sec(VALUE) or -- musical interval
px_per_sec*Music_Div_To_Sec(1/4) -- empty, 0 or non-numeric input so it defaults to 1 beat
end

local scroll_distance_init = Scroll_Distance(SEC, VALUE)


-- Calculate pixels in the current INCREMENT value

local scroll_distance = not HORIZ_SCROLL and scroll_distance_init/r.GetHZoomLevel() -- when scrolling is not enabled use direct values instead of pixels to move loop/time selection in case KEEP_LOOP_TIME_IN_VIEW setting is enabled
or scroll_distance_init < 16 and 0 or round(scroll_distance_init/16) -- divided by 16 since it's the minimum possble horizontal scroll step supported by CSurf_OnScroll() function; minimum possble vertical scroll step is 8 px; each next integer adds 16 or 8 px respectively, so the input value is multiplied by 16 or by 8, e.g. x value 16 means 16 x 16 = 256 px and therefore must be offset through division by 16 // because of that precise scrolling by predefined interval is only possible when the scroll_distance_init value obtained in the first expression above is an exact multiple of 16, if it's not, which is always the case, then after division by 16 the result is rounded to the closest integer (since pixels cannot be fractional) as if scroll_distance_init were the exact multiple of 16, so this is were the imprecision comes from, the effective scroll_distance_init will always be several pixels either greater or lesser than the number it should be due to the need to conform to constraints imposed by CSurf_OnScroll() function; if scroll_distance_init value, obtained in the first expression above, is less than 16, meaning that there're less than the minimum 16 px in the INCREMENT value, then round down to 0 to be able to trigger auto zoom-in or a prompt to zoom in to have the Arrange zoom-in increased and hence the resolution.


----- Keep loop and time selection in view while scrolling ------------------
-- Placed before scroll function to allow loop and time selection slide into view one more time once the leftward scroll hits project start, because project start is used as a condition in Keep_Loop_Time_in_View() function to prevent any further shift when sctipt is run but no scrolling occurs


function Keep_Loop_Time_in_View(isLoop, scroll_distance, val, mousewheel_reverse, HORIZ_SCROLL) -- mousewheel_reverse is boolean // depends on r.get_action_context() for 'val' return value to determine shift direction

local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0) -- isSet false
local proj_time_offset = r.GetProjectTimeOffset(0, false) -- rndframe false
local st, fin = r.GetSet_LoopTimeRange(false, isLoop, 0, 0, false) -- isSet false, isLoop as selected, allowautoseek false

local dir
	if mousewheel_reverse then
	dir = val > 0 and -1 or val < 0 and 1 -- down - lefwards or up - righwards
	else
	dir = val > 0 and 1 or val < 0 and -1 -- down - righwards or up - lefwards
	end

local zoom_lev = r.GetHZoomLevel()
-- using scroll_distance var multiplied by 16 ensures that loop and time sel never drift as scrolling progresses being shifted by exactly as much as the timeline is shifted with scrolling, because when HORIZ_SCROLL is true scroll_distance_init is divided by 16 in the 'Calculate pixels in the current INCREMENT value' section
local st_new = HORIZ_SCROLL and st+scroll_distance*16/zoom_lev*dir or st+scroll_distance*dir -- use direct value instead of pixels if scrolling isn't enabled
local fin_new = HORIZ_SCROLL and fin+scroll_distance*16/zoom_lev*dir or fin+scroll_distance*dir -- same

	if HORIZ_SCROLL and start_time == proj_time_offset and not (mousewheel_reverse and val < 0 or val > 0) -- prevent loop and time sel shift once project start is reached while scrolling but allow when scrolling direction is rightwards, i.e. val is either positive or negatve if reversed with the REVERSE_MOUSEWHEEL_DIRECTION setting
	or scroll_distance == 0 -- if resolution is too low for the scroll by the INCREMENT value
	or not HORIZ_SCROLL and (st_new <= start_time or fin_new >= end_time) -- no scrolling and loop or time sel go beyond the visible portion of the timeline // while scrolling they can because of being eventually brought into view; without HORIZ_SCROLL condition they glitch out if close to the Arrange edges when the scrolling occurs
	then return end

r.GetSet_LoopTimeRange(true, isLoop, st_new, fin_new, false) --  isSet true, isLoop as selected, allowautoseek false

end

-- Validate settings

local is_integer = tonumber(KEEP_LOOP_TIME_IN_VIEW)
local loop = is_integer and tonumber(KEEP_LOOP_TIME_IN_VIEW) == 1.0
local time_sel = is_integer and tonumber(KEEP_LOOP_TIME_IN_VIEW) == 2.0
local loop_time = is_integer and tonumber(KEEP_LOOP_TIME_IN_VIEW) == 3.0

-- Move loop/time selection

local keep_loop_in_view = (loop or loop_time) and Keep_Loop_Time_in_View(true, scroll_distance, val, REVERSE_MOUSEWHEEL_DIRECTION, HORIZ_SCROLL) -- isLoop true
local keep_time_in_view = (time_sel or loop_time) and Keep_Loop_Time_in_View(false, scroll_distance, val, REVERSE_MOUSEWHEEL_DIRECTION, HORIZ_SCROLL) -- isLoop false // time selection

-------------------------------------------------------------

	if HORIZ_SCROLL then

	----- Auto-zoom in or prompt to zoom in ----------------

		if scroll_distance == 0 and AUTO_ZOOM_IN then -- INCREMENT setting is too fine for the current zoom amount (minimum possible for horizontal scroll is 16 px as per the limit of CSurf_OnScroll() function), so zoom in until it fits

		r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping) // centermode arg of adjustZoom() function is only known to support default setting of Preferences -> Editing Behavior -> Horizontal zoom center; what integer makes it hone in on the mouse cursor is not documented, hence the use of the edit cursor to point to the mouse cursor // overall seems to work with mouse cursor as the zoom center if either edit or mouse cursor are set in the Preferences, center view doesn't seem to work well with the routine

			repeat -- zoom in until the resolution is sufficient
			r.adjustZoom(5, 0, true, -1) -- amt, forceset, doupd, centermode // HORIZONTAL ZOOM ONLY // amt > 0 zooms in, < 0 zooms out, the greater the value the greater the zoom; forceset ~= 0 zooms out, if amt value is 1 then zooms out fully, if amt is greater then depends on the amt value but the relationship isn't clear, if bound to mousewheel, amt must be modified by val return value of get_action_context() function to change direction of the zoom, positive IN, negative OUT; doupd false no zoomming; centermode ?????
			-- forceset=0,doupd=true (do update),centermode=-1 for default
			until Scroll_Distance(SEC, VALUE) >= 16 -- minimum required for horizontal scroll in CSurf_OnScroll()

		elseif scroll_distance == 0 then
		Error_Tooltip('\n\n low resolution, zoom in. \n\n')
		end

		if REVERSE_MOUSEWHEEL_DIRECTION then
		dir = val > 0 and -1 or val < 0 and 1 -- down - lefwards or up - righwards
		else
		dir = val > 0 and 1 or val < 0 and -1 -- down - righwards or up - lefwards
		end


	r.CSurf_OnScroll(scroll_distance*dir, 0) -- y is 0, no vertical scrolling

	end


do return r.defer(function() do return end end) end -- prevent undo point creation




