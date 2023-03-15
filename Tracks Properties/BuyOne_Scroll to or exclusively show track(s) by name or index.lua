--[[
ReaScript name: Scroll to or exclusively show track(s) by name or index
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.1
Changelog: #Fixed search by search terms consisting of more than one word
	   #Fixed switching to exclusive display mode using list and range of track indices
	   #Ensured that, if selected by the user, folders uncollapse during search and not afterwards
	   #Added a setting to restore collapsed state of folders containing matching tracks skipped by the user
	   #Updated Guide
Licence: WTFPL
REAPER: at least v5.962
About:  G I U D E
		
	The script in essense does in its own way what the native Track Manager,
	the SWS extension Find utility, mpl_search tracks.lua, 
	X-Raym_Scroll vertically to track by name and select it.lua, 
	spk77_Track Tags.lua, tack_Select Track By Name.lua, 
	Lokasenna_Select tracks by name.lua scripts do. 
	In addition, besides track names track indices can be used to get to them.

	OPERATORS (the character case is irrelevant) 

	1. Search term modifiers: e, c, i

	no operator - Search track by elements contained in the track name

	e - (exact) Search by exact name; the operator covers syntax, scope of the track name
	and the register of its characters, so to satisfy the search the track name 
	must only consist of the search term and match its characters register; without 
	this operator any track name which contains all the elements of the search term 
	regardless of their order will be valid (see above)		

	c - (case) Ignore search term and track name register; can be enabled permanently 
	in the USER SETTINGS

	i - (index) Search track by index, the search term is interpreted as track 
	index hence only numerals are supported; ignored when the search term is a mix
	of alphabetic and numeric characters; if along with numerals the search term 
	contains alphabetic and/or punctuation characters 'i' operator is ignored; 
	combined with the exclusive display mode 'h' operator (see below) this operator 
	supports lists and ranges in the format: (for range) 1-5=ih or 5-1=ih, 
	and (for list) 1,3,5=ih, in this case if the search term containing a single 
	numeral is followed by a comma the operator will work; 'i' operator can be enabled 
	permanently in the USER SETTINGS

	2. Action operators: u, h, s

	u - (uncollapse) Uncollapse all collapsed parent tracks if the matching track 
	is inside a collapsed folder, including nested; doesn't apply to MCP, where 
	if track is inside collapsed folders its first uncollapsed parent track is the one 
	to be scrolled into view; can be enabled permanently in the USER SETTINGS as well
	as a setting to restore collapsed state of folders at the end of the search if
	their children tracks matched the search term but were skipped

	h - (hide) Hide all tracks bar those whose name/index matches the search term, 
	and if such track belongs to a folder then bar all its parents, children and siblings

	s - (show) Unhide all tracks hidden through the use of exclusive display mode
	'h' operator; this operator should not be preceded by '=' sign (see below) 
	but feature alone in the search field; to make the script ignore 's' character
	as an operatior and allow searching for 's' or 'S' characters in track names 
	add '=' sign after them

	3. Examples:

	If applied, operators must follow the search term and be separated from it 
	with the '=' sign, they can be combined, e.g.:

	ad-lib - scroll to a track whose name contains the word 'ad-lib';  
	background vox - scroll to a track whose name contains both words regardless
	of their order or presence of intervening elements;  
	10 - scroll to a track whose name contains numeral '10';   
	10=i - scroll to track No 10;  
	bass=ec - scroll to a track named exactly 'bass', disregarding the name's 
	register (case), so the name 'BASS' is also valid;  
	guitar=u - scroll to a track whose name contains the word 'guitar' and if 
	it's a child in a collapsed folder, uncollapse it;  
	12,35,44=hiu - exclusively show tracks No 12, 35 and 44 (including their folder 
	relatives, if any) and if any of them is a child in a collapsed folder, uncollapse it;  
	DRUMS=ch - exclusively show tracks whose names contain the word 'DRUMS' (including 
	their folder relatives, if any), disregarding the word's register (case) so names 
	containing 'drums' are also valid.

	The order in which the operators are combined and their register is immaterial.		

	In the TCP context (Arrange) the searched track is scrolled into view at the top 
	of the tracklist. In the MCP context it's scrolled to the leftmost position. 
	Contexts are enabled in the USER SETTINGS.

	If the searched track is inside a collapsed folder and 'u' operator isn't used, 
	then its first uncollapsed parent track is scrolled into view.

	If the found track is a folder child track, the track which ends up being selected 
	depends on the currently active context, TCP or MCP, because folder state which 
	the selection is conditioned by, in TCP and MCP may differ. If both contexts are active, 
	track selection in the TCP has priority. Since track selection is global it cannot be 
	different between the TCP and the MCP at the same time, so TCP has been chosen to be primary.

	If several track names match the search term, after the 1st one found is scrolled 
	into view the input dialogue reappears to allow continuing the search for the next 
	one. When the last such track has been found the search dialogue doesn't reappear.

	Unless 'e' (exact) operator is used all elements of a multi-word search term must 
	be present in a track name regardless of their order.

	EXCLUSIVE DISPLAY MODE

	'h' operator allows to selectively show tracks whose index or names match the search 
	term and the criteria set by the operators while keeping the rest hidden. To selectively 
	show tracks by their indices make sure to add 'i' operator to the 'h' operator, 
	i.e. 'ih' or 'hi'.

	When only TCP or MCP context is enabled in the USER SETTINGS only tracks in this context 
	will be hidden and unhidden.

	When tracks matching the search term are part of a folder, the entire folder they belong to 
	is shown, except for the tracks hidden prior to the application of the 'h' operator.

	When exclusive display mode is first activated the tracks matching the search term 
	do not scroll into view.

	When tracks are in exclusive display mode the search dialogue search field is autofilled 
	with 'h' perator showing that the mode is active. To be able to search tracks while in
	exclusive display mode remove the 'h' operator from the search field.

	To unhide all tracks hidden through the use of the 'h' run 's' operator alone.
		
]]

-----------------------------------------------------------------
-------------------------- USER SETTINGS -------------------------
------------------------------------------------------------------

-- TCP - 1, MCP - 2
-- both - empty or any other input;
-- if enabled the script will only affect tracks
-- in one of the contexts
CONTEXT = ""


