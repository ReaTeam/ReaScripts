--[[
ReaScript Name: Duplicate selected tracks, media or automation items with input box
Author: BuyOne
Version: 1.0
Changelog: Initial release
Author URL: https://forum.cockos.com/member.php?u=134058
Licence: WTFPL
REAPER: at least v5.962
About: 	The script is designed for duplication of objects according 
		to the active context determined by a mouse click.  
		So before using the script you can click any track, Arrange
		canvas or envelope or their elements to activate required context.  
		Still the script provides an option to select context with 
		a context switch key inside the input box.  
		
		The native 'Nudge/set items' utility allows duplicating media items
		but doesn't affect tracks or automation items, so this sctipt 
		attempts to coalesce duplication tasks in one place.  
		It also allows free (within music theory limits) formatting of note lengths.
		The advantage of 'Nudge/set items' utility in this respect is that
		items can be selected when the utility is open. The script input box however
		blocks the UI so selection must be done beforehand and can't be changed
		without closing the box.
		
		CAVEATS
		
		The action 'Options: Trim content behind automation items when editing or writing automation' 
		doesn't affect automation items when pasting, therefore 
		after duplication of automation items some of them may end up overlapped 
		and occupy different lanes.
		
		Further details see in HELP below or run the script, type in h
		in the upper field and click OK.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable to have the script store last used setting per context
-- in the current project;
-- the project must be saved at least once for the data to be
-- available in the next session;
-- after the setting has been disabled all stored settings will
-- be deleted
LOAD_LAST_USED_SETT = "1" -- any alphanumeric character

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


HELP = [[

The command line consists of 4 commands in this oder: Context, Direction, Number of repeats, Note length

Out of these only Number of repeats command is essential

------------------------------------------

C O N T E X T  S W I T C H  c o m m a n d

(only if the current context indicated in the upper bar is different from the desired)

Regardless of the register

t - tracks
i - media items
a - automation items

------------------------------------------

R E P E A T S   c o m m a n d


Any whole number (integer).

------------------------------------------

D I R E CT I O N  c o m m a n d


No command

For media/automation items — indicates rightward (forward) duplication.

For tracks — indicates duplication in place.

— A minus sign

For media/automation items — immediately preceeding repeats or note values or both indicates leftward (backward) duplication.

For tracks — immediately preceeding repeats value indicates duplication to the end of track list visible in Arrange, hidden tracks are ignored and when revealed they will succeed the duplicate in the tracklist.

------------------------------------------

N O T E  L E N G T H  c o m m a n d

(for items only; follows REPEATS command separated by space)

No command — all selected items are treated as a single block; in rightward (forward) duplication the first duplicate is placed immediately after the last selected item; in leftward (backward) duplication the last duplicate is placed immediately before the first selected item. A single selected item is always duplicated back to back.

Otherwise only selected items within the same track/envelope are treated as a single block.
From 1/256th (the finest grid division REAPER supports), including triplets, to any number of whole notes, i.e. 1/256, 1/192, 1/128, 1/96, 1/64, 1/48, 1/36, 1/24, 1/16, 1/12, 1/8, 1/6, 1/4, 1/3, 1/2, 1, 2 etc.

The fraction numerator can be greater than 1 and greater than the denominator, which is useful when a distance longer than 1 note division is required or when a whole note needs to be extended, e.g. 10/16, 5/12, 3/2 is 1.5 notes, 5/2 is 2.5 notes, 4/3 is 1 + 1/3 notes (a whole + 1/2 triplet), 5/3 is 1 + 2/3 notes (a whole + two 1/2 triplets).

Length of a dotted note is equivalent to the length of 3 notes of a smaller division, e.g. 1 dotted = 3/2, 1/2 dotted = 3/4, 1/4 dotted = 3/8 etc. To combine several dotted notes multiply the nominator by the number of such notes, e.g. 9/2 = 3 dotted whole notes (3 x 3/2), 12/4 = 4 dotted half notes (4 x 3/4), 6/8 = 2 dotted quarter notes (2 x 3/8). To append dotted notes to whole notes: 1 whole note + 1/2 dotted = 4/4 + 3/4 = 7/4, 2 whole notes + three 1/16 dotted = 64/32 + 3 x 3/32 = 64/32 + 9/32 = 73/32.



L O N E  S L A S H

(follows REPEATS command separated by space, instead of the NOTE LENGTH command)

For media/automation items — duplicate back to back, duplicates are placed immediately after or before the originals depending on the chosen direction.
With multiple selected items spacial relationship is only maintained within track/envelope, similarly to duplication by note.
A single selected item is always duplicated back to back regardless of LONE SLASH presence.

For tracks (when accompanied by DIRECTION command) — duplicate to the end of track list after the very last track whether hidden or not in the Arrange.

****************************************

ALL OTHER CHARACTERS ARE IGNORED.



E X A M P L E S


a4  — switch context to automation items and duplicate selected automation items 3 times rightwards (forward)

i2 1/8  — switch context to media items and duplicate selected media items twice by 1/8 note rightwards (forward)

a-3 1  — switch context to automation items and duplicate selected automation items 3 times leftwards (backwards) by a whole note

-5 /  — (items context) duplicate selected items in the current context leftwards (backwards) 5 times back to back; (tracks context) duplicate selected tracks 5 times to the very end of the track list

t-4  — switch context to tracks and duplicate selected tracks 4 times placing at the end of the track list visible in Arrange

8 /  — (items context) duplicate selected items 8 times rightwards (forward); (tracks context) duplicate selected tracks 8 times, slash command is ignored

****************************************


]]


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


local r = reaper


local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local named_ID = sect_ID..':'..r.ReverseNamedCommandLookup(cmd_ID)


--================ F U N C T I O N S ===================


function spaceout(str)
return str:gsub('.', '%0 ')
end

function Note_Format_Check(note)
-- note is either whole 1,2,3 etc or fractional 1/2, 3/4, 7/12 etc
	for i = 1, 8 do
	local denom = 2^i -- straight note value in all major note divisions is a power of 2
	local straight = tostring(denom):match('(.+)%.') -- truncating decimal 0 with string function
	local triplet = tostring(denom+denom/2):match('(.+)%.') -- a triplet note denominator is a sum of straight note denominator + half of the straight note denominator: 1/3 = 1/2 + 1; 1/6 = 1/4 + 2; 1/12 = 1/8 + 4; 1/24 = 1/16 + 8; 1/48 = 1/32 + 16; 1/96 = 1/64 + 32
		if note:match('%-?%d+/'..straight) or note:match('%-?%d+/'..triplet)
		or tonumber(note) and tonumber(note) == math.floor(tonumber(note)) -- whole
		then
		return true end
	end
return note:match('^/$')
end


function Get_Sel_AI_St_And_End(t)
-- get the start of the first and the end of the last amongst selected AIs
local first_start = math.huge
local last_end = math.huge*-1
	for env in pairs(t) do
		for _, AI_idx in ipairs(t[env].idx) do
			if r.GetSetAutomationItemInfo(env, AI_idx, 'D_UISEL', -1, false) > 0 then -- selected; is_set false
			local pos = r.GetSetAutomationItemInfo(env, AI_idx, 'D_POSITION', -1, false) -- is_set false
			local fin = pos + r.GetSetAutomationItemInfo(env, AI_idx, 'D_LENGTH', -1, false) -- is_set false
			first_start = pos < first_start and pos or first_start
			last_end = fin > last_end and fin or last_end
			end
		end
	end
return first_start, last_end
end


function Music_Div_To_Sec(val)
-- val is either integer (whole bars/notes) or quotient of a fraction x/x
	if not val or val == 0 then return end
local tempo = r.Master_GetTempo()
return 60/tempo*4*val -- multiply crotchet's length by 4 to get full bar length and then multiply the result by the note division
end


function Duplicate_Items_B2B(repeats, t) -- B2B is back to back
sel_itm_t = sel_itm_t or {} -- global so needs no return from the function
local track
	if not t then
		for i = 0, r.CountSelectedMediaItems(0)-1 do -- store selected items by tracks to then be able to re-select them track by track as one block for duplication
		local item = r.GetSelectedMediaItem(0,i)
		local tr = r.GetMediaItemTrack(item)
		sel_itm_t[tr] = tr ~= track and {} or sel_itm_t[tr]
		track = tr -- update for the next cycle
		local len = #sel_itm_t[tr] -- to make sure items in the same track are stored sequentianlly
		sel_itm_t[tr][len+1] = r.GetSelectedMediaItem(0,i)
		end
	end

	for tr in pairs(sel_itm_t) do
	r.SelectAllMediaItems(0, false) -- selected false // deselect all items to be able to select them track by track below
	local first_start = math.huge -- when repeats value is negative (leftward duplication) we search for the earliest pos value amongst selected items in track
	local last_end = math.huge*-1 -- when duplicating rightwards we search for the latest end value
		for _, item in ipairs(sel_itm_t[tr]) do -- select items in track and get the values
		r.SetMediaItemSelected(item, true) -- selected true
		local pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
		local len = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
		first_start = pos < first_start and pos or first_start
		last_end = pos+len > last_end and pos+len or last_end
		end

	local cur_pos = repeats > 0 and last_end or first_start-(last_end-first_start) -- either end of the last selected or start of the first selected - the length of the entire block to accommodate its duplicate on the timeline
	r.SetEditCurPos(cur_pos, false, false) -- moveview, seekplay false
	r.Main_OnCommand(41309,0) -- Item edit: Move duplicate of item to edit cursor // item track doesn't need selection

		for i = 0, r.CountSelectedMediaItems(0)-1 do -- store new selected items which are duplicates just created, for the next duplication cycle if any
		sel_itm_t[tr][i+1] = r.GetSelectedMediaItem(0,i)
		end
	end

end


function Duplicate_Tracks_To_End_Of_Trklist(note)
local last_tr_idx
	if note ~= 0 then -- get last visible track in Arrange
		for i = 0, r.CountTracks(0)-1 do
		local name, flags = r.GetTrackState(r.GetTrack(0, i))
		last_tr_idx = flags&512 ~= 512 and i or last_tr_idx -- visible or hidden
		end
	else -- get absolute last track
	last_tr_idx = r.CountTracks(0)-1
	end
r.ReorderSelectedTracks(last_tr_idx+1, 0) -- makePrevFolder 0 - no folder; last_tr_idx+1 is a non-existing index to fashion placement beforeTrackIdx and hence below the last visible/existing track depending on the 'note' argument
end


function Re_Store_Selected_Objects(ctx, t1, t2)

local t1, t2 = t1, t2

	if not t1 and ctx:match('Automation') then -- media items selection gets lost when AIs are being duplicated
	-- Store selected items
	local sel_itms_cnt = r.CountSelectedMediaItems(0)
		if sel_itms_cnt > 0 then
		t1 = {}
		local i = sel_itms_cnt-1
			while i >= 0 do -- in reverse due to deselection
			local item = r.GetSelectedMediaItem(0,i)
			t1[#t1+1] = item
		--	r.SetMediaItemSelected(item, false) -- selected false; deselect item // OPTIONAL
			i = i - 1
			end
		end
	elseif t1 and #t1 > 0 then -- Restore selected items
--	r.Main_OnCommand(40289,0) -- Item: Unselect all items
--	OR
	r.SelectAllMediaItems(0, false) -- selected false
		for _, item in ipairs(t1) do
		r.SetMediaItemSelected(item, true) -- selected true
		end
	r.UpdateArrange()
	end

	if not t2 and ctx == 'Items' then -- track selection is lost when media items are being duplicated
	-- Store selected tracks
	local sel_trk_cnt = reaper.CountSelectedTracks2(0,true) -- plus Master, wantmaster true
		if sel_trk_cnt > 0 then
		t2 = {}
		local i = sel_trk_cnt-1
			while i >= 0 do -- in reverse due to deselection
			local tr = r.GetSelectedTrack2(0,i,true) -- plus Master, wantmaster true
		--	r.SetTrackSelected(tr, false) -- selected false; deselect track // OPTIONAL
			t2[#t2+1] = tr
			i = i - 1
			end
		end
	elseif t2 and #t2 > 0 then
	r.Main_OnCommand(40297,0) -- Track: Unselect all tracks
	r.SetTrackSelected(r.GetMasterTrack(0), false) -- unselect Master
		for _, tr in ipairs(t2) do
		r.SetTrackSelected(tr, true) -- selected true
		end
	r.UpdateArrange()
	r.TrackList_AdjustWindows(0)
	end

return t1, t2

end

function Autofill(named_ID, ctx, str)
	if not str then
	local ret, last_sett = r.GetProjExtState(0, named_ID, ctx)
	return last_sett
	end
return str
end

function RESOLVE_AI_OVERLAPS()

local sel_AI_t = {}

	for i = 0, r.CountTracks(0)-1 do -- store selected AIs and deselect
	local tr = r.GetTrack(0,i)
		for i = 0, r.CountTrackEnvelopes(tr)-1 do
		local env = r.GetTrackEnvelope(tr, i)
			for i = 0, r.CountAutomationItems(env)-1 do -- backwards because some AIs may need to be deleted
				if r.GetSetAutomationItemInfo(env, i, 'D_UISEL', 0, false) ~= 0 then -- is_set false
				sel_AI_t[env] = not sel_AI_t[env] and {} or sel_AI_t[env]
				sel_AI_t[env][1] = r.CountAutomationItems(env) -- store count to collate later to allow deciding whether to restore
				local len = #sel_AI_t[env] -- for brevity
				sel_AI_t[env][len+1] = i
				r.GetSetAutomationItemInfo(env, i, 'D_UISEL', 0, true) -- is_set true // deselect
				end
			end
		end
	end


local cur_pos = r.GetCursorPosition()

local func = r.GetSetAutomationItemInfo

local function Find_First_Overlap(env, AI_idx, pos_curr) -- addresses cases when one AI overlaps several other AIs and have index which is not immediately precedes current AI index
	for i = AI_idx-1, 0, -1 do -- start from previous
	local fin_prev = func(env, i, 'D_POSITION', 0, false) + func(env, i, 'D_LENGTH', 0, false) -- is_set false
	local diff = fin_prev - pos_curr
		if diff > 0 then return diff, fin_prev end
	end
end

local function Trim_AI_By_Splitting(env, AI_idx, fin_prev)
func(env, AI_idx, 'D_UISEL', 1, true) -- is_set true // select AI
r.SetEditCurPos(fin_prev, false, false) -- oveview, seekplay false // set cur to the end of prev AI which overlaps
r.Main_OnCommand(42087, 0) -- Envelope: Split automation items
func(env, AI_idx+1, 'D_UISEL', 0, true)-- is_set true // deselect right part of the split
func(env, AI_idx, 'D_UISEL', 1, true) -- is_set true // select left part of the split
r.Main_OnCommand(42086, 0) -- Envelope: Delete automation items // delete left part
end

	for i = 0, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
		for i = 0, r.CountTrackEnvelopes(tr)-1 do
		local env = r.GetTrackEnvelope(tr, i)
			for i = r.CountAutomationItems(env)-1, 0, -1 do -- backwards because some AIs may need to be deleted
			local func = r.GetSetAutomationItemInfo
			local pos_curr = func(env, i, 'D_POSITION', 0, false) -- is_set false
			local len_curr = func(env, i, 'D_LENGTH', 0, false) -- is_set false
			local startoffs_curr = func(env, i, 'D_STARTOFFS', 0, false) -- is_set false
			local playrate = func(env, i, 'D_PLAYRATE', 0, false) -- is_set false
			local fin_curr = pos_curr + len_curr
			local diff, fin_prev = Find_First_Overlap(env, i, pos_curr) -- addresses cases when one AI overlaps several which don't overlap each other
				if diff and diff > 0 then -- AIs overlap
					if len_curr < 0.02 -- delete because it cannot be shortened or split, AI length cannot be set to less than 100 ms via API (when setting length shorter that 100 ms to a an already shorter AI it ends up being exactly 100 ms) and it cannot be split with action if the edit cursor is at less than 10 ms from either of AI edges // must be deleted with action because setting length to 0 only shortens AI down to 100 ms // requires preemptive deselection of all AIs
					or fin_prev >= fin_curr -- prev AI fully overlaps current one, delete current
					or fin_curr - fin_prev < 0.01 -- overlaps almost completely shy of 10 ms, delete because there'll be no way to shorten the AI or to split and keep that extra non-overlapped length of under 10 ms // same as len_curr - diff < 0.01
					then
					func(env, i, 'D_UISEL', 1, true) -- is_set true // select
					r.Main_OnCommand(42086, 0) -- Envelope: Delete automation items
					elseif len_curr - diff >= 0.1 then -- can be shortened via API since certainly won't get shorter than 100 ms
					func(env, i, 'D_POSITION', fin_prev, true) -- is_set true // shift rightwards
					func(env, i, 'D_LENGTH', len_curr-diff, true) -- is_set true // shorten
					func(env, i, 'D_STARTOFFS', startoffs_curr+diff*playrate, true) -- is_set true // shift contents leftwards so that it looks as if the AI start (pos) was cut off
					elseif diff >= 0.01 and fin_curr-fin_prev >= 0.01 -- // same as len_curr - diff >= 0.01
					then -- can't be shortened via API hence must be split provided the edit cursor can be placed farther than or at 0.01 from either edge of the AI; select, split with action, delete left hand part // action splits all selected AI crossed by the edit cursor so requires preemptive deselection of all, after split always selects right
					Trim_AI_By_Splitting(env, i, fin_prev)
					else -- the overlapped part is shorter than 10 ms which prevents splitting, hence lengthen the AI, shift left increasing the overlapped part to or to over 10 ms so it could be split and moving contents to original pos where they should end up after splitting
					local ext = 0.1-len_curr -- minimum length to which an AI shorter than 100 ms can be set is 100 ms
					func(env, i, 'D_LENGTH', len_curr+ext, true) -- is_set true // lengthen up to 100 ms
					func(env, i, 'D_POSITION', pos_curr-ext, true) -- is_set true // offset by shifting left by the same amount
					func(env, i, 'D_STARTOFFS', startoffs_curr-ext*playrate, true) -- is_set true // move contents rightwards by the same amount to restore their orig pos after split
					Trim_AI_By_Splitting(env, i, fin_prev)
					end
				end
			end -- AI loop end
		end -- env loop end
	end -- track loop end

r.SetEditCurPos(cur_pos, false, false) -- oveview, seekplay false // restore cur pos in case changed

	-- Restore AI selection
	for env in pairs(sel_AI_t) do
	local AI_cnt = r.CountAutomationItems(env)
		if AI_cnt == sel_AI_t[env][1] then -- if count didn't change in the interim
			for k, AI_idx in ipairs(sel_AI_t[env]) do -- restore AI selection
			local re_sel = k ~= 1 and r.GetSetAutomationItemInfo(env, AI_idx, 'D_UISEL', 1, true) -- is_set true // excluding 1st field because it holds total count
			end
		end
	end

end -- RESOLVE_AI_OVERLAPS() end



--================ F U N C T I O N S  E N D ===================


local is_AI_sel
local sel_AI = {}
	for tr_idx = 0, r.CountTracks(0)-1 do -- check if there're selected AI and save them because they'll have to be deselected below in order to not be affected by duplication of media items directly above them
	local tr = r.GetTrack(0,tr_idx)
		for env_idx = 0, r.CountTrackEnvelopes(tr)-1 do
		local env = r.GetTrackEnvelope(tr, env_idx)
			for AI_idx = 0, r.CountAutomationItems(env)-1 do
				if r.GetSetAutomationItemInfo(env, AI_idx, 'D_UISEL', -1, false) > 0 -- selected; is_set false
				then
				sel_AI[env] = not sel_AI[env] and {idx = {}, pos = {}} or sel_AI[env] -- only create table if there're selected AIs
				local len = #sel_AI[env].idx -- for brevity
				sel_AI[env].idx[len+1] = AI_idx -- saving indices as well for simplicity of code in AI de-selecton routine before the main
					if r.GetToggleCommandStateEx(0, 40070) == 1 -- Options: Move envelope points with media items and razor edits
					then -- if the option is ON and context is 'Items' and the media items have AIs attached to them, the AIs will be duplicated along with media items so their total count will change and their indices won't be reliable to restore their selection at the end of the script which is especially true with leftward duplication because count starts from the left; position seems the only most reliable piece of data in this case which is still not failproof because AI start might get trimmed with another overlapping AI during duplication
					local len = #sel_AI[env].pos -- for brevity
					sel_AI[env].pos[len+1] = r.GetSetAutomationItemInfo(env, AI_idx, 'D_POSITION', -1, false) -- is_set false
					end
				is_AI_sel = 1
				end
			end
		end
	end


	-- NO SELECTED OBJECTS ERROR MESS
	if not r.GetSelectedTrack(0,0) and not r.GetSelectedMediaItem(0,0) and not is_AI_sel then
	local x, y = r.GetMousePosition()
	r.TrackCtl_SetToolTip(('\n\n   no selected objects  \n\n  '):upper():gsub('.', '%0 '), x, y, true) -- topmost
	return r.defer(function() do return end end) end


LOAD_LAST_USED_SETT = #LOAD_LAST_USED_SETT:gsub(' ', '') > 0


-- PROCESS USER INPUT
::RETRY::
local ctx = r.GetCursorContext2(true) -- want_last_valid true
local warn = ' >>>>>> NO SELECTED '
local warn = ctx == 1 and not r.GetSelectedMediaItem(0,0) and warn..'ITEMS' or ctx == 2 and not is_AI_sel and warn..'AIs' or ctx == 0 and not r.GetSelectedTrack(0,0) and warn..'TRACKS' or '' -- upper bar warning
local ctx = ctx == 1 and 'Items' or ctx == 2 and 'Automation items' or 'Tracks'
local clear = not LOAD_LAST_USED_SETT and r.SetProjExtState(0, named_ID, '', '') -- clear the data // doesn't clear the extension name represented with named_ID
autofill = Autofill(named_ID, ctx, autofill) -- autofill either with the current setting after error message or with last setting used for the current context
local ret, output = r.GetUserInputs('Duplicate selected '..ctx..warn, 2, 'Command string:,(t/i/a)(—)N (—(N/N or N or /)),extrawidth=150', autofill..',type h in the upper field and click OK for Help')
	if not ret or #output:match('(.*),') == 0 then return r.defer(function() do return end end) end

local output = output:match('(.+),'):gsub(',','') -- exclude the 2nd field & ignore commas

local ctx_switch, repeats, note = output:match('%s*(%a*)%s*(%-?%d*)%s*([%-/%dtd%.,b2]*)') -- * to allow empty strings (contrary to +) and not undercut other return values, because if one of them is nil all are nil

	if ctx_switch:match('[Hh]+') then -- HELP
	Msg(HELP, r.ClearConsole()) goto RETRY
	end

local ctx = ctx_switch:match('[Tt]+') and 'Tracks' or ctx_switch:match('[Ii]+') and 'Items' or ctx_switch:match('[Aa]+') and 'Automation items' or ctx
local repeats = tonumber(repeats)

--------- CATCH ERRORS ---------

	if ctx == 'Tracks' and not r.GetSelectedTrack(0,0) or ctx == 'Items' and not r.GetSelectedMediaItem(0,0) or ctx == 'Automation items' and not is_AI_sel then
	local x, y = r.GetMousePosition()
	r.TrackCtl_SetToolTip('\n\n   '..('NO SELECTED '..ctx):upper():gsub('.', '%0 ')..'  \n\n  ', x, y, true) -- topmost
	goto RETRY
	end

local err = #ctx_switch > 0 and not ctx_switch:match('[AaIiTt]+') and spaceout('Invalid context switch command. \n')
local err = err or (not repeats or math.floor(repeats) ~= repeats or repeats == 0) and 'Repeats value must be integer  \n\n         (a whole number) bar 0. \n' or #note > 0 and (note:match('^0/') or note:match('/0$')) and 'Note value must not include zero. \n'
or (note:match('^/%d+') or note:match('%d+/$')) and spaceout('Invalid note format. \n') -- when no numerator or no denominator
local err = err or #note > 0 and ctx:match('[Ii]tems') and not Note_Format_Check(note) and spaceout('Wrong note length format. \n') -- when wrong denominator

	if err then
	local x, y = r.GetMousePosition()
	r.TrackCtl_SetToolTip('\n\n   '..err:upper()..'  \n  ', x, y, true) -- topmost
	autofill = output
	goto RETRY
	end

----------------------------

local store = LOAD_LAST_USED_SETT and r.SetProjExtState(0, named_ID, ctx, output) -- store user input as last used setting to autofill the input field on the next run


function Toggle_Trim_AI_On_and_Off(trim_content)
local act = r.Main_OnCommand
local get_toggle = r.GetToggleCommandStateEx
	if not trim_content	then
	trim_content = get_toggle(0, 42206) == 0 -- Options: Trim content behind automation items when editing or writing automation
	and get_toggle(0, 40070) == 1 -- Options: Move envelope points with media items and razor edits
	local set_on = trim_content and act(42206,0) -- Options: Trim content behind automation items when editing or writing automation
	return trim_content
	else
	local restore = trim_content and act(42206,0) -- Options: Trim content behind automation items when editing or writing automation
	end
end


-- GET NOTE
local undo_note = note -- store in orig format for undo
local note = note:match('^/$') and 0 -- convert back-to-back slash modifier to 0
or note:match('/') and (tonumber(note:match('(%-?%d+)/')) / tonumber(note:match('%-?%d+/(%d+)'))) or tonumber(note:match('%-?%d+'))
local note = repeats < 0 and note and note > 0 and note*-1 or note -- make note val negative if it's positive and repeats value is negative (prefixed with minus "-") indicating leftward duplication
local note = note ~= 0 and Music_Div_To_Sec(note) or note -- convert user entered note val to duration in sec only if note isn't 0 which indicates back-to-back duplication


	-- Get length of automation items selection as 1 block
	if ctx:match('Automation') then -- must be outside of the loop so it's not affected by changes in the AI table
	local first_start, last_end = Get_Sel_AI_St_And_End(sel_AI) -- the start of the first and the end of the last amongst selected AIs
	AI_sel_length = last_end - first_start -- AI selection length to be treated as 1 block for the sake of duplication similar to how media item duplication works
	end


-- STORE DATA
local sel_env = r.GetSelectedEnvelope(0) -- store sel envelope because the selection is likely to change when duplicating AIs
local cur_pos = r.GetCursorPosition() -- store edit cursor pos to restore at the end since it'll be used for items duplication
local sel_item_t, sel_tr_t = Re_Store_Selected_Objects(ctx)

	if ctx == 'Items' then -- deselect selected AIs so they're not affected by media item duplication in case they start and/or end outside of media item bounds when option 'Move envelope points with media items abd razor edits' is ON; doesn't help much if media item overlaps at least two AIs
		for env in pairs(sel_AI) do
			for _, AI_idx in ipairs(sel_AI[env].idx) do
			r.GetSetAutomationItemInfo(env, AI_idx, 'D_UISEL', 0, true) -- is_set true
			end
		end
	trim_content = Toggle_Trim_AI_On_and_Off() -- enable 'Options: Trim content behind automation items when editing or writing automation' if 'Options: Move envelope points with media items and razor edits' is ON to prevent possible bunching up of AIs duplicated along with their media items in separate lanes when they end up being overlapped and instead trim any overlapping ones just like the native 'Item: Duplicate items' action does
	end


-- START MAIN ROUTINE

r.Undo_BeginBlock()
r.PreventUIRefresh(1) -- to disguse edit cursor movements

	for i = 1, math.abs(repeats) do	-- rectify tepeats value in case it's preceded by minus as an indication of leftward duplication
		if ctx == 'Tracks' then
		r.Main_OnCommand(40062,0) -- Track: Duplicate tracks
		local dup = repeats < 0 and Duplicate_Tracks_To_End_Of_Trklist(note) -- move to the end of tracklist in Arrange
		elseif ctx == 'Items' then

			if note == 0 then -- back-to-back duplication, only respecting relative position of items selected within track
			Duplicate_Items_B2B(repeats)
			else -- spacial duplication respecting relative position of items selected on multiple tracks
			-- When duplicating multiple items rightwards the start of the 1st item duplicate touches the end of the last original item
			-- When duplicating leftwards the end of the last item duplicate touches the start of the 1st original item so edit cursor must precede the first item start by the length of the entire selected items block
			local item = r.GetSelectedMediaItem(0,0) -- get 1st selected item
			r.SetOnlyTrackSelected(r.GetMediaItemTrack(item)) -- when copying/pasting the track of the topmost selected item must be selected which also happens to be the 1st selected one
			local first_start = math.huge -- when note or repeats value is negative (leftward duplication) we search for the earliest pos value
			local last_end = math.huge*-1 -- when duplicating rightwards we search for the latest end value
					for i = 0, r.CountSelectedMediaItems(0)-1 do
					local item = r.GetSelectedMediaItem(0,i)
					local item_pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
					first_start = item_pos < first_start and item_pos or first_start -- get the earliest pos value amongst selected items because when copying/pasting multiple items which maintain their relative positions that's the defining value
					local fin = item_pos + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
					last_end = fin > last_end and fin or last_end -- get the latest end value amongst selected items to place cursor at to emulate duplicate action
					end
			local pos = note and first_start + note or repeats < 0 and first_start-(last_end-first_start) or last_end -- duplicate by note or maintaining relative positions of all selected items

		--	r.Main_OnCommand(40057,0) -- Edit: Copy items/tracks/envelope points (depending on focus) ignoring time selection
			r.SetEditCurPos(pos, false, false) -- moveview, seekplay false
		--	r.Main_OnCommand(42398,0) -- Item: Paste items/tracks
			r.Main_OnCommand(41309,0) -- Item edit: Move duplicate of item to edit cursor // same as above two actions 40057 and 42398
			end
		-- in REAPER automation item duplication with action 'Envelope: Duplicate automation items' works differently from media item duplication, when several AIs are selected on diff tracks they're duplicated as if AIs were selected independently on each track so they're not treated as one block and each duplicate block of AIs per track is placed immediately after the last original AI of such block in the envelope lane
		elseif ctx == 'Automation items' then
			for env in pairs(sel_AI) do
			local pos
				for _, AI_idx in ipairs(sel_AI[env].idx) do -- AIs must ber re-selected because after pasting they all get de-selected apart from the newly created duplicates in the selected envelope
				r.GetSetAutomationItemInfo(env, AI_idx, 'D_UISEL', 1, true) -- is_set true
				end
			-- Get the start and the end values of selection as 1 block
			local first_AI_idx = sel_AI[env].idx[1]
			local pos = r.GetSetAutomationItemInfo(env, first_AI_idx, 'D_POSITION', -1, false) -- is_set false
			local last_AI_idx = sel_AI[env].idx[#sel_AI[env].idx]
			local last_AI_end = r.GetSetAutomationItemInfo(env, last_AI_idx, 'D_POSITION', -1, false) + r.GetSetAutomationItemInfo(env, last_AI_idx, 'D_LENGTH', -1, false) -- is_set false

			-- Calc required edit curs pos
			local pos = note and note ~= 0 and pos + note -- duplicate by note
			or note and note == 0 and repeats > 0 and last_AI_end -- duplicate back to back
			or note and note == 0 and repeats < 0 and pos-(last_AI_end-pos) -- this and prev emulate 'Envelope: Duplicate automation items' which duplicates them back to back, start of 1st duplicate is attached to the end of the last original and with leftward duplication end of last duplicate is attached to the start of 1st original
			or repeats < 0 and pos-AI_sel_length or pos+AI_sel_length -- the last is when repeats > 0 // duplicate maintaining relative positions of all selected items

			r.SetCursorContext(2, env) -- select envelope // AIs can only be copied from the selected envelope even if AIs on other envelopes are selected as well // DESELECTS ALL SELECTED MEDIA ITEMS
			r.Main_OnCommand(40057,0) -- Edit: Copy items/tracks/envelope points (depending on focus) ignoring time selection
			r.SetEditCurPos(pos, false, false) -- moveview, seekplay false
			r.Main_OnCommand(42398,0) -- Item: Paste items/tracks
			sel_AI[env].idx = nil
				for AI_idx = 0, r.CountAutomationItems(env)-1 do -- store new selected instances of AIs after duplication to be reused in the next cycle of the repeats loop; after duplication only the newly created AIs end up being selected
					if r.GetSetAutomationItemInfo(env, AI_idx, 'D_UISEL', -1, false) > 0 -- selected; is_set false
					then
					sel_AI[env].idx = not sel_AI[env].idx and {} or sel_AI[env].idx -- only create table if there're selected AIs
					local len = #sel_AI[env].idx -- for brevity
					sel_AI[env].idx[len+1] = AI_idx
					end
				end
			end

		end
	end


	-- RESTORE OBJECT SELECTION, SETTINGS, CURS POSITION

	Re_Store_Selected_Objects(ctx, sel_item_t, sel_tr_t)

	local restore_env = sel_env and ctx:match('Automation') and r.SetCursorContext(2, sel_env)

	r.SetEditCurPos(cur_pos, false, false) -- moveview, seekplay false // restore position

	Toggle_Trim_AI_On_and_Off(trim_content)

	if ctx:match('[Ii]tems') then -- re-select originally selected AIs if 'Items' context because in this case AIs are deselected to prevent possible glitches; or select all last duplicate instances if 'Automation items' context, otherwise only the very last ends up being selected
		for env in pairs(sel_AI) do
			if ctx == 'Items' and r.GetToggleCommandStateEx(0, 40070) == 1 -- use position data to restore selection because that's what was saved in the loop at the beginning of the script under the GetToggleCommandStateEx condition
			then
				for _, AI_pos in ipairs(sel_AI[env].pos) do
					for AI_idx = 0, r.CountAutomationItems(env)-1 do
					local pos = r.GetSetAutomationItemInfo(env, AI_idx, 'D_POSITION', -1, false) -- is_set false
						if pos == AI_pos then r.GetSetAutomationItemInfo(env, AI_idx, 'D_UISEL', 1, true) -- is_set true
						break end -- to jump to the next AI_data value
					end
				end
			else -- context 'Automation items', if context is 'Tracks' the table is empty
				for _, AI_idx in ipairs(sel_AI[env].idx) do
				r.GetSetAutomationItemInfo(env, AI_idx, 'D_UISEL', 1, true) -- is_set true
				end
			end
		end
	end


	if ctx:match('Automation') then -- the option 'Options: Trim content behind automation items when editing or writing automation' doesn't work when pasting AIs alone, only along with media items while 'Options: Move envelope points with media items and razor edits' is ON, hence the need to resolve possible overlaps after AI duplication
	RESOLVE_AI_OVERLAPS()
	end

r.PreventUIRefresh(-1)
local items = ctx:match('[Ii]tems')
local tracks = 'to the end of %s track list'
local dir = (repeats < 0 or undo_note and undo_note:match('%-')) and items and 'backwards' or items and 'forward' or repeats < 0 and #undo_note == 0 and tracks:format('visible') or ''
local note = undo_note:match('%d') and items and 'by '..undo_note:gsub('%-','')..' %s whole note(s)' or #undo_note > 0 and items and 'back to back' or #undo_note > 0 and repeats < 0 and tracks:format('') or ''
local note = note:match('whole') and note:match('/') and note:format('of the') or note:match('whole') and note:format('') or note
r.Undo_EndBlock('Duplicate selected '..ctx:lower()..' '..math.abs(repeats)..' times '..dir..' '..note, -1)





