--[[
ReaScript name: Save track template with items selected or within time selection
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About:  The script allows saving track template with selected 
        items or items within time selection provided option  
        'Include track items in template'  
        is enabled in 'Save track template' dialogue.
        REAPER native action saves all items on selected tracks.
        Without the option enabled the script is useless.  

        Inspired by a feature request at  
        https://forum.cockos.com/showthread.php?t=277300

        The script works in 2 stages, first it triggers
        the native action 'Track: Save tracks as track template...'
        to allow you to save track template as normal.

        Once 'Save track template' dialogue is closed the script
        immediately triggers custom 'Select .RTrackTemplate file' 
        dialogue inviting you to select the template just saved 
        in order to process it.  
        After the newly saved template is selected and button 'Open'
        is clicked in the dialogue the script completes its task
        leaving the track template only containing items you selected.

        'Select .RTrackTemplate file' dialogue points to the 
        /TrackTemplates folder inside REAPER resource directory 
        which is the default location for saving track templates.  
        If you saved a template elsewhere, simply navigate to that 
        location.  
	The script is blind to the path of the newly saved template 
	file, to the actual save operation and to the state of the 
	option 'Include track items in template', therefore 
	'Select .RTrackTemplate file' dialogue will appear even if 
	you closed native 'Save track template' dialogue without 
	saving a template or didn't enable the option to save items.  

        If after saving a template you closed 'Select .RTrackTemplate file'
        dialogue without allowing the script to process the template
        file you'll be given an opportunity to keep the data until
        the next run. 		

        Items whose start coincides with time selection end 
        or whose end coincides with time selection start 
        aren't considered to be included in time selection.

        Since REAPER saves folder parent track templates with all 
        their children, time selection bounds and selected state 
        apply to items on their children tracks, to the parent 
        track they apply in case it has any items, so if the parent
        track is selected the children tracks don't have to be 
        explicitly selected.
		
]]


local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function Error_Tooltip(text)
local x, y = r.GetMousePosition()
r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
local time_init = r.time_precise()
	repeat
	until r.time_precise()-time_init >= 0.7
end


function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or r.Main_OnCommand(comm_ID, 0)) -- only if valid command_ID
end


