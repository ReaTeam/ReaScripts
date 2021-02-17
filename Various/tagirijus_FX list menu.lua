-- @description FX list as popup
-- @author Manuel Senfft
-- @version 1.0
-- @changelog First version!
-- @about
--   # Description
--
--   This plugin will open a quick drop down menu on the mouse cursor listing all the FX for the selected track. A click on any FX will open its window floating.

--[[
 * ReaScript Name: tagirijus_FX list menu.lua
 * Author: Manuel Senfft (Tagirijus)
 * Licence: MIT
 * REAPER: 6.23
 * Extensions: None
 * Version: 1.0
--]]

local FXINDEX = 0
local TRACK = -1


function debugMsg(msg)
	reaper.ShowMessageBox(tostring(msg), 'DEBUG MSG', 0)
end


function OpenFXMenu()
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
	local title = "Hidden gfx window for showing the markers showmenu"
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
	if reaper.TrackFX_GetFloatingWindow(track, fxid) then
		FXName = ' >>> ' .. FXName
	end
	return FXName
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


function ShowOrHide(track, fxIndex)
	local visibility = reaper.TrackFX_GetFloatingWindow(track, fxIndex)
	if visibility == nil then
		reaper.TrackFX_Show(track, fxIndex, 3)
		if BypassWhenHidden == 1 then
			reaper.TrackFX_SetEnabled(track, fxIndex, true)
		end
	else
		reaper.TrackFX_Show(track, fxIndex, 2)
		if BypassWhenHidden == 1 then
			reaper.TrackFX_SetEnabled(track, fxIndex, false)
		end
	end
end


function main()
	reaper.Undo_BeginBlock()

	-- Open the popup for chosing the FX
	OpenFXMenu()

	-- Interprete the selection
	if FXINDEX > 0 then
		ShowOrHide(TRACK, FXINDEX - 1)
	end

	reaper.Undo_EndBlock("Tagirijus: FX list menu", -1)
end

main()
