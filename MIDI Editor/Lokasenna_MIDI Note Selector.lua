--[[
Description: MIDI Note Selector
Version: 2.0.1
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
    Fix: Expand error message when the library is missing
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About:
    Takes an existing note selection and selects only every 'n'th
    note.
Extensions:
--]]

-- Licensed under the GNU GPL v3

local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please install 'Lokasenna's GUI library v2 for Lua', available on ReaPack, then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()

GUI.req("Classes/Class - Slider.lua")()
GUI.req("Classes/Class - Button.lua")()

GUI.name = "MIDI Note Selector"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 256, 160
GUI.anchor, GUI.corner = "mouse", "C"

local function get_selection(take)
  local selection = {}
	local note = -2
	while note ~= -1 do

		note = reaper.MIDI_EnumSelNotes(take, note)
		selection[#selection + 1] = note

	end

  return selection
end

local function btn_click()

	local step = GUI.Val("sel_sldr")
	local offset = GUI.Val("off_sldr")

  local editor = reaper.MIDIEditor_GetActive()
  if not editor then return end

  local take = reaper.MIDIEditor_GetTake(editor)
  if not take then return end

  reaper.Undo_BeginBlock()

  local selection = get_selection(take)
  if (not selection or #selection == 0) then return end

  reaper.MIDI_SelectAll(take, 0)
  for i = offset, #selection, step do
    reaper.MIDI_SetNote(take, selection[i], 1)
  end

  reaper.Undo_EndBlock("Lokasenna_MIDI Note Selector", -1)
end

GUI.New("sel_sldr", "Slider", 1, 48, 16, 160, "", 1, 16, 1)
GUI.New("off_sldr", "Slider", 1, 48, 60, 160, "", 1, 16, 0)

GUI.elms.sel_sldr.output = function (val)
  return "Select every " .. GUI.ordinal(tonumber(val)) .. " note,"
end

GUI.elms.off_sldr.output = function (val)
  return "starting with the " .. GUI.ordinal(tonumber(val)) .. " note"
end

GUI.New("btn_go", "Button",	1, 88, 112, 80, 20, "Go!", btn_click)

GUI.Init()
GUI.Main()
