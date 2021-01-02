-- @description Swap 2 items (select both)
-- @author BuyOne
-- @version 1.0
-- @website https://forum.cockos.com/member.php?u=134058

-- Licence: WTFPL

val = reaper.NamedCommandLookup("_BR_SAVE_CURSOR_POS_SLOT_1") -- SWS/BR: Save edit cursor position, slot 01
	if val == 0 then reaper.MB("SWS/S&M extension is not installed.","ERROR",0) return end

itms_cnt = reaper.CountSelectedMediaItems(0)
	if itms_cnt == 0 then error_mess = "No items selected."
	elseif itms_cnt ~= 2 then error_mess = "Exactly 2 items must be selected."
	end
	if error_mess ~= nil then reaper.MB(error_mess,"ERROR",0) return end

item1 = reaper.GetSelectedMediaItem(0,0)
item1_track = reaper.GetMediaItemTrack(item1)
item1_pos = reaper.GetMediaItemInfo_Value(item1, "D_POSITION")
item1_end = reaper.GetMediaItemInfo_Value(item1, "D_LENGTH") + item1_pos
item2 = reaper.GetSelectedMediaItem(0,1)
item2_track = reaper.GetMediaItemTrack(item2)
item2_pos = reaper.GetMediaItemInfo_Value(item2, "D_POSITION")
item2_end = reaper.GetMediaItemInfo_Value(item2, "D_LENGTH") + item2_pos

local function vertically()

reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELTRKWITEM"),0) -- SWS: Select only track(s) with selected item(s)
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVESEL"),0) -- SWS: Save current track selection
reaper.Main_OnCommand(41173,0) -- Item navigation: Move cursor to start of items
reaper.Main_OnCommand(40289,0) -- Item: Unselect all items
reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELFIRSTOFSELTRAX"),0) -- Xenakios/SWS: Select first of selected tracks
reaper.Main_OnCommand(41666,0) -- View: Move cursor left 8 pixels
reaper.Main_OnCommand(40417,0) -- Item navigation: Select and move to next item
reaper.Main_OnCommand(40699,0) -- Edit: Cut items
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTORESEL"),0) -- SWS: Restore saved track selection
reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELLASTOFSELTRAX"),0) -- Xenakios/SWS: Select last of selected tracks
reaper.Main_OnCommand(41666,0) -- View: Move cursor left 8 pixels
reaper.Main_OnCommand(40417,0) -- Item navigation: Select and move to next item
reaper.Main_OnCommand(40001,0) -- Track: Insert new track
reaper.Main_OnCommand(40118,0) -- Item edit: Move items/envelope points down one track/a bit
reaper.Main_OnCommand(40286,0) -- Track: Go to previous track
reaper.Main_OnCommand(42398,0) -- Item: Paste items/tracks
reaper.Main_OnCommand(41173,0) -- Item navigation: Move cursor to start of items
reaper.Main_OnCommand(40289,0) -- Item: Unselect all items
reaper.Main_OnCommand(40285,0) -- Track: Go to next track
reaper.Main_OnCommand(41666,0) -- View: Move cursor left 8 pixels
reaper.Main_OnCommand(40417,0) -- Item navigation: Select and move to next item
reaper.Main_OnCommand(40699,0) -- Edit: Cut items
reaper.Main_OnCommand(40005,0) -- Track: Remove tracks
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTORESEL"),0) -- SWS: Restore saved track selection
reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELFIRSTOFSELTRAX"),0) -- Xenakios/SWS: Select first of selected tracks
reaper.Main_OnCommand(42398,0) -- Item: Paste items/tracks
reaper.Main_OnCommand(41173,0) -- Item navigation: Move cursor to start of items
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTORESEL"),0) -- SWS: Restore saved track selection

end



local function horizontally()

reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELTRKWITEM"),0) -- SWS: Select only track(s) with selected item(s)
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVESEL"),0) -- SWS: Save current track selection
reaper.Main_OnCommand(41173,0) -- Item navigation: Move cursor to start of items
reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_SAVE_CURSOR_POS_SLOT_1"),0) -- SWS/BR: Save edit cursor position, slot 01
	if not adjacent then
	reaper.Main_OnCommand(40319,0) -- Item navigation: Move cursor right to edge of item
	end