-- To enable any of the following settings, place any QWERTY
-- character between the quotation marks.

-- Either enable this setting or use 'i' operator in the search field
-- when searching or exclusively showing tracks by indices;
-- if enabled, any numeral in the search term will be interpreted
-- as a track index rather than part of its name unless the search
-- term is a mix of alphanumeric characters.
INDEX = ""


-- Either enable this setting
-- or use 'c' operator in the search field when needed.
CASE_INSENSITIVE = ""


-- When the found track is inside a collapsed
-- folder and this setting is enabled, the folder
-- will be uncollapsed enough to reveal the track;
-- alternatively you can use 'u' operator in the search
-- field when needed;
-- otherwise the collapsed parent track of the found track
-- will be scrolled into view instead.
UNCOLLAPSE = ""


-- If any of the above 3 settings is enabled, the corresponding
-- operator character will be displayed capitalized in the legend
-- at the top of the search dialogue.


-- Restore collapsed state of the folders to which belong children
-- tracks matching the search term but which were skipped during search;
-- the folder of the last found track or the track at which search was
-- aborted won't be collapsed;
-- only relevant if UNCOLLAPSE setting is enabled
-- or if 'u' operator is used
RE_COLLAPSE = "1"

-------------------------------------------------------------------
----------------------- END OF USER SETTINGS ----------------------
-------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function Esc(str)
return str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
end


function validate_sett(sett) -- validate setting, can be either a non-empty string or any number
return type(sett) == 'string' and #sett:gsub(' ','') > 0 or type(sett) == 'number'
end


function round(num) -- if decimal part is greater than or equal to 0.5 round up else round down; rounds to the closest integer
	if math.floor(num) == num then return num end -- if number isn't decimal
return math.ceil(num) - num <= num - math.floor(num) and math.ceil(num) or math.floor(num)
end

function Error_Tooltip(text)
local x, y = r.GetMousePosition()
--r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
r.TrackCtl_SetToolTip(text, x, y, true) -- spaced out // topmost true
end

function Are_Tracks_Visible_TCP()
	for i = 0, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
	local retval, flags = r.GetTrackState(tr)
		if flags&512 ~= 512 then return true end-- visible in TCP
	end
end

	if not r.GetTrack(0,0) or not Are_Tracks_Visible_TCP() then Error_Tooltip(('\n\n no tracks in arrange \n\n'):upper():gsub('.','%0 '))
	return r.defer(function() do return end end) end


local function GetObjChunk(obj)
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua
		if not obj then return end
local tr = r.ValidatePtr(obj, 'MediaTrack*')
local item = r.ValidatePtr(obj, 'MediaItem*')
local env = r.ValidatePtr(obj, 'TrackEnvelope*') -- works for take envelope as well
  -- Try standard function -----
	local t = tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} -- isundo = false
	local ret, obj_chunk = table.unpack(t)
	-- OR
	-- local ret, obj_chunk = table.unpack(tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} or {x,x}) -- isundo = false
		if ret and obj_chunk and #obj_chunk >= 4194303 and not r.APIExists('SNM_CreateFastString') then return 'err_mess'
		elseif ret and obj_chunk and #obj_chunk < 4194303 then return ret, obj_chunk -- 4194303 bytes (4.194303 Mb) = (4096 kb * 1024 bytes) - 1 byte
		end
-- If chunk_size >= max_size, use wdl fast string --
	local fast_str = r.SNM_CreateFastString('')
		if r.SNM_GetSetObjectState(obj, fast_str, false, false) -- setnewvalue and wantminimalstate = false
		then obj_chunk = r.SNM_GetFastString(fast_str)
		end
	r.SNM_DeleteFastString(fast_str)
		if obj_chunk then return true, obj_chunk end
end


function Err_mess() -- if chunk size limit is exceeded and SWS extension isn't installed // U N U S E D

	local sws_ext_err_mess = "              The size of data requires\n\n     the SWS/S&M extension to handle them.\n\nIf it's installed then it needs to be updated.\n\n         After clicking \"OK\" a link to the\n\n SWS extension website will be provided\n\n\tThe script will now quit."
	local sws_ext_link = 'Get the SWS/S&M extension at\nhttps://www.sws-extension.org/\n\n'

	local resp = r.MB(sws_ext_err_mess,'ERROR',0)
		if resp == 1 then r.ShowConsoleMsg(sws_ext_link, r.ClearConsole()) return end
end


local function SetObjChunk(obj, obj_chunk) -- U N U S E D
	if not (obj and obj_chunk) then return end
local tr = r.ValidatePtr(obj, 'MediaTrack*')
local item = r.ValidatePtr(obj, 'MediaItem*')
local env = r.ValidatePtr(obj, 'TrackEnvelope*') -- works for take envelope as well
	return tr and r.SetTrackStateChunk(obj, obj_chunk, false) or item and r.SetItemStateChunk(obj, obj_chunk, false) or env and r.SetEnvelopeStateChunk(obj, obj_chunk, false) -- isundo is false
end


