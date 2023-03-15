--[[
ReaScript name: Delete selected item(s) and select next or previous
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Provides: [main] .
Licence: WTFPL
REAPER: at least v5.962
About:	When selected item is deleted, if there's next on the same track,
	next item is selected, else if there's previous, previous item is selected.  
	Or vice versa if enabled in the USER SETTINGS section.  
	Multiple item selection is supported.
]]
-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- Default primary selection target is next item.
-- This setting makes it previous item and only if absent, next item is selected.
-- To enable place any alphanumetic character between the quotation marks.

local REVERSE_SELECTION_TARGET = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper

local sel_itms_t = {}
local sel_itms_trks_t = {}

	-- collect selected items and their tracks
	for i = 0, r.CountSelectedMediaItems(0)-1 do
	local item = r.GetSelectedMediaItem(0,i)
	sel_itms_t[#sel_itms_t+1] = item
	sel_itms_trks_t[#sel_itms_trks_t+1] = r.GetMediaItemTrack(item)
	end
	

r.Undo_BeginBlock()

	
local REVERSE = #REVERSE_SELECTION_TARGET:gsub(' ','') > 0

	-- iterate over stored tracks
	for _, tr in ipairs(sel_itms_trks_t) do
		for i = r.CountTrackMediaItems(tr)-1, 0, -1 do
		local item = r.GetTrackMediaItem(tr, i)
			for _, sel_itm in ipairs(sel_itms_t) do
				if item == sel_itm then
				local next = r.GetTrackMediaItem(tr, i+1)
				local prev = r.GetTrackMediaItem(tr, i-1)
					if not REVERSE then
					sel_next_or_prev = next and r.SetMediaItemSelected(next, true) or not next and prev and r.SetMediaItemSelected(prev, true)
					else 
					sel_prev_or_next = prev and r.SetMediaItemSelected(prev, true) or not prev and next and r.SetMediaItemSelected(next, true)
					end
				r.DeleteTrackMediaItem(r.GetMediaItemTrack(sel_itm), sel_itm)
				end
			end
		end
	end
	
r.UpdateArrange()
	
r.Undo_EndBlock('Delete selected items and select next/prev', -1)




