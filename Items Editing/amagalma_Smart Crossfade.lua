-- @description Smart Crossfade
-- @author amagalma
-- @version 1.50
-- @changelog
--   - fixed one bug, improved code in many places
--   - from now on the setting for the crossfade length and shape is gotten automatically from Reaper Preferences ("Overlap and crossfade items when splitting, length" and "Default crossfade shape")
--   - updated ReaPack info
-- @link https://forum.cockos.com/showthread.php?t=195490
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Crossfades selected items
--
--   - If any two items are adjacent then it creates a crossfade on the left side of the items' touch point
--   - If any two items are almost adjacent and their gap is less or equal to the default crossfade time then a crossfade is created
--   - If items overlap then it creates a crossfade at the overlapping area
--   - If there is a time selection covering part of both items, then it crossfades at the time selection area (items do not have to touch - closes the gap)
--   - Can be used with as many items in different tracks as you like
--   - Smart undo point creation (only if there has been at least one change)
--   - You can set inside the script if you want to keep the time selection or remove it (default: remove)
--   - You can set inside the script if you want to keep selected the previously selected items or not (default: keep selected)
--   - Default crossfade length and type are gotten automatically from Reaper Preferences ("Overlap and crossfade items when splitting, length" and "Default crossfade shape")


----------------------------------- USER SETTINGS -------------------------------------------------
                                                                                                 --
local keep_selected  = 1 -- Set to 1 if you want to keep the items selected (else unselect all)  --
local remove_timesel = 1 -- Set to 1 if you want to remove the time selection (else keep it)     --
                                                                                                 --
---------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------

local item_cnt = reaper.CountSelectedMediaItems(0)
if item_cnt < 2 then return end
local math = math
local sel_item = {}
local sel_start, sel_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
local change = false -- to be used for undo point creation
local timeselexists
local debug = true
if debug then reaper.ClearConsole() end
local xfadetime = tonumber(({reaper.get_config_var_string( "defsplitxfadelen" )})[2]) or 0.01
local xfadeshape = tonumber(({reaper.get_config_var_string( "defxfadeshape" )})[2]) or 7

local function eq( a, b ) -- equal
  return (math.abs( a - b ) < 0.00001)
end

local function leq( a, b ) -- a less than or equal to b
	return a < b + 0.00001
end

local function geq( a, b ) -- a greater than or equal to b
	return a + 0.00001 > b 
end

local function Msg(str)
	if debug then reaper.ShowConsoleMsg(tostring(str) .."\n") end
end
---------------------------------------------------------------------------------------------------

local function FadeIn(item, value)
  reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO", value)
  reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", xfadeshape)
end

local function FadeOut(item, value)
  reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO", value)
  reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", xfadeshape)
end

