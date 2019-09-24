--[[
Description: Item selection follows the edit cursor for selected tracks
Version: 1.1.0
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	Add: Script's toggle state is tracked in the action list and on toolbars
Links:
	Forum Thread http://forum.cockos.com/showthread.php?p=1583631
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About:
  Similar to functionality available on a Yamaha NUAGE console, this script
  updates the item selection as you move the edit cursor - only items under
  the cursor, on the selected tracks, will be selected.
Provides:
    [main] . > Lokasenna_Item selection follows the edit cursor for selected tracks (preserve existing selection).lua
--]]

-- Licensed under the GNU GPL v3

local function Msg(str)
	reaper.ShowConsoleMsg(tostring(str).."\n")
end

local _XENAKIOS_SELITEMSUNDEDCURSELTX =
  reaper.NamedCommandLookup("_XENAKIOS_SELITEMSUNDEDCURSELTX")

local PRESERVE_SELECTION = ({reaper.get_action_context()})[2]
  :match("([^/\\_]+).lua$")
  :match("preserve")

local sel_tracks = {}
local cursor_pos

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

-- Very limited - no error checking, types, hash tables, etc
local function shallow_equal(t1, t2)
  if #t1 ~= #t2 then return false end
  for k, v in pairs(t1) do
    if v ~= t2[k] then return false end
  end
  return true
end

local function Main()
  local current_pos = reaper.GetCursorPosition()
	local num_tracks = reaper.CountSelectedTracks( 0 )

  -- Using a lookup table ({ tr = true}) for easy checking against items' tracks
	local cur_tracks = {}
  for i = 1, num_tracks do
    local tr = reaper.GetSelectedTrack( 0, i - 1)
    cur_tracks[tr] = true
  end

	if current_pos ~= cursor_pos or not shallow_equal(sel_tracks, cur_tracks) then
    reaper.PreventUIRefresh(1)

    local sel_items = {}
    if PRESERVE_SELECTION then
      local num_sel_items = reaper.CountSelectedMediaItems(0)

      for i = 1, num_sel_items do
        local item = reaper.GetSelectedMediaItem(0, i - 1)
        local tr = reaper.GetMediaItem_Track(item)

        if cur_tracks[tr] then
          sel_items[#sel_items + 1] = item
        end
      end
    end

    reaper.Main_OnCommand(_XENAKIOS_SELITEMSUNDEDCURSELTX, 0)

    if PRESERVE_SELECTION then
      for _, item in pairs(sel_items) do
        reaper.SetMediaItemSelected(item, true)
      end
    end

    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()

    cursor_pos = current_pos
		sel_tracks = cur_tracks
	end

	reaper.defer(Main)
end

Main()