function Unhide_All(TCP, MCP, BOTH_CTX, clear_x_unhide) -- unhide all previosuly hidden with the script with 'h' operator // clear_x_unide is boolean to be able to avoid unhiding and clearing ext data when the function is used to determine whether the mode is exclusive track display in which case the dialogue input field is autofilled with =h operator

	for i = 0, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
	local name, flags = r.GetTrackState(tr)
		if (TCP or BOTH_CTX) and flags&512 == 512 then -- invisible in TCP -- OR r.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') == 0
		local retval, ext_data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:NEDDIH_PCT', '', false) -- setNewValue false // find if it was hidden with this script, NEDDIH_PCT = TCP_HIDDEN in reverse
			if retval and clear_x_unhide then --r.GetSetMediaTrackInfo_String(tr, P_EXT:NEDDIH_PCT', '', true) -- setNewValue true // delete ext data
			r.SetMediaTrackInfo_Value(tr, 'B_SHOWINTCP', 1) -- unhide in TCP
			elseif retval then return ext_data -- tracklist is in exclusive track display mode // when no ext data ext_data var is nil
			end
		end
		if (MCP or BOTH_CTX) and flags&1024 == 1024 then -- invisible in MCP -- OR r.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') == 0
		local retval, ext_data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:NEDDIH_PCM', '', false) -- setNewValue false // find if it was hidden with this script, NEDDIH_PCM = MCP_HIDDEN in reverse
			if retval and clear_x_unhide then
			r.SetMediaTrackInfo_Value(tr, 'B_SHOWINMIXER', 1) -- unhide in MCP
			elseif retval then return ext_data -- tracklist is in exclusive track display mode // when no ext data ext_data var is nil
			end
		end
		if clear_x_unhide then
		-- delete ext data from all, whether just unhidden or not, just in case the track was unhidden manually so its ext data didn't have a chance to be deleted by this script
		local del = (TCP or BOTH_CTX) and r.GetSetMediaTrackInfo_String(tr, 'P_EXT:NEDDIH_PCT', '', true) -- setNewValue true
		local del = (MCP or BOTH_CTX) and r.GetSetMediaTrackInfo_String(tr, 'P_EXT:NEDDIH_PCM', '', true) -- setNewValue true
		end
	end
r.TrackList_AdjustWindows(false) -- isMinor false - both TCP and MCP
end


function Get_Vis_TCP_Tracklist_Length_px(unhide, exclusive_track_display)
-- UNHIDING AND GETTING TRACKLIST LENGTH IN THE SAME FUNCTION DOESN'T WORK

	local function get_next_vis_track(cur_idx)
		for i = cur_idx, r.CountTracks(0)-1 do
		local tr = r.GetTrack(0,i)-- or master_vis and r.GetMasterTrack(0)
		local name, flags = r.GetTrackState(tr)
			if flags&512 ~= 512 then return tr end
		end
	end

local master_vis = r.GetMasterTrackVisibility()&1 -- in TCP // OR r.GetToggleCommandStateEx(0,40075) == 1 -- View: Toggle master track visible

local tracklist_len, topmost_vis_tr
--	for i = 0, r.CountTracks(0)-1 do
	for i = master_vis and -1 or 0, r.CountTracks(0)-1 do -- -1 to account for the Master track if visible in the TCP
	local tr = r.GetTrack(0,i) or master_vis and r.GetMasterTrack(0)
	local name, flags = r.GetTrackState(tr) -- reget the state after unhiding (if ever) to account for in the TCP length
		if flags&512 ~= 512 then -- visible in TCP -- OR r.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') == 1
		local tr_TCPY = r.GetMediaTrackInfo_Value(tr, 'I_TCPY')
			if not topmost_vis_tr and tr_TCPY + r.GetMediaTrackInfo_Value(tr, 'I_WNDH') >= 0 -- find 1st track whose TCP top is at 0 px or which crosses from negative (partially hidden from view at the top) to positive pixel value
			then
				if math.abs(tr_TCPY) < r.GetMediaTrackInfo_Value(tr, 'I_WNDH')/2 -- store the top track as long as its TCPY value is less than the half of its height + envelopes, i.e. sticks out of the Arrange top edge by at least half of its height + envelopes and if less, the next track will be stored and scrolled to; math.abs to account for negative TCPY value when part of a track is hidden at the top // store only once, as long as topmost_vis_tr is nil
				and (not (unhide and exclusive_track_display) or unhide and exclusive_track_display and i~=-1) -- accounting for cases of 's' operator usage while not in exclusive display mode and its usage while in exclusive display mode with Master track being the topmost visible to ensure that the topmost media track is kept at the top instead when all tracks are unhidden
				then
				topmost_vis_tr = tr
				else -- if the top track is hidden by more than half or when going out of the exclusive display mode with Master track visible, store the next track
				topmost_vis_tr = get_next_vis_track(i+1) or tr -- store only once as long as topmost_vis_tr is nil // accounting for a case where there's no next track
				end
			end
		tracklist_len = tr_TCPY + r.GetMediaTrackInfo_Value(tr, 'I_WNDH') -- incl envelopes // count
		end
	end

return tracklist_len, topmost_vis_tr

end


function Scroll_Track_To_Top(tr, parent_tr)
local tr = parent_tr or tr -- if uncollapse setting or operator aren't used 1st uncollapsed parent track will be scrolled to
local tr_y = r.GetMediaTrackInfo_Value(tr, 'I_TCPY')
local dir = tr_y < 0 and -1 or tr_y > 0 and 1 or 0 -- if less than 0 (out of sight above) the scroll must move up to bring the track into view, hence -1 and vice versa
r.PreventUIRefresh(1)
local cntr, Y_init = 0 -- to store track Y coordinate between loop cycles and monitor when the stored one equals to the one obtained after scrolling within the loop which will mean the scrolling can't continue due to reaching scroll limit when the track is close to the track list end or is the very last, otherwise the loop will become endless because there'll be no condition for it to stop
    repeat
    r.CSurf_OnScroll(0, dir) -- unit is 8 px
    local Y = r.GetMediaTrackInfo_Value(tr, 'I_TCPY')
		if Y ~= Y_init then Y_init = Y -- store
		else cntr = cntr+1
		end
    until not Y or dir > 0 and Y <= 0 or dir < 0 and Y >= 0 or cntr == 1 -- not Y if tr is invalid
r.PreventUIRefresh(-1)
end


function Re_Collapse_Tracks(t, next_name_t)
	if #t == 1 then return end -- length of the sett.PARENTS table being 1 at the end of the script routine means that either the only matching track was found or none was found, if its a child track prevent its folder from being re-collapsed below
	for k, tabl in ipairs(t) do
		for _, tr in ipairs(tabl) do
		r.SetMediaTrackInfo_Value(tr, 'I_FOLDERCOMPACT', 2) -- tiny children
		end
	local stop_idx = next_name_t and #t-1 or #t-2 -- when user aborts search deliberately (next_name_t is true) the folder of the last found track must be ignored to keep it open after aborting the search hence stoppage at index preceding the one contianing its parent tracks which is the very last, but if the search proceeds until no macthing track is found (next_name_t is false) the last field in the table t (sett.PARENTS) which is returned by Get_Found_Track_Height() function will be nil while the last valid field which contains parents of the last found matching track will be at the 2nd index from the table end, hence stoppage before that to keep the folders of the last found track open
		if k == stop_idx then break end -- do not re-collapse last open folders since it's when the user stopped the search // table.remove(next_name_t and #t or #t-1) could be used before the loop instead
	end
end


::RESTART:: -- reload the search dialogue

local numeral = tonumber(CONTEXT)
TCP = numeral and tonumber(CONTEXT) == 1.0 or not numeral
MCP = numeral and tonumber(CONTEXT) == 2.0 or not numeral
BOTH_CTX = TCP and MCP
local ctx = TCP and MCP and 'TMCP' or TCP and 'TCP' or MCP and 'MCP' -- to display in the dialogie ribbon

sett = sett or {} -- to retain the settings within RESTART loop for display in the search dialogue, because the variables are overwritten downstream // only initialized when nil, otherwise keep in RESTART loop
sett.INDEX = validate_sett(INDEX) or sett.INDEX -- 2nd option is for RESTART loop to retain the USER SETTINGS since they're not covered by the loop scope and end up being nil
sett.CASE_INSENSITIVE = validate_sett(CASE_INSENSITIVE) or sett.CASE_INSENSITIVE -- same
sett.UNCOLLAPSE = validate_sett(UNCOLLAPSE) or sett.UNCOLLAPSE -- same
sett.RE_COLLAPSE = validate_sett(RE_COLLAPSE) or sett.RE_COLLAPSE -- same
sett.PARENTS = sett.PARENTS or {} -- to store parent tracks of collapsed folders to re-collapse them if RE_COLLAPSE setting is enabled


function capitalize(sett, str)
return sett and str:upper() or str
end

local exclusive_track_display = Unhide_All(TCP, MCP, BOTH_CTX, false) -- clear_x_unhide false, only evaluate if there're hidden tracks with ext data

local next_tr_idx = next_name_t and next_name_t[2] -- must be placed here as after submitting GetUserInputs() the variable gets reset, probably because the script is restarted
local prev_output = next_name_t and next_name_t[1]

local retval, output_orig = r.GetUserInputs('Contxt: '..(ctx)..'  (indx: ='..capitalize(sett.INDEX,'i')..' ; exct: e ; case insens: '..capitalize(sett.CASE_INSENSITIVE,'c')..' ; uncollps: '..capitalize(sett.UNCOLLAPSE,'u')..' ; hide: h ; show all: s)', 1, 'extrawidth=240,Type in name or numeric index:', next_name_t and next_name_t[1] or exclusive_track_display and '=h' or '') -- autofilling with the original search term if the dialogue is reloaded or with the =h operator if in exclusive track display mode // the operators are capitalized for consistency because user may enter characters in any register

	if not retval or #output_orig:gsub(' ', '') == 0 then
		if UNCOLLAPSE and sett.RE_COLLAPSE then
		Re_Collapse_Tracks(sett.PARENTS, next_name_t) -- next_name_t arg makes sure that the folders of the last found track stay open when the search is finished whether another matching track exists or not
		local jump = found_tr and Scroll_Track_To_Top(found_tr)-- repeat scrolling to the last found track because after collapse track list height changes due to shrinking and the found track goes out of sight
		end
	return r.defer(function() do return end end) end

	if output_orig ~= prev_output then next_tr_idx = nil end -- if, after the search dialogue had been reloaded, the user changed the search term, reset the variable of the next track index stored to resume the search from, so the search starts from the beginning as normal


local operators = output_orig:match('^.+=(.+)')
local index = operators and operators:match('[Ii]+') -- track index
local exact = operators and operators:match('[Ee]+') -- name strict match
local uncollapse = operators and operators:match('[Uu]+')
local case_insens = operators and operators:match('[Cc]+')
local hide = operators and operators:match('[Hh]+')
local unhide = output_orig:lower():gsub(' ',''):match('.+') == 's'
local output = output_orig:match('^(.+)=') or output_orig -- keep output and output_orig separated so that output_orig can be reused for autofilling the reloaded search dialogue with full search string including operators when another track with a matching name is found

	if hide or unhide then
	tracklist_len, topmost_vis_tr = table.unpack((TCP or BOTH_CTX) and {Get_Vis_TCP_Tracklist_Length_px(unhide, exclusive_track_display)} or {nil}) --- tracklist_len is used to scroll the tracklist all the way up when going into the exclusive display mode with 'h' operator because otherwise it ends up scrolled all the way down; topmost_vis_tr is needed to be able, when exiting the exclusive display mode with 's' operator, to restore scroll state // MUST COME BEFORE Unhide_All() to get the top track in case of exiting the exclusive display mode to be able to restore its scroll position in the unhidden tracklist
	leftmost_vis_tr = (MCP or BOTH_CTX) and r.GetMixerScroll() -- to restore Mixer scroll state when going out of the exclusive display mode
	end


local show_all = exclusive_track_display and unhide and Unhide_All(TCP, MCP, BOTH_CTX, true) -- if no =h operator unhide all that where hidden before // clear_x_unhide true

INDEX = (validate_sett(INDEX) or index or sett.INDEX) and not output:match('%a+') -- either enabled default setting, 'i' operator in the user input or default setting within RESTART loop // only if the search term isn't a mix of alphabetic, punctuation and numeric characters and doesn't only contain spaces
CASE_INSENSITIVE = validate_sett(CASE_INSENSITIVE) or case_insens or sett.CASE_INSENSITIVE -- either enabled default setting or 'c' operator in the user input or default setting within RESTART loop
UNCOLLAPSE = validate_sett(UNCOLLAPSE) or uncollapse or sett.UNCOLLAPSE -- either enabled default setting or 'u' operator in the user input or default setting within RESTART loop

local output = CASE_INSENSITIVE and output:lower() or output

local output = unhide and '' or output:match('^%s*(.-)%s*$') or output:match('[%w%p]+') -- if 's' (unhide) operator is used, prevent search for 's' character; strip off empty spaces, last option when the search term is 1 character long

	if hide or unhide then r.Undo_BeginBlock() end -- scroll position isn't stored in undo history but track visibility is


function Get_Found_Track_Height(start_idx, output, output_orig, INDEX, exact, CASE_INSENSITIVE, UNCOLLAPSE, TCP, MCP, BOTH_CTX)

	if #output == 0 then return end -- true when 's' (unhide) operator is applied

	local function validate_name(output, tr_name)
	local cnt = 0
	local truth_cnt = 0
		for w in output:gmatch('[%w%p]+') do
			if w then cnt = cnt+1 end
			if tr_name:match(Esc(w)) then truth_cnt = truth_cnt+1 end
		end
	return cnt > 0 and cnt == truth_cnt -- all words/punctuation marks of the search term found in the track name; preventing equality of zeros
	end

	local function get_last_TCP_uncollapsed_parent(child_idx, child_tr, t) -- t is a table // last uncollapsed means that the parent itself isn't collapsed inside the folder it belongs to, unless it's the topmost level parent of the entire folder which cannot be collapsed, this is equal to the parent of the 1st/topmost (sub)folder whose child tracks are collapsed
		for i = child_idx, 0, -1 do -- in reverse
		local tr = r.GetTrack(0,i)
			if tr == r.GetParentTrack(child_tr) then
				if r.GetMediaTrackInfo_Value(tr, 'I_FOLDERCOMPACT') == 2 -- parent track whose child tracks are fully collapsed // only valid for folders
				then
				t[#t+1] = tr
				end
			get_last_TCP_uncollapsed_parent(i, tr, t) -- go recursive, using current parent as a child to find its own parent, if any, and so on
			end
		end
	return t, t[#t] -- return table to use for uncollapsing and the last uncollapsed track which ends up being the very last in the table
	end

	local function uncollapse_parents_in_TCP(t)
		for _, tr in ipairs(t) do
		r.SetMediaTrackInfo_Value(tr, 'I_FOLDERCOMPACT', 1) -- 1 small
		end
	end

	local function get_next_name(start_idx, output, exact, CASE_INSENSITIVE, TCP, MCP, BOTH_CTX)
		for i = start_idx+1, r.CountTracks(0)-1 do -- start search from the next track
		local tr = r.GetTrack(0,i)
		local name, flags = r.GetTrackState(tr)
		local name = CASE_INSENSITIVE and name:lower() or name
		local vis_TCP, vis_MCP = (TCP or BOTH_CTX) and flags&512 ~= 512, (MCP or BOTH_CTX) and flags&1024 ~= 1024
			if (vis_TCP or vis_MCP) and #name:gsub(' ','') > 0 then
				if exact and name:match('^%s*('..Esc(output)..')%s*$') -- exact name match
				or not exact and validate_name(output, name)--name:match(Esc(output)) -- word match // must be conditioned with 'not exact' to prevent it being true when exact is false and the name happens to contain the search term
				then return true
				end
			end
		end
	end

	for i = start_idx, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
	local name, flags = r.GetTrackState(tr)
	local name = CASE_INSENSITIVE and name:lower() or name
	local vis_TCP, vis_MCP = (TCP or BOTH_CTX) and flags&512 ~= 512, (MCP or BOTH_CTX) and flags&1024 ~= 1024
		if vis_TCP or vis_MCP then
			if INDEX and tonumber(output) == i+1 -- index matches
			or exact and name:match('^%s*('..Esc(output)..')%s*$') -- exact name match
			or not exact and validate_name(output, name) -- word match // must be conditioned with 'not exact' to prevent it being true when exact is false and the name happens to contain the search term
			then
			-- Look for another track with the same name to condition reloading of the search dialogue
			local next_name = not INDEX and get_next_name(i, output, exact, CASE_INSENSITIVE, TCP, MCP, BOTH_CTX) -- start_idx = i
			local next_name_t = next_name and {output_orig, i+1} -- store values for the next run of the search after the dialogue has been reloaded // +1 so the next search starts from the next track; store output_orig to autofull the dialogue with the original search string incl. operators
			local collapsed_folder_parents_t, uncollapsed_parent_tr = get_last_TCP_uncollapsed_parent(i, tr, {}) -- child_idx = i, child_tr = tr, table is to store the topmost uncollapsed parent
			-- if several tracks match the search term in the folder the last or its parent (if the track is collapsed) will be selected
				if uncollapsed_parent_tr and not UNCOLLAPSE then -- topmost uncollapsed parent will be returned, selected and scrolled to
				r.SetOnlyTrackSelected(uncollapsed_parent_tr, true) -- selected true
				return tr, next_name_t, collapsed_folder_parents_t, uncollapsed_parent_tr
				else -- the actual track, child or not, will be returned, selected and scrolled to
					if UNCOLLAPSE then uncollapse_parents_in_TCP(collapsed_folder_parents_t) end -- parent tracks will be uncollapsed if chosen by the user, if the table is empty nothing will happen
				r.SetOnlyTrackSelected(tr, true) -- selected true
				return tr, next_name_t, collapsed_folder_parents_t
				end
			end
		end
	end

end


function Show_Hide(output, INDEX, exact, CASE_INSENSITIVE, UNCOLLAPSE, cmdID, TCP, MCP, BOTH_CTX) -- run when -h (hide) operator is used

	local function get_index_from_range_or_list(output, tr_idx)
	local min, max = output:match('(%d+)%s*%-%s*(%d+)') -- the syntax is X-X // range
		if (min and max)
		and (tr_idx >= min+0 and max+0 >= tr_idx or tr_idx >= max+0 and min+0 >= tr_idx) -- range // +0 converts string to number to match num data type // allows reversed ranges, e.g. 10 - 1
		then return true
		elseif output:match('%d+,') then -- list // additional condition to prevent falling back on this routine when previous expression returns nils, because this will return true at least once since in the list the 1st numeral will always be found
			for idx in output:gmatch('%d+') do -- list
				if tonumber(idx) == tr_idx then return true end
			end
		end
	end

	local function validate_name(output, tr_name)
	local cnt = 0
	local truth_cnt = 0
		for w in output:gmatch('[%w%p]+') do
			if w then cnt = cnt+1 end
			if tr_name:match(Esc(w)) then truth_cnt = truth_cnt+1 end
		end
	return cnt > 0 and cnt == truth_cnt -- all words/punctuation marks of the search term found in the track name; preventing equality of zeros
	end

	local function get_last_uncollapsed_parent(child_idx, child_tr, t, tcp) -- t is a table; tcp is boolean to activate either the tcp or the mcp routine // last uncollapsed means that the parent itself isn't collapsed inside the folder it belongs to, unless it's the topmost level parent of the entire folder which cannot be collapsed, this is equal to the parent of the 1st/topmost (sub)folder whose child tracks are collapsed
		if tcp then -- get in the TCP and store all parents of the found track
			for i = child_idx, 0, -1 do -- in reverse
			local tr = r.GetTrack(0,i)
				if tr == r.GetParentTrack(child_tr) then
					if r.GetMediaTrackInfo_Value(tr, 'I_FOLDERCOMPACT') == 2 -- parent track whose child tracks are fully collapsed // only valid for folders
					then
					t[#t+1] = tr
					end
				get_last_uncollapsed_parent(i, tr, t, tcp) -- go recursive, using current parent as a child to find its own parent, if any, and so on
				end
			end
		return t[#t], t -- return last uncollapsed track which ends up being the very last and the table to use for uncollapsing

		else -- search the leftmost uncollapsed parent in the MCP, if any, to select it if the context is not TCP (not TCP cond is applied outside of the function

		-- Collect all parents of the track to then find the last (rightmost) uncollapsed if any // uncollapsed means that the parent itself isn't collapsed inside the folder it belongs to, unless it's the topmost level parent of the entire folder which cannot be collapsed, this is equal to the parent of the leftmost (sub)folder whose child tracks are collapsed
		local parent = r.GetParentTrack(child_tr)
			for i = child_idx, 0, -1 do -- in reverse
			local tr = r.GetTrack(0,i)
				if tr == parent then
				t[#t+1] = tr -- in the table the leftmost track is at the end
				parent = r.GetParentTrack(tr)
				end
			end
			-- Find the leftmost collapsed parent, if any
			for i = #t, 1, -1 do -- in reverse since parent tracks were stored from right to left; if the table is empty the loop won't start
			local tr = t[i]
			local ret, chunk = GetObjChunk(tr)
				if ret ~= 'err_mess' -- if parent track chunk is larger than 4.194303 Mb and no SWS extension to handle that to find out if it's collapsed
				and chunk:match('BUSCOMP %d (%d)') == '1' then -- child tracks are collapsed
				return tr -- as soon as parent with collapsed children is found; since the parents are traversed from the left, first parent with collapsed children means that lower level parents are all collapsed and are unsuitable for selection
				end
			end
		end

	end

	local function uncollapse_TCP_parents(t)
		for _, tr in ipairs(t) do
		r.SetMediaTrackInfo_Value(tr, 'I_FOLDERCOMPACT', 1) -- 1 small
		end
	end

	local function show_track_and_relatives(found_tr_idx, found_tr, TCP, MCP, BOTH_CTX, UNCOLLAPSE)
	local topmost_parent = r.GetTrackDepth(found_tr) == 0
	-- Get the last track in the folder the child belongs to
	local last_child_idx
	local cntr = 0 -- keep track of track indices to find the last child if it's the last track in the entire tracklist in which case the loop produces nil
		for i = found_tr_idx, r.CountTracks(0)-1 do
		cntr = i
		local tr = r.GetTrack(0,i)
			if not topmost_parent and r.GetTrackDepth(tr) == 0 -- first track outside of the folder, if the found_tr is not already the topmost parent, otherwise it's the topmost parent index which will be assigned here and the loop will exit pre-emptively
			or topmost_parent and r.GetTrackDepth(tr) == 0 and i > found_tr_idx -- if the found_tr is the topmost parent exit as soon as the 1st non-child track is found, meaning the folder hasended
			then last_child_idx = i-1 break end
		end
		if not last_child_idx then last_child_idx = cntr end -- the last child was the last in the entire tracklist

		local start, fin, dir = table.unpack(not topmost_parent and {last_child_idx, 0, -1} or {found_tr_idx, last_child_idx, 1}) -- if found_tr is not the topmost parent iterate in reverse, otherwise directly

	-- Unhide all siblings and parents which were just hidden (contain ext data), optionally uncollapsing
		for i = start, fin, dir do
		local tr = r.GetTrack(0,i)
		local has_parent = r.GetParentTrack(tr)
		local tcp_retval, ext_data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:NEDDIH_PCT', '', false) -- setNewValue false
		local mcp_retval, ext_data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:NEDDIH_PCM', '', false) -- setNewValue false
			-- Unhide
			if (TCP or BOTH_CTX) and tcp_retval then -- there's extended data, i.e. was just hidden, so unhide (any relative)
			r.GetSetMediaTrackInfo_String(tr, 'P_EXT:NEDDIH_PCT', '', true) -- setNewValue true // delete ext data
			r.SetMediaTrackInfo_Value(tr, 'B_SHOWINTCP', 1) -- show in TCP
			end
			if (MCP or BOTH_CTX) and mcp_retval then -- there's extended data, i.e. was just hidden, so unhide (any relative)
			r.GetSetMediaTrackInfo_String(tr, 'P_EXT:NEDDIH_PCM', '', true) -- setNewValue true // delete ext data
			r.SetMediaTrackInfo_Value(tr, 'B_SHOWINMIXER', 1) -- show in MCP
			end
			-- Uncollapse TCP folders, select tracks in TCP and MCP
			if tr == found_tr and has_parent then
			-- if several tracks match the search term in the folder the last or its parent (if the track is collapsed) will be selected
				if TCP or BOTH_CTX then
				local uncollapsed_parent_tr, collapsed_folder_parents_t = get_last_uncollapsed_parent(i, tr, {}, true) -- child_idx = i, child_tr = tr, table is to store the topmost uncollapsed parent for TCP context, tcp is true
					if uncollapsed_parent_tr and not UNCOLLAPSE then
					r.SetOnlyTrackSelected(uncollapsed_parent_tr, true) -- selected true // if not UNCOLLAPSE select first uncollapsed parent // if there're other tracks mathings the search term they might end up being selected instead and not a particular child or its parents
					else -- select the actual search matching track
						if UNCOLLAPSE then uncollapse_TCP_parents(collapsed_folder_parents_t) end -- parent tracks will be uncollapsed if chosen by the user, if the table is empty nothing will happen
					r.SetOnlyTrackSelected(tr, true) -- selected true // if there're other tracks matching the search term their exclusive selection might override this track selection or that of its parents
					end
				elseif MCP and not TCP then -- only select the matching track or its uncollapsed parent in MCP if TCP context isn't active, otherwise TCP it's the primary selection target
				local uncollapsed_parent_tr = get_last_uncollapsed_parent(i, tr, {}, tcp) -- child_idx = i, child_tr = tr, table is to temprarily store found parent tracks (with MCP isn't really necessary as it can be initialized inside, tcp is false. i.e. run MCP routine
				r.SetOnlyTrackSelected(uncollapsed_parent_tr or found_tr, true) -- if no parent with collapsed children is found select track which matches the search term
				end
			elseif tr == found_tr then
			r.SetOnlyTrackSelected(found_tr, true)
			end
			-- Exit
			if not topmost_parent and r.GetTrackDepth(tr) == 0 -- the folder's topmost parent, i.e. end of the folder, if the found_tr is not already the topmost parent and iteration is done in reverse, otherwise the condition would be true as soon as the loop starts so it will be exited pre-emptively; if the found_tr is the topmost paret the loop will exit naturally at the last child track
			then break end
		end
	end

-- Determine the tracklist state, whether it's been affected by the =h operator or not to decide whether to condition track search in the next loop with presence of the ext data // when tracks have been hidden ext data condition is necessary to avoid unhiding tracks hidden previously by the user if they happen to match the search term // when tracks are unhidden with this script the ext data is deleted and when hiding tracks of the fully unhidden tracklist the ext data won't be present and the condition will be false, preventing the routine

local is_hidden_on

		for i = 0, r.CountTracks(0)-1 do
		local tr = r.GetTrack(0,i)
		-- for TCP and MCP contexts separate ext data is required to be able to accurately unhide tracks from one context when ext data has been cleared for the other; P_EXT param name must also differ because clearing affects all data associated with the parameter; using fixed P_EXT param for each context so it's the same across all copies of the script, the ext data isn't piled up and script copies always search for the same type of ext data: NEDDIH_PCT = TCP_HIDDEN, NEDDIH_PCM = MCP_HIDDEN in reverse
		local tcp_retval, tcp_ext_data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:NEDDIH_PCT', '', false) -- setNewValue false
		local mcp_retval, mcp_ext_data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:NEDDIH_PCM', '', false) -- setNewValue false
			if (TCP or BOTH_CTX) and tcp_retval
			or (MCP or BOTH_CTX) and mcp_retval
			then
			is_hidden_on = 1 break end
		end

-- Find if there're matching tracks and store in a table
local found_tr_t = {}

	for i = 0, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
	local name, flags = r.GetTrackState(tr)
	local tcp_retval, ext_data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:NEDDIH_PCT', '', false) -- setNewValue false
	local mcp_retval, ext_data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:NEDDIH_PCM', '', false) -- setNewValue false
	local name = CASE_INSENSITIVE and name:lower() or name
		if ((is_hidden_on and (tcp_retval or mcp_retval)) -- temporarily hidden tracks contain ext data
		or (not tcp_retval and flags&512 ~= 512 -- either there's ext data because exclusive display mode has been applied or there's no ext data because all are visible in the TCP
		or not mcp_retval and flags&1024 ~= 1024))
		and (INDEX and ( tonumber(output) and tonumber(output) == i+1 or get_index_from_range_or_list(output, i+1) ) -- index matches or indices match
		or exact and name:match('^%s*('..Esc(output)..')%s*$') -- exact name match
		or not exact and --name:match(Esc(output)) )
		validate_name(output, name) ) -- word match // must be conditioned with 'not exact' to prevent it being true when exact is false and the name happens to contain the search term
		then
		found_tr_t[i] = tr
		end
	end

	if next(found_tr_t) then -- the table isn't empty, i.e. some tracks were found

		-- Hide all from TCP/MCP and add ext data
		for i = 0, r.CountTracks(0)-1 do
		local tr = r.GetTrack(0,i)
		local name, flags = r.GetTrackState(tr)
			if (TCP or BOTH_CTX) and flags&512 ~= 512 then -- visible in TCP // OR r.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') == 1
			r.GetSetMediaTrackInfo_String(tr, 'P_EXT:NEDDIH_PCT', '.', true) -- setNewValue true // add ext data
			r.SetMediaTrackInfo_Value(tr, 'B_SHOWINTCP', 0) -- hide from TCP
			end
			if (MCP or BOTH_CTX) and flags&1024 ~= 1024 then -- visible in MCP // OR r.GetMediaTrackInfo_Value(tr, 'B_SHOWINMIXER') == 1
			r.GetSetMediaTrackInfo_String(tr, 'P_EXT:NEDDIH_PCM', '.', true) -- setNewValue true // add ext data
			r.SetMediaTrackInfo_Value(tr, 'B_SHOWINMIXER', 0) -- hide from MCP
			end
		end

		-- Unhide those which match the search term and contain ext data added above with their parents, children and siblings which contain the ext data and delete their ext data

			for found_tr_idx, found_tr in pairs(found_tr_t) do -- pairs instead of ipairs because the table isn't indexed sequentially, as table indices track indices are stored
				if r.GetParentTrack(found_tr) -- if track is a child // the track will be treated within the show_track_and relatives() function
				or ({r.GetTrackState(found_tr)})[2]&1 == 1 -- OR r.GetMediaTrackInfo_Value(found_tr, 'I_FOLDERDEPTH') == 1
				and r.GetTrackDepth(found_tr) == 0 -- topmost folder parent, in case it's the topmost parent track
				then
				show_track_and_relatives(found_tr_idx, found_tr, TCP, MCP, BOTH_CTX, UNCOLLAPSE) -- uncollapsing in TCP if needed and selecting in MCP if needed
				else -- not a child track
					if TCP or BOTH_CTX then
					r.GetSetMediaTrackInfo_String(found_tr, 'P_EXT:NEDDIH_PCT', '', true) -- setNewValue true // delete ext data
					r.SetMediaTrackInfo_Value(found_tr, 'B_SHOWINTCP', 1) -- show in TCP
					r.SetOnlyTrackSelected(found_tr, true) -- selected true
					end
					if MCP or BOTH_CTX then
					r.GetSetMediaTrackInfo_String(found_tr, 'P_EXT:NEDDIH_PCM', '', true) -- setNewValue true // delete ext data
					r.SetMediaTrackInfo_Value(found_tr, 'B_SHOWINMIXER', 1) -- show in MCP
					local select = not TCP and r.SetOnlyTrackSelected(found_tr, true) -- selected true // only select if TCP context isn't active, otherwise it's the primary one for selection, because selection cannot differ between TCP and MCP
					end
				end
			end
	return true

	else -- tracks weren't found, the table is empty

	Error_Tooltip(('\n\n track '..(INDEX and '#' or 'name ')):upper():gsub('.','%0 ')..'"'..output..('"\n\n was not found \n\n'):upper():gsub('.','%0 '))

		if not is_hidden_on then return false end -- to condition restoration of the scroll state outside of the function

	end


end


	if hide then

	local ok = Show_Hide(output, INDEX, exact, CASE_INSENSITIVE, UNCOLLAPSE, cmdID, TCP, MCP, BOTH_CTX)
		if ok then -- 'h' operator and searched tracks were found
		local scroll_tcp = (TCP or BOTH_CTX) and r.CSurf_OnScroll(0, tracklist_len*-1) -- scroll the tracklist all the way up, without division by 8, to the very start to then be able to scroll down from 0 (I_TCPY value of the 1st visible track) searching for a specific track, otherwise the tracklist ends up being scrolled all the way down
		end

	else

	local len = #sett.PARENTS+1
	found_tr, next_name_t, sett.PARENTS[len], uncollapsed_parent_tr = Get_Found_Track_Height(next_tr_idx or 0, output, output_orig, INDEX, exact, CASE_INSENSITIVE, UNCOLLAPSE, TCP, MCP, BOTH_CTX) -- vals must be GLOBAL for the sake of next_name_t so the reloaded search dialogue can be autofilled with original output string stored in its 1st field and for other vars to remain valid within RESTART loop

	-- Scroll in TCP
	local jump = found_tr and Scroll_Track_To_Top(found_tr, uncollapsed_parent_tr)

		-- Scroll in MCP
		if found_tr and (MCP or BOTH_CTX) then -- scroll the found track to the leftmost position in the Mixer
		-- Collect all parents of the found track to then find the first (leftmost) uncollapsed if any
		local parent = r.GetParentTrack(found_tr)
		local parents_t = {}
			for i = r.CSurf_TrackToID(found_tr, false)-2, 0, -1 do -- in reverse // mcpView false, use even if it's hidden in a collapsed folder // -2 to start from immediatedly preceding track
			local tr = r.GetTrack(0,i)
				if tr == parent then -- and itself has a parent
				parents_t[#parents_t+1] = tr -- in the table the leftmost track is at the end
				parent = r.GetParentTrack(tr)
				end
			end
			-- Find the leftmost uncollapsed parent, if any ((un)collapsing Mixer tracks must be done via chunk which is too cumbersome and isn't worth the effort for this script)
			for i = #parents_t, 1, -1 do -- in reverse since parent tracks were stored from right to left; if the table is empty the loop won't start
			local parent_tr = parents_t[i]
			local ret, chunk = GetObjChunk(parent_tr)
				if ret ~= 'err_mess' -- if parent track chunk is larger than 4.194303 Mb and no SWS extension to handle that to find out if it's collapsed
				and chunk:match('BUSCOMP %d (%d)') == '1' then -- collapsed
				found_tr = parent_tr
				break end -- as soon as uncollapsed parent is found
			end
			if MCP and not TCP then r.SetOnlyTrackSelected(found_tr, true) end -- if TCP context isn't engaged select the track in the Mixer, otherwise TCP is the primary selection target; since folder state in MCP is independent of the TCP the track needed selection in the MCP might differ from that in the TCP // if several tracks match the search term in the folder the last or its parent (if the track is collapsed) will be selected

		r.SetMixerScroll(found_tr)

		end

		if next_name_t then -- if next track with the same name wasn't found the table var will be nil, if it was, reload the search dialogue
		restart = true -- to condition no error message when track isn't found at the end of a RESTART loop
		goto RESTART
		end

	--	if not found_tr then -- if track name or index aren't found or 's' operator is used restore track list to scroll position prior to scrolling it all the way up
		if unhide and exclusive_track_display then
			if TCP or BOTH_CTX then -- if TCP context is active in the settings, restore scroll position
			local topmost_vis_tr_I_TCPY = r.GetMediaTrackInfo_Value(topmost_vis_tr, 'I_TCPY') -- - r.GetMediaTrackInfo_Value(topmost_vis_tr, 'I_WNDH')
			-- - (topmost_vis_tr_TCPY > 0 and r.GetMediaTrackInfo_Value(topmost_vis_tr, 'I_WNDH') or 0)
			r.CSurf_OnScroll(0, round(topmost_vis_tr_I_TCPY/8))
			end
			if (MCP or BOTH_CTX) and exclusive_track_display and leftmost_vis_tr then -- restore Mixer scroll position when going out of exclusive display mode
			r.SetMixerScroll(leftmost_vis_tr)
			end
		elseif not found_tr and not unhide and not restart then -- do not display error mess when 's' (unhide) operator is used (it's unlikely to be used as a track name but will trigger the error mess every time) and when restart loop is active so it's not displayed when the loop has reached the last matching track, i.e. no next is found
		Error_Tooltip(('\n\n track '..(INDEX and '#' or 'name ')):upper():gsub('.','%0 ')..'"'..output..('"\n\n was not found \n\n'):upper():gsub('.','%0 '))
		end

	end


	if UNCOLLAPSE and sett.RE_COLLAPSE then
	Re_Collapse_Tracks(sett.PARENTS, next_name_t) -- next_name_t arg makes sure that the folders of the last found track stay open when the search is finished whether another matching track exists or not
	local jump = found_tr and Scroll_Track_To_Top(found_tr)-- repeat scrolling to the last found track because after collapse track list height changes due to shrinking and the found track goes out of sight
	end


r.TrackList_AdjustWindows(false) -- isMinor false - both TCP and MCP

local undo = hide and 'Exclusively show track(s) '..(INDEX and '# ' or 'containing «')..output..(not INDEX and '»' or '') or unhide and 'Unhide previously hidden tracks' --or undo == '' and undo or 'Scroll to track(s) '..(INDEX and '# ' or 'containing «')..output..(not INDEX and '»' or '')

	if hide or unhide then r.Undo_EndBlock(undo,-1) -- scroll position isn't stored in undo history but track visibility is
	else return r.defer(function() do return end end) -- prevent 'ReaScript: Run' undo point creation in all other cases
	end




