-- @description FX list menu
-- @author Tagirijus
-- @version 1.3
-- @changelog When shift+clicking TrackFXs bypass state is now being toggled and with ctrl+clicking a TrackXF gets removed.
-- @about
--   # Description
--
--   This plugin will open a quick drop down menu on the mouse cursor listing all the FX for the selected track. A click on any FX will open its window floating.

local FXINDEX = 0
local TRACK = -1
local FOCUSED_WINDOW = nil


function debugMsg(msg)
	reaper.ShowMessageBox(tostring(msg), 'DEBUG MSG', 0)
end


function OpenFXMenu()
	-- Since I create a GUI just for the popup menu,
	-- which would get the actual focus, I "store" the
	-- FX window, which had focus before that into
	-- a variable to be able to know later in the
	-- script which FX window had focus in the first
	-- place.
	FOCUSED_WINDOW = reaper.JS_Window_GetForeground()

	TRACK = reaper.GetSelectedTrack(0, 0)
	if TRACK == nil then
		return nil
	end
	FXList = GetFXListForTrack(TRACK)
	if FXList == nil then
		return nil
	end
	showPopup(FXList)
end

function showPopup(content)
	-- Here I create a GUI window, which I will place
	-- (and thus "hide") outside the screen, just
	-- to be able to show a popup menu
	local title = "Hidden gfx window for FX List menu"
	gfx.init(title, 0, 0, 0, 0, 0)
	local hwnd = reaper.JS_Window_Find(title, true)
	local out = 0
	if hwnd then
		out = 7000
		reaper.JS_Window_Move(hwnd, -out, -out)
	end
	out = reaper.GetOS():find("OSX") and 0 or out
	gfx.x, gfx.y = gfx.mouse_x + out, gfx.mouse_y + out
	FXINDEX = gfx.showmenu(content)
	gfx.quit()
end

function GetFXListForTrack(track)
	local FXCount = reaper.TrackFX_GetCount(track)
	if FXCount == 0 then
		return nil
	end
	local FXList = ""
	for i = 0, FXCount - 1 do
		retval, buf = reaper.TrackFX_GetFXName(track, i, '')
		FXName = stripFXName(buf)
		FXName = modifyFXNameForEnabled(track, i, FXName)
		FXName = modifyFXNameForShowStatus(track, i, FXName)
		FXList = FXList .. FXName .. "|"
	end
	return FXList
end

function modifyFXNameForEnabled(track, fxid, FXName)
	if not reaper.TrackFX_GetEnabled(track, fxid) then
		FXName = '( ' .. FXName .. ' )'
	end
	return FXName
end

function modifyFXNameForShowStatus(track, fxid, FXName)
	hwnd = reaper.TrackFX_GetFloatingWindow(track, fxid)
	title = reaper.JS_Window_GetTitle(reaper.TrackFX_GetFloatingWindow(track, fxid))
	if hwnd then
		if fxHasFocus(hwnd) then
			FXName = ' >>> ' .. FXName
		else
			FXName = ' > ' .. FXName
		end
	end
	return FXName
end

function fxHasFocus(hwnd)
	focus_title = reaper.JS_Window_GetTitle(FOCUSED_WINDOW)
	hwnd_title = reaper.JS_Window_GetTitle(hwnd)
	-- debugMsg(focus_title)
	-- debugMsg(hwnd_title)
	if focus_title == hwnd_title then
		return true
	else
		return false
	end
end


function stripFXName(fxname)
	-- I almost copied the function from the MFXList script by M Fabian
	local fxtype = fxname:match("(.-:)") or "VID:"  -- Video processor FX don't have prefixes
	local segments = split(fxname, "/")
	local trimmed_fx_name = segments[#segments]

	-- Strip parenthesized text
	trimmed_fx_name = trimmed_fx_name:gsub("%([^()]*%)", "")

	--[[ -- Something is wronmg with this claim, comes from PR #25
	-- JSFX doesn't have "JS:" appended to it like "VST" does, so let's fake-append it for uniformity and easier if/else logic
	if fxtype == "JS:" then
		trimmed_fx_name = "JS: " .. trimmed_fx_name
	end
	--]]

	-- For video processor we remove trailing " -- video processor"
	if fxtype == "VID:" then
		trimmed_fx_name = trimmed_fx_name:gsub(" -- video processor", "")
	end

	trimmed_fx_name = trimmed_fx_name:gsub("(.-:)" .. "%s", "") -- up to colon and then space, replace by nothing

	return trim(trimmed_fx_name)
end

function split(str, sep)
	local fields = {}
	local pattern = str.format("([^%s]+)", sep)
	str:gsub(
		pattern,
		function(c)
			fields[#fields + 1] = c
		end
	)
	return fields
end

function trim(s)
	return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end


function ShowOrHideOrFocus(track, fxIndex)
	local visibility = reaper.TrackFX_GetFloatingWindow(track, fxIndex)
	if visibility == nil then
		reaper.TrackFX_Show(track, fxIndex, 3)
	else
		if fxHasFocus(visibility) then
			reaper.TrackFX_Show(track, fxIndex, 2)
		else
			reaper.JS_Window_SetForeground(visibility)
		end
	end
end


function toggleBypass(track, fxid)
	local bypass_state = reaper.TrackFX_GetEnabled(track, fxid)
	reaper.TrackFX_SetEnabled(track, fxid, not bypass_state)
end


function main()
	reaper.Undo_BeginBlock()

	-- Open the popup for chosing the FX
	OpenFXMenu()

	-- Interprete the selection
	if FXINDEX > 0 then
		ctrl = reaper.JS_Mouse_GetState(4)
		shift = reaper.JS_Mouse_GetState(8)

		if ctrl == 4 and shift == 0 then
			-- Only Ctrl is being held down during click
			-- DELETE FX
			-- Since Alt closes the popup, I am using Ctrl to delete FX
			-- (by default in Reaper it is by Alt+Clicking though!)
			reaper.TrackFX_Delete(TRACK, FXINDEX - 1)
		elseif ctrl == 0 and shift == 8 then
			-- Only Shift is being held down during click
			-- BYPASS TOGGLE
			toggleBypass(TRACK, FXINDEX - 1)
		elseif ctrl == 4 and shift == 8 then
			-- Ctrl AND Shift are being held down during click
			-- For future stuff ...
			debugMsg('Ctrl+Shift is reserved for future stuff. (-;')
		else
			-- no Ctrl or Shift is held down during click
			ShowOrHideOrFocus(TRACK, FXINDEX - 1)
		end
	end

	reaper.Undo_EndBlock("Tagirijus: FX list menu", -1)
end

main()
