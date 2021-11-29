--[[
ReaScript name: Ripple edit per track when selected item length changes from the right
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
Screenshots: https://git.io/JME3D
About:	An enhancement to 'Ripple edit per track' mode.
		As such only works when this mode is enabled.
		Makes all items following the one whose right edge
		is being extended/trimmed move just like regular 
		Ripple edit does when selected items are moved.  
		The item whose right edge is being extended/trimmed
		MUST BE SELECTED, otherwise no change occurs in items 
		positioning.  
		
		CAUTION:   
		Do not drag the right edge fast because the data won't 
		be processed as fast and item positions will end up being 
		messed up.  
		Avoid dragging item right edge over following items.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- Ripple edit AFTER selecting the item whose right edge position has changed,
-- (see demo at the link provided in the 'Screenshots' tag above);
-- could be useful to avoid the risk of disturbing items alignment while
-- dragging the right edge by 1) deselecting ALL items, 2) changing the item's
-- right edge position and 3) re-selecting it;
-- in this case the change occurs in one go instead of being incremental and gradual;
-- for this to work the edited item must be the last selected before deselecting
-- all and the fist one selected afterwards;
-- while the option is ON, to prevent ripple taking effect after changing the
-- length of the item, select another item instead and only then select the one
-- which has been edited;
-- If not enabled change in positioning will only occur as long as the item
-- whose right edge position is being changed is selected

RIPPLE_POST_FACTUM = "1" -- any alphanumeric character

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper

local item_start_init
local item_end_init

function RUN()

	if r.GetToggleCommandStateEx(0, 41990) == 1 -- Toggle ripple editing per-track
	then -- only run when Ripple edit per track is enabled

	local item = r.GetSelectedMediaItem(0,0)

		if item then

		local item_start = r.GetMediaItemInfo_Value(item, 'D_POSITION')
		local item_end = item_start + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
		local item_idx = r.GetMediaItemInfo_Value(item, 'IP_ITEMNUMBER')

			if item_start ~= item_start_init and item_end ~= item_end_init then -- when the whole selected item has been moved or another item has been selected, just update; if moved, native Ripple edit will take care of the changes in Arrange
			item_start_init = item_start
			item_end_init = item_end
			elseif item_end ~= item_end_init and item_start == item_start_init then -- when only right edge pos has changed, move next item
			local item_tr = r.GetMediaItemTrack(item)
				for i = item_idx+1, r.CountTrackMediaItems(item_tr)-1 do
				local item_next = r.GetTrackMediaItem(item_tr, i)
					if item_next then
					local item_next_pos = r.GetMediaItemInfo_Value(item_next, 'D_POSITION')
					r.SetMediaItemInfo_Value(item_next, 'D_POSITION', item_next_pos + item_end - item_end_init)
					end
				end
			item_end_init = item_end -- update stored value
			end
      
		elseif not RIPPLE_POST_FACTUM then -- reset when no items selected
		item_start_init = nil
		item_end_init = nil
		end
	end

r.defer(RUN)

end

RIPPLE_POST_FACTUM = #RIPPLE_POST_FACTUM:gsub(' ','') > 0

-- (re)setting toggle state and updating toolbar button
local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()

r.SetToggleCommandState(sect_ID, cmd_ID, 1)
r.RefreshToolbar(cmd_ID)

RUN()

r.atexit(function() r.SetToggleCommandState(sect_ID, cmd_ID, 0); r.RefreshToolbar(cmd_ID) end)