function Get_Children_Tracks(tr, t)
local cnt = 0
	for i = r.CSurf_TrackToID(tr, false), r.CountTracks(0)-1 do -- mcpView false // starting loop from the 1st child
	local chld_tr = r.GetTrack(0, i)
		if r.GetTrackDepth(chld_tr) > 0 then
		t[#t+1] = chld_tr
		cnt = cnt+1
		end
	end
end


function weed_out_item_chunks(itm_t, line, templ_t, idx)
local GUID = line:match('<ITEM (.+)') or line:match('IGUID (.+)')
-- search for a GUID of an item found in the line of the template code among the items slated for removal
local found
	for k, v in ipairs(itm_t) do
		if v == GUID then
		table.remove(itm_t, k) -- to optimize so that next cycle is shorter
		found = true break
		end
	end
	if found then -- if turns out to be an item slated for removal
	local i = idx -- starting from the index of the item chunk first line in the template code
		repeat
			if templ_t[i+1] and not templ_t[i+1]:match('<TRACK') then
			templ_t[i] = '' -- remove lines by replacing with empty space unless next block is <TRACK because it will be preceded by closure of the previous <TRACK block which should be left intact to ensure integrity of the code, the template won't load otherwise
			end
		i = i+1
		until templ_t[i]:match('<ITEM') or templ_t[i]:match('<TRACK') or i == #templ_t -- until the index of the next chunk block or template end
	end
end


function Process_Track_Template(templ_t, itm_t, filename)

local idx_init
	for idx, line in ipairs(templ_t) do
		if line:match('<ITEM') then idx_init = idx end -- store table index of the first line in item chunk
		if idx_init and (line:match('<ITEM (.+)') or line:match('IGUID')) then -- in some track template files the <ITEM block start may not include the GUID so watch for the line where it appears inside the item chunk
		weed_out_item_chunks(itm_t, line, templ_t, idx_init)
		idx_init = nil
		end
	end

local templ = ''
	for k, line in ipairs(templ_t) do
		if #line > 0 then -- not a line of a removed item chunk
		local lb = k == 1 and '' or '\n' -- only add line break from 2nd line onwards
		templ = templ..lb..line
		end
	end

local f = io.open(filename, 'w')
f:write(templ)
f:close()

end


function Delete_Ext_States(sect)
local i = 1
	repeat
	r.DeleteExtState(sect, i, true) -- persist true
	i = i+1
	until r.GetExtState(sect, i) == '' -- first key without stored value
end


local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local named_ID = r.ReverseNamedCommandLookup(cmd_ID)
local state = r.GetExtState(named_ID, '1') -- check if there're stored data from previous run when the user didn't update the template file
local path = r.GetResourcePath()
local sep = path:match('[\\/]')
local tr_tmpl_fld = path..sep..'TrackTemplates'..sep

-- Allow user to process template file with stored data if there're any
	if #state > 0 then
	local resp = r.MB('Last time you didn\'t update the template file.\n\n\t  Wish to update it now?\n\n    After cancellation or assention and then\n\n\t   declining the dialogue,\n\n'..(' '):rep(10)..'the stored data will be removed.', 'PROMPT', 4)
		if resp == 6 then -- OK
		::RETRY::
		local retval, filename = r.GetUserFileNameForRead(tr_tmpl_fld, 'Select a .RTrackTemplate file', '.RTrackTemplate')
			if retval and not filename:match('%.RTrackTemplate$') then
			local resp = r.MB('       Invalid file type. Wish to retry?\n\nIf not, the stored data will be removed.', 'ERROR', 4)
				if resp == 6 then -- OK
				goto RETRY
				end
			elseif retval then
			local templ_t = {}
				for line in io.lines(filename) do -- lines aren't followed by line break
				templ_t[#templ_t+1] = line
				end
			local itm_t = {}
			local i = 1
				repeat -- construct item GUID table from extended states
				itm_t[#itm_t+1] = r.GetExtState(named_ID, i)
				i = i+1
				until r.GetExtState(named_ID, i) == '' -- first key without stored value
			Process_Track_Template(templ_t, itm_t, filename)
			end
		end
	Delete_Ext_States(named_ID)
	return r.defer(function() do return end end) end


-- Start main routine

local sel_tr_cnt = r.CountSelectedTracks(0)

	if sel_tr_cnt == 0 then
	Error_Tooltip('\n\n no selected tracks \n\n')
	return r.defer(function() do return end end) end

local resp = r.MB('\"YES\" —  items within time selection on selected tracks\n\n\"NO\" —  selected items on selected tracks', 'PROMPT', 3)
	if resp == 2 then -- Cancel
	return r.defer(function() do return end end) end


local itm_t = {}
local GET = r.GetMediaItemInfo_Value

	if resp == 6 then -- items within time selection
	local st, fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop, allowautoseek false
		if st == fin then
		r.MB('Time selection isn\'t set.', 'ERROR', 0)
		return r.defer(function() do return end end) end

	local tr_t = {}
		for i = 0, sel_tr_cnt-1 do
		local tr = r.GetSelectedTrack(0,i)
		tr_t[#tr_t+1] = tr
		Get_Children_Tracks(tr, tr_t) -- folder parent track templates are saved with their children so children track items have to be taken into account
		end

	local itm_cnt = 0
		for _, tr in ipairs(tr_t) do
		local tr_itm_cnt = r.GetTrackNumMediaItems(tr)
		itm_cnt = itm_cnt+tr_itm_cnt
			for i = 0, tr_itm_cnt-1 do
			local itm = r.GetTrackMediaItem(tr, i)
			local itm_st = GET(itm, 'D_POSITION')
			local itm_end = itm_st + GET(itm, 'D_LENGTH')
				if itm_st >= fin or itm_end <= st then -- only items which are explicitly not within time selection
				local retval, GUID = r.GetSetMediaItemInfo_String(itm, 'GUID', '', false) -- setNewValue false
				itm_t[#itm_t+1] = GUID
				end
			end
		end

		local err = itm_cnt == 0 and 'No items on selected tracks.' or itm_cnt == #itm_t and 'No items within time selection\n\n'..(' '):rep(10)..'on selected tracks.'
		if err then
		r.MB(err, 'ERROR', 0)
		return r.defer(function() do return end end) end

	elseif resp == 7 then -- selected items

	local tr_t = {}
		for i = 0, sel_tr_cnt-1 do
		local tr = r.GetSelectedTrack(0,i)
		tr_t[#tr_t+1] = tr
		Get_Children_Tracks(tr, tr_t) -- folder parent track templates are saved with their children so children track items have to be taken into account
		end

	local itm_cnt = 0
		for _, tr in ipairs(tr_t) do
		local tr_itm_cnt = r.GetTrackNumMediaItems(tr)
		itm_cnt = itm_cnt+tr_itm_cnt
			for i = 0, tr_itm_cnt-1 do
			local itm = r.GetTrackMediaItem(tr, i)
				if not r.IsMediaItemSelected(itm) then -- only collect non-selected items
				local retval, GUID = r.GetSetMediaItemInfo_String(itm, 'GUID', '', false) -- setNewValue false
				itm_t[#itm_t+1] = GUID
				end
			end
		end

		local err = itm_cnt == 0 and 'No items on selected tracks.' or itm_cnt == #itm_t and 'No selected items.'
		if err then
		r.MB(err, 'ERROR', 0)
		return r.defer(function() do return end end) end

	end

-- this particular method has been preferred over using chunk to create a template file because track templates contain some values not present in chunks, in particular additional envelope point values, two item length values, item GUID appearing in the item chunk start besides its IGUID inside the chunk
ACT(40392) -- Track: Save tracks as track template...
::RETRY::
local retval, filename = r.GetUserFileNameForRead(tr_tmpl_fld, 'Select a .RTrackTemplate file', '.RTrackTemplate')

	if retval and not filename:match('%.RTrackTemplate$') then
	local resp = r.MB('Invalid file type. Wish to retry?', 'ERROR', 4)
		if resp == 6 then -- OK
		goto RETRY
		else retval = nil end -- to trigger the next prompt
	end

	if not retval then -- user closed the dialogue without file
	local s = ' '
	local resp = r.MB(' If a template was saved its file was not updated.\n\n'..s:rep(7)..'Wish to keep the data until the next run?\n\n'..s:rep(8)..'(only relevant if a template was saved)\n\n'..s:rep(10)..'If so, at next run during this session\n\n'..s:rep(13)..'you\'ll be asked to update the file.', 'PROMPT', 4)
		if resp == 6 then -- OK // store GUIDs of items whose chunks are to be removed from track template
			for k, GUID in ipairs(itm_t) do
			r.SetExtState(named_ID, k, GUID, false) -- persist false
			end
		end
	return r.defer(function() do return end end) end

local templ_t = {}
	for line in io.lines(filename) do -- lines aren't followed by line break
	templ_t[#templ_t+1] = line
	end

Process_Track_Template(templ_t, itm_t, filename)

do return r.defer(function() do return end end) end -- prevent undo point creation



