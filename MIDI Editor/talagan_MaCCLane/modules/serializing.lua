-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local Tab               = require "classes/tab"
local GlobalScopeRepo   = require "classes/global_scope_repo"
local JSON              = require "lib/json"

Serializing = {}

-- Load tabs contained in entity
Serializing.loadTabsFromEntity = function(mec, etype, entity)
    local succ, v = false, ''

    if not entity and not (etype == Tab.Types.PROJECT) then
        return {}
    end

    if etype == Tab.Types.GLOBAL then
        succ, v = true, GlobalScopeRepo.instance():getContent()
    elseif etype == Tab.Types.PROJECT then
        -- Allow to pass nil
        local master_track = reaper.GetMasterTrack()
        succ, v = reaper.GetSetMediaTrackInfo_String(master_track, "P_EXT:MACCLANE", '', false)
    elseif etype == Tab.Types.TRACK then
        succ, v = reaper.GetSetMediaTrackInfo_String(entity, "P_EXT:MACCLANE", '', false)
    elseif etype == Tab.Types.ITEM then
        succ, v = reaper.GetSetMediaItemInfo_String(entity, "P_EXT:MACCLANE", '', false)
    else
        succ, v = false, ''
    end

    local json_tabs = {}
    if succ then
        pcall(function()
            json_tabs = JSON.decode(v)
        end)
    end

    local tabs = {}
    for uuid, json_tab in pairs(json_tabs) do

        local params = {}
        local state  = nil
        if json_tab.version == 1 then
            -- New format. We save the params and the state, so that when reloading the project it works.
            params = json_tab.params
            state  = json_tab.state
        else
            -- Old format, the full json for this tab was the params (the state was not there at all)
            params = json_tab
        end

        local tab   = Tab:new(mec, entity, params, state)
        -- Use saved uuid
        tab.uuid        = uuid
        tab.new_record  = false

        tabs[tab:UUID()] = tab
    end

    return tabs
end

Serializing.saveTabsToEntitity = function(etype, entity, tabs)
    local succ, v = false, ''

    if not entity and not (etype == Tab.Types.PROJECT) then
        return { success=false, errors={ 'No entity given !'} }
    end

    local tab_params_array = {}
    for uuid, t in pairs(tabs) do
        tab_params_array[uuid] = { version=1, params=t.params, state=t.state }
    end

    local json = JSON.encode(tab_params_array)

    if etype == Tab.Types.GLOBAL then
        GlobalScopeRepo.instance():setContent(json)
    elseif etype == Tab.Types.PROJECT then
        -- Allow to pass nil
        local master_track = reaper.GetMasterTrack()
        succ = reaper.GetSetMediaTrackInfo_String(master_track, "P_EXT:MACCLANE", json, true)
    elseif etype == Tab.Types.TRACK then
        succ = reaper.GetSetMediaTrackInfo_String(entity, "P_EXT:MACCLANE", json, true)
    elseif etype == Tab.Types.ITEM then
        succ = reaper.GetSetMediaItemInfo_String(entity, "P_EXT:MACCLANE", json, true)
    else
        succ = false
    end

    return {success=true, errors={}}
end

Serializing.loadTabTemplate = function(templatePath)
    local file = io.open(templatePath, "rb")
    local ret  = {}

    if not file then
        return ret
    end

    local json = file:read("*all")
    file:close()

    if not json then
        return ret
    end

    local succ, err = pcall(function()
        -- Bypass exceptions. Return nil if failing.
        ret = JSON.decode(json)
    end)

    return ret
end

function Serializing.serializeTabForTemplate(tab)
    return JSON.encode({
        owner_type = tab.owner_type,
        params     = tab.params
    })
end


function Serializing.createTabFromTemplate(mec, templatePath)
    local json        = Serializing.loadTabTemplate(templatePath)

    if not json or not json.params then
        reaper.MB("Failed to load template. Wrong format ?", "Oops.", 0)
        return nil
    end

    -- Set owner dependning on the clue saved in the template
    local owner = nil
    local take  = reaper.MIDIEditor_GetTake(mec.me)
    local item  = nil
    local track = nil

    if take then
        track = reaper.GetMediaItemTake_Track(take)
        item  = reaper.GetMediaItemTake_Item(take)
    end

    if (json.owner_type) == nil or (json.owner_type == Tab.Types.PROJECT) then
        owner = nil
    elseif json.owner_type == Tab.Types.GLOBAL then
        owner = GlobalScopeRepo.instance()
    elseif json.owner_type == Tab.Types.TRACK then
        owner = track
    elseif json.owner_type == Tab.Types.ITEM then
        owner = item
    end

    local tab = Tab:new(mec, owner, json.params, nil)

    return tab
end

return Serializing