reaper.Main_OnCommand(40319,0) -- Item navigation: Move cursor right to edge of item
reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_SAVE_CURSOR_POS_SLOT_2"),0) -- SWS/BR: Save edit cursor position, slot 02
reaper.Main_OnCommand(40289,0) -- Item: Unselect all items
reaper.Main_OnCommand(41666,0) -- View: Move cursor left 8 pixels
reaper.Main_OnCommand(40417,0) -- Item navigation: Select and move to next item
reaper.Main_OnCommand(40699,0) -- Edit: Cut items
reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_RESTORE_CURSOR_POS_SLOT_1"),0) -- SWS/BR: Restore edit cursor position, slot 01
reaper.Main_OnCommand(41666,0) -- View: Move cursor left 8 pixels
reaper.Main_OnCommand(40417,0) -- Item navigation: Select and move to next item
reaper.Main_OnCommand(40001,0) -- Track: Insert new track
reaper.Main_OnCommand(40118,0) -- Item edit: Move items/envelope points down one track/a bit
reaper.Main_OnCommand(40286,0) -- Track: Go to previous track
reaper.Main_OnCommand(42398,0) -- Item: Paste items/tracks
reaper.Main_OnCommand(41173,0) -- Item navigation: Move cursor to start of items
reaper.Main_OnCommand(40285,0) -- Track: Go to next track
reaper.Main_OnCommand(41666,0) -- View: Move cursor left 8 pixels
reaper.Main_OnCommand(40417,0) -- Item navigation: Select and move to next item
reaper.Main_OnCommand(40699,0) -- Edit: Cut items
reaper.Main_OnCommand(40005,0) -- Track: Remove tracks
reaper.Main_OnCommand(40286,0) -- Track: Go to previous track
reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_RESTORE_CURSOR_POS_SLOT_2"),0) -- SWS/BR: Restore edit cursor position, slot 02
reaper.Main_OnCommand(42398,0) -- Item: Paste items/tracks
reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_RESTORE_CURSOR_POS_SLOT_1"),0) -- SWS/BR: Restore edit cursor position, slot 01
reaper.Main_OnCommand(41666,0) -- View: Move cursor left 8 pixels
reaper.Main_OnCommand(40417,0) -- Item navigation: Select and move to next item

end



local function diagonally_bottom_top()

reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELTRKWITEM"),0) -- SWS: Select only track(s) with selected item(s)
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVESEL"),0) -- SWS: Save current track selection
reaper.Main_OnCommand(41173,0) -- Item navigation: Move cursor to start of items
reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_SAVE_CURSOR_POS_SLOT_1"),0) -- SWS/BR: Save edit cursor position, slot 01
reaper.Main_OnCommand(40319,0) -- Item navigation: Move cursor right to edge of item
	if not overlap then
	reaper.Main_OnCommand(40319,0) -- Item navigation: Move cursor right to edge of item
	end
reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_SAVE_CURSOR_POS_SLOT_2"),0) -- SWS/BR: Save edit cursor position, slot 02
reaper.Main_OnCommand(41173,0) -- Item navigation: Move cursor to start of items
reaper.Main_OnCommand(40289,0) -- Item: Unselect all items
reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELLASTOFSELTRAX"),0) -- Xenakios/SWS: Select last of selected tracks
reaper.Main_OnCommand(41666,0) -- View: Move cursor left 8 pixels
reaper.Main_OnCommand(40417,0) -- Item navigation: Select and move to next item
reaper.Main_OnCommand(40699,0) -- Edit: Cut items
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTORESEL"),0) -- SWS: Restore saved track selection
reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELFIRSTOFSELTRAX"),0) -- Xenakios/SWS: Select first of selected tracks
reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_RESTORE_CURSOR_POS_SLOT_2"),0) -- SWS/BR: Restore edit cursor position, slot 02
reaper.Main_OnCommand(41666,0) -- View: Move cursor left 8 pixels
reaper.Main_OnCommand(40417,0) -- Item navigation: Select and move to next item
reaper.Main_OnCommand(40001,0) -- Track: Insert new track
reaper.Main_OnCommand(40118,0) -- Item edit: Move items/envelope points down one track/a bit
reaper.Main_OnCommand(40286,0) -- Track: Go to previous track
reaper.Main_OnCommand(42398,0) -- Item: Paste items/tracks
reaper.Main_OnCommand(41173,0) -- Item navigation: Move cursor to start of items
reaper.Main_OnCommand(40289,0) -- Item: Unselect all items
reaper.Main_OnCommand(40285,0) -- Track: Go to next track
reaper.Main_OnCommand(41666,0) -- View: Move cursor left 8 pixels
reaper.Main_OnCommand(40417,0) -- Item navigation: Select and move to next item
reaper.Main_OnCommand(40699,0) -- Edit: Cut items
reaper.Main_OnCommand(40005,0) -- Track: Remove tracks
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTORESEL"),0) -- SWS: Restore saved track selection
reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELLASTOFSELTRAX"),0) -- Xenakios/SWS: Select last of selected tracks
reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_RESTORE_CURSOR_POS_SLOT_1"),0) -- SWS/BR: Restore edit cursor position, slot 01
reaper.Main_OnCommand(42398,0) -- Item: Paste items/tracks
reaper.Main_OnCommand(41173,0) -- Item navigation: Move cursor to start of items
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTORESEL"),0) -- SWS: Restore saved track selection

end



local function diagonally_top_bottom()

reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELTRKWITEM"),0) -- SWS: Select only track(s) with selected item(s)
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVESEL"),0) -- SWS: Save current track selection
reaper.Main_OnCommand(41173,0) -- Item navigation: Move cursor to start of items
reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_SAVE_CURSOR_POS_SLOT_1"),0) -- SWS/BR: Save edit cursor position, slot 01
reaper.Main_OnCommand(40319,0) -- Item navigation: Move cursor right to edge of item
	if not overlap then
	reaper.Main_OnCommand(40319,0) -- Item navigation: Move cursor right to edge of item
	end
reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_SAVE_CURSOR_POS_SLOT_2"),0) -- SWS/BR: Save edit cursor position, slot 02
reaper.Main_OnCommand(41173,0) -- Item navigation: Move cursor to start of items
reaper.Main_OnCommand(40289,0) -- Item: Unselect all items
reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELFIRSTOFSELTRAX"),0) -- Xenakios/SWS: Select first of selected tracks
reaper.Main_OnCommand(41666,0) -- View: Move cursor left 8 pixels
reaper.Main_OnCommand(40417,0) -- Item navigation: Select and move to next item
reaper.Main_OnCommand(40699,0) -- Edit: Cut items
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTORESEL"),0) -- SWS: Restore saved track selection
reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELLASTOFSELTRAX"),0) -- Xenakios/SWS: Select last of selected tracks
reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_RESTORE_CURSOR_POS_SLOT_2"),0) -- SWS/BR: Restore edit cursor position, slot 02
reaper.Main_OnCommand(41666,0) -- View: Move cursor left 8 pixels
reaper.Main_OnCommand(40417,0) -- Item navigation: Select and move to next item
reaper.Main_OnCommand(40001,0) -- Track: Insert new track
reaper.Main_OnCommand(40118,0) -- Item edit: Move items/envelope points down one track/a bit
reaper.Main_OnCommand(40286,0) -- Track: Go to previous track
reaper.Main_OnCommand(42398,0) -- Item: Paste items/tracks
reaper.Main_OnCommand(41173,0) -- Item navigation: Move cursor to start of items
reaper.Main_OnCommand(40289,0) -- Item: Unselect all items
reaper.Main_OnCommand(40285,0) -- Track: Go to next track
reaper.Main_OnCommand(41666,0) -- View: Move cursor left 8 pixels
reaper.Main_OnCommand(40417,0) -- Item navigation: Select and move to next item
reaper.Main_OnCommand(40699,0) -- Edit: Cut items
reaper.Main_OnCommand(40005,0) -- Track: Remove tracks
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTORESEL"),0) -- SWS: Restore saved track selection
reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELFIRSTOFSELTRAX"),0) -- Xenakios/SWS: Select first of selected tracks
reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_RESTORE_CURSOR_POS_SLOT_1"),0) -- SWS/BR: Restore edit cursor position, slot 01
reaper.Main_OnCommand(42398,0) -- Item: Paste items/tracks
reaper.Main_OnCommand(41173,0) -- Item navigation: Move cursor to start of items
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTORESEL"),0) -- SWS: Restore saved track selection

end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

group = reaper.GetToggleCommandStateEx(0, 1156) -- Options: Toggle item grouping override
	if group == 1 then reaper.Main_OnCommand(1156,0) end -- Options: Toggle item grouping override (set to OFF)

ripple_per_track = reaper.GetToggleCommandStateEx(0, 41990) -- Toggle ripple editing per-track
ripple_all_tracks = reaper.GetToggleCommandStateEx(0, 41991) -- Toggle ripple editing all tracks
	if ripple_per_track == 1 or ripple_all_tracks == 1 then reaper.Main_OnCommand(40309,0) -- Set ripple editing off
	end


	if item1_pos == item2_pos and item1_track ~= item2_track then vertically(); undo = "items vertically"
	elseif item1_pos ~= item2_pos then
		if item1_track == item2_track then
			if item1_end == item2_pos then adjacent = true end
		horizontally(); undo = "items horizontally"
		elseif item1_track ~= item2_track then
			if item1_pos > item2_pos then
				if item1_pos > item2_end then diagonally_bottom_top(); undo = "items diagonally /"
				else overlap = true; diagonally_bottom_top(); undo = "overlapping items diagonally /"
				end
			elseif item1_pos < item2_pos then
				if item2_pos > item1_end then diagonally_top_bottom(); undo = "items diagonally \\"
				else overlap = true; diagonally_top_bottom(); undo = "overlapping items diagonally \\"
				end
			end
		end
	end

	if group == 1 then reaper.Main_OnCommand(1156,0) end -- Options: Toggle item grouping override (set back to ON)

	-- Re-enable Ripple mode
	if ripple_per_track == 1 then reaper.Main_OnCommand(40310,0) -- Set ripple editing per-track
	elseif ripple_all_tracks == 1 then reaper.Main_OnCommand(40311,0) -- Set ripple editing all tracks
	end

reaper.Undo_EndBlock("Swap 2 "..undo,-1)
reaper.PreventUIRefresh(-1)



