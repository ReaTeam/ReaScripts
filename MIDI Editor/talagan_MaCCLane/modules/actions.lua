-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local S         = require "modules/settings"
local JSON      = require "lib/json"
local MEContext = require "classes/midi_editor_context"
local Tab       = require "classes/tab"

local function LaunchTab(finder)
    local me = reaper.MIDIEditor_GetActive()
    if not me then return end
    local mec = MEContext.getContextForME(me)
    if not mec then return end

    local tabs = mec:tabs()
    local tab  = finder(tabs)

    if not tab then return end
    if not tab:callableByAction() then return end

    tab:onLeftClick(mec, {highlight=0.4})
end


local function LaunchTabNumber(tab_num)
    LaunchTab(function(tabs)
        return tabs[tab_num]
    end)
end

local function LaunchTabNamed(tab_name)
    LaunchTab(function(tabs)
        local matching_tabs = {}
        for _, tab in ipairs(tabs) do
            if tab.params.title == tab_name then
                matching_tabs[#matching_tabs+1] = tab
            end
        end
        table.sort(matching_tabs, function(t1,t2) return Tab.ownerTypePriority(t1.owner_type) > Tab.ownerTypePriority(t2.owner_type) end)
        return matching_tabs[1]
    end)
end

local function LaunchTabByRole(role)
    LaunchTab(function(tabs)
        local matching_tabs = {}
        for _, tab in ipairs(tabs) do
            if tab.params.role == role then
                matching_tabs[#matching_tabs+1] = tab
            end
        end
        table.sort(matching_tabs, function(t1,t2) return Tab.ownerTypePriority(t1.owner_type) > Tab.ownerTypePriority(t2.owner_type) end)
        return matching_tabs[1]
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
