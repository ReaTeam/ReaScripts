--[[
ReaScript name: Fade presets
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About:	

The script stores fades as a preset to be applied later.  

A maximum of 16 preset slots is available.  

To store a preset:  
1) Select media items with fades (MIDI items are supported)  
2) Run the script, access Fade Preset X -> Store menu item and click it. 
3) Name the preset or leave the generic name and click OK; storing with 
the empty name field results in the generic name being used;   
to abort storing a preset click 'Cancel'.   

The presets are stored in the Fade_presets.ini file located in the /Data
folder inside REAPER resource directory.  

Only the fisrt fade of each kind (fade-in, fade-out, crossfade) will be stored, 
i.e. if several selected items have a fade-in only the first one found will be stored.

To store a crossfade both items sharing a crossfade must be selected.  
To be stored a crossfade doesn't have to be uniform, i.e. one in which lengths 
of the fade-in and of the fade-out equal items intersection area size, because
lengths of crossfade sides aren't stored with a preset. It's enough of fade-out
and fade-in intersect.  
When a preset is applied crossfade length is determined based on the intersection 
area size and its sides are made equal to the size of the intersection.  
If items overlap without a crossfade but there're either fade-in or fade-out or both, 
these are stored as separate fades.  

To apply a preset:  
1) Select target media items (MIDI items aren't supported)  
2) Run the script and click Apply button corresponding with the preset.  

The script is agnostic about fades already present in selected items 
so if any exist they will be overwritten with the preset fades.  
If selected item overlaps a non-selected item and the preset contains a fade 
relevant for the overlapping end of the selected item, it will be applied.   
For a crossfade to be applied both overlapping items must be selected.  

To rename a preset:  
1) Apply a preset as described above  
2) Select the items the preset has been applied to and follow storing 
routine described above, or simply rename it directly inside Fade_presets.ini 
file replacing the old name in the 'name=' key in the corresponding preset 
section, in which case 50 character limit must be observed otherwise the name 
won't load being replaced by the generic one.

To delete a preset:  
1) De-select all items (both MIDI and audio)  
2) Run the script, access Fade Preset X -> Store menu item and click it.  

When there's no stored data in a preset slot, 'Apply' menu item is greyed out.  

An alphanumeric character next to the 'Store' and 'Apply' menu items can be used 
as a quick access shortcut to execute the menu action from the keyboard.  

The types of fades stored in a preset are represented by pictographs 
next to the 'Apply' button: diagonal line from lower left to upper right - fade-in;
diagonal cross - crossfade; diagonal line from lower right to upper left - fade-out.

The default number of preset slots can be increased in the USER SETTINGS.   

See also script BuyOne_Apply fade in, fade out and crossfade to selected items.lua
		
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Select the number of presets to be available in the menu
-- by inserting a numeral between the quotation marks.
-- Max is 16, if empty or invalid defaults to 8,
-- if greater than 16 is clamped to 16.
PRESET_NUMBER = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

function Esc(str)
	if not str then return end
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end

function Store_Preset(input, stored)

