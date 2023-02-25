--[[
ReaScript name: Move edit cursor to snap offset cursor / fades / Razor Edit area edges (10 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
Metapackage: true
Provides:   . > BuyOne_Move edit cursor right to snap offset cursor in items.lua
            . > BuyOne_Move edit cursor left to snap offset cursor in items.lua
            . > BuyOne_Move edit cursor right to fade in items.lua
            . > BuyOne_Move edit cursor left to fade in items.lua
            . > BuyOne_Move edit cursor right to edge of Razor Edit area.lua
            . > BuyOne_Move edit cursor left to edge of Razor Edit area.lua
            . > BuyOne_Move edit cursor right to edge of item Razor Edit area.lua
            . > BuyOne_Move edit cursor left to edge of item Razor Edit area.lua
            . > BuyOne_Move edit cursor right to edge of envelope Razor Edit area.lua
            . > BuyOne_Move edit cursor left to edge of envelope Razor Edit area.lua
About: 	The set of scripts is meant to complement 
        REAPER stock navigation actions.  

        ► Snap offset cursor & Fades  

        Scripts which move the edit cursor to snap offset cursor 
        and fades in items only apply to selected items if any
        are selected, otherwise they move the edit cursor to snap 
        offset cursor and fades in all items.  
        If any tracks are selected these scripts only apply to items
        on selected tracks.  
        Snap offset cursor position is only respected if it differs
        from item start.  

        ► Razor Edit areas  

        Scripts which move the edit cursor to Razor Edit area edges
        only apply to these on selected tracks if any are selected,
        otherwise they apply to Razor Edit area edges on all tracks. 
        If certain Razor Edit area covers both item and envelope on 
        the same track the scripts don't dicriminate between them 
        and move the edit cursor to the area edges regardless of the 
        script name, however track selection condition applies.  
        If certain Razor Edit area covers items and envelopes on 
        multiple tracks, neither script names nor track selection 
        condition apply, the edit cursor will always move to its edges.  
        If certain Razor Edit area covers an item on one track and 
        an envelope on the previous track the script names and selection 
        conditions described above apply as normal.  
        The Master track is supported for builds 6.72 onwards.  
	
	In the USER SETTINGS you can enable MOVE_VIEW setting so that
	the the Arrange view scrolls when the edit cursor moves to out
	of sight areas.
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable settings insert any alphanumeric character between the quotes

-- Enable to make the Arrange view scroll when the time point 
-- the cursor moves to is out of sight
MOVE_VIEW = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function Move_EditCur_To_SnapoffsetCur(dir, sel_tracks) -- if snap offset differs from item start
-- dir is string 'right' or 'left' taken from the script name
-- if sel_tracks true only applies to items on selected tracks, see next condition
-- if some items are selected, only applies to them, otherwise to all items either on selected or all tracks depending on the above condition

local right = dir:match('right')
local left = dir:match('left')
local edit_cur_pos = r.GetCursorPosition()
local sel_itm_cnt = r.CountSelectedMediaItems(0)
local GetItem = sel_itm_cnt > 0 and r.GetSelectedMediaItem or r.GetMediaItem(0,0) and r.GetMediaItem
local itm_cnt = sel_itm_cnt > 0 and sel_itm_cnt or GetItem and r.CountMediaItems(0) or 0

	if itm_cnt > 0 then
	local GetVal = r.GetMediaItemInfo_Value
	local t = {}
		for i = 0, itm_cnt-1 do
		local item = GetItem(0,i)
		local pos = GetVal(item, 'D_POSITION')
		local snapoffs = pos + GetVal(item, 'D_SNAPOFFSET')
		local itm_tr = r.GetMediaItemTrack(item)
		local retval, tr_flags = r.GetTrackState(itm_tr)
		local tr_vis = tr_flags&512 ~= 512 -- visible in TCP
		local is_track_sel = r.IsTrackSelected(itm_tr)
		  if tr_vis and (sel_tracks and is_track_sel or not sel_tracks)
		  and snapoffs ~= pos then t[#t+1] = snapoffs end
		end

		if right then table.sort(t) elseif left then table.sort(t, function(a,b) return a > b end) end

		for _, snapoffs in ipairs(t) do
			if right and snapoffs > edit_cur_pos or left and snapoffs < edit_cur_pos then
			r.SetEditCurPos(snapoffs, MOVE_VIEW, false) -- moveview, seekplay false // if moveview is true only moves if the time point is out of sight
			break end
		end
	end

end


function Move_EditCur_To_Fade(dir, sel_tracks)
-- dir is string 'right' or 'left' taken from the script name
-- if sel_tracks true only applies to items on selected tracks, see next condition
-- if some items are selected, only applies to them, otherwise to all items either on selected or all tracks depending on the above condition

local right = dir:match('right')
local left = dir:match('left')
local edit_cur_pos = r.GetCursorPosition()
local sel_itm_cnt = r.CountSelectedMediaItems(0)
local GetItem = sel_itm_cnt > 0 and r.GetSelectedMediaItem or r.GetMediaItem(0,0) and r.GetMediaItem
local itm_cnt = sel_itm_cnt > 0 and sel_itm_cnt or GetItem and r.CountMediaItems(0) or 0

	if itm_cnt > 0 then
	local GetVal = r.GetMediaItemInfo_Value
	local t = {}
		for i = 0, itm_cnt-1 do
		local item = GetItem(0,i)
		local itm_tr = r.GetMediaItemTrack(item)
		local retval, tr_flags = r.GetTrackState(itm_tr)
		local tr_vis = tr_flags&512 ~= 512 -- visible in TCP
		local is_track_sel = r.IsTrackSelected(itm_tr)
		local pos = GetVal(item, 'D_POSITION')
		local fin = pos + GetVal(item, 'D_LENGTH')
		local fadein = GetVal(item, 'D_FADEINLEN_AUTO')
		local fadein = fadein > 0 and fadein or GetVal(item, 'D_FADEINLEN')
		local fadeout = GetVal(item, 'D_FADEOUTLEN_AUTO')
		local fadeout = fadeout > 0 and fadeout or GetVal(item, 'D_FADEOUTLEN')
			if tr_vis and (sel_tracks and is_track_sel or not sel_tracks) then
				if fadein > 0 then t[#t+1] = pos+fadein end
				if fadeout > 0 then t[#t+1] = fin-fadeout end
			end
		end

	if right then table.sort(t) elseif left then table.sort(t, function(a,b) return a > b end) end

		for _, fade in ipairs(t) do
		if right and fade > edit_cur_pos or left and fade < edit_cur_pos then
		r.SetEditCurPos(fade, MOVE_VIEW, false) -- moveview, seekplay false // if moveview is true only moves if the time point is out of sight
		break end
		end

	end

end


function REAPER_Ver_Check(build) -- build is REAPER build number, the function must be followed by 'do return end'
	if tonumber(r.GetAppVersion():match('(.+)/')) < build then -- or match('[%d%.]+')
	local x,y = r.GetMousePosition()
	local mess = '\n\n   THE SCRIPT REQUIRES\n\n  REAPER '..build..' AND ABOVE  \n\n '
	local mess = mess:gsub('.','%0 ')
	r.TrackCtl_SetToolTip(mess, x, y+10, true) -- topmost true
	return true
	end
end

function Move_EditCur_To_RazEdAreaEdge(dir, items, envs)
-- if any tracks are selected only applies to RazEd areas on them, otherwise to RazEd areas on all tracks
-- if items and envs are both true or both are false, the function applies to both item and env RazEd areas

	if REAPER_Ver_Check(6.24) then return end -- Razor Edit and API were introduced in 6.24

local right = dir:match('right')
local left = dir:match('left')
local edit_cur_pos = r.GetCursorPosition()
local master_raz = tonumber(r.GetAppVersion():match('(.+)/')) >= 6.72 -- Razor Edit for Master track was added in 6.72
local sel_tr_cnt = not master_raz and r.CountSelectedTracks(0)
local GetTr = sel_tr_cnt > 0 and r.GetSelectedTrack or r.GetTrack
local tr_cnt = sel_tr_cnt > 0 and sel_tr_cnt or GetTr and r.CountTracks(0) or 0
local t = {}
	for i = -1, tr_cnt-1 do -- -1 account for the Master track in builds where it supports Razor Edits
	local master = r.GetMasterTrack(0)
	local master_sel = r.IsTrackSelected(master)
	local tr = GetTr(0,i) or master_raz and (sel_tr_cnt > 0 and master_sel or sel_tr_cnt == 0) and r.GetMasterTrack(0)
	local retval, tr_flags = table.unpack(tr and {r.GetTrackState(tr)} or {nil})
	local tr_vis = tr_flags and tr_flags&512 ~= 512 -- works for the Master track as well
		if tr and tr_vis then
		local ret, razor_data = r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS', '', false) -- setNewValue false
			if ret then
				for area in razor_data:gmatch('.-".-"') do
				local itm = area:match('""') -- unlike env area data, item area data instead of GUID contain just quotes
				local env = area:match('".+"')
					if items and not envs and itm or envs and not items and env
					or (not items and not envs or items and envs) and (itm or env) then
					local st, fin = area:match('([%d%.]+) ([%d%.]+)')
					t[#t+1] = st+0 -- converting to number
					t[#t+1] = fin+0
					end
				end
			end
		end
	end

	if right then table.sort(t) elseif left then table.sort(t, function(a,b) return a > b end) end

	for _, raz_edge in ipairs(t) do
		if right and raz_edge > edit_cur_pos or left and raz_edge < edit_cur_pos then
		r.SetEditCurPos(raz_edge, MOVE_VIEW, false) -- moveview, seekplay false // if moveview is true only moves if the time point is out of sight
		break end
	end

end


local scr_name = scr_name:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext
local type_t = {'snap offset', 'fade', 'Razor Edit'}
	for _, v in ipairs(type_t) do
		if scr_name:match(v) then
		Type = scr_name:match(v) break
		end
	end

MOVE_VIEW = #MOVE_VIEW:gsub(' ','') > 0	
	
local sel_tracks = r.CountSelectedTracks(0) > 0

	if Type == 'snap offset' then
	Move_EditCur_To_SnapoffsetCur(scr_name, sel_tracks) -- dir arg is scr_name, sel_track boolean depends on presence of selected tracks
	elseif Type == 'fade' then
	Move_EditCur_To_Fade(scr_name, sel_tracks) -- dir arg is scr_name, sel_track flag depends on presence of selected tracks
	elseif Type == 'Razor Edit' then
	Move_EditCur_To_RazEdAreaEdge(scr_name, scr_name:match('item'), scr_name:match('envelope')) -- dir arg is scr_name, items & envs booleans are obtained from scr_name capture
	end






