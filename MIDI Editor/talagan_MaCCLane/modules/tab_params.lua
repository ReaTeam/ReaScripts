-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local D = require "modules/defines"

local Enum = require "classes/enum"

local generic_mode_def = {
    { name = 'bypass', human = "Bypass" },
    { name = 'custom', human = "Custom" },
}

local generic_mode_def_with_record = {
    { name = 'bypass', human = "Bypass" },
    { name = 'custom', human = "Custom" },
    { name = 'record', human = 'Record' }
}

local color_mode_def = {
    { name = 'bypass',      human = "Bypass" },
    { name = 'overload',    human = "Override" },
}

local margin_mode_def = {
    { name = 'bypass',      human = "Bypass" },
    { name = 'overload',    human = "Override" },
}

local piano_roll_def = {
    { name = 'bypass',    human = "Bypass" },
    { name = 'custom',    human = "Custom" },
    { name = 'fit',       human = "Fit Notes" },
    { name = 'record',    human = "Record" }
}

-- Main=0, Main (alt recording)=100, MIDI Editor=32060, MIDI Event List Editor=32061, MIDI Inline Editor=32062, Media Explorer=32063
local action_section_def = {
    { name = "main",                human = "Main",         v = D.SECTION_MAIN },
    { name = "midi_editor",         human = "Midi Editor",  v = D.SECTION_MIDI_EDITOR }
}

local action_when_def = {
    { name = 'before' , human = "Before" },
    { name = 'after'  , human = "After" }
}

local docking_mode_def = {
    { name = 'bypass',   human = 'Bypass' },
    { name = 'windowed', human = 'Windowed' },
    { name = 'docked',   human = 'Docked' },
    { name = 'record',   human = 'Record'}
}

local if_docked_mode_def = {
    { name = 'bypass',   human = 'Bypass' },
    { name = 'maximize', human = 'Maximize' },
    { name = 'minimize', human = 'Minimize' },
    { name = 'custom',   human = 'Custom' },
    { name = 'record',   human = 'Record' }
}

local if_windowed_mode_def = {
    { name = 'bypass',   human = 'Bypass' },
    { name = 'custom',   human = 'Custom' },
    { name = 'record',   human = 'Record' }
}

local sort_strategy_def = {
    { name = 'pti_alpha',   human = 'Global|Project|Track|Item - Alphabetical' },
    { name = 'pti_prio',    human = 'Global|Project|Track|Item - Priority' },
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

local time_window_anchoring_def = {
    { name = 'left',        human = 'Left' },
    { name = 'center',      human = 'Center' },
    { name = 'right',       human = 'Right' },
}

local grid_type_def = {
    { name = 'triplet',     human = 'Triplet' },
    { name = 'dotted',      human = 'Dotted' },
    { name = 'straight',    human = 'Straight' },
    { name = 'swing',       human = 'Swing' },
}
local me_coloring_mode_def = {
    { name = 'velocity',    human = "Velocity"},
    { name = 'channel',     human = "Channel"},
    { name = 'pitch',       human = "Pitch"},
    { name = 'source',      human = "Source"},
    { name = 'track',       human = "Track"},
    { name = 'media_item',  human = "Media Item"},
    { name = 'voice',       human = "Voice"},
}

local function SanitizeBool(b, v)
    if b == nil then return v end
    return b
end

return {
    DockingMode             = Enum:new(docking_mode_def),
    CCLaneMode              = Enum:new(generic_mode_def_with_record),
    PianoRollMode           = Enum:new(piano_roll_def),
    MidiChanMode            = Enum:new(generic_mode_def_with_record),
    ActionMode              = Enum:new(generic_mode_def),
    ActionSection           = Enum:new(action_section_def),
    ActionWhen              = Enum:new(action_when_def),
    IfDockedMode            = Enum:new(if_docked_mode_def),
    IfWindowedMode          = Enum:new(if_windowed_mode_def),
    SortStrategy            = Enum:new(sort_strategy_def),
    ColorMode               = Enum:new(color_mode_def),
    MarginMode              = Enum:new(margin_mode_def),

    PianoRollFitTimeScope   = Enum:new(piano_roll_fit_time_scope),
    PianoRollFitOwnerScope  = Enum:new(piano_roll_fit_owner_scope),

    TimeWindowPosMode       = Enum:new(generic_mode_def_with_record),
    TimeWindowSizingMode    = Enum:new(generic_mode_def_with_record),
    TimeWindowAnchoring     = Enum:new(time_window_anchoring_def),
    GridMode                = Enum:new(generic_mode_def_with_record),
    GridType                = Enum:new(grid_type_def),
    MEColoringMode          = Enum:new(generic_mode_def_with_record),
    MEColoringType          = Enum:new(me_coloring_mode_def),

    SanitizeBool            = SanitizeBool
}