local function FadeInOK(item, value)
  if eq( reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO"), value) and
     reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE") == xfadeshape
  then
    return true
  end
end

local function FadeOutOK(item, value)
  if eq( reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO"), value) and
     reaper.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE") == xfadeshape
  then
		return true
	end
end

local function CrossfadeOK(item, prev_item, second_start, first_end)
  local prev_fadelen = reaper.GetMediaItemInfo_Value(prev_item, "D_FADEOUTLEN_AUTO")
  local next_fadelen = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO")
  if prev_fadelen > 0 and eq( next_fadelen, prev_fadelen ) and
     eq( first_end - prev_fadelen, second_start )
  then
    return true
  end
end

---------------------------------------------------------------------------------------------------

reaper.PreventUIRefresh(1)

local trimstate = reaper.GetToggleCommandStateEx( 0, 41117) -- get Options: Toggle trim behind items state
if trimstate == 1 then
	reaper.Main_OnCommand(41121, 0) -- Options: Disable trim behind items when editing
end

-- Store Selected items
for i = 1, item_cnt do
	local item = reaper.GetSelectedMediaItem(0, 0)
	sel_item[i] = item
	reaper.SetMediaItemSelected(item, false)
end

for i = 2, item_cnt do
	local item = sel_item[i]
	local prev_item = sel_item[i-1]
	-- check if item and previous item are on the same track
	if reaper.GetMediaItem_Track(item) == reaper.GetMediaItem_Track(prev_item) then
		local second_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
		local second_end = second_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
		local first_start = reaper.GetMediaItemInfo_Value(prev_item, "D_POSITION")
		local first_end = first_start + reaper.GetMediaItemInfo_Value(prev_item, "D_LENGTH")
		if first_end < second_start - xfadetime and (sel_start == sel_end or (first_end < sel_start and second_start > sel_end)) then
			-- items do not touch and there is no time selection covering parts of both items
			-- do nothing
			Msg("not touch - gap greater than xfadetime")
		elseif geq( second_start - first_end, xfadetime) then
		--leq( first_start, second_start) and geq( first_end, second_end) then
			-- one item encloses the other
			-- do nothing
			Msg("enclosure")
		elseif sel_start ~= sel_end and geq(sel_end, second_start) and leq(sel_end, second_end) and leq(sel_start, first_end) and geq(sel_start, first_start) then
			-- time selection exists and covers parts of both items
			Msg("inside time selection")
			timeselexists = 1
			local timesel = sel_end - sel_start
			if not FadeInOK(item, timesel) or not FadeOutOK(prev_item, timesel) then
				-- previous item
				reaper.SetMediaItemSelected(prev_item, true)
				reaper.ApplyNudge(0, 1, 3, 1, sel_end, 0, 0)
				FadeOut(prev_item, timesel)
				reaper.SetMediaItemSelected(prev_item, false)
				-- item
				reaper.SetMediaItemSelected(item, true)
				reaper.ApplyNudge(0, 1, 1, 1, sel_start, 0, 0)
				FadeIn(item, timesel)
				reaper.SetMediaItemSelected(item, false)
				change = true
			end
		elseif geq(second_start, first_end) and leq(second_start, first_end + xfadetime)
			then -- items are adjacent (or there is a gap smaller or equal to the crossfade time)
			Msg("adjacent - gap: " .. second_start - first_end)
			if not CrossfadeOK(item, prev_item, second_start, first_end) then
				-- previous item (ensure it ends exactly at the start of the next item)
				reaper.SetMediaItemSelected(prev_item, true)
				reaper.ApplyNudge(0, 1, 3, 1, second_start, 0, 0)
				FadeOut(prev_item, xfadetime)
				reaper.SetMediaItemSelected(prev_item, false)
				-- item
				reaper.SetMediaItemSelected(item, true)
				reaper.ApplyNudge(0, 1, 1, 1, second_start - xfadetime, 0, 0)
				FadeIn(item, xfadetime)
				reaper.SetMediaItemSelected(item, false)
				change = true
			end
		elseif first_end > second_start then -- items are overlapping
			local overlap = first_end - second_start
			Msg("overlap")
			if overlap > xfadetime then
				Msg("overlap > xfadetime")
				if not FadeInOK(item, overlap) or not FadeOutOK(prev_item, overlap) then
					FadeIn(item, overlap)
					FadeOut(prev_item, overlap)
					change = true
				end
			else
				Msg("overlap <= xfadetime")
				if not CrossfadeOK(item, prev_item, second_start, first_end) then
					-- previous item (fade out xfadetime)
					reaper.SetMediaItemSelected(prev_item, true)
					FadeOut(prev_item, xfadetime)
					reaper.SetMediaItemSelected(prev_item, false)
					-- extend second item so that it overlaps with previous one
					reaper.SetMediaItemSelected(item, true)
					reaper.ApplyNudge(0, 1, 1, 1, second_start - xfadetime + overlap, 0, 0)
					FadeIn(item, xfadetime)
					reaper.SetMediaItemSelected(item, false)
					change = true
				end
			end
		end
	end
end

-- Re-enable trim behind items (if it was enabled)
if trimstate == 1 then
	reaper.Main_OnCommand(41120,0)
end

-- Undo point creation ----------------------------------------------------------------------------
if change then
	Msg("done")
  if keep_selected == 1 then -- keep selected the previously selected items
    for i = 1, #sel_item do
      reaper.SetMediaItemSelected(sel_item[i], true)
    end
  end
	local timesel_removed = 0
  if remove_timesel == 1 and timeselexists == 1 then -- remove time selection
    reaper.GetSet_LoopTimeRange(true, false, sel_start, sel_start, false)
    timesel_removed = 8
  end
	reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.Undo_OnStateChangeEx("Smart Crossfade selected items", 4|timesel_removed, -1)
else -- No undo
	Msg("nothing done")
  -- restore item selection
  for i = 1, #sel_item do
    reaper.SetMediaItemSelected(sel_item[i], true)
  end
  reaper.PreventUIRefresh(-1)
	reaper.UpdateArrange()
  reaper.defer(function() end)
end
