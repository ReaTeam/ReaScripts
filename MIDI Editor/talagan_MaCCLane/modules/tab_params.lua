-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local Enum = require "classes/enum"

local generic_mode_def = {
    { name = 'bypass', human = "Bypass" },
    { name = 'custom', human = "Custom" },
}

local color_mode_def = {
    { name = 'bypass',      human = "Bypass" },
    { name = 'overload',    human = "Overload" },
}

local margin_mode_def = {
    { name = 'bypass',      human = "Bypass" },
    { name = 'overload',    human = "Overload" },
}

local piano_roll_def = {
    { name = 'bypass',    human = "Bypass" },
    { name = 'custom',    human = "Custom" },
    { name = 'fit',       human = "Fit Notes" }
}

-- Main=0, Main (alt recording)=100, MIDI Editor=32060, MIDI Event List Editor=32061, MIDI Inline Editor=32062, Media Explorer=32063
local action_section_def = {
    { name = "main",                human = "Main",         v = 100 },
    { name = "midi_editor",         human = "Midi Editor",  v = 32060 }
}

local action_when_def = {
    { name = 'before' , human = "Before" },
    { name = 'after'  , human = "After" }
}

local docking_mode_def = {
    { name = 'bypass',   human = 'Bypass' },
    { name = 'windowed', human = 'Windowed' },
    { name = 'docked',   human = 'Docked' },
}

local if_docked_mode_def = {
    { name = 'bypass',   human = 'Bypass' },
    { name = 'maximize', human = 'Maximize' },
    { name = 'minimize', human = 'Minimize' },
    { name = 'custom',   human = 'Custom' },
}

local if_windowed_mode_def = {
    { name = 'bypass',   human = 'Bypass' },
    { name = 'custom',   human = 'Custom' },
}

local sort_strategy_def = {
    { name = 'pti_alpha',   human = 'Project|Track|Item - Alphabetical' },
    { name = 'pti_prio',    human = 'Project|Track|Item - Priority' },
    { name = 'mixed_alpha', human = 'Mixed Types - Alphabetical' },
    { name = 'mixed_prio', human = 'Mixed Types - Priority' },
}

local piano_roll_fit_time_scope = {
    { name = 'visible',       human = 'Visible Range' },
    { name = 'everywhere',    human = 'Everywhere' },
}

local piano_roll_fit_owner_scope = {
    { name = 'take',   human = 'Active take' },
    { name = 'track',  human = "Active take's track" },
    { name = 'takes',  human = "All ME active takes" }
}

return {
    DockingMode     = Enum:new(docking_mode_def),
    CCLaneMode      = Enum:new(generic_mode_def),
    PianoRollMode   = Enum:new(piano_roll_def),
    MidiChanMode    = Enum:new(generic_mode_def),
    ActionMode      = Enum:new(generic_mode_def),
    ActionSection   = Enum:new(action_section_def),
    ActionWhen      = Enum:new(action_when_def),
    IfDockedMode    = Enum:new(if_docked_mode_def),
    IfWindowedMode  = Enum:new(if_windowed_mode_def),
    SortStrategy    = Enum:new(sort_strategy_def),
    ColorMode       = Enum:new(color_mode_def),
    MarginMode      = Enum:new(margin_mode_def),
    PianoRollFitTimeScope = Enum:new(piano_roll_fit_time_scope),
    PianoRollFitOwnerScope = Enum:new(piano_roll_fit_owner_scope)
}
