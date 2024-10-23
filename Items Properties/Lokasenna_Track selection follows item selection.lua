--[[
Description: Track selection follows item selection
Version: 1.1.2
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
  Fix: Setting the last touched track wasn't working
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

-- Very limited - no error checking, types, hash tables, etc
local function shallow_equal(t1, t2)
  if #t1 ~= #t2 then return false end
  for k, v in pairs(t1) do
    if v ~= t2[k] then return false end
  end
  return true
end

(function()
  local _, _, sectionId, cmdId = reaper.get_action_context()

  if sectionId ~= -1 then
    reaper.SetToggleCommandState(sectionId, cmdId, 1)
    reaper.RefreshToolbar2(sectionId, cmdId)

    reaper.atexit(function()
      reaper.SetToggleCommandState(sectionId, cmdId, 0)
      reaper.RefreshToolbar2(sectionId, cmdId)
    end)
  end
end)()

local function Main()
	local num_tracks = reaper.CountSelectedTracks( 0 )

	local cur_tracks = {}
	for i = 1, num_tracks do
		cur_tracks[i] = reaper.GetSelectedTrack( 0, i - 1)
  end

  if shallow_equal(sel_tracks, cur_tracks) then
    -- The track selection hasn't been changed, so we
    -- can move on to looking at the item selection

    local num_items = reaper.CountSelectedMediaItems( 0 )

    -- Grab their MediaItems into a table
    local cur_items = {}
    for i = 1, num_items do
      cur_items[i] = reaper.GetSelectedMediaItem( 0, i - 1 )
    end

    -- If all MediaItems have a partner then the selection hasn't changed
    if not shallow_equal(sel_items, cur_items) then
      sel_items = cur_items

      local tracks = {}
      for i = 1, num_items do
        tracks[i] = reaper.GetMediaItem_Track(sel_items[i])
      end

      if #tracks > 0 then
        reaper.PreventUIRefresh(1)

        -- Unselect all tracks
        reaper.Main_OnCommand(40297, 0)

        for _, v in pairs(tracks) do
          reaper.SetTrackSelected(v, true)
        end

        -- "Touch" the first track so we don't mess up things like pasting items
        -- over multiple tracks
        reaper.Main_OnCommand(40914, 0)

        ------------------------------------------
        -- Scroll the mixer to the first selected track
        -- Comment out the lines below if you want
        if num_items > 0 then
          reaper.SetMixerScroll(reaper.GetSelectedTrack(0, 0))
        end
        ------------------------------------------

        reaper.PreventUIRefresh(-1)
        reaper.UpdateArrange()
      end
    end

  -- User changed the track selection manually
  else
    sel_tracks = cur_tracks
  end

	reaper.defer(Main)
end

Main()
