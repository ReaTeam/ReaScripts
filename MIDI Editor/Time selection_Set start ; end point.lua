--[[
ReaScript name: Time selection: Set start/end point
Author: REAPER community
Version: 1.0
About: Curiously the action is unavalable in the sections other than the Main.
	     This is meant to make up for that so it can be used in custom actions
	     in other contexts, mainly MIDI Editor.
Metapackage: true
Provides: [main=midi_editor,midi_inlineeditor] . > Time selection_Set start point.lua
		      [main=midi_editor,midi_inlineeditor] . > Time selection_Set end point.lua
]]


local _, scr_name, sect_ID, cmd_ID, _,_,_ = reaper.get_action_context()

local start_point = scr_name:match('([^\\/]+)%.%w+'):match('start point')
local end_point = scr_name:match('([^\\/]+)%.%w+'):match('end point')

reaper.Undo_BeginBlock()

if start_point then
reaper.Main_OnCommand(40625,0)
undo = 'Time selection: Set start point'
elseif end_point then
reaper.Main_OnCommand(40626,0)
undo = 'Time selection: Set end point'
end

reaper.Undo_EndBlock('undo', -1)
