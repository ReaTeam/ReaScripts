--[[
Description: Track selection follows item selection
Version: 1.0.2
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	Bug fix
Links:
	Forum Thread http://forum.cockos.com/showthread.php?p=1583631
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
	Runs in the background and allows you to replicate a behavior 
	from Cubase - when selecting items, the	track selection is 
	changed to match and the mixer view is scrolled to show the first
	selected track.
	
	To exit, open the Actions menu, and click on:
	Running script: Lokasenna_Track selection follows item selection.lua
	down at the bottom.
	
	Note: This script is a rewrite of:
	tritonality_X-Raym_Cubase_Style_SelectTrack_On_ItemSelect.lua
	
	It had a few bugs and I couldn't understand the original code
	well enough to fix them, so I opted to rewrite it from scratch.
Extensions:
--]]

-- Licensed under the GNU GPL v3

local function Msg(str)
	reaper.ShowConsoleMsg(tostring(str).."\n")
end

local sel_items, sel_tracks = {}, {}

local num_tracks, num_items

-- Very limited for error checking, types, etc
local function compare_tables(t1, t2)
  if #t1 ~= #t2 then return false end
  for k, v in pairs(t1) do
    if v ~= t2[k] then return false end
  end
  return true
end

local function Main()

	-- Get the number of selected tracks
	num_tracks = reaper.CountSelectedTracks( 0 )

	-- Grab their MediaTracks into a table
	local cur_tracks = {}
	for i = 1, num_tracks do
		cur_tracks[i] = reaper.GetSelectedTrack( 0, i - 1)
	end

	if compare_tables(sel_tracks, cur_tracks) then	

		-- The track selection hasn't been changed, so we
		-- can move on to looking at the item selection

		-- Get the number of selected items
		num_items = reaper.CountSelectedMediaItems( 0 ) 
		--Msg("num = "..num_items)
		
		-- Grab their MediaItems into a table
		local cur_items = {}
		for i = 1, num_items do
			cur_items[i] = reaper.GetSelectedMediaItem( 0, i - 1 )
		end
		
		--Msg("#cur = "..#cur_items.."  |  #sel = "..#sel_items)

		-- If all MediaItems have a partner then the selection hasn't changed
		if not compare_tables(sel_items, cur_items) then
			
			-- If it has...
			--Msg("item selection changed")
			--Msg("\t"..num_items.." items selected")
			
			sel_items = cur_items
			
			-- Unselect all tracks
			reaper.Main_OnCommand(40297, 0)
			
			-- Make a list of the tracks for these items
			local tracks = {}
			for i = 1, num_items do
				table.insert(tracks, reaper.GetMediaItem_Track(sel_items[i]) )
			end
			
			-- Select them
			for k, v in pairs(tracks) do
				reaper.SetMediaTrackInfo_Value(v, "I_SELECTED", 1)
			end
			
			------------------------------------------
			--Optional, comment this out if you want--
			if num_items > 0 then
				reaper.SetMixerScroll( reaper.GetSelectedTrack(0, 0) )
			end
			------------------------------------------
			
		else
		
			--Msg("item compare returned true")
		end


	else
	
		-- User changed the track selection
		--Msg("track selection changed")
		
		sel_tracks = cur_tracks
		
	end

	reaper.defer(Main)

end

--Msg("starting")
Main()