local t = {1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31}
local presetNo
	for _, v in ipairs(t) do -- get preset number based on the number of a Store menu item
		if input == v then presetNo = math.floor(input/2 + .5) -- math.floor to truncate trailing decimal zero
		break end
	end

	if presetNo then -- only run if Store menu item is clicked

	local Get = r.GetMediaItemInfo_Value

	local t = {}

		for i = 0, r.CountSelectedMediaItems(0)-1 do
		local itm = r.GetSelectedMediaItem(0,i)
		local itm_pos = Get(itm, 'D_POSITION')
		local itm_end = itm_pos + Get(itm, 'D_LENGTH')
		local fadein_len = Get(itm, 'D_FADEINLEN')
		local fadeout_len = Get(itm, 'D_FADEOUTLEN')
		local xfade_out_len = Get(itm, 'D_FADEOUTLEN_AUTO')
		local fadeout_shape = Get(itm, 'C_FADEOUTSHAPE')
		local fadeout_curve = Get(itm, 'D_FADEOUTDIR')
		-- Find if the item is overlapped by a preceding item regardless of selection so that only its regular fade-in is stored, if any, and not crossfade's fade-in
		local itm_idx = Get(itm, 'IP_ITEMNUMBER')
		local itm_tr = r.GetMediaItemTrack(itm)
		local prev_itm = r.GetTrackMediaItem(itm_tr, itm_idx-1)
		local prev_itm_end = prev_itm and Get(prev_itm, 'D_POSITION') + Get(prev_itm, 'D_LENGTH')
		local prev_itm_sel = prev_itm and r.IsMediaItemSelected(prev_itm)
		local prev_itm_xfade_out_len = prev_itm and Get(prev_itm, 'D_FADEOUTLEN_AUTO')
		local prev_itm_xfade_out_len = prev_itm and (prev_itm_xfade_out_len > 0 and prev_itm_xfade_out_len or Get(prev_itm, 'D_FADEOUTLEN')) -- do prefer auto-crossfade fade-out value but if 0 get regular fade-out

		local start_overlap_size = prev_itm and prev_itm_end - itm_pos
		local prev_itm_overlap = prev_itm and prev_itm_end > itm_pos
			if fadein_len > 0 and (not prev_itm_overlap or prev_itm_overlap and (not prev_itm_sel or fadein_len + prev_itm_xfade_out_len < start_overlap_size) )
			and not t.fadein_len then -- only store once if genuine fade-in, not crosssfade fade-in
			t.fadein_len = fadein_len
			t.fadein_shape = Get(itm, 'C_FADEINSHAPE')
			t.fadein_curve = Get(itm, 'D_FADEINDIR')
			end
		-- Find if the item is overlapped by a following item regardless of selection so that only its regular fade-out is stored, if any, and not crossfade's fade-out
		local next_itm = r.GetTrackMediaItem(itm_tr, itm_idx+1)
		local next_itm_pos = next_itm and Get(next_itm, 'D_POSITION')
		local next_itm_sel = next_itm and r.IsMediaItemSelected(next_itm)
		local next_itm_xfade_in_len = next_itm and Get(next_itm, 'D_FADEINLEN_AUTO')
		local next_itm_xfade_in_len = next_itm and (next_itm_xfade_in_len > 0 and next_itm_xfade_in_len or Get(next_itm, 'D_FADEINLEN')) -- do prefer auto-crossfade fade-in value but if 0 get regular fade-in

		local end_overlap_size = next_itm and itm_end - next_itm_pos
		local next_itm_overlap = next_itm and next_itm_pos < itm_end
		local xfade_out_len = xfade_out_len > 0 and xfade_out_len or fadeout_len -- do prefer auto-crossfade fade-in value but if 0 get regular fade-in
			if fadeout_len > 0 and (not next_itm_overlap or next_itm_overlap and (not next_itm_sel or fadeout_len + next_itm_xfade_in_len < end_overlap_size) )
			and not t.fadeout_len then -- only store once if genuine fade-out, not crosssfade fade-out
			t.fadeout_len = fadeout_len
			t.fadeout_shape = fadeout_shape
			t.fadeout_curve = fadeout_curve
			elseif next_itm_overlap and next_itm_sel and xfade_out_len > 0 and next_itm_xfade_in_len > 0 and xfade_out_len + next_itm_xfade_in_len > end_overlap_size and not t.xfadeout_shape
			then -- only store once and when there're fades in the intesection and the fades intersect as well // crossfade on the right
			-- crossfade length isn't stored as it will be determined at runtime according to the overlap size
			t.xfadeout_shape = tostring(fadeout_shape) -- tostring is meant to prevent occasional 'No fades in selected items to store' message after applying crossfade and then trying to store it as is or after change to another crossfade shape from the stock menu, not sure if helps !!!!!!!!!!!!!!!!!!!!!
			t.xfadeout_curve = tostring(fadeout_curve)
			t.xfadein_shape = tostring(Get(next_itm, 'C_FADEINSHAPE'))
			t.xfadein_curve = tostring(Get(next_itm, 'D_FADEINDIR'))
			end
		end

	local items_selected = r.GetSelectedMediaItem(0,0)
	local data_exists = t.fadein_len or t.fadeout_len or t.xfadeout_shape
	local preset_stored = stored[presetNo] and (stored[presetNo].fadein or stored[presetNo].fadeout or stored[presetNo].xfade)

	local err = items_selected and not data_exists and {mess='No fades in selected items to store.', tit='INFO'} or not items_selected and (preset_stored and {mess='The selected fade preset is about to be deleted !!', tit='WARNING'} or {mess='No selected items.', tit='INFO'})

		if err then
		local resp = r.MB(err.mess, err.tit, err.tit == 'INFO' and 0 or 1)
			if resp == 2 or err.tit == 'INFO' then return end -- if Cancel is clicked in Warning or OK in Info
		end


	local autofill, retval, name

		if items_selected then -- only allow saving preset name if preset itself will be saved that is when there're selected items with fades

		local f_path = r.GetResourcePath()..'/Data/Fade_presets.ini'
			if r.file_exists(f_path) then
				for line in io.lines(f_path) do
					if line:match('FADE PRESET '..presetNo) then autofill = 1 end
					if autofill and line:match('name=') then autofill = line:match('name=(.+)')
					break end
				end
			end

		local generic_pres_name = 'Fade preset '..presetNo

		::RETRY::
		retval, name = r.GetUserInputs('Type in preset name or leave as is + OK; Cancel to abort', 1, '50 chars max,extrawidth=200', autofill or generic_pres_name)
			if not retval then return end -- abort storing
		name = (not #name:gsub(' ','') == 0 or name:match('^%s*(Fade%s*preset%s*'..presetNo..')%s*$')) and '' or name -- don't save generic name

			if #name > 50 then
			local resp = r.MB(string.rep(' ',11)..'The name length exceeds 50 character limit.\n\n\t\tWish to retry?\n\n\tClick NO to use the generic name.', 'ERROR ... '..generic_pres_name, 3)
				if resp == 6 then autofill = name; goto RETRY
				elseif resp == 2 then return -- abort storing
				else name = '' -- 'No' is clicked
				end
			end
		end

	local preset_new = items_selected and -- only if there're selected items
	'FADE PRESET '..presetNo..
	'\nname='..name..
	'\nfadein_len='..(t.fadein_len or '')..
	'\nfadein_shape='..(t.fadein_shape or '')..
	'\nfadein_curve='..(t.fadein_curve or '')..
	'\nfadeout_len='..(t.fadeout_len or '')..
	'\nfadeout_shape='..(t.fadeout_shape or '')..
	'\nfadeout_curve='..(t.fadeout_curve or '')..
	'\nxfadeout_shape='..(t.xfadeout_shape or '')..
	'\nxfadeout_curve='..(t.xfadeout_curve or '')..
	'\nxfadein_shape='..(t.xfadein_shape or '')..
	'\nxfadein_curve='..(t.xfadein_curve or '')
	or '' -- empty string if there're no selected items to delete a preset

	local f_path = r.GetResourcePath()..'/Data/Fade_presets.ini'
	local f_exists = r.file_exists(f_path)
	local f = f_exists and io.open(f_path, 'r') or io.open(f_path, 'w')
	local cont = f_exists and f:read('*a') or ''
	f:close()
	local preset_old = cont:match('FADE PRESET '..presetNo..'.-xfadein_curve[=%-%d%.]+')

	local cont_new
		if preset_old then
		local preset_old = preset_new ~= '' and preset_old or '\n'..preset_old..'\n\n'
		local preset_old = Esc(preset_old)
		cont_new = cont:gsub(preset_old, preset_new)
		elseif preset_new ~= '' then -- there're selected items with fades so a preset has been extracted
		cont_new = #cont > 0 and (cont:match('(.+=[%d%.]*)') or cont:match('.+[%w]') or '')..'\n\n\n'..preset_new..'\n\n' -- prev preset, only script reference or empty file
		or 'The file was generated by the script BuyOne_Fade presets.lua\n\n\n'..preset_new
		end

	f = io.open(f_path, 'w')
	f:write(cont_new)
	f:close()

	return true -- to trigger script exit without undo

	end

end



function Stored_Presets()

-- ╱ ╳ ╲ -- fadein, crossfade, fadeout, Unicode subrange, Box Drawings, SimSum
-- U+2571, U+2573, U+2572

local f_path = r.GetResourcePath()..'/Data/Fade_presets.ini'
local f_exists = r.file_exists(f_path)
local h = '#' -- to grey out Apply menu item when no preset is stored
local t = {}
local preset
	if f_exists then
		for line in io.lines(f_path) do
		local presetNo = line:match('FADE PRESET (%d)')
			if presetNo and presetNo ~= preset then
			preset = math.floor(presetNo+0) -- math.floor to truncate trailing decimal zero to use as table key
			t[preset] = {act='', name='Fade preset '..presetNo, fadein='', fadeout='', xfade=''}
			end
			if preset then
			local pres_name = line:match('name=(.+)')
			t[preset].name = pres_name and #pres_name <= 50 and pres_name or t[preset].name -- replace with generic preset name if the one extracted from the file exceeds 50 characters, in case of being modified manually by the user
			t[preset].fadein = line:match('fadein_len=%d+') and '╱' or t[preset].fadein
			t[preset].fadeout = line:match('fadeout_len=%d+') and '╲' or t[preset].fadeout
			t[preset].xfade = line:match('xfadeout_shape=%d+') and '╳' or t[preset].xfade
			end
		end
	end
return t

end



function Apply_Preset(input, stored)

local t = {2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32}
local presetNo
	for _, v in ipairs(t) do -- get preset number based on the number of a Store menu item
		if input == v then presetNo = math.floor(input/2) -- math.floor to truncate trailing decimal zero
		break end
	end

	if presetNo then -- only run if Apply menu item is clicked

	local sel_itm_cnt = r.CountSelectedMediaItems(0)

		if sel_itm_cnt == 0 then r.MB('No selected items.', 'INFO', 0) return end

	local f_path = r.GetResourcePath()..'/Data/Fade_presets.ini'

	--[[ WORKS BUT PROBABLY NOT VERY EFFICIENT, replaced with io.lines() loop below

	local f = io.open(f_path, 'r')
	local cont = f:read('*a') or ''
	f:close()
	local preset = cont:match('FADE PRESET '..presetNo..'\n(.-xfadein_curve[=%-%d%.]+)')

	local t = {}
		for parm in preset:gmatch('[^\n\r]+') do -- collect parameters
		t[parm:match('(.+)=')] = parm:match('=(.+)')
		end

	--]]


	local t, found = {}
		for line in io.lines(f_path) do
			if line:match('FADE PRESET '..presetNo) then found = 1
			elseif found and not line:match('(.+)=') then break -- must go 2nd to prevent error in the next condition when preset block has been parsed in full and the next line contains no keys
			elseif found then
			t[line:match('(.+)=')] = line:match('=(.+)')
			end
		end

	local Get, Set = r.GetMediaItemInfo_Value, r.SetMediaItemInfo_Value

	r.Undo_BeginBlock()

		for i = 0, sel_itm_cnt-1 do
		local itm = r.GetSelectedMediaItem(0,i)
		local midi_take = r.TakeIsMIDI(r.GetActiveTake(itm))
		local itm_idx = Get(itm, 'IP_ITEMNUMBER')
		local itm_tr = r.GetMediaItemTrack(itm)
		local pos = r.GetMediaItemInfo_Value(itm, 'D_POSITION')
		local itm_prev = r.GetTrackMediaItem(itm_tr, itm_idx-1)
		local fin_prev = itm_prev and Get(itm_prev, 'D_POSITION') + Get(itm_prev, 'D_LENGTH')
		local midi_take_prev = itm_prev and r.TakeIsMIDI(r.GetActiveTake(itm_prev))
		local itm_prev_tr = itm_prev and r.GetMediaItemTrack(itm_prev)
		local prev_selected = itm_prev and r.IsMediaItemSelected(itm_prev)
			if t.xfadein_shape and not midi_take and itm_prev and not midi_take_prev
			and pos < fin_prev and prev_selected then -- crossfade fade in, only if overlapping item is selected // covers cases where there's no previous item
			Set(itm, 'D_FADEINLEN_AUTO', prev_itm_end-pos) -- length is calculated according to the size of the overlap
			Set(itm, 'C_FADEINSHAPE', t.xfadein_shape)
			Set(itm, 'D_FADEINDIR', t.xfadein_curve)
			crossfade = 'crossfade'
			elseif t.fadein_len and not midi_take and ( not itm_prev or itm_prev and (pos > fin_prev or not prev_selected) )
			then -- regular fade in if the current item doesn't overlap the prev item or dpes overlap and the prev item isn't selected // covers cases where there's no previous item
			Set(itm, 'D_FADEINLEN', t.fadein_len)
			Set(itm, 'C_FADEINSHAPE', t.fadein_shape)
			Set(itm, 'D_FADEINDIR', t.fadein_curve)
			fadein = 'fade-in'
			end
		local fin = pos + Get(itm, 'D_LENGTH')
		prev_itm_end = fin
		local itm_nxt = r.GetTrackMediaItem(itm_tr, itm_idx+1)
		local pos_nxt = itm_nxt and Get(itm_nxt, 'D_POSITION')
		local midi_take_nxt = itm_nxt and r.TakeIsMIDI(r.GetActiveTake(itm_nxt))
		local itm_nxt_tr = itm_nxt and r.GetMediaItemTrack(itm_nxt)
		local nxt_selected = itm_nxt and r.IsMediaItemSelected(itm_nxt)
			if t.xfadeout_shape and not midi_take and pos_nxt and itm_nxt and not midi_take_nxt
			and pos_nxt < fin and nxt_selected then -- crossfade fade out, only if overlapping item is selected
			Set(itm, 'D_FADEOUTLEN_AUTO', fin-pos_nxt) -- length is calculated according to the size of the overlap
			Set(itm, 'C_FADEOUTSHAPE', t.xfadeout_shape)
			Set(itm, 'D_FADEOUTDIR', t.xfadeout_curve)
			elseif t.fadeout_len and not midi_take and ( not itm_nxt or itm_nxt and (pos_nxt >= fin or not nxt_selected) )
			then -- regular fade out only if the current item doesn't overlap the next item or does overlap and the next item isn't selected // covers cases where there's no next item
			Set(itm, 'D_FADEOUTLEN', t.fadeout_len)
			Set(itm, 'C_FADEOUTSHAPE', t.fadeout_shape)
			Set(itm, 'D_FADEOUTDIR', t.fadeout_curve)
			fadeout = 'fade-out'
			end
		r.UpdateItemInProject(itm)
		end

	local name = stored[presetNo].name
	local name = name:match('Fade preset '..presetNo) and name or 'fade preset '..name
	r.Undo_EndBlock('Apply '..name, -1)
	end

end


PRESET_NUMBER = tonumber(PRESET_NUMBER)
PRESET_NUMBER = PRESET_NUMBER and (PRESET_NUMBER > 16 and 16 or PRESET_NUMBER == 0 and 8 or math.floor(PRESET_NUMBER)) or 8

local stored = Stored_Presets()

gfx.init('Fade presets', 0, 0)
-- open menu at the mouse cursor
gfx.x = gfx.mouse_x
gfx.y = gfx.mouse_y

local menu = ''
local quick_access = {1,2,3,4,5,6,7,8,9,'A','B','C','D','E','F','G'} -- to add as quick access characters with ampersand
	for i = 1, PRESET_NUMBER do
	local amp = quick_access[i]
	local name = stored[i] and stored[i].name or 'Fade preset '..i -- covers both stored and non-stored preset names
	local fadein = stored[i] and stored[i].fadein..' ' or ''
	local fadeout = stored[i] and stored[i].fadeout or ''
	local xfade = stored[i] and stored[i].xfade..' ' or ''
	local fades = fadein..xfade..fadeout
	menu = menu..'>'..name..' |<Store  &'..amp..'|'..(stored[i] and stored[i].act or '#')..'Apply  &'..amp..'  '..fades..'|'..(i < PRESET_NUMBER and '||' or '')
	end

local input = gfx.showmenu(menu..'|||#Fade presets script')

gfx.quit()

	if input == 0 then return r.defer(function() do return end end) end


local exit = Store_Preset(input, stored)
	if exit then return r.defer(function() do return end end) end -- no Undo if storing

Apply_Preset(input, stored) -- Undo routine is inside





