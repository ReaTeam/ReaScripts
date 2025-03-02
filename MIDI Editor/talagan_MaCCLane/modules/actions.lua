-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local S         = require "modules/settings"
local JSON      = require "lib/json"
local MEContext = require "classes/midi_editor_context"

local function LaunchTab(finder)
    local me = reaper.MIDIEditor_GetActive()
    if not me then return end
    local mec = MEContext.getContextForME(me)
    if not mec then return end

    local tabs = mec:tabs()
    local tab  = finder(tabs)

    if not tab then return end

    tab:onLeftClick(mec, {highlight=0.4})
end


local function LaunchTabNumber(tab_num)
    LaunchTab(function(tabs)
        return tabs[tab_num]
    end)
end

local function LaunchTabNamed(tab_name)
    LaunchTab(function(tabs)
        for _, tab in ipairs(tabs) do
            if tab.params.title == tab_name then
                return tab
            end
        end
        return nil
    end)
end

local function LaunchTabByRole(role)
    LaunchTab(function(tabs)
        for _, tab in ipairs(tabs) do
            if tab.params.role == role then
                return tab
            end
        end
        return nil
    end)
end

local function ClearQueuedAction()
    S.setSetting("QueuedAction", nil)
end

local function ProcessIncomingAction()
    local action = S.getSetting("QueuedAction")
    if not action then return end
    ClearQueuedAction()

    local action_def = JSON.decode(action)

    if action_def.type == 'number' then
        LaunchTabNumber(action_def.number)
    elseif action_def.type == 'name' then
        LaunchTabNamed(action_def.name)
    elseif action_def.type == 'role' then
        LaunchTabByRole(action_def.role)
    end
end


return {
    LaunchTabNumber         = LaunchTabNumber,
    LaunchTabNamed          = LaunchTabNamed,
    ProcessIncomingAction   = ProcessIncomingAction,
    ClearQueuedAction       = ClearQueuedAction
}
