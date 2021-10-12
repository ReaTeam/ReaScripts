--[[
ReaScript name: Move items from one track to many or from many to one
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About:	When one track is selected or all selected items 
		belong to the same track - moves respectively all 
		or only selected items to separate tracks.   
		Only works with one track at a time.   
		
		When at least two of selected items belong 
		to different tracks - moves all selected items 
		to a single track inserted right above the 1st 
		selected item or at the top of the track list, 
		depending on user's choice, retaining their 
		relative positons or lining them up back to back 
		without gaps and overlaps starting from the 1st 
		selected item or from the project start depending 
		on user's choice.  
		
		In essense does what 
		'Xenakios/SWS: Explode selected items to new tracks (keeping positions)' 
		action does (without creating a folder) and what 
		'Item: Implode items across tracks into items on one track' does 
		followed by 'Xenakios/SWS: Reposition selected items...' 
		with the settings being 'Item end' and '0' when removeing gaps 
		betnween and overlaps in items.   
		
		Also check out mordi_Move selected items to new individual tracks.lua
]]



function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function ACT(comm_ID) -- both string and integer work
r.Main_OnCommand(r.NamedCommandLookup(comm_ID),0)
end


function is_same_track() -- if all selected items belong to the same track
local sel_itm_cnt = r.CountSelectedMediaItems(0)
	if sel_itm_cnt > 0 then
	local ref_tr = r.GetMediaItemTrack(r.GetSelectedMediaItem(0,0))
		for i = 0, sel_itm_cnt-1 do
			if r.GetMediaItemTrack(r.GetSelectedMediaItem(0,i)) ~= ref_tr then return false end
		end
	end
return true
end


function MOVE_TO_SEP_TRACKS(t, resp)
	if t and #t > 0 then
	local tr_idx = r.CSurf_TrackToID(r.GetMediaItemTrack(t[1]), true) -- mcpView is true
		for k, v in ipairs(t) do
		r.SelectAllMediaItems(0, false)
		r.SetMediaItemSelected(v, true)
			if resp == 7 then -- create new track for each item
			r.InsertTrackAtIndex(tr_idx-1+k, false) -- wantDefaults is false
			end
		local i = 0
			repeat
			ACT(40118) -- Item edit: Move items/envelope points down one track/a bit
			i = i + 1
			until i == k
		end
	end
end


function MOVE_TO_SINGLE_NEW_TRACK(t, resp)

local dispos = r.MB('"YES"  —  to keep items relative positions\n\n"NO"  —  to butt items together', 'PROMPT 2', 3)
	if dispos == 2 then r.defer(function() end) return end

	if t and #t > 0 then
		if resp == 6 then -- Insert track above the 1st item and move there
		local first_item_tr_id = r.CSurf_TrackToID(r.GetMediaItemTrack(t[1]), true) -- mcpView is true
		r.InsertTrackAtIndex(first_item_tr_id-1, false) -- wantDefaults is false
		tr = r.GetTrack(0, first_item_tr_id-1)
		else -- Insert track at the first position in the track list and move there
		r.InsertTrackAtIndex(0, false) -- wantDefaults is false
		tr = r.GetTrack(0,0)
		end

		for k, v in ipairs(t) do -- move all media items to track, their relative positons are retained
		r.MoveMediaItemToTrack(v, tr)
		end
			
		if dispos == 7 then
			for k, v in ipairs(t) do -- resolve any gaps and overlaps butting items together
			local prev_end = resp == 6 and (k == 1 and r.GetMediaItemInfo_Value(t[k], 'D_POSITION') or k > 1 and r.GetMediaItemInfo_Value(t[k-1], 'D_POSITION')+r.GetMediaItemInfo_Value(t[k-1], 'D_LENGTH')) -- track above the 1st item without shifting the 1st item
			or resp == 7 and (k == 1 and 0+r.GetProjectTimeOffset(0, false) -- rndframe is false
			or r.GetMediaItemInfo_Value(t[k-1], 'D_POSITION')+r.GetMediaItemInfo_Value(t[k-1], 'D_LENGTH') ) -- track at the top of track list shifting the 1st item to project start
			r.SetMediaItemInfo_Value(v, 'D_POSITION', prev_end)
			end
		end
	end
end


local itm_cnt = r.CountSelectedMediaItems(0)
local tr_cnt = r.CountSelectedTracks(0) -- mcpView is true
local err = 'ERROR'
local prompt = 'PROMPT'
local same_tr = is_same_track()
local explode = 'items will be moved to separate tracks.\n\n"YES"  —  move items to existing tracks creating new as needed\n\n"NO"  —  move items to new tracks'
local mess =
-- errors
(itm_cnt == 1 or itm_cnt == 0 and tr_cnt == 1 and r.GetTrackNumMediaItems(r.GetSelectedTrack(0,0)) == 1) and {'Applying script to a single item\n\n        isn\'t of much use IMO.', err, 0}
or itm_cnt + tr_cnt == 0 and {'No selected tracks or items.', err, 0}
or itm_cnt == 0 and tr_cnt > 1 and {'   Since there\'re no selected items\n\nonly one track needs to be selected.', err, 0}
or itm_cnt == 0 and tr_cnt == 1 and r.GetTrackNumMediaItems(r.GetSelectedTrack(0,0)) == 0 and {'   No selected items and\n\nno items on selected track.', err, 0}
-- prompts
or itm_cnt == 0 and tr_cnt == 1 and {'All track '..explode, prompt, 3}
or itm_cnt > 1 and same_tr and {'Selected '..explode, prompt, 3}
or itm_cnt > 1 and not same_tr and {'All items will be moved to a new track.\n\n"YES"  —  to a track just above the 1st item\n\twithout shifting this item\'s position\n\n"NO"  —  to a track at the top of the track list\n\tshifting items to project start', 'PROMPT 1', 3}

	if mess then resp = r.MB(mess[1], mess[2], mess[3])
		if resp == 1 or resp == 2 then return r.defer(function() end)
		else
		r.Undo_BeginBlock()
		r.PreventUIRefresh(1)
			if mess[3] == 3 and same_tr then				
			-- Store either all track items if only track is selected or selected items only to allow leaving the first one on the current track
			local tr = r.GetSelectedTrack(0,0)
			local all = mess[1]:match('All')
			local cnt = all and r.GetTrackNumMediaItems(tr) or r.CountSelectedMediaItems(0)
			local t = {}
				for i = 0, cnt-1 do
				t[#t+1] = all and r.GetTrackMediaItem(tr,i) or r.GetSelectedMediaItem(0,i)
				end
			MOVE_TO_SEP_TRACKS(t, resp) -- resp value determines if existing tracks will be used or new ones created
			else
			local t = {}
				for i = 0, r.CountSelectedMediaItems(0)-1 do
				t[#t+1] = r.GetSelectedMediaItem(0,i)
				end
			MOVE_TO_SINGLE_NEW_TRACK(t, resp)
			end
		r.PreventUIRefresh(-1)
		r.Undo_EndBlock(({r.get_action_context()})[2]:match('([^\\/_]+)%.%w+'), -1) -- script name only
		end
	end



